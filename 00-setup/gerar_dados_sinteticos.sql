-- ============================================================================
-- Workshop Hapvida x Databricks — Geração de dados sintéticos (SOMENTE INSTRUTOR)
-- ============================================================================
-- Objetivo: ampliar hapvida_dev.bronze para um volume realista, mantendo o
-- schema real das tabelas raw_hap_* e integridade referencial entre elas.
--
-- IMPORTANTE:
--   * Este script NÃO deve ser executado pelos participantes.
--   * No ambiente dos participantes as tabelas bronze JÁ vêm completas.
--   * As 10 linhas originais são PRESERVADAS (append). Elas não cruzam chave
--     com o resto e servem como caso real de "beneficiários órfãos" no
--     módulo de Qualidade de Dados (quarentena).
--
-- Determinismo: usamos hash(id)/pmod(...) em vez de rand() para que a geração
-- seja reprodutível (rand() com seed variável por linha não é permitido).
--
-- Volume gerado: 5.000 pessoas, 5.000 beneficiários, ~10.000 eventos de
-- auditoria (média de 2 eventos por beneficiário), churn ~19%.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) PESSOAS sintéticas
-- ----------------------------------------------------------------------------
INSERT INTO hapvida_dev.bronze.raw_hap_tb_pessoa
  (CD_PESSOA, NU_CGC_CPF, DT_NASCIMENTO_FUNDACAO, NM_PESSOA_RAZAO_SOCIAL, FL_SEXO,
   FL_TIPO_PESSOA, CD_EMPRESA_PLANO, FL_EXCLUIDO, merge_key, dt_carga_bronze)
SELECT
  CAST(600000000 + id AS DECIMAL(38,10))                                        AS CD_PESSOA,
  CAST(10000000000 + id * 7 AS DECIMAL(38,10))                                  AS NU_CGC_CPF,
  CAST(DATE_ADD('1950-01-01', pmod(hash(id), 26000)) AS TIMESTAMP)              AS DT_NASCIMENTO_FUNDACAO,
  CONCAT('BENEFICIARIO SINTETICO ', LPAD(CAST(id AS STRING), 6, '0'))           AS NM_PESSOA_RAZAO_SOCIAL,
  CASE WHEN pmod(hash(id,'sexo'),2)=0 THEN 'M' ELSE 'F' END                     AS FL_SEXO,
  CAST(1 AS DECIMAL(38,10))                                                     AS FL_TIPO_PESSOA,
  CAST(CASE WHEN pmod(hash(id),5)=0 THEN 14 ELSE 1 END AS DECIMAL(38,10))       AS CD_EMPRESA_PLANO,
  -- ~2% de registros marcados como excluídos (exercício de filtro FL_EXCLUIDO)
  CAST(CASE WHEN pmod(hash(id,'exc'),50)=0 THEN 1 ELSE 0 END AS DECIMAL(38,10)) AS FL_EXCLUIDO,
  CAST(600000000 + id AS STRING)                                               AS merge_key,
  CURRENT_TIMESTAMP()                                                          AS dt_carga_bronze
FROM (SELECT explode(sequence(1, 5000)) AS id);

-- ----------------------------------------------------------------------------
-- 2) BENEFICIÁRIOS (usuários) — CD_PESSOA casa 1:1 com as pessoas acima
--    Status 4 = cancelado (churn ~18%), status 2 = ativo.
-- ----------------------------------------------------------------------------
INSERT INTO hapvida_dev.bronze.raw_hap_tb_usuario
  (NU_USUARIO, NU_TITULAR, CD_PESSOA, CD_USUARIO, FL_STATUS_USUARIO, CD_PLANO,
   CD_TIPO_ACOMODACAO, DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO,
   VL_MENSALIDADE, CD_TIPO_DEPENDENTE_USUARIO, FL_EXCLUIDO, merge_key, dt_carga_bronze)
SELECT
  CAST(200000000 + id AS DECIMAL(38,10))                                        AS NU_USUARIO,
  CAST(200000000 + id AS DECIMAL(38,10))                                        AS NU_TITULAR,
  CAST(600000000 + id AS DECIMAL(38,10))                                        AS CD_PESSOA,
  CONCAT('SYN', LPAD(CAST(id AS STRING), 11, '0'))                              AS CD_USUARIO,
  churn.st                                                                      AS FL_STATUS_USUARIO,
  CAST(element_at(array(7735,8390,8764,9021), 1 + pmod(hash(id,'plano'),4)) AS DECIMAL(38,10)) AS CD_PLANO,
  CAST(1 + pmod(hash(id,'acom'),3) AS DECIMAL(38,10))                           AS CD_TIPO_ACOMODACAO,
  cad.dt                                                                        AS DT_CADASTRAMENTO,
  CASE WHEN churn.st = 4 THEN CAST(DATE_ADD(cad.dt, 90 + pmod(hash(id,'canc'),700)) AS TIMESTAMP) END AS DT_CANCELAMENTO,
  CASE WHEN churn.st = 4 THEN CAST(1 + pmod(hash(id,'mot'),8) AS DECIMAL(38,10)) END AS CD_CANCELAMENTO,
  CAST(150 + pmod(hash(id,'mens'),850) + pmod(hash(id,'cent'),100)/100.0 AS DECIMAL(38,10)) AS VL_MENSALIDADE,
  CASE WHEN pmod(hash(id,'dep'),3)=0 THEN CAST(1 AS DECIMAL(38,10)) END          AS CD_TIPO_DEPENDENTE_USUARIO,
  CAST(CASE WHEN pmod(hash(id,'exc'),60)=0 THEN 1 ELSE 0 END AS DECIMAL(38,10))  AS FL_EXCLUIDO,
  CAST(200000000 + id AS STRING)                                               AS merge_key,
  CURRENT_TIMESTAMP()                                                           AS dt_carga_bronze
