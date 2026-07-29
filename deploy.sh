#!/usr/bin/env bash
# ============================================================================
# Deploy do Workshop Hapvida x Databricks (INSTRUTOR)
# Publica os notebooks no workspace usando a Databricks CLI.
# ============================================================================
set -euo pipefail

# Perfil da CLI já autenticado (ajuste se necessário)
PROFILE="${DATABRICKS_PROFILE:-classic-stable}"

# Pasta destino no workspace do instrutor
WS_DEST="${WS_DEST:-/Workspace/Shared/hapvida-saude-workshop}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> Perfil Databricks : ${PROFILE}"
echo ">> Destino no workspace: ${WS_DEST}"

# Confere se a CLI está disponível
if ! command -v databricks >/dev/null 2>&1; then
  echo "ERRO: Databricks CLI não encontrada. Instale: https://docs.databricks.com/dev-tools/cli/"
  exit 1
fi

echo ">> Criando diretório destino..."
databricks --profile "${PROFILE}" workspace mkdirs "${WS_DEST}" || true

echo ">> Importando notebooks de setup..."
databricks --profile "${PROFILE}" workspace import-dir \
  "${SCRIPT_DIR}/00-setup" "${WS_DEST}/00-setup" --overwrite

echo ">> Importando notebooks de engenharia de dados..."
databricks --profile "${PROFILE}" workspace import-dir \
  "${SCRIPT_DIR}/01-engenharia-dados" "${WS_DEST}/01-engenharia-dados" --overwrite

echo ">> Deploy concluído em ${WS_DEST}"
echo ">> Lembrete: rode 00-setup/gerar_dados_sinteticos.sql se precisar popular a bronze."
