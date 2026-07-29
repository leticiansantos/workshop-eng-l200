-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 03 — Silver: Eventos e Vigências (SCD2)
-- MAGIC
-- MAGIC Objetivo: reconstruir a linha do tempo de cada beneficiário (auditoria +
-- MAGIC estado atual) e calcular vigências (SCD Tipo 2). Base para o modelo de churn.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Unificar eventos (auditoria) + estado atual
-- MAGIC
-- MAGIC Crie `slv_eventos` com UNION ALL de:
-- MAGIC - **histórico**: `raw_hap_au_usuario` (tipando as colunas e filtrando
-- MAGIC   `FL_EXCLUIDO = 0`). **Atenção à precedência AND/OR**: use parênteses
-- MAGIC   ao redor do bloco de `OR`!
-- MAGIC - **atual**: `slv_usuario_pessoa`, com `CURRENT_DATE() AS DT_AUDIT`.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_eventos') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Vigências (SCD2)
-- MAGIC
-- MAGIC Crie `slv_beneficiario_vigencia`:
-- MAGIC - `DT_FIM_VIGENCIA` = `DT_AUDIT`
-- MAGIC - `DT_INICIO_VIGENCIA` = `COALESCE(LAG(DT_AUDIT) OVER (...), DT_CADASTRAMENTO, DT_AUDIT)`
-- MAGIC - Use `FIRST_VALUE(col, true) OVER (PARTITION BY NU_USUARIO ORDER BY DT_FIM_VIGENCIA DESC ...)`
-- MAGIC   para preencher atributos nulos com o valor mais recente.
-- MAGIC - Mantenha apenas vigências válidas: `DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA`.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

-- TODO: conte as linhas de slv_eventos e slv_beneficiario_vigencia

