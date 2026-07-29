-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Módulo 02 — Silver: Usuário + Pessoa
-- MAGIC
-- MAGIC Objetivo: `slv_usuario_pessoa`, base limpa e conformada, com **4 camadas
-- MAGIC de qualidade**: tipagem, filtro `FL_EXCLUIDO`, deduplicação (`QUALIFY`) e
-- MAGIC integridade referencial (INNER JOIN) + quarentena dos órfãos.

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ⭐ Exercício-chave (com o Assistant) — Silver usuário + pessoa
-- MAGIC
-- MAGIC Este é o coração da limpeza. **PROMPT sugerido para o Assistant:**
-- MAGIC > _"Crie a tabela IDENTIFIER(meu_schema || '.slv_usuario_pessoa') juntando
-- MAGIC > `hapvida_dev.bronze.raw_hap_tb_usuario` (u) com `raw_hap_tb_pessoa` (p) por
-- MAGIC > CD_PESSOA. Antes do join, em cada tabela: filtre FL_EXCLUIDO = 0, converta
-- MAGIC > as colunas decimais para os tipos apropriados (BIGINT para códigos como
-- MAGIC > NU_USUARIO/NU_TITULAR/CD_PESSOA/CD_PLANO/CD_CANCELAMENTO, INT para
-- MAGIC > FL_STATUS_USUARIO, DATE para as datas, DECIMAL(18,2) para VL_MENSALIDADE),
-- MAGIC > e mantenha apenas a versão mais recente por chave usando QUALIFY
-- MAGIC > ROW_NUMBER() ordenado por dt_carga_bronze DESC (particionando por
-- MAGIC > NU_USUARIO na tabela de usuário e por CD_PESSOA na de pessoa). Use INNER
-- MAGIC > JOIN para manter só beneficiários com cadastro válido. Selecione da tabela
-- MAGIC > de usuário: NU_USUARIO, NU_TITULAR, FL_STATUS_USUARIO, CD_PLANO,
-- MAGIC > DT_CADASTRAMENTO, DT_CANCELAMENTO, CD_CANCELAMENTO, CD_USUARIO,
-- MAGIC > VL_MENSALIDADE. E da tabela de pessoa: CD_PESSOA, a coluna
-- MAGIC > DT_NASCIMENTO_FUNDACAO (renomeie para DT_NASCIMENTO), FL_SEXO (renomeie
-- MAGIC > para CD_SEXO), a coluna de documento NU_CGC_CPF (renomeie para NU_CGC_CPF)
-- MAGIC > e NM_PESSOA_RAZAO_SOCIAL."_
-- MAGIC
-- MAGIC > 💡 **Atenção:** a tabela de pessoa tem duas colunas de documento parecidas
-- MAGIC > (`NU_CGC_CPF` e `NU_CNPJ_CPF`). Use **`NU_CGC_CPF`**, que é a que está
-- MAGIC > preenchida. Sempre confira as colunas que a IA escolheu contra a tabela real.
-- MAGIC
-- MAGIC Revise o SQL gerado (compare com `respostas/02_...`) antes de rodar.

-- COMMAND ----------

-- 👉 Gere o SQL aqui com o Databricks Assistant usando o prompt acima.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — quarentena de órfãos
-- MAGIC Beneficiários sem pessoa não são descartados: ficam registrados com motivo.

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
-- MAGIC ## Célula pronta — conferência

-- COMMAND ----------

SELECT
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.slv_usuario_pessoa')) AS validos,
  (SELECT COUNT(*) FROM IDENTIFIER(meu_schema || '.qua_usuario_orfao'))  AS em_quarentena;
