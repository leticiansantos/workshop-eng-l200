-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 03 — Silver: Eventos e Vigências (SCD2)
-- MAGIC
-- MAGIC Reconstruir a linha do tempo de cada beneficiário (auditoria + estado atual)
-- MAGIC e calcular vigências (SCD Tipo 2). É a base do modelo de churn — por isso
-- MAGIC este módulo tem **dois** exercícios-chave.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave 1 (com o Assistant) — Unificar eventos
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie a tabela IDENTIFIER(meu_schema || '.slv_eventos') com UNION ALL de
-- MAGIC > dois conjuntos. Primeiro, o histórico: de `hapvida_dev.bronze.raw_hap_au_usuario`,
-- MAGIC > tipando as colunas (NU_USUARIO, NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO como
-- MAGIC > inteiros; DT_CADASTRAMENTO, DT_CANCELAMENTO, DT_AUDIT como date), filtrando
-- MAGIC > FL_EXCLUIDO = 0 E (NU_TITULAR não nulo OU FL_STATUS_USUARIO não nulo OU
-- MAGIC > CD_PLANO não nulo OU DT_CADASTRAMENTO não nulo) — use parênteses no bloco OR.
-- MAGIC > Segundo, o estado atual: de IDENTIFIER(meu_schema || '.slv_usuario_pessoa'),
-- MAGIC > com CURRENT_DATE() como DT_AUDIT."_
-- MAGIC
-- MAGIC ⚠️ **Atenção à precedência AND/OR**: sem os parênteses no bloco de OR, o
-- MAGIC filtro `FL_EXCLUIDO = 0` é ignorado. Verifique isso no SQL gerado!

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave 2 (com o Assistant) — Vigências (SCD2)
-- MAGIC
-- MAGIC **PROMPT sugerido para o Assistant:**
-- MAGIC > _"A partir de IDENTIFIER(meu_schema || '.slv_eventos'), crie a tabela
-- MAGIC > IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia'). Para cada NU_USUARIO:
-- MAGIC > DT_FIM_VIGENCIA = DT_AUDIT; DT_INICIO_VIGENCIA = COALESCE(LAG(DT_AUDIT) OVER
-- MAGIC > (PARTITION BY NU_USUARIO ORDER BY DT_AUDIT), DT_CADASTRAMENTO, DT_AUDIT).
-- MAGIC > Use FIRST_VALUE(coluna, true) OVER (PARTITION BY NU_USUARIO ORDER BY
-- MAGIC > DT_FIM_VIGENCIA DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) para
-- MAGIC > preencher NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO e DT_CADASTRAMENTO com o
-- MAGIC > valor não nulo mais recente. Só traga cancelamento quando DT_CANCELAMENTO
-- MAGIC > for menor que DT_FIM_VIGENCIA. Mantenha apenas linhas com
-- MAGIC > DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA."_

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_eventos'))               AS eventos,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_beneficiario_vigencia')) AS vigencias;
