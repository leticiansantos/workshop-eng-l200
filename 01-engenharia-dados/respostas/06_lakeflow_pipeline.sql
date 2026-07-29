-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 06 — Lakeflow Declarative Pipeline (SQL) (GABARITO)
-- MAGIC
-- MAGIC Nos módulos anteriores construímos o pipeline de forma **imperativa**:
-- MAGIC nós dissemos *como* fazer (CREATE TABLE após CREATE TABLE, na ordem certa).
-- MAGIC
-- MAGIC Agora reescrevemos o **mesmo** pipeline de forma **declarativa** com
-- MAGIC Lakeflow Declarative Pipelines (SDP). Declaramos *o que* cada tabela é;
-- MAGIC o Lakeflow descobre a ordem, materializa e aplica as regras de qualidade.
-- MAGIC
-- MAGIC > **Como executar:** este arquivo NÃO roda como notebook comum. Ele é o
-- MAGIC > **código-fonte de um Pipeline**. Crie um Lakeflow Pipeline (SDP) apontando
-- MAGIC > para este notebook, defina o catálogo `workshop_dev` e o seu schema como
-- MAGIC > destino, e clique em **Start**.
-- MAGIC
-- MAGIC **Destaque de qualidade:** as regras viram `CONSTRAINT ... EXPECT`, aplicadas
-- MAGIC automaticamente e visíveis no painel do pipeline.
-- MAGIC
-- MAGIC > **Nomes com prefixo `sdp_`:** um Lakeflow Pipeline precisa ser o **dono**
-- MAGIC > das tabelas que materializa. Se as tabelas `slv_*`/`gold_*` já existirem
-- MAGIC > (criadas nos módulos 02–04, manualmente ou via Job), o pipeline falha com
-- MAGIC > `TABLE_ALREADY_EXISTS`. Usando o prefixo `sdp_`, a versão declarativa
-- MAGIC > convive com a imperativa e o pipeline roda quantas vezes for preciso.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Silver 1 — usuário + pessoa (com expectativas)

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW sdp_slv_usuario_pessoa (
  CONSTRAINT pessoa_valida    EXPECT (CD_PESSOA IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT status_conhecido EXPECT (FL_STATUS_USUARIO IS NOT NULL)
) AS
WITH usuario_limpo AS (
  SELECT
    CAST(NU_USUARIO AS BIGINT)            AS NU_USUARIO,
    CAST(NU_TITULAR AS BIGINT)            AS NU_TITULAR,
    CAST(CD_PESSOA  AS BIGINT)            AS CD_PESSOA,
    CD_USUARIO,
    CAST(FL_STATUS_USUARIO AS INT)        AS FL_STATUS_USUARIO,
    CAST(CD_PLANO AS INT)                 AS CD_PLANO,
    CAST(DT_CADASTRAMENTO AS DATE)        AS DT_CADASTRAMENTO,
    CAST(DT_CANCELAMENTO  AS DATE)        AS DT_CANCELAMENTO,
    CAST(CD_CANCELAMENTO  AS INT)         AS CD_CANCELAMENTO,
    CAST(VL_MENSALIDADE AS DECIMAL(18,2)) AS VL_MENSALIDADE
  FROM hapvida_dev.bronze.raw_hap_tb_usuario
  WHERE CAST(FL_EXCLUIDO AS INT) = 0
  QUALIFY ROW_NUMBER() OVER (PARTITION BY NU_USUARIO ORDER BY dt_carga_bronze DESC) = 1
),
pessoa_limpa AS (
  SELECT
    CAST(CD_PESSOA AS BIGINT)             AS CD_PESSOA,
    CAST(DT_NASCIMENTO_FUNDACAO AS DATE)  AS DT_NASCIMENTO,
    FL_SEXO                               AS CD_SEXO,
    CAST(NU_CGC_CPF AS DECIMAL(38,0))     AS NU_CGC_CPF,
    NM_PESSOA_RAZAO_SOCIAL
  FROM hapvida_dev.bronze.raw_hap_tb_pessoa
  WHERE CAST(FL_EXCLUIDO AS INT) = 0
  QUALIFY ROW_NUMBER() OVER (PARTITION BY CD_PESSOA ORDER BY dt_carga_bronze DESC) = 1
)
SELECT
  u.NU_USUARIO, u.NU_TITULAR, u.FL_STATUS_USUARIO, u.CD_PLANO,
  u.DT_CADASTRAMENTO, u.DT_CANCELAMENTO, u.CD_CANCELAMENTO, u.CD_USUARIO, u.VL_MENSALIDADE,
  p.CD_PESSOA, p.DT_NASCIMENTO, p.CD_SEXO, p.NU_CGC_CPF, p.NM_PESSOA_RAZAO_SOCIAL
FROM usuario_limpo u
INNER JOIN pessoa_limpa p ON p.CD_PESSOA = u.CD_PESSOA;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Silver 2 — eventos unificados

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW sdp_slv_eventos AS
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
  FROM LIVE.sdp_slv_usuario_pessoa
)
SELECT * FROM eventos_historico
UNION ALL
SELECT * FROM eventos_atual;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Silver 3 — vigências (SCD2)

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW sdp_slv_beneficiario_vigencia (
  CONSTRAINT vigencia_valida EXPECT (DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA) ON VIOLATION DROP ROW
) AS
WITH vigencias AS (
  SELECT *,
    DT_AUDIT AS DT_FIM_VIGENCIA,
    COALESCE(LAG(DT_AUDIT) OVER (PARTITION BY NU_USUARIO ORDER BY DT_AUDIT),
             DT_CADASTRAMENTO, DT_AUDIT) AS DT_INICIO_VIGENCIA
  FROM LIVE.sdp_slv_eventos
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
-- MAGIC ## Gold — tabela enriquecida para churn

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW sdp_gold_beneficiario_enriquecida (
  CONSTRAINT sk_nao_nula EXPECT (SK_BENEFICIARIO IS NOT NULL) ON VIOLATION DROP ROW,
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
FROM LIVE.sdp_slv_beneficiario_vigencia b
LEFT JOIN LIVE.sdp_slv_usuario_pessoa p ON b.NU_USUARIO = p.NU_USUARIO;
