-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 00 — Setup e Exploração dos Dados
-- MAGIC
-- MAGIC Antes de construir, vamos **conhecer** a camada bronze (`hapvida_dev.bronze`),
-- MAGIC que é **somente leitura** e tem 3 tabelas.
-- MAGIC
-- MAGIC > Preencha os trechos marcados com `-- TODO`. Confira o gabarito só depois de tentar.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

SELECT meu_schema AS schema_de_trabalho, current_user() AS usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Liste as tabelas da camada bronze

-- COMMAND ----------

-- TODO: use SHOW TABLES para listar as tabelas em hapvida_dev.bronze


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Descreva a estrutura da tabela de beneficiários

-- COMMAND ----------

-- TODO: use DESCRIBE TABLE em hapvida_dev.bronze.raw_hap_tb_usuario


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 3 — Conte os registros de cada tabela

-- COMMAND ----------

-- TODO: retorne, numa única query, a contagem de linhas das 3 tabelas bronze
--       (raw_hap_tb_pessoa, raw_hap_tb_usuario, raw_hap_au_usuario)


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 4 — Distribuição de status dos beneficiários
-- MAGIC (2 = ativo, 4 = cancelado)

-- COMMAND ----------

-- TODO: agrupe raw_hap_tb_usuario por FL_STATUS_USUARIO e conte


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 5 — Quantos beneficiários órfãos existem?
-- MAGIC (beneficiários sem pessoa correspondente — candidatos a quarentena)

-- COMMAND ----------

-- TODO: LEFT JOIN de raw_hap_tb_usuario com raw_hap_tb_pessoa por CD_PESSOA,
--       contando onde a pessoa é NULL

