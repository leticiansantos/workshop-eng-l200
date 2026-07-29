-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 00 — Setup e Exploração dos Dados (GABARITO)
-- MAGIC
-- MAGIC Antes de construir qualquer coisa, precisamos **conhecer** os dados de origem.
-- MAGIC A camada bronze (`hapvida_dev.bronze`) é **somente leitura** e contém 3 tabelas.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

SELECT meu_schema AS schema_de_trabalho, current_user() AS usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## As 3 tabelas bronze

-- COMMAND ----------

SHOW TABLES IN hapvida_dev.bronze;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Estrutura das tabelas
-- MAGIC - `raw_hap_tb_pessoa`   — cadastro de pessoas (CPF/CNPJ, nome, sexo, nascimento)
-- MAGIC - `raw_hap_tb_usuario`  — beneficiários do plano (carteira, plano, mensalidade, status)
-- MAGIC - `raw_hap_au_usuario`  — auditoria: histórico de alterações do beneficiário

-- COMMAND ----------

DESCRIBE TABLE hapvida_dev.bronze.raw_hap_tb_usuario;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Profiling rápido: volumes e integridade

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_pessoa)  AS qt_pessoa,
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_usuario) AS qt_usuario,
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_au_usuario) AS qt_auditoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Distribuição de status dos beneficiários
-- MAGIC (2 = ativo, 4 = cancelado). Isso já dá uma ideia da taxa de churn.

-- COMMAND ----------

SELECT
  CAST(FL_STATUS_USUARIO AS INT) AS status,
  COUNT(*) AS qt
FROM hapvida_dev.bronze.raw_hap_tb_usuario
GROUP BY CAST(FL_STATUS_USUARIO AS INT)
ORDER BY qt DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exercício de observação: integridade referencial
-- MAGIC Quantos beneficiários NÃO têm pessoa correspondente? (candidatos a quarentena)

-- COMMAND ----------

SELECT COUNT(*) AS beneficiarios_orfaos
FROM hapvida_dev.bronze.raw_hap_tb_usuario u
LEFT JOIN hapvida_dev.bronze.raw_hap_tb_pessoa p ON p.CD_PESSOA = u.CD_PESSOA
WHERE p.CD_PESSOA IS NULL;
