-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 04 — Gold: Tabela Enriquecida para Churn (GABARITO)
-- MAGIC
-- MAGIC Objetivo: materializar `gold_beneficiario_enriquecida`, a tabela que o time
-- MAGIC de ciência de dados usará para treinar o modelo de **predição de churn**.
-- MAGIC
-- MAGIC Aqui juntamos o histórico de vigências com os atributos cadastrais da pessoa,
-- MAGIC geramos a **surrogate key** (`SK_BENEFICIARIO`) e derivamos features úteis
-- MAGIC (idade, flag de churn).
-- MAGIC
-- MAGIC **Qualidade nesta etapa:** a surrogate key deve ser única por vigência.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida') AS
SELECT
  b.NU_USUARIO,
  -- Surrogate key: única por (beneficiário, início de vigência)
  XXHASH64(CAST(b.NU_USUARIO AS STRING), CAST(b.DT_INICIO_VIGENCIA AS STRING)) AS SK_BENEFICIARIO,
  b.NU_TITULAR,
  b.FL_STATUS_USUARIO,
  b.CD_PLANO,
  b.DT_CADASTRAMENTO,
  b.DT_CANCELAMENTO,
  b.CD_CANCELAMENTO,
  b.DT_AUDIT,
  b.DT_INICIO_VIGENCIA,
  b.DT_FIM_VIGENCIA,
  p.DT_NASCIMENTO,
  FLOOR(DATEDIFF(b.DT_FIM_VIGENCIA, p.DT_NASCIMENTO) / 365.25) AS IDADE,
  p.CD_SEXO,
  p.NU_CGC_CPF,
  p.NM_PESSOA_RAZAO_SOCIAL,
  p.CD_USUARIO,
  p.VL_MENSALIDADE,
  -- Alvo do modelo: status 4 = cancelado = churn
  CASE WHEN b.FL_STATUS_USUARIO = 4 THEN 1 ELSE 0 END AS FL_CHURN
FROM IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia') b
LEFT JOIN IDENTIFIER(meu_schema || '.slv_usuario_pessoa') p
  ON b.NU_USUARIO = p.NU_USUARIO;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Verificação de qualidade da surrogate key
-- MAGIC O total de linhas deve ser igual ao total de chaves distintas.

-- COMMAND ----------

SELECT
  COUNT(*)                        AS total_linhas,
  COUNT(DISTINCT SK_BENEFICIARIO) AS sk_distintas,
  CASE WHEN COUNT(*) = COUNT(DISTINCT SK_BENEFICIARIO)
       THEN 'OK: SK unica' ELSE 'ERRO: SK duplicada' END AS resultado
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Amostra da tabela final

-- COMMAND ----------

SELECT * FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida') LIMIT 100;
