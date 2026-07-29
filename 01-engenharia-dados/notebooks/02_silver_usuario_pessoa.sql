-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 02 — Silver: Usuário + Pessoa
-- MAGIC
-- MAGIC Objetivo: `slv_usuario_pessoa`, base limpa e conformada, com **4 camadas
-- MAGIC de qualidade**: tipagem, filtro `FL_EXCLUIDO`, deduplicação (`QUALIFY`) e
-- MAGIC integridade referencial (INNER JOIN) + quarentena dos órfãos.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Silver usuário + pessoa
-- MAGIC
-- MAGIC Este é o coração da limpeza. **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie a tabela IDENTIFIER(meu_schema || '.slv_usuario_pessoa') juntando
-- MAGIC > `hapvida_dev.bronze.raw_hap_tb_usuario` com `raw_hap_tb_pessoa` por CD_PESSOA.
-- MAGIC > Antes do join, em cada tabela: filtre FL_EXCLUIDO = 0, converta as colunas
-- MAGIC > decimais para BIGINT/INT/DATE/DECIMAL(18,2) apropriados, e mantenha apenas
-- MAGIC > a versão mais recente por chave usando QUALIFY ROW_NUMBER() ordenado por
-- MAGIC > dt_carga_bronze DESC. Use INNER JOIN para manter só beneficiários com
-- MAGIC > cadastro válido. Traga NU_USUARIO, NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO,
-- MAGIC > datas de cadastramento/cancelamento, CD_CANCELAMENTO, CD_USUARIO,
-- MAGIC > VL_MENSALIDADE, e da pessoa: CD_PESSOA, DT_NASCIMENTO, sexo, CPF/CNPJ e nome."_
-- MAGIC
-- MAGIC Revise o SQL gerado (compare com `respostas/02_...`) antes de rodar.

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — quarentena de órfãos
-- MAGIC Beneficiários sem pessoa não são descartados: ficam registrados com motivo.

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.qua_usuario_orfao') AS
SELECT
  CAST(u.NU_USUARIO AS BIGINT) AS NU_USUARIO,
  CAST(u.CD_PESSOA  AS BIGINT) AS CD_PESSOA,
  'CD_PESSOA sem correspondencia em raw_hap_tb_pessoa' AS motivo_quarentena,
  CURRENT_TIMESTAMP() AS dt_quarentena
FROM hapvida_dev.bronze.raw_hap_tb_usuario u
LEFT JOIN hapvida_dev.bronze.raw_hap_tb_pessoa p ON p.CD_PESSOA = u.CD_PESSOA
WHERE CAST(u.FL_EXCLUIDO AS INT) = 0 AND p.CD_PESSOA IS NULL;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')) AS validos,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.qua_usuario_orfao'))  AS em_quarentena;
