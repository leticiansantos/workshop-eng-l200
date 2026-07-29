-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 00 — Setup e Exploração dos Dados
-- MAGIC
-- MAGIC Vamos conhecer a camada bronze (`hapvida_dev.bronze`, **somente leitura**).
-- MAGIC
-- MAGIC ## Como usar o Databricks Assistant ("Genie") neste workshop
-- MAGIC Em vez de digitar SQL na mão, você vai **descrever em português** o que quer
-- MAGIC e deixar o **Databricks Assistant** gerar o SQL para você:
-- MAGIC
-- MAGIC 1. Em uma célula vazia, clique no ícone do **Assistant** (✨) ou pressione
-- MAGIC    `Cmd/Ctrl + I`.
-- MAGIC 2. Escreva o prompt (texto em português) e gere o código.
-- MAGIC 3. **Revise** o SQL gerado, rode e confira o resultado.
-- MAGIC
-- MAGIC > Nos blocos **PROMPT** abaixo está o texto sugerido. Ajuste como quiser.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — visão geral das tabelas
-- MAGIC Rode para ver o volume das 3 tabelas de origem.

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_pessoa)  AS qt_pessoa,
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_tb_usuario) AS qt_usuario,
  (SELECT COUNT(*) FROM hapvida_dev.bronze.raw_hap_au_usuario) AS qt_auditoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Integridade referencial
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Conte quantos beneficiários da tabela `hapvida_dev.bronze.raw_hap_tb_usuario`
-- MAGIC > não têm pessoa correspondente em `hapvida_dev.bronze.raw_hap_tb_pessoa`,
-- MAGIC > fazendo um LEFT JOIN por CD_PESSOA e contando onde a pessoa é nula."_
-- MAGIC
-- MAGIC Esses são os beneficiários **órfãos** — vamos tratá-los no módulo 02.
-- MAGIC Gere o SQL com o Assistant na célula abaixo, rode e observe o resultado.

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant (Cmd/Ctrl + I) usando o prompt acima.