FROM (SELECT explode(sequence(1, 5000)) AS id) g
  CROSS JOIN LATERAL (SELECT CAST(TIMESTAMP(DATE_ADD('2021-01-01', pmod(hash(g.id,'cad'), 900))) AS TIMESTAMP) AS dt) cad
  CROSS JOIN LATERAL (SELECT CASE WHEN pmod(hash(g.id,'churn'),100) < 18
                                  THEN CAST(4 AS DECIMAL(38,10))
                                  ELSE CAST(2 AS DECIMAL(38,10)) END AS st) churn;

-- ----------------------------------------------------------------------------
-- 3) AUDITORIA — 1 a 3 eventos por beneficiário ao longo do tempo.
--    CD_ACAO 1 = inclusão (primeiro evento), 2 = alteração.
--    O plano pode mudar entre eventos (exercício de vigência / SCD2).
--    O último evento reflete o status final (cancelamento, quando houver).
-- ----------------------------------------------------------------------------
INSERT INTO hapvida_dev.bronze.raw_hap_au_usuario
  (CD_ACAO, NU_USUARIO, NU_TITULAR, CD_PESSOA, CD_USUARIO, FL_STATUS_USUARIO, CD_PLANO,
   DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO, VL_MENSALIDADE, DT_AUDIT,
   CD_OPERADOR, FL_EXCLUIDO, merge_key, dt_carga_bronze)
SELECT
  CASE WHEN t.evento = 0 THEN CAST(1 AS DECIMAL(38,10)) ELSE CAST(2 AS DECIMAL(38,10)) END AS CD_ACAO,
  u.NU_USUARIO,
  u.NU_TITULAR,
  u.CD_PESSOA,
  u.CD_USUARIO,
  CASE WHEN t.evento = element_at(u._max_ev_arr, 1) THEN u.FL_STATUS_USUARIO ELSE CAST(2 AS DECIMAL(38,10)) END AS FL_STATUS_USUARIO,
  CAST(element_at(array(7735,8390,8764,9021), 1 + pmod(hash(u.NU_USUARIO,'plano',t.evento),4)) AS DECIMAL(38,10)) AS CD_PLANO,
  CAST(u.DT_CADASTRAMENTO AS TIMESTAMP) AS DT_CADASTRAMENTO,
  CASE WHEN t.evento = element_at(u._max_ev_arr,1) AND u.FL_STATUS_USUARIO = 4 THEN u.DT_CANCELAMENTO END AS DT_CANCELAMENTO,
  CASE WHEN t.evento = element_at(u._max_ev_arr,1) AND u.FL_STATUS_USUARIO = 4 THEN u.CD_CANCELAMENTO END AS CD_CANCELAMENTO,
  u.VL_MENSALIDADE,
  CAST(DATE_ADD(u.DT_CADASTRAMENTO, t.evento * (30 + pmod(hash(u.NU_USUARIO, t.evento),120))) AS TIMESTAMP) AS DT_AUDIT,
  CASE WHEN pmod(hash(u.NU_USUARIO,'op'),2)=0 THEN 'SYS' ELSE 'DBA_MATHEUS' END AS CD_OPERADOR,
  CAST(0 AS DECIMAL(38,10)) AS FL_EXCLUIDO,
  CONCAT(CAST(u.NU_USUARIO AS STRING), '_', CAST(t.evento AS STRING)) AS merge_key,
  CURRENT_TIMESTAMP() AS dt_carga_bronze
FROM (
  SELECT NU_USUARIO, NU_TITULAR, CD_PESSOA, CD_USUARIO, FL_STATUS_USUARIO,
         DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO, VL_MENSALIDADE,
         array(pmod(hash(NU_USUARIO,'nev'),3)) AS _max_ev_arr
  FROM hapvida_dev.bronze.raw_hap_tb_usuario
  WHERE NU_USUARIO >= 200000001            -- apenas os beneficiários sintéticos
) u
LATERAL VIEW explode(sequence(0, pmod(hash(u.NU_USUARIO,'nev'),3))) t AS evento;

-- ----------------------------------------------------------------------------
-- 4) Verificação rápida (opcional)
-- ----------------------------------------------------------------------------
-- SELECT
--   (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_pessoa)  AS total_pessoa,
--   (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_usuario) AS total_usuario,
--   (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_au_usuario) AS total_audit;
