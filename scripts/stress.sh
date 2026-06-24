#!/usr/bin/env bash
# =============================================================================
# horus_tech_stress_test.sh
# Simulador de acessos de alunos para teste
# Tem performado melhor que o userdata.sh

cat <<'EOF'
# =============================================================================
# =============================================================================
#   ███████╗████████╗██████╗ ███████╗███████╗███████╗
#   ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
#   ███████╗   ██║   ██████╔╝█████╗  ███████╗███████╗
#   ╚════██║   ██║   ██╔══██╗██╔══╝  ╚════██║╚════██║
#   ███████║   ██║   ██║  ██║███████╗███████║███████║
#   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
#   
#   ████████╗███████╗███████╗████████╗
#   ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
#      ██║   █████╗  ███████╗   ██║
#      ██║   ██╔══╝  ╚════██║   ██║
#      ██║   ███████╗███████║   ██║
#      ╚═╝   ╚══════╝╚══════╝   ╚═╝
# =============================================================================
# =============================================================================
EOF


echo
echo "=== Configuração do Teste ==="
read -rp "URL do sistema: " URL
read -rp "Quantidade de usuários simultâneos [50]: " USUARIOS
read -rp "Duração do teste em segundos [30]: " DURACAO

USUARIOS=${USUARIOS:-50}
DURACAO=${DURACAO:-30}

echo
echo "Iniciando stress: $USUARIOS usuários por ${DURACAO}s -> $URL"
echo "timestamp,status,tempo_ms" > resultado.csv

FIM=$(( $(date +%s) + DURACAO ))

requisicao() {
  local inicio status tempo
  inicio=$(date +%s%3N)
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL" 2>/dev/null || echo "000")
  tempo=$(( $(date +%s%3N) - inicio ))
  echo "$(date '+%H:%M:%S'),$status,$tempo" >> resultado.csv
}
 
while [[ $(date +%s) -lt $FIM ]]; do
  for (( i=1; i<=USUARIOS; i++ )); do
    requisicao &
  done
  wait
  echo "[$(date '+%H:%M:%S')] Onda enviada — $USUARIOS requisicoes simultaneas"
done
 
echo ""
echo "=== Resultado ==="
awk -F',' 'NR>1 { total++; if($2~/^[23]/) ok++; soma+=$3 }
  END { printf "Total: %d | Sucesso: %d | Erros: %d | Tempo medio: %.0fms\n", total, ok, total-ok, soma/total }' resultado.csv
echo "CSV salvo em resultado.csv"
