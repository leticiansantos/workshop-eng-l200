-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 04 — Gold: Tabela Enriquecida para Churn
-- MAGIC
-- MAGIC Materializar `gold_beneficiario_enriquecida` — a tabela que o time de ML
-- MAGIC usará para prever churn. Junta vigências + cadastro, gera a surrogate key
-- MAGIC e deriva features (idade, flag de churn).

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Tabela gold enriquecida
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie a tabela IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')
-- MAGIC > juntando IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia') (b) com
-- MAGIC > IDENTIFIER(meu_schema || '.slv_usuario_pessoa') (p) por NU_USUARIO via LEFT
-- MAGIC > JOIN. Inclua uma surrogate key SK_BENEFICIARIO = XXHASH64(CAST(NU_USUARIO AS
-- MAGIC > STRING), CAST(DT_INICIO_VIGENCIA AS STRING)); IDADE = FLOOR(DATEDIFF(
-- MAGIC > DT_FIM_VIGENCIA, DT_NASCIMENTO)/365.25); e FL_CHURN = CASE WHEN
-- MAGIC > FL_STATUS_USUARIO = 4 THEN 1 ELSE 0 END. Traga também as demais colunas de
-- MAGIC > vigência e os atributos cadastrais da pessoa."_

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — qualidade da surrogate key e amostra
-- MAGIC O total de linhas deve ser igual ao total de SKs distintas.

-- COMMAND ----------

SELECT
  COUNT(*)                        AS total_linhas,
  COUNT(DISTINCT SK_BENEFICIARIO) AS sk_distintas,
  CASE WHEN COUNT(*) = COUNT(DISTINCT SK_BENEFICIARIO)
       THEN 'OK: SK unica' ELSE 'ERRO: SK duplicada' END AS resultado
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida');

-- COMMAND ----------

SELECT * FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida') LIMIT 100;
