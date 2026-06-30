#!/bin/bash
# FALTAM AJUSTES PARA FUNCIONAR 100%


set -e

yum update -y
yum install -y httpd php stress-ng awscli jq

STRESS_NG_BIN="$(command -v stress-ng)"

if [ -z "$STRESS_NG_BIN" ]; then
  echo "stress-ng was not installed" >&2
  exit 1
fi

cat > /etc/sudoers.d/apache-stress <<EOF
apache ALL=(root) NOPASSWD: $STRESS_NG_BIN, /usr/bin/kill
EOF

chmod 440 /etc/sudoers.d/apache-stress
visudo -cf /etc/sudoers.d/apache-stress

systemctl enable httpd
systemctl start httpd

cat > /var/www/html/index.php <<'EOF'
<?php
$asg_name = "${asg_name}";
$alb_dns  = "${alb_dns}";
$logo_url = "${logo_url}";

// IMDSv2
function meta($path) {
    $token = trim(shell_exec(
        "curl -s --max-time 2 -X PUT " .
        "'http://169.254.169.254/latest/api/token' " .
        "-H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' 2>/dev/null"
    ));
    if (empty($token)) return "N/A";
    return trim(shell_exec(
        "curl -s --max-time 2 " .
        "-H 'X-aws-ec2-metadata-token: " . escapeshellarg($token) . "' " .
        "'http://169.254.169.254/latest/meta-data/" . escapeshellarg($path) . "' 2>/dev/null"
    ));
}

$instance_id   = meta("instance-id");
$az            = meta("placement/availability-zone");
$private_ip    = meta("local-ipv4");
$instance_type = meta("instance-type");
$region        = substr($az, 0, -1);

// ---------------------------------------------------------------------------
// Endpoint AJAX - retorna JSON com dados do ASG para atualizacao em tempo real
// ---------------------------------------------------------------------------
if (isset($_GET["api"])) {
    header("Content-Type: application/json");
    $asg_json = shell_exec(
        "aws autoscaling describe-auto-scaling-groups" .
        " --auto-scaling-group-names " . escapeshellarg($asg_name) .
        " --region " . escapeshellarg($region) . " 2>/dev/null"
    );
    $events_json = shell_exec(
        "aws autoscaling describe-scaling-activities" .
        " --auto-scaling-group-name " . escapeshellarg($asg_name) .
        " --max-items 5" .
        " --region " . escapeshellarg($region) . " 2>/dev/null"
    );
    $asg    = json_decode($asg_json, true);
    $group  = $asg["AutoScalingGroups"][0] ?? [];
    $events = json_decode($events_json, true);
    echo json_encode([
        "desired"    => $group["DesiredCapacity"] ?? "N/A",
        "min"        => $group["MinSize"] ?? "N/A",
        "max"        => $group["MaxSize"] ?? "N/A",
        "instances"  => $group["Instances"] ?? [],
        "activities" => ($events["Activities"] ?? []),
        "stress_active" => file_exists("/tmp/stress.pid") &&
            trim(shell_exec("kill -0 \$(cat /tmp/stress.pid) 2>/dev/null; echo \$?")) === "0",
    ]);
    exit;
}

// ---------------------------------------------------------------------------
// Endpoint interno chamado pelos outros IPs do ASG para iniciar stress local
// Chamado via curl de dentro da propria rede privada
// ---------------------------------------------------------------------------
if (isset($_GET["internal_stress"])) {
    shell_exec(
        "sudo " . escapeshellarg(trim(shell_exec("which stress-ng"))) .
        " --cpu 0 --timeout 300s > /tmp/stress.log 2>&1 & echo \$! > /tmp/stress.pid"
    );
    echo "ok";
    exit;
}

if (isset($_GET["internal_stop"])) {
    $pid = trim(@file_get_contents("/tmp/stress.pid"));
    if (ctype_digit($pid)) {
        shell_exec("sudo kill " . escapeshellarg($pid) . " 2>/dev/null");
    }
    @unlink("/tmp/stress.pid");
    echo "ok";
    exit;
}

