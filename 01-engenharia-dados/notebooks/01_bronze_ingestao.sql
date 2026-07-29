-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 01 — Bronze: Ingestão para o seu schema
-- MAGIC
-- MAGIC Como `hapvida_dev.bronze` é somente leitura, cada participante materializa
-- MAGIC uma **cópia bronze** no seu schema, com uma coluna técnica de ingestão.
-- MAGIC
-- MAGIC Conceitos: `CREATE OR REPLACE TABLE ... AS SELECT` (CTAS), coluna `_dt_ingestao`.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Bronze pessoa
-- MAGIC Copie `raw_hap_tb_pessoa` para `<seu_schema>.brz_pessoa`, adicionando
-- MAGIC uma coluna `_dt_ingestao` com `CURRENT_TIMESTAMP()`.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_pessoa') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Bronze usuário

-- COMMAND ----------

-- TODO: mesmo padrão para raw_hap_tb_usuario -> brz_usuario


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 3 — Bronze auditoria

-- COMMAND ----------

-- TODO: mesmo padrão para raw_hap_au_usuario -> brz_auditoria


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

-- TODO: conte as linhas das 3 tabelas bronze que você criou no seu schema

