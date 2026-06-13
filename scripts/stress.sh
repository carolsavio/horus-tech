#!/usr/bin/env bash
# =============================================================================
# horus_tech_stress_test.sh
# Simulador de acessos de alunos para teste
# TCC - Arquitetura AWS
# Uso: ./stress.sh <URL> <usuarios> <duracao_segundos>
# Ex:  ./stress.sh http://meu-alb.amazonaws.com 200 60
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

URL="${1:?Informe a URL}"
USUARIOS="${2:-50}"
DURACAO="${3:-30}"

echo "Iniciando stress: $USUARIOS usuarios por ${DURACAO}s -> $URL"
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
