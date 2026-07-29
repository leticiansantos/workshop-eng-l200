-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 07 — Consumo e Orquestração
-- MAGIC
-- MAGIC Crie as views de consumo que respondem perguntas de negócio sobre churn.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — View do estado atual
-- MAGIC A gold tem uma linha por vigência. Crie `vw_beneficiario_atual` com apenas
-- MAGIC a vigência mais recente por beneficiário (dica: `QUALIFY ROW_NUMBER()`).

-- COMMAND ----------

-- TODO: CREATE OR REPLACE VIEW IDENTIFIER(meu_schema || '.vw_beneficiario_atual') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Churn por plano e faixa etária
-- MAGIC Agrupe por CD_PLANO e faixa etária; traga beneficiários, cancelados,
-- MAGIC % de churn e ticket médio.

-- COMMAND ----------

-- TODO


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 3 — Churn por sexo

-- COMMAND ----------

-- TODO


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Discussão — Orquestração
-- MAGIC Compare as duas formas de rodar este pipeline de forma recorrente:
-- MAGIC 1. Lakeflow **Job** (uma tarefa por notebook, 00 → 07).
-- MAGIC 2. Lakeflow **Declarative Pipeline** (módulo 06).
-- MAGIC
-- MAGIC Quando usar cada um? Anote suas conclusões aqui.

