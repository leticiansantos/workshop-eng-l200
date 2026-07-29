-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 05 — Qualidade de Dados: Painel Consolidado
-- MAGIC
-- MAGIC Consolide as regras de qualidade dos módulos anteriores num painel único
-- MAGIC (`dq_metricas`), que funciona como "porta de qualidade" do pipeline.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 1 — Tabela de métricas
-- MAGIC
-- MAGIC Crie `dq_metricas` (colunas: metrica, valor, severidade) com UNION ALL de,
-- MAGIC pelo menos:
-- MAGIC - beneficiários válidos na silver
-- MAGIC - registros em quarentena (severidade 'atencao' se > 0)
-- MAGIC - vigências na gold
-- MAGIC - SK duplicadas (severidade 'erro' se > 0)
-- MAGIC - idades inválidas (< 0 ou > 120)
-- MAGIC - mensalidades negativas

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.dq_metricas') AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 2 — Painel

-- COMMAND ----------

-- TODO: SELECT * ... ORDER BY severidade, metrica


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício 3 — Porta de qualidade
-- MAGIC Retorne apenas as métricas com severidade 'erro'. Se vier vazio, o
-- MAGIC pipeline está saudável.

-- COMMAND ----------

-- TODO: SELECT ... WHERE severidade = 'erro'

