-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 07 — Consumo e Orquestração
-- MAGIC
-- MAGIC Respostas de negócio sobre churn a partir da gold.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — view do estado atual
-- MAGIC A gold tem uma linha por vigência; aqui pegamos a vigência mais recente
-- MAGIC por beneficiário.

-- COMMAND ----------

CREATE OR REPLACE VIEW IDENTIFIER(meu_schema || '.vw_beneficiario_atual') AS
SELECT *
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')
QUALIFY ROW_NUMBER() OVER (PARTITION BY NU_USUARIO ORDER BY DT_FIM_VIGENCIA DESC) = 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Análise de churn
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Usando IDENTIFIER(meu_schema || '.vw_beneficiario_atual'), mostre a taxa
-- MAGIC > de churn por CD_PLANO e por faixa etária (00-17, 18-29, 30-44, 45-59, 60+).
-- MAGIC > Para cada grupo traga: total de beneficiários, quantidade de cancelados
-- MAGIC > (soma de FL_CHURN), percentual de churn e ticket médio (média de
-- MAGIC > VL_MENSALIDADE)."_
-- MAGIC
-- MAGIC Depois, experimente variar o prompt: churn por sexo, por ano de
-- MAGIC cadastramento, etc.

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Discussão — Orquestração
-- MAGIC Compare as duas formas de rodar o pipeline recorrentemente:
-- MAGIC 1. **Lakeflow Job** — uma tarefa por notebook (00 → 07), você controla a ordem.
-- MAGIC 2. **Lakeflow Declarative Pipeline** (módulo 06) — resolve dependências e
-- MAGIC    reprocessa incrementalmente. Recomendado para produção.