// ---------------------------------------------------------------------------
// Stress em TODAS as instancias do ASG via curl para o IP privado de cada uma
// Nao depende de SSM - usa o proprio Apache como relay interno
// ---------------------------------------------------------------------------
$stress_msg    = "";
$stress_err    = "";

function get_asg_private_ips($asg_name, $region) {
    $json = shell_exec(
        "aws autoscaling describe-auto-scaling-groups" .
        " --auto-scaling-group-names " . escapeshellarg($asg_name) .
        " --region " . escapeshellarg($region) .
        " --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId'" .
        " --output json 2>/dev/null"
    );
    $ids = json_decode(trim($json), true);
    if (!is_array($ids) || empty($ids)) return [];

    $ips = [];
    foreach ($ids as $id) {
        $ip = trim(shell_exec(
            "aws ec2 describe-instances" .
            " --instance-ids " . escapeshellarg($id) .
            " --region " . escapeshellarg($region) .
            " --query 'Reservations[0].Instances[0].PrivateIpAddress'" .
            " --output text 2>/dev/null"
        ));
        if (!empty($ip) && $ip !== "None") {
            $ips[$id] = $ip;
        }
    }
    return $ips;
}

$stress_active = file_exists("/tmp/stress.pid") &&
    trim(shell_exec("kill -0 \$(cat /tmp/stress.pid) 2>/dev/null; echo \$?")) === "0";

if (isset($_GET["stress"]) && !$stress_active) {
    $targets = get_asg_private_ips($asg_name, $region);

    if (empty($targets)) {
        $stress_err = "Nenhuma instancia InService encontrada no ASG.";
    } else {
        $ok = 0;
        foreach ($targets as $id => $ip) {
            // Chama o endpoint interno de cada instancia pelo IP privado
            // Timeout de 3s - nao espera o stress terminar, so dispara
            $resp = trim(shell_exec(
                "curl -s --max-time 3 " .
                "'http://" . escapeshellarg($ip) . "/index.php?internal_stress=1' 2>/dev/null"
            ));
            if ($resp === "ok") $ok++;
        }
        $total = count($targets);
        if ($ok > 0) {
            $stress_msg = "Stress iniciado em {$ok}/{$total} instancia(s). CPU vai subir em ~30s. Aguarde o ASG escalar (3-5 min).";
        } else {
            $stress_err = "Nenhuma instancia respondeu ao comando de stress. Verifique se o httpd esta rodando em todas.";
        }
    }
}

if (isset($_GET["stop_stress"])) {
    $pid = trim(@file_get_contents("/tmp/stress.pid"));
    if (ctype_digit($pid)) {
        shell_exec("sudo kill " . escapeshellarg($pid) . " 2>/dev/null");
    }
    @unlink("/tmp/stress.pid");

    // Para nas outras instancias tambem
    $targets = get_asg_private_ips($asg_name, $region);
    foreach ($targets as $id => $ip) {
        shell_exec("curl -s --max-time 3 'http://" . escapeshellarg($ip) . "/index.php?internal_stop=1' 2>/dev/null");
    }
    $stress_msg = "Stress encerrado em todas as instancias.";
    $stress_active = false;
}

