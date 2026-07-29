-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 03 — Silver: Eventos e Vigências (SCD2) (GABARITO)
-- MAGIC
-- MAGIC Objetivo: reconstruir a **linha do tempo** de cada beneficiário usando a
-- MAGIC tabela de auditoria (`raw_hap_au_usuario`) somada ao estado atual, e
-- MAGIC calcular os períodos de vigência (SCD Tipo 2) de cada versão do cadastro.
-- MAGIC
-- MAGIC Este é o coração do caso de uso de **churn**: para o modelo de ML, precisamos
-- MAGIC saber como cada beneficiário evoluiu ao longo do tempo (plano, status).
-- MAGIC
-- MAGIC **Camadas de qualidade aplicadas:**
-- MAGIC 1. **Precedência lógica** — filtro da auditoria com parênteses explícitos em `AND/OR`.
-- MAGIC 2. **Vigência válida** — descartamos intervalos onde `DT_FIM <= DT_INICIO`.
-- MAGIC 3. **Preenchimento de atributos** — `FIRST_VALUE(..., true)` propaga o valor
-- MAGIC    mais recente conhecido quando um evento vem com campos nulos.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 1 — Unificar eventos históricos (auditoria) + estado atual

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_eventos') AS
WITH eventos_historico AS (
  SELECT
    CAST(NU_USUARIO AS BIGINT)     AS NU_USUARIO,
    CAST(NU_TITULAR AS BIGINT)     AS NU_TITULAR,
    CAST(FL_STATUS_USUARIO AS INT) AS FL_STATUS_USUARIO,
    CAST(CD_PLANO AS INT)          AS CD_PLANO,
    CAST(DT_CADASTRAMENTO AS DATE) AS DT_CADASTRAMENTO,
    CAST(DT_CANCELAMENTO  AS DATE) AS DT_CANCELAMENTO,
    CAST(CD_CANCELAMENTO  AS INT)  AS CD_CANCELAMENTO,
    CAST(DT_AUDIT AS DATE)         AS DT_AUDIT
  FROM hapvida_dev.bronze.raw_hap_au_usuario
  WHERE CAST(FL_EXCLUIDO AS INT) = 0
    -- QUALIDADE: parênteses corrigem a precedência entre AND e OR.
    -- Sem eles, o filtro FL_EXCLUIDO seria anulado pelos OR seguintes.
    AND (
      NU_TITULAR IS NOT NULL
      OR FL_STATUS_USUARIO IS NOT NULL
      OR CD_PLANO IS NOT NULL
      OR DT_CADASTRAMENTO IS NOT NULL
    )
),
eventos_atual AS (
  SELECT
    NU_USUARIO, NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO,
    DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO,
    CURRENT_DATE() AS DT_AUDIT
  FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')
)
SELECT * FROM eventos_historico
UNION ALL
SELECT * FROM eventos_atual;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 2 — Calcular vigências e preencher atributos (SCD2)
-- MAGIC
-- MAGIC - `DT_FIM_VIGENCIA` = data do evento;
-- MAGIC - `DT_INICIO_VIGENCIA` = data do evento anterior (`LAG`), ou cadastro/auditoria no 1º;
-- MAGIC - `FIRST_VALUE(..., true)` = propaga o valor não-nulo mais recente.

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia') AS
WITH vigencias AS (
  SELECT
    *,
    DT_AUDIT AS DT_FIM_VIGENCIA,
    COALESCE(
      LAG(DT_AUDIT) OVER (PARTITION BY NU_USUARIO ORDER BY DT_AUDIT),
      DT_CADASTRAMENTO,
      DT_AUDIT
    ) AS DT_INICIO_VIGENCIA
  FROM IDENTIFIER(meu_schema || '.slv_eventos')
)
SELECT
  NU_USUARIO,
  FIRST_VALUE(NU_TITULAR, true)        OVER w AS NU_TITULAR,
  FIRST_VALUE(FL_STATUS_USUARIO, true) OVER w AS FL_STATUS_USUARIO,
  FIRST_VALUE(CD_PLANO, true)          OVER w AS CD_PLANO,
  FIRST_VALUE(DT_CADASTRAMENTO, true)  OVER w AS DT_CADASTRAMENTO,
  CASE WHEN DT_CANCELAMENTO < DT_FIM_VIGENCIA THEN DT_CANCELAMENTO END AS DT_CANCELAMENTO,
  CASE WHEN DT_CANCELAMENTO < DT_FIM_VIGENCIA THEN CD_CANCELAMENTO END AS CD_CANCELAMENTO,
  DT_AUDIT, DT_INICIO_VIGENCIA, DT_FIM_VIGENCIA
FROM vigencias
WHERE DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA   -- QUALIDADE: expectativa de vigência válida
WINDOW w AS (
  PARTITION BY NU_USUARIO ORDER BY DT_FIM_VIGENCIA DESC
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_eventos'))                AS eventos,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia'))  AS vigencias;
