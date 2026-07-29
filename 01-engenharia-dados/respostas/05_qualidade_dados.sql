-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 05 — Qualidade de Dados: Painel Consolidado (GABARITO)
-- MAGIC
-- MAGIC Ao longo dos módulos 02–04 aplicamos regras de qualidade dentro das
-- MAGIC transformações. Aqui **consolidamos** essas regras num painel único,
-- MAGIC que serve como "porta de qualidade" (data quality gate) do pipeline.
-- MAGIC
-- MAGIC A ideia: cada linha é uma métrica; valores fora do esperado sinalizam
-- MAGIC problemas antes de os dados chegarem ao modelo de churn.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.dq_metricas') AS
SELECT 'silver_beneficiarios_validos' AS metrica,
       CAST(COUNT(*) AS STRING) AS valor,
       'informativo' AS severidade
FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')

UNION ALL
SELECT 'quarentena_orfaos',
       CAST(COUNT(*) AS STRING),
       CASE WHEN COUNT(*) > 0 THEN 'atencao' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.qua_usuario_orfao')

UNION ALL
SELECT 'gold_vigencias',
       CAST(COUNT(*) AS STRING),
       'informativo'
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')

UNION ALL
SELECT 'sk_duplicadas',
       CAST(COUNT(*) - COUNT(DISTINCT SK_BENEFICIARIO) AS STRING),
       CASE WHEN COUNT(*) - COUNT(DISTINCT SK_BENEFICIARIO) > 0 THEN 'erro' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')

UNION ALL
SELECT 'gold_idade_invalida',
       CAST(SUM(CASE WHEN IDADE < 0 OR IDADE > 120 THEN 1 ELSE 0 END) AS STRING),
       CASE WHEN SUM(CASE WHEN IDADE < 0 OR IDADE > 120 THEN 1 ELSE 0 END) > 0 THEN 'erro' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')

UNION ALL
SELECT 'gold_mensalidade_negativa',
       CAST(SUM(CASE WHEN VL_MENSALIDADE < 0 THEN 1 ELSE 0 END) AS STRING),
       CASE WHEN SUM(CASE WHEN VL_MENSALIDADE < 0 THEN 1 ELSE 0 END) > 0 THEN 'erro' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Painel de qualidade

-- COMMAND ----------

SELECT * FROM IDENTIFIER(meu_schema || '.dq_metricas') ORDER BY severidade, metrica;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Porta de qualidade: falha se houver qualquer erro
-- MAGIC Se esta query retornar linhas, o pipeline **não** deveria seguir para produção.

-- COMMAND ----------

SELECT * FROM IDENTIFIER(meu_schema || '.dq_metricas') WHERE severidade = 'erro';
