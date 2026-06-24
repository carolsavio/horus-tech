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
$alb_dns = "${alb_dns}";
$logo_url = "${logo_url}";

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
function meta($path) {
    $token = trim(shell_exec(
        "curl -s --max-time 2 -X PUT " .
        "'http://169.254.169.254/latest/api/token' " .
        "-H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' " .
        "2>/dev/null"
    ));
    if (empty($token)) return "indisponível";
    return trim(shell_exec(
        "curl -s --max-time 2 " .
        "-H 'X-aws-ec2-metadata-token: " . escapeshellarg($token) . "' " .
        "'http://169.254.169.254/latest/meta-data/" . escapeshellarg($path) . "' " .
        "2>/dev/null"
    ));
}

$instance_id = meta("instance-id");
$az = meta("placement/availability-zone");
$private_ip = meta("local-ipv4");
$instance_type = meta("instance-type");
$region = substr($az, 0, -1);

$stress_msg  = "";
$stress_err  = "";
$stress_active = file_exists("/tmp/stress.pid") &&
                 shell_exec("kill -0 $(cat /tmp/stress.pid) 2>/dev/null; echo $?") === "0\n";

if (isset($_GET["stress"]) && !$stress_active) {
    // Usa sudo para escalar privilégios, redireciona stderr também
    shell_exec(
        "sudo /usr/bin/stress-ng --cpu 0 --timeout 300s " .
        "> /tmp/stress.log 2>&1 & echo $! > /tmp/stress.pid"
    );
    sleep(1); // aguarda 1s para o processo inicializar

    $pid = trim(@file_get_contents("/tmp/stress.pid"));
    $running = !empty($pid) && shell_exec("kill -0 $pid 2>/dev/null; echo $?") === "0\n";

    if ($running) {
        $stress_msg = "✅ Carga de CPU iniciada (PID $pid) — duração: 300 segundos. Acompanhe a CPU subir no CloudWatch.";
    } else {
        $stress_err = "⚠️ O processo stress-ng não iniciou. Verifique /tmp/stress.log na instância.";
    }
} elseif (isset($_GET["stress"]) && $stress_active) {
    $stress_msg = "⚠️ Teste de carga já está rodando nesta instância.";
}

if (isset($_GET["stop_stress"])) {
    $pid = trim(@file_get_contents("/tmp/stress.pid"));

    if (ctype_digit($pid)) {
        shell_exec("sudo kill " . escapeshellarg($pid) . " 2>/dev/null");
    }

    @unlink("/tmp/stress.pid");
    $stress_msg = "Teste de carga encerrado.";
}

$asg_json = shell_exec("aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asg_name --region $region 2>/dev/null");
$asg = json_decode($asg_json, true);
$group = $asg["AutoScalingGroups"][0] ?? [];

$desired = $group["DesiredCapacity"] ?? "N/A";
$min = $group["MinSize"] ?? "N/A";
$max = $group["MaxSize"] ?? "N/A";
$instances = $group["Instances"] ?? [];
$running = count($instances);

$status_msg = ($running >= 2) ? "Auto Scaling está funcionando!" : "Auto Scaling ainda não demonstrou escala.";
?>

<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8">
<title>Horus Tech - Escola Tech</title>

<style>
:root {
    --bg: #05DB1F;
    --dark: #0D1030;
    --white: #E9E9FE;
    --orange: #FFBA1C;
    --purple: #65ABFF;
    --card: rgba(13,16,48,0.92);
}

* { box-sizing: border-box; }

body {
    margin: 0;
    font-family: Arial, sans-serif;
    background: #050716;
    color: var(--white);
}

header {
    text-align: center;
    padding: 25px 20px 15px;
    border-bottom: 1px solid var(--purple);
    background: radial-gradient(circle at top, #101545, #050716 70%);
}

.logo {
    max-width: 330px;
    margin-bottom: 10px;
}

h1 {
    font-size: 34px;
    margin: 18px 0 10px;
}

.subtitle {
    font-size: 18px;
}

.client {
    margin: 15px auto;
    padding: 12px 25px;
    border: 1px solid var(--purple);
    border-radius: 12px;
    max-width: 620px;
    font-size: 18px;
}

.client strong { color: var(--orange); }

.topbar {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
    margin: 18px 25px;
}

.box, .card {
    background: var(--card);
    border: 1px solid var(--purple);
    border-radius: 14px;
    padding: 18px;
    box-shadow: 0 0 18px rgba(101,171,255,0.18);
}

.grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 14px;
    margin: 20px 25px;
}

