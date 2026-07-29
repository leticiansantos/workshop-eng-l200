-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 04 — Gold: Tabela Enriquecida para Churn
-- MAGIC
-- MAGIC Objetivo: materializar `gold_beneficiario_enriquecida` — a tabela que o
-- MAGIC time de ML usará para prever churn. Junta vigências + cadastro, gera a
-- MAGIC surrogate key e deriva features (idade, flag de churn).

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Tabela gold enriquecida
-- MAGIC
-- MAGIC Junte `slv_beneficiario_vigencia` (b) com `slv_usuario_pessoa` (p) por NU_USUARIO.
-- MAGIC Inclua:
-- MAGIC - `SK_BENEFICIARIO = XXHASH64(CAST(NU_USUARIO AS STRING), CAST(DT_INICIO_VIGENCIA AS STRING))`
-- MAGIC - `IDADE = FLOOR(DATEDIFF(DT_FIM_VIGENCIA, DT_NASCIMENTO) / 365.25)`
-- MAGIC - `FL_CHURN = CASE WHEN FL_STATUS_USUARIO = 4 THEN 1 ELSE 0 END`

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Verifique a unicidade da surrogate key
-- MAGIC O total de linhas deve ser igual ao total de SK distintas.

-- COMMAND ----------

-- TODO: compare COUNT(*) com COUNT(DISTINCT SK_BENEFICIARIO)


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Amostra final

-- COMMAND ----------

-- TODO: SELECT * ... LIMIT 100