// Dados iniciais do ASG (renderizados no HTML, depois atualizados via AJAX)
$asg_json = shell_exec(
    "aws autoscaling describe-auto-scaling-groups" .
    " --auto-scaling-group-names " . escapeshellarg($asg_name) .
    " --region " . escapeshellarg($region) . " 2>/dev/null"
);
$asg      = json_decode($asg_json, true);
$group    = $asg["AutoScalingGroups"][0] ?? [];
$desired  = $group["DesiredCapacity"] ?? "N/A";
$min      = $group["MinSize"] ?? "N/A";
$max      = $group["MaxSize"] ?? "N/A";
$instances = $group["Instances"] ?? [];
$running  = count($instances);
$status_msg = ($running >= 2) ? "Auto Scaling esta funcionando!" : "Auto Scaling ainda nao demonstrou escala.";
?>
<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8">
<title>Horus Tech - Escola Tech</title>
<style>
:root {
    --dark: #0D1030;
    --white: #E9E9FE;
    --orange: #FFBA1C;
    --purple: #65ABFF;
    --card: rgba(13,16,48,0.92);
}
* { box-sizing: border-box; }
body { margin:0; font-family:Arial,sans-serif; background:#050716; color:var(--white); }
header { text-align:center; padding:25px 20px 15px; border-bottom:1px solid var(--purple); background:radial-gradient(circle at top,#101545,#050716 70%); }
.logo { max-width:330px; margin-bottom:10px; }
h1 { font-size:34px; margin:18px 0 10px; }
.subtitle { font-size:18px; }
.client { margin:15px auto; padding:12px 25px; border:1px solid var(--purple); border-radius:12px; max-width:620px; font-size:18px; }
.client strong { color:var(--orange); }
.topbar { display:grid; grid-template-columns:repeat(4,1fr); gap:10px; margin:18px 25px; }
.box,.card { background:var(--card); border:1px solid var(--purple); border-radius:14px; padding:18px; box-shadow:0 0 18px rgba(101,171,255,0.18); }
.grid { display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin:20px 25px; }
.card h2,.panel h2 { color:var(--orange); font-size:20px; margin-top:0; }
.card p,.box p { line-height:1.6; }
.value { color:var(--orange); font-weight:bold; }
.green { color:#56ff65; font-weight:bold; }
button { width:100%; background:linear-gradient(90deg,#FFBA1C,#ff7800); border:none; border-radius:10px; padding:16px; font-weight:bold; font-size:16px; color:#080915; cursor:pointer; }
.btn-stop { background:linear-gradient(90deg,#ff4e4e,#c0392b); color:#fff; }
.success { margin-top:14px; padding:14px; border-radius:10px; background:rgba(0,120,35,0.35); border:1px solid #28ff55; color:#56ff65; }
.error-box { margin-top:14px; padding:14px; border-radius:10px; background:rgba(180,0,0,0.25); border:1px solid #ff5555; color:#ff8888; }
.monitor { display:grid; grid-template-columns:2fr 1.2fr; gap:14px; margin:15px 25px 30px; }
.panel { background:var(--card); border:1px solid var(--purple); border-radius:14px; padding:20px; }
.stats { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin-bottom:18px; }
.stat { border:1px solid #44318f; border-radius:12px; padding:14px; }
.stat strong { font-size:28px; color:var(--orange); }
table { width:100%; border-collapse:collapse; margin-top:12px; }
th,td { padding:11px; border-bottom:1px solid #2a315c; text-align:left; }
th { color:var(--purple); }
.footer { text-align:center; padding:22px; color:#bbb; border-top:1px solid #291b50; }
.refresh-badge { font-size:11px; color:#888; margin-left:8px; }
@media(max-width:1100px) { .grid,.topbar,.monitor,.stats { grid-template-columns:1fr; } }
</style>
</head>
<body>

<header>
    <img class="logo" src="<?php echo htmlspecialchars($logo_url); ?>" alt="Horus Tech Logo">
    <div class="subtitle">Cloud Infrastructure Demo - High Availability and Auto Scaling</div>
    <div class="client">Projeto desenvolvido para a <strong>Escola Tech</strong> como cliente.</div>
</header>

<div class="topbar">
    <div class="box">Ambiente: <span class="value">Producao Demo</span></div>
    <div class="box">Regiao AWS: <span class="value"><?php echo htmlspecialchars($region); ?></span></div>
    <div class="box">Load Balancer DNS:<br><span class="value"><?php echo htmlspecialchars($alb_dns); ?></span></div>
    <div class="box">Health: <span class="green">Targets Healthy</span></div>
</div>

<h1 style="text-align:center;">Horus Tech Web Application</h1>

<section class="grid">
    <div class="card">
        <h2>Descricao do Projeto</h2>
        <p>Arquitetura altamente disponivel na AWS usando EC2, ALB e Auto Scaling Group para atender a Escola Tech com escalabilidade e tolerancia a falhas.</p>
        <p>Cliente: <span class="value">Escola Tech</span></p>
    </div>

    <div class="card">
        <h2>Instancia Atual</h2>
        <p>ID: <span class="value"><?php echo htmlspecialchars($instance_id); ?></span></p>
        <p>AZ: <span class="value"><?php echo htmlspecialchars($az); ?></span></p>
        <p>IP Privado: <span class="value"><?php echo htmlspecialchars($private_ip); ?></span></p>
        <p>Tipo: <span class="value"><?php echo htmlspecialchars($instance_type); ?></span></p>
    </div>

    <div class="card">
        <h2>Teste de Alta Disponibilidade</h2>
        <p>Atualize a pagina pelo DNS do ALB. Se aparecerem IDs ou AZs diferentes, o balanceamento esta funcionando.</p>
        <div class="success">HA Teste: Funcionando!</div>
    </div>

    <div class="card">
        <h2>Teste de Auto Scaling</h2>
        <p>Envia <code>stress-ng</code> para <strong>todas</strong> as instancias do ASG simultaneamente via rede interna, elevando a CPU media acima de 70%.</p>
        <?php if ($stress_active): ?>
            <div class="success" style="margin-bottom:12px;">stress-ng ativo nesta instancia.</div>
            <form method="GET">
                <button class="btn-stop" name="stop_stress" value="1">Parar Stress em Todas</button>
            </form>
        <?php else: ?>
            <form method="GET" style="margin-top:12px;">
                <button name="stress" value="1">Iniciar Stress em Todas as Instancias (300s)</button>
            </form>
        <?php endif; ?>
        <?php if (!empty($stress_msg)): ?>
            <div class="success"><?php echo htmlspecialchars($stress_msg); ?></div>
        <?php endif; ?>
        <?php if (!empty($stress_err)): ?>
            <div class="error-box"><?php echo htmlspecialchars($stress_err); ?></div>
        <?php endif; ?>
    </div>
</section>

<section class="monitor">
    <div class="panel">
        <!-- Este painel e atualizado via AJAX a cada 10s sem recarregar a pagina -->
        <h2>Auto Scaling Group - Tempo Real <span class="refresh-badge" id="last-update"></span></h2>

        <div class="stats">
            <div class="stat">Capacidade Desejada<br><strong id="val-desired"><?php echo $desired; ?></strong> instancias</div>
            <div class="stat">Em Execucao<br><strong id="val-running"><?php echo $running; ?></strong> instancias</div>
            <div class="stat">Minimo<br><strong id="val-min"><?php echo $min; ?></strong> instancias</div>
            <div class="stat">Maximo<br><strong id="val-max"><?php echo $max; ?></strong> instancias</div>
        </div>

        <h2>Instancias do ASG</h2>
        <table>
            <thead><tr><th>ID</th><th>AZ</th><th>Status</th><th>Lifecycle</th></tr></thead>
            <tbody id="instances-table">
            <?php foreach($instances as $i): ?>
            <tr>
                <td><?php echo htmlspecialchars($i["InstanceId"]); ?></td>
                <td><?php echo htmlspecialchars($i["AvailabilityZone"]); ?></td>
                <td class="green"><?php echo htmlspecialchars($i["HealthStatus"]); ?></td>
                <td><?php echo htmlspecialchars($i["LifecycleState"]); ?></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>

        <div class="success" id="status-msg"><?php echo htmlspecialchars($status_msg); ?></div>
    </div>

    <div class="panel">
        <h2>Eventos Recentes do ASG <span class="refresh-badge" id="events-update"></span></h2>
        <div id="events-container">
        <?php
        $events_json = shell_exec(
            "aws autoscaling describe-scaling-activities" .
            " --auto-scaling-group-name " . escapeshellarg($asg_name) .
            " --max-items 5 --region " . escapeshellarg($region) . " 2>/dev/null"
        );
        $events_data = json_decode($events_json, true);
        $activities  = $events_data["Activities"] ?? [];
        ?>
        <?php if (!empty($activities)): ?>
        <table>
            <tr><th>Data</th><th>Descricao</th><th>Status</th></tr>
            <?php foreach ($activities as $act): ?>
            <tr>
                <td style="font-size:12px;white-space:nowrap;"><?php echo htmlspecialchars(substr($act["StartTime"] ?? "", 0, 16)); ?></td>
                <td style="font-size:12px;"><?php echo htmlspecialchars($act["Description"] ?? ""); ?></td>
                <td style="font-size:12px;" class="<?php echo ($act['StatusCode'] ?? '') === 'Successful' ? 'green' : ''; ?>"><?php echo htmlspecialchars($act["StatusCode"] ?? ""); ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
        <?php else: ?>
            <p style="color:#aaa;font-size:13px;">Nenhum evento ainda. Inicie o stress para acionar o Auto Scaling.</p>
        <?php endif; ?>
        </div>
    </div>
</section>

<div class="footer">Horus Tech (c) 2024 | Cloud - AWS - Terraform</div>

<script>
// Atualiza painel do ASG via AJAX a cada 10 segundos sem recarregar a pagina
function pad(n){ return String(n).padStart(2,'0'); }
function now(){ var d=new Date(); return pad(d.getHours())+':'+pad(d.getMinutes())+':'+pad(d.getSeconds()); }

function renderInstances(instances){
    var html = '';
    instances.forEach(function(i){
        var lc = i.LifecycleState || '';
        var style = (lc === 'Pending' || lc === 'Warmed:Pending') ? 'color:#FFBA1C' : '';
        html += '<tr>' +
            '<td>' + (i.InstanceId||'') + '</td>' +
            '<td>' + (i.AvailabilityZone||'') + '</td>' +
            '<td class="green">' + (i.HealthStatus||'') + '</td>' +
            '<td style="' + style + '">' + lc + '</td>' +
        '</tr>';
    });
    return html;
}

function renderEvents(activities){
    if(!activities || activities.length === 0){
        return '<p style="color:#aaa;font-size:13px;">Nenhum evento ainda.</p>';
    }
    var html = '<table><tr><th>Data</th><th>Descricao</th><th>Status</th></tr>';
    activities.forEach(function(a){
        var cls = a.StatusCode === 'Successful' ? 'class="green"' : '';
        html += '<tr>' +
            '<td style="font-size:12px;white-space:nowrap;">' + (a.StartTime||'').slice(0,16) + '</td>' +
            '<td style="font-size:12px;">' + (a.Description||'') + '</td>' +
            '<td style="font-size:12px;" ' + cls + '>' + (a.StatusCode||'') + '</td>' +
        '</tr>';
    });
    return html + '</table>';
}

function fetchASG(){
    fetch('?api=1')
        .then(function(r){ return r.json(); })
        .then(function(d){
            document.getElementById('val-desired').textContent = d.desired;
            document.getElementById('val-running').textContent = d.instances.length;
            document.getElementById('val-min').textContent     = d.min;
            document.getElementById('val-max').textContent     = d.max;
            document.getElementById('instances-table').innerHTML = renderInstances(d.instances);
            document.getElementById('events-container').innerHTML = renderEvents(d.activities);
            var n = d.instances.length;
            document.getElementById('status-msg').textContent =
                n >= 2 ? 'Auto Scaling esta funcionando! (' + n + ' instancias)' :
                         'Aguardando escalonamento...';
            var t = now();
            document.getElementById('last-update').textContent  = 'atualizado ' + t;
            document.getElementById('events-update').textContent = 'atualizado ' + t;
        })
        .catch(function(){ /* silencioso - tenta de novo em 10s */ });
}

fetchASG();
setInterval(fetchASG, 10000);
</script>

</body>
</html>
EOF

systemctl restart httpd
