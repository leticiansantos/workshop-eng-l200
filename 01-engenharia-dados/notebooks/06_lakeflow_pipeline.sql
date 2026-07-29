-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 06 — Lakeflow Declarative Pipeline (SQL)
-- MAGIC
-- MAGIC Reescreva o pipeline dos módulos 02–04 de forma **declarativa**.
-- MAGIC
-- MAGIC > **Como executar:** este notebook é o código-fonte de um **Pipeline**.
-- MAGIC > Crie um Lakeflow Declarative Pipeline apontando para ele, destino =
-- MAGIC > catálogo `workshop_dev` + seu schema, e clique em Start.
-- MAGIC
-- MAGIC Sintaxe: `CREATE OR REFRESH MATERIALIZED VIEW <nome> ( CONSTRAINT <c>
-- MAGIC EXPECT (<cond>) [ON VIOLATION DROP ROW] ) AS <query>`. Referências internas
-- MAGIC usam o prefixo `LIVE.`.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Células prontas — silver eventos e vigências
-- MAGIC Estas duas MVs já vêm prontas como referência de sintaxe declarativa.

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW slv_eventos AS
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
    AND (NU_TITULAR IS NOT NULL OR FL_STATUS_USUARIO IS NOT NULL
         OR CD_PLANO IS NOT NULL OR DT_CADASTRAMENTO IS NOT NULL)
),
eventos_atual AS (
  SELECT NU_USUARIO, NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO,
         DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO,
         CURRENT_DATE() AS DT_AUDIT
  FROM LIVE.slv_usuario_pessoa
)
SELECT * FROM eventos_historico
UNION ALL
SELECT * FROM eventos_atual;

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW slv_beneficiario_vigencia (
  CONSTRAINT vigencia_valida EXPECT (DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA) ON VIOLATION DROP ROW
) AS
WITH vigencias AS (
  SELECT *,
    DT_AUDIT AS DT_FIM_VIGENCIA,
    COALESCE(LAG(DT_AUDIT) OVER (PARTITION BY NU_USUARIO ORDER BY DT_AUDIT),
             DT_CADASTRAMENTO, DT_AUDIT) AS DT_INICIO_VIGENCIA
  FROM LIVE.slv_eventos
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
WINDOW w AS (PARTITION BY NU_USUARIO ORDER BY DT_FIM_VIGENCIA DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — MV silver com CONSTRAINT EXPECT
-- MAGIC
-- MAGIC Esta é a primeira MV do pipeline (as de cima dependem dela).
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie uma MATERIALIZED VIEW chamada slv_usuario_pessoa com a mesma lógica
-- MAGIC > do módulo 02 (limpeza e join de usuario e pessoa lendo de
-- MAGIC > hapvida_dev.bronze), adicionando duas expectativas de qualidade:
-- MAGIC > CONSTRAINT pessoa_valida EXPECT (CD_PESSOA IS NOT NULL) ON VIOLATION DROP ROW,
-- MAGIC > e CONSTRAINT status_conhecido EXPECT (FL_STATUS_USUARIO IS NOT NULL). Use a
-- MAGIC > sintaxe CREATE OR REFRESH MATERIALIZED VIEW."_
-- MAGIC
-- MAGIC (Compare com `respostas/06_lakeflow_pipeline.sql`.)

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — gold declarativa

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW gold_beneficiario_enriquecida (
  CONSTRAINT sk_nao_nula     EXPECT (SK_BENEFICIARIO IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT idade_plausivel EXPECT (IDADE BETWEEN 0 AND 120)
) AS
SELECT
  b.NU_USUARIO,
  XXHASH64(CAST(b.NU_USUARIO AS STRING), CAST(b.DT_INICIO_VIGENCIA AS STRING)) AS SK_BENEFICIARIO,
  b.NU_TITULAR, b.FL_STATUS_USUARIO, b.CD_PLANO,
  b.DT_CADASTRAMENTO, b.DT_CANCELAMENTO, b.CD_CANCELAMENTO,
  b.DT_AUDIT, b.DT_INICIO_VIGENCIA, b.DT_FIM_VIGENCIA,
  p.DT_NASCIMENTO,
  FLOOR(DATEDIFF(b.DT_FIM_VIGENCIA, p.DT_NASCIMENTO) / 365.25) AS IDADE,
  p.CD_SEXO, p.NU_CGC_CPF, p.NM_PESSOA_RAZAO_SOCIAL, p.CD_USUARIO, p.VL_MENSALIDADE,
  CASE WHEN b.FL_STATUS_USUARIO = 4 THEN 1 ELSE 0 END AS FL_CHURN
FROM LIVE.slv_beneficiario_vigencia b
LEFT JOIN LIVE.slv_usuario_pessoa p ON b.NU_USUARIO = p.NU_USUARIO;
