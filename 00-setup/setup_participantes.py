# Databricks notebook source
# MAGIC %md
# MAGIC # Workshop Hapvida x Databricks — Setup do Participante
# MAGIC
# MAGIC Este notebook prepara o ambiente **individual** de cada participante.
# MAGIC Rode-o **uma única vez** no início do workshop.
# MAGIC
# MAGIC O que ele faz:
# MAGIC 1. Descobre o seu usuário automaticamente.
# MAGIC 2. Cria o seu schema pessoal em `workshop_dev.<seu_usuario>`.
# MAGIC 3. Confere que você consegue **ler** a camada bronze (`hapvida_dev.bronze`).
# MAGIC 4. Confere que você consegue **escrever** no seu schema.
# MAGIC
# MAGIC > A fonte de dados (`hapvida_dev.bronze`) é **somente leitura**.
# MAGIC > Toda a construção das camadas silver e gold acontece no **seu** schema
# MAGIC > dentro de `workshop_dev`.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Identificação do participante

# COMMAND ----------

# O e-mail do usuário logado vira o nome do schema (sanitizado).
raw_user = spark.sql("SELECT current_user() AS u").first()["u"]

# Ex.: "maria.silva@hapvida.com.br" -> "maria_silva"
username = raw_user.split("@")[0].replace(".", "_").replace("-", "_").lower()

print(f"Usuário logado : {raw_user}")
print(f"Schema pessoal : {username}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Helpers de identificador
# MAGIC
# MAGIC Funções para montar nomes totalmente qualificados e sanitizados com crases
# MAGIC (backticks), evitando problemas com caracteres especiais.

# COMMAND ----------


def quote_identifier(value: str) -> str:
    """Sanitiza um identificador com crases (backticks)."""
    return f"`{value.replace('`', '``')}`"


CATALOG = "workshop_dev"
BRONZE_SOURCE = "hapvida_dev.bronze"

catalog_q = quote_identifier(CATALOG)
schema_q = quote_identifier(username)
target_schema = f"{catalog_q}.{schema_q}"


def table_name(name: str) -> str:
    """Nome de tabela totalmente qualificado dentro do schema do participante."""
    return f"{target_schema}.{quote_identifier(name)}"


print(f"Schema de trabalho: {target_schema}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Criação do schema pessoal

# COMMAND ----------

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {target_schema}")
print(f"Schema pronto: {target_schema}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Teste de LEITURA da camada bronze

# COMMAND ----------

bronze_check = spark.sql(f"""
    SELECT
        (SELECT COUNT(*) FROM {BRONZE_SOURCE}.raw_hap_tb_pessoa)  AS qt_pessoa,
        (SELECT COUNT(*) FROM {BRONZE_SOURCE}.raw_hap_tb_usuario) AS qt_usuario,
        (SELECT COUNT(*) FROM {BRONZE_SOURCE}.raw_hap_au_usuario) AS qt_auditoria
""")
display(bronze_check)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Teste de ESCRITA no seu schema

# COMMAND ----------

spark.sql(f"CREATE OR REPLACE TABLE {table_name('_setup_check')} AS SELECT 1 AS ok")
display(spark.sql(f"SELECT * FROM {table_name('_setup_check')}"))
spark.sql(f"DROP TABLE IF EXISTS {table_name('_setup_check')}")

print("Setup concluído! Você já pode começar o módulo 01 (Bronze).")
print(f"Lembre-se: escreva sempre no seu schema -> {target_schema}")
