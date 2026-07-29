-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 07 — Consumo e Orquestração (GABARITO)
-- MAGIC
-- MAGIC Com a gold pronta, criamos as **views de consumo** que respondem perguntas
-- MAGIC de negócio sobre churn, e discutimos como **orquestrar** o pipeline.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## View: estado atual de cada beneficiário
-- MAGIC A gold tem uma linha por vigência. Para análises de "foto atual",
-- MAGIC pegamos a vigência mais recente por beneficiário.

-- COMMAND ----------

CREATE OR REPLACE VIEW IDENTIFIER(meu_schema || '.vw_beneficiario_atual') AS
SELECT *
FROM IDENTIFIER(meu_schema || '.gold_beneficiario_enriquecida')
QUALIFY ROW_NUMBER() OVER (PARTITION BY NU_USUARIO ORDER BY DT_FIM_VIGENCIA DESC) = 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Análise de churn por plano e faixa etária

-- COMMAND ----------

SELECT
  CD_PLANO,
  CASE WHEN IDADE < 18 THEN '00-17' WHEN IDADE < 30 THEN '18-29'
       WHEN IDADE < 45 THEN '30-44' WHEN IDADE < 60 THEN '45-59'
       ELSE '60+' END AS faixa_etaria,
  COUNT(*)                          AS beneficiarios,
  SUM(FL_CHURN)                     AS cancelados,
  ROUND(100.0 * AVG(FL_CHURN), 1)   AS pct_churn,
  ROUND(AVG(VL_MENSALIDADE), 2)     AS ticket_medio
FROM IDENTIFIER(meu_schema || '.vw_beneficiario_atual')
GROUP BY CD_PLANO, faixa_etaria
ORDER BY CD_PLANO, faixa_etaria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Churn por sexo

-- COMMAND ----------

SELECT
  CD_SEXO,
  COUNT(*)                        AS beneficiarios,
  ROUND(100.0 * AVG(FL_CHURN), 1) AS pct_churn
FROM IDENTIFIER(meu_schema || '.vw_beneficiario_atual')
GROUP BY CD_SEXO
ORDER BY CD_SEXO;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Orquestração
-- MAGIC
-- MAGIC Para rodar este pipeline de forma recorrente, há duas opções principais:
-- MAGIC
-- MAGIC 1. **Lakeflow Job** com uma tarefa por notebook (00 → 07), na ordem.
-- MAGIC    Cada tarefa depende da anterior; falhas param o fluxo.
-- MAGIC 2. **Lakeflow Declarative Pipeline** (módulo 06): o próprio pipeline
-- MAGIC    resolve dependências e reprocessa só o necessário — recomendado
-- MAGIC    para produção.
-- MAGIC
-- MAGIC **Comparação imperativo x declarativo:**
-- MAGIC
-- MAGIC | Aspecto            | Imperativo (mód. 01–05) | Declarativo (mód. 06) |
-- MAGIC |--------------------|-------------------------|-----------------------|
-- MAGIC | Ordem de execução  | você controla           | Lakeflow deduz        |
-- MAGIC | Qualidade          | queries manuais         | CONSTRAINT EXPECT     |
-- MAGIC | Reprocessamento    | tabela inteira          | incremental           |
-- MAGIC | Observabilidade    | manual                  | painel do pipeline    |
