-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 02 — Silver: Usuário + Pessoa
-- MAGIC
-- MAGIC Objetivo: produzir `slv_usuario_pessoa`, cruzando beneficiários com o
-- MAGIC cadastro de pessoas, aplicando **4 camadas de qualidade**:
-- MAGIC 1. Tipagem correta (decimal(38,10) → BIGINT/INT/DATE/DECIMAL)
-- MAGIC 2. Filtro `FL_EXCLUIDO = 0`
-- MAGIC 3. Deduplicação com `QUALIFY ROW_NUMBER()`
-- MAGIC 4. Integridade referencial (INNER JOIN) + quarentena dos órfãos

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Tabela silver usuário + pessoa
-- MAGIC
-- MAGIC Dica: use duas CTEs (usuario_limpo, pessoa_limpa), cada uma com
-- MAGIC `WHERE FL_EXCLUIDO = 0` e `QUALIFY ROW_NUMBER() OVER (PARTITION BY <chave>
-- MAGIC ORDER BY dt_carga_bronze DESC) = 1`. Depois faça INNER JOIN por CD_PESSOA.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_usuario_pessoa') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Quarentena de órfãos
-- MAGIC Registre (não descarte!) os beneficiários sem pessoa correspondente
-- MAGIC em `<seu_schema>.qua_usuario_orfao`, com um motivo e um timestamp.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.qua_usuario_orfao') AS ...
--       (LEFT JOIN usuario x pessoa, filtrando onde pessoa é NULL)


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

-- TODO: conte quantos registros ficaram na silver e quantos na quarentena