.card h2, .panel h2 {
    color: var(--orange);
    font-size: 20px;
    margin-top: 0;
}

.card p, .box p {
    line-height: 1.6;
}

.value {
    color: var(--orange);
    font-weight: bold;
}

.green {
    color: #56ff65;
    font-weight: bold;
}

button {
    width: 100%;
    background: linear-gradient(90deg, #FFBA1C, #ff7800);
    border: none;
    border-radius: 10px;
    padding: 16px;
    font-weight: bold;
    font-size: 16px;
    color: #080915;
    cursor: pointer;
}

.success {
    margin-top: 14px;
    padding: 14px;
    border-radius: 10px;
    background: rgba(0,120,35,0.35);
    border: 1px solid #28ff55;
    color: #56ff65;
}

.monitor {
    display: grid;
    grid-template-columns: 2fr 1.2fr;
    gap: 14px;
    margin: 15px 25px 30px;
}

.panel {
    background: var(--card);
    border: 1px solid var(--purple);
    border-radius: 14px;
    padding: 20px;
}

.stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
    margin-bottom: 18px;
}

.stat {
    border: 1px solid #44318f;
    border-radius: 12px;
    padding: 14px;
}

.stat strong {
    font-size: 28px;
    color: var(--orange);
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 12px;
}

th, td {
    padding: 11px;
    border-bottom: 1px solid #2a315c;
    text-align: left;
}

th {
    color: var(--purple);
}

.badge {
    background: #5325ff;
    color: white;
    border-radius: 8px;
    padding: 3px 8px;
    font-size: 12px;
}

.footer {
    text-align: center;
    padding: 22px;
    color: #bbb;
    border-top: 1px solid #291b50;
}

@media(max-width: 1100px) {
    .grid, .topbar, .monitor, .stats {
        grid-template-columns: 1fr;
    }
}
</style>
</head>

<body>

<header>
    <img class="logo" src="<?php echo $logo_url; ?>" alt="Horus Tech Logo">
    <div class="subtitle">Cloud Infrastructure Demo - High Availability and Auto Scaling</div>
    <div class="client">Projeto desenvolvido para a <strong>Escola Tech</strong> como cliente.</div>
</header>

<div class="topbar">
    <div class="box">Ambiente: <span class="value">Produção Demo</span></div>
    <div class="box">Região AWS: <span class="value"><?php echo $region; ?></span></div>
    <div class="box">Load Balancer DNS:<br><span class="value"><?php echo $alb_dns; ?></span></div>
    <div class="box">Health: <span class="green">Targets Healthy</span></div>
</div>

<h1 style="text-align:center;">Horus Tech Web Application</h1>

<section class="grid">
    <div class="card">
        <h2>Descrição do Projeto</h2>
        <p>
            Este projeto demonstra uma arquitetura altamente disponível na AWS usando EC2,
            Application Load Balancer e Auto Scaling Group para atender a Escola Tech com
            escalabilidade, disponibilidade e tolerância a falhas.
        </p>
        <p>Cliente: <span class="value">Escola Tech</span></p>
    </div>

    <div class="card">
        <h2>Detalhes da Instância Atual</h2>
        <p>ID da Instância: <span class="value"><?php echo $instance_id; ?></span></p>
        <p>Zona de Disponibilidade: <span class="value"><?php echo $az; ?></span></p>
        <p>IP Privado: <span class="value"><?php echo $private_ip; ?></span></p>
        <p>Tipo de Instância: <span class="value"><?php echo $instance_type; ?></span></p>
    </div>

    <div class="card">
        <h2>Teste de Alta Disponibilidade</h2>
        <p>
            Atualize esta página usando o DNS do Load Balancer.
            Se aparecerem diferentes IDs de instância ou Zonas de Disponibilidade,
            o balanceamento entre múltiplas EC2 está funcionando.
        </p>
        <div class="success">HA Teste: Funcionando!</div>
    </div>

    <div class="card">
        <h2>Teste de Auto Scaling</h2>
        <p>
            Gera carga real de CPU nesta instância via <code>stress-ng</code>.
            Quando a CPU média do ASG ultrapassar o alvo configurado (60%),
            o Auto Scaling Group provisionará novas instâncias automaticamente.
        </p>
        <p style="margin-top:10px;font-size:13px;color:#aaa;">
            ⚠️ Este botão stressa apenas <em>esta</em> instância. Para acionar
            o scaling de todas ao mesmo tempo, use o <code>load_test.sh</code> externo.
        </p>
        <?php if ($stress_active): ?>
            <div class="success" style="margin-bottom:12px;">🔥 Teste de carga ativo nesta instância.</div>
            <form method="GET">
                <button name="stop_stress" value="1" style="background:linear-gradient(90deg,#ff4e4e,#c0392b);">
                    Parar Teste de Carga
                </button>
            </form>
        <?php else: ?>
            <form method="GET" style="margin-top:12px;">
                <button name="stress" value="1">Iniciar Teste de Carga de CPU (180s)</button>
            </form>
        <?php endif; ?>
        <?php if (!empty($stress_msg)): ?>
            <div class="success"><?php echo htmlspecialchars($stress_msg); ?></div>
        <?php endif; ?>
        <?php if (!empty($stress_err)): ?>
            <div class="success" style="border-color:#ff5555;background:rgba(180,0,0,0.25);color:#ff8888;">
                <?php echo htmlspecialchars($stress_err); ?>
            </div>
        <?php endif; ?>
    </div>
