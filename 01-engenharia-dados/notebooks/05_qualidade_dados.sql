-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 05 — Qualidade de Dados: Painel Consolidado
-- MAGIC
-- MAGIC Consolidamos as regras de qualidade num painel `dq_metricas` que funciona
-- MAGIC como "porta de qualidade" do pipeline.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — painel de métricas
-- MAGIC Rode para materializar o painel com as principais checagens.

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.dq_metricas') AS
SELECT 'silver_beneficiarios_validos' AS metrica,
       CAST(COUNT(*) AS STRING) AS valor, 'informativo' AS severidade
FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')
UNION ALL
SELECT 'quarentena_orfaos', CAST(COUNT(*) AS STRING),
       CASE WHEN COUNT(*) > 0 THEN 'atencao' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.qua_usuario_orfao')
UNION ALL
SELECT 'sk_duplicadas', CAST(COUNT(*) - COUNT(DISTINCT SK_BENEFICIARIO) AS STRING),
       CASE WHEN COUNT(*) - COUNT(DISTINCT SK_BENEFICIARIO) > 0 THEN 'erro' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')
UNION ALL
SELECT 'gold_idade_invalida',
       CAST(SUM(CASE WHEN IDADE < 0 OR IDADE > 120 THEN 1 ELSE 0 END) AS STRING),
       CASE WHEN SUM(CASE WHEN IDADE < 0 OR IDADE > 120 THEN 1 ELSE 0 END) > 0 THEN 'erro' ELSE 'ok' END
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida');

-- COMMAND ----------

SELECT * FROM IDENTIFIER(meu_schema || '.dq_metricas') ORDER BY severidade, metrica;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Porta de qualidade
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Da tabela IDENTIFIER(meu_schema || '.dq_metricas'), retorne apenas as
-- MAGIC > linhas cuja severidade seja 'erro'. Se o resultado vier vazio, o pipeline
-- MAGIC > está saudável e pode seguir para produção."_

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

