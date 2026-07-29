-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 01 — Bronze: Ingestão para o seu schema
-- MAGIC
-- MAGIC Como `hapvida_dev.bronze` é somente leitura, materializamos uma **cópia
-- MAGIC bronze** no seu schema, com uma coluna técnica de ingestão (`_dt_ingestao`).
-- MAGIC Conceito: `CREATE OR REPLACE TABLE ... AS SELECT` (CTAS), idempotente.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Células prontas — bronze pessoa e auditoria
-- MAGIC Duas das três cópias já vêm prontas como referência de padrão. Rode-as.

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_pessoa') AS
SELECT *, CURRENT_TIMESTAMP() AS _dt_ingestao
FROM hapvida_dev.bronze.raw_hap_tb_pessoa;

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.brz_auditoria') AS
SELECT *, CURRENT_TIMESTAMP() AS _dt_ingestao
FROM hapvida_dev.bronze.raw_hap_au_usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Bronze usuário
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie ou substitua a tabela identificada por `meu_schema || '.brz_usuario'`
-- MAGIC > usando IDENTIFIER, selecionando todas as colunas de
-- MAGIC > `hapvida_dev.bronze.raw_hap_tb_usuario` e adicionando uma coluna
-- MAGIC > `_dt_ingestao` com CURRENT_TIMESTAMP()."_
-- MAGIC
-- MAGIC Siga o mesmo padrão das células prontas acima.

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_pessoa'))    AS brz_pessoa,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_usuario'))   AS brz_usuario,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.brz_auditoria')) AS brz_auditoria;
