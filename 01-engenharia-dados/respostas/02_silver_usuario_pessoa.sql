-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 02 — Silver: Usuário + Pessoa (GABARITO)
-- MAGIC
-- MAGIC Objetivo: produzir `slv_usuario_pessoa`, a base limpa e conformada que
-- MAGIC cruza beneficiários (`raw_hap_tb_usuario`) com o cadastro de pessoas
-- MAGIC (`raw_hap_tb_pessoa`).
-- MAGIC
-- MAGIC **Camadas de qualidade aplicadas nesta etapa:**
-- MAGIC 1. **Tipagem** — converter `decimal(38,10)` para tipos corretos (BIGINT, INT, DATE, DECIMAL).
-- MAGIC 2. **Filtro de exclusão** — descartar `FL_EXCLUIDO = 1`.
-- MAGIC 3. **Deduplicação** — manter a versão mais recente por chave (`QUALIFY ROW_NUMBER`).
-- MAGIC 4. **Integridade referencial** — beneficiário precisa ter pessoa (INNER JOIN),
-- MAGIC    e os órfãos vão para uma tabela de **quarentena** (não são descartados em silêncio).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Setup do schema pessoal
-- MAGIC Declaramos uma variável de sessão com o seu schema. Ela é usada com
-- MAGIC `IDENTIFIER()` nas células seguintes.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

SELECT meu_schema AS schema_de_trabalho;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Tabela silver: usuário + pessoa (apenas registros válidos)

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.slv_usuario_pessoa') AS
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
  WHERE CAST(FL_EXCLUIDO AS INT) = 0                        -- QUALIDADE: remove excluídos
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY NU_USUARIO ORDER BY dt_carga_bronze DESC
  ) = 1                                                     -- QUALIDADE: 1 linha por beneficiário
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
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY CD_PESSOA ORDER BY dt_carga_bronze DESC
  ) = 1
)
SELECT
  u.NU_USUARIO, u.NU_TITULAR, u.FL_STATUS_USUARIO, u.CD_PLANO,
  u.DT_CADASTRAMENTO, u.DT_CANCELAMENTO, u.CD_CANCELAMENTO, u.CD_USUARIO, u.VL_MENSALIDADE,
  p.CD_PESSOA, p.DT_NASCIMENTO, p.CD_SEXO, p.NU_CGC_CPF, p.NM_PESSOA_RAZAO_SOCIAL
FROM usuario_limpo u
INNER JOIN pessoa_limpa p ON p.CD_PESSOA = u.CD_PESSOA;    -- QUALIDADE: só quem tem cadastro válido

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Tabela de quarentena: beneficiários órfãos
-- MAGIC Beneficiários sem pessoa correspondente não são jogados fora: ficam
-- MAGIC registrados com o motivo, para investigação posterior.

-- COMMAND ----------

CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.qua_usuario_orfao') AS
SELECT
  CAST(u.NU_USUARIO AS BIGINT) AS NU_USUARIO,
  CAST(u.CD_PESSOA  AS BIGINT) AS CD_PESSOA,
  'CD_PESSOA sem correspondencia em raw_hap_tb_pessoa' AS motivo_quarentena,
  CURRENT_TIMESTAMP() AS dt_quarentena
FROM hapvida_dev.bronze.raw_hap_tb_usuario u
LEFT JOIN hapvida_dev.bronze.raw_hap_tb_pessoa p ON p.CD_PESSOA = u.CD_PESSOA
WHERE CAST(u.FL_EXCLUIDO AS INT) = 0 AND p.CD_PESSOA IS NULL;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')) AS validos,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.qua_usuario_orfao'))  AS em_quarentena;
