-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 01 — Bronze: Ingestão para o seu schema (GABARITO)
-- MAGIC
-- MAGIC No ambiente do workshop a fonte `hapvida_dev.bronze` é **somente leitura**.
-- MAGIC Para trabalhar com liberdade, cada participante materializa uma **cópia
-- MAGIC bronze** dentro do seu próprio schema, adicionando metadados de ingestão.
-- MAGIC
-- MAGIC Conceitos:
-- MAGIC - `CREATE TABLE ... AS SELECT` (CTAS) para materializar dados.
-- MAGIC - Coluna técnica de ingestão (`_dt_ingestao`) para rastreabilidade.
-- MAGIC - Idempotência: `CREATE OR REPLACE` permite reexecutar sem duplicar.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze: pessoa

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_pessoa') AS
SELECT *, CURRENT_TIMESTAMP() AS _dt_ingestao
FROM hapvida_dev.bronze.raw_hap_tb_pessoa;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze: usuário (beneficiário)

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_usuario') AS
SELECT *, CURRENT_TIMESTAMP() AS _dt_ingestao
FROM hapvida_dev.bronze.raw_hap_tb_usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze: auditoria

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_auditoria') AS
SELECT *, CURRENT_TIMESTAMP() AS _dt_ingestao
FROM hapvida_dev.bronze.raw_hap_au_usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_pessoa'))    AS brz_pessoa,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_usuario'))   AS brz_usuario,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_auditoria')) AS brz_auditoria;