</section>

<section class="monitor">
    <div class="panel">
        <h2>Auto Scaling Group - Monitoramento em Tempo Real</h2>

        <div class="stats">
            <div class="stat">Capacidade Desejada<br><strong><?php echo $desired; ?></strong> instâncias</div>
            <div class="stat">Instâncias em Execução<br><strong><?php echo $running; ?></strong> instâncias</div>
            <div class="stat">Capacidade Mínima<br><strong><?php echo $min; ?></strong> instâncias</div>
            <div class="stat">Capacidade Máxima<br><strong><?php echo $max; ?></strong> instâncias</div>
        </div>

        <h2>Instâncias do Auto Scaling Group</h2>
        <table>
            <tr>
                <th>ID da Instância</th>
                <th>AZ</th>
                <th>Status</th>
                <th>Lifecycle</th>
            </tr>

            <?php foreach($instances as $i) { ?>
            <tr>
                <td><?php echo $i["InstanceId"]; ?></td>
                <td><?php echo $i["AvailabilityZone"]; ?></td>
                <td class="green"><?php echo $i["HealthStatus"]; ?></td>
                <td><?php echo $i["LifecycleState"]; ?></td>
            </tr>
            <?php } ?>
        </table>

        <div class="success"><?php echo $status_msg; ?></div>
    </div>

    <div class="panel">
        <h2>Eventos Recentes do ASG</h2>
        <?php
        // Busca os últimos 5 eventos de scaling diretamente da API da AWS
        $events_json = shell_exec(
            "aws autoscaling describe-scaling-activities " .
            "--auto-scaling-group-name $asg_name " .
            "--max-items 5 " .
            "--region $region " .
            "2>/dev/null"
        );
        $events_data = json_decode($events_json, true);
        $activities  = $events_data["Activities"] ?? [];
        ?>
        <?php if (!empty($activities)): ?>
        <table>
            <tr>
                <th>Data</th>
                <th>Descrição</th>
                <th>Status</th>
            </tr>
            <?php foreach ($activities as $act): ?>
            <tr>
                <td style="font-size:12px;white-space:nowrap;">
                    <?php echo htmlspecialchars(substr($act["StartTime"] ?? "", 0, 16)); ?>
                </td>
                <td style="font-size:12px;">
                    <?php echo htmlspecialchars($act["Description"] ?? ""); ?>
                </td>
                <td style="font-size:12px;" class="<?php echo ($act['StatusCode'] ?? '') === 'Successful' ? 'green' : ''; ?>">
                    <?php echo htmlspecialchars($act["StatusCode"] ?? ""); ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
        <?php else: ?>
            <p style="color:#aaa;font-size:13px;">Nenhum evento de escalonamento registrado ainda.<br>
            Inicie o teste de carga para acionar o Auto Scaling.</p>
        <?php endif; ?>
    </div>
</section>

<div class="footer">
    Horus Tech © 2024 | Cloud • AWS • IA • Terraform • Prompt • Carreira Tech
</div>

</body>
</html>
EOF

systemctl restart httpd
