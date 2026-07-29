-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 06 — Lakeflow Declarative Pipeline (SQL)
-- MAGIC
-- MAGIC Reescreva o pipeline dos módulos 02–04 de forma **declarativa**.
-- MAGIC
-- MAGIC > **Como executar:** este notebook é o código-fonte de um **Pipeline**.
-- MAGIC > Crie um Lakeflow Declarative Pipeline apontando para este notebook,
-- MAGIC > destino = catálogo `workshop_dev` + seu schema, e clique em Start.
-- MAGIC
-- MAGIC Dicas de sintaxe:
-- MAGIC - `CREATE OR REFRESH MATERIALIZED VIEW <nome> ( CONSTRAINT <c> EXPECT (<cond>) [ON VIOLATION DROP ROW] ) AS <query>`
-- MAGIC - Referencie tabelas do próprio pipeline com o prefixo `LIVE.` (ex.: `LIVE.slv_usuario_pessoa`).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — MV slv_usuario_pessoa (com CONSTRAINT EXPECT)

-- COMMAND ----------

-- TODO: CREATE OR REFRESH MATERIALIZED VIEW slv_usuario_pessoa ( ... ) AS
--       (mesma lógica do módulo 02, lendo de hapvida_dev.bronze.*)


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — MV slv_eventos (lendo LIVE.slv_usuario_pessoa)

-- COMMAND ----------

-- TODO


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 3 — MV slv_beneficiario_vigencia (CONSTRAINT vigencia_valida)

-- COMMAND ----------

-- TODO


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 4 — MV gold_beneficiario_enriquecida (CONSTRAINTs de SK e idade)

-- COMMAND ----------

-- TODO

