# Workshop Hapvida x Databricks — Engenharia de Dados (L200)

## Apostila do Participante

Bem-vindo(a) ao workshop **hands-on** de Engenharia de Dados com Databricks!
Este material é 100% em **SQL** — você não precisa saber Python.

---

## Objetivo do dia

Produzir a tabela **`gold_beneficiario_enriquecida`**, que será usada pelo time
de ciência de dados para treinar um modelo de **predição de churn**.

> **Churn**: métrica que mede o cancelamento/evasão de clientes num período.
> No nosso caso, um beneficiário com status **cancelado** (`FL_STATUS_USUARIO = 4`)
> é considerado churn.

Vamos construir um pipeline completo em **arquitetura medalhão**:

```
BRONZE (dados crus)  ->  SILVER (limpo + histórico)  ->  GOLD (pronto p/ negócio/ML)
```

---

## Ambiente

| Recurso | Onde | Acesso |
|--------|------|--------|
| Dados de origem | `hapvida_dev.bronze` (3 tabelas `raw_hap_*`) | **somente leitura** |
| Seu espaço de trabalho | `workshop_dev.<seu_usuario>` | **leitura e escrita** |

Cada participante trabalha no **seu próprio schema**, criado no notebook de setup.
Todas as tabelas que você criar ficam isoladas em `workshop_dev.<seu_usuario>`.

### As 3 tabelas de origem

| Tabela | Conteúdo | Papel no pipeline |
|--------|----------|-------------------|
| `raw_hap_tb_pessoa` | Cadastro de pessoas (CPF/CNPJ, nome, sexo, nascimento) | atributos cadastrais |
| `raw_hap_tb_usuario` | Beneficiários (carteira, plano, mensalidade, status, cancelamento) | estado atual |
| `raw_hap_au_usuario` | Auditoria: histórico de alterações do beneficiário | linha do tempo (SCD2) |

---

## Como você vai trabalhar: Databricks Assistant

Neste workshop você **não digita SQL na mão**. Em vez disso, descreve em
português o que quer e deixa o **Databricks Assistant** (a IA do notebook) gerar
o código para você:

1. Numa célula vazia, abra o Assistant (ícone ✨ ou `Cmd/Ctrl + I`).
2. Cole/adapte o **PROMPT sugerido** do exercício.
3. **Sempre revise** o SQL gerado antes de rodar — comparar com a pasta
   `respostas/` é uma ótima forma de aprender.

> A IA é uma copiloto: ela acelera, mas **você** valida o resultado. Entender
> *por que* o SQL está correto é o objetivo do workshop.

### Menos exercícios, mais foco

Cada notebook tem **poucas células de exercício** (marcadas com ⭐), sempre no
**ponto-chave** do módulo. O "encanamento" repetitivo já vem em **células
prontas** para rodar — assim o pipeline flui e você concentra energia no que
importa.

## Padrão dos notebooks

Todo notebook começa declarando o seu schema numa variável de sessão:

```sql
DECLARE OR REPLACE VARIABLE meu_schema STRING
  DEFAULT 'workshop_dev.' || replace(split(current_user(), '@')[0], '.', '_');
```

E referencia tabelas com `IDENTIFIER()`:

```sql
CREATE OR REPLACE TABLE IDENTIFIER(meu_schema || '.minha_tabela') AS SELECT ...;
```

Assim o mesmo código funciona para todos, sem colisão de nomes.

---

## Agenda (dia inteiro, ~6–8h)

| # | Módulo | Duração | ⭐ Exercícios | O que você aprende |
|---|--------|---------|:---:|--------------------|
| 00 | Setup & exploração | 30 min | 1 | conhecer os dados; integridade referencial |
| 01 | Bronze — ingestão | 45 min | 1 | CTAS, coluna de ingestão, idempotência |
| 02 | Silver — limpeza | 60 min | 1 | tipagem, `FL_EXCLUIDO`, dedup (`QUALIFY`), quarentena |
| 03 | Silver — eventos & vigências (SCD2) | 60 min | 2 | `UNION ALL`, `LAG`, `FIRST_VALUE`, precedência AND/OR |
| — | **Almoço** | — | — | — |
| 04 | Gold — tabela enriquecida | 75 min | 1 | joins, surrogate key, features (idade, churn) |
| 05 | Qualidade de dados | 45 min | 1 | painel de métricas, porta de qualidade |
| 06 | Lakeflow Declarative Pipeline | 75 min | 1 | MV declarativas + `CONSTRAINT EXPECT` |
| 07 | Consumo & orquestração | 45 min | 1 | análise de churn, Job vs. Pipeline |

> Os exercícios ⭐ são os pontos-chave de cada módulo, resolvidos com o
> **Databricks Assistant**. As demais células já vêm prontas.

---

## Módulo 00 — Setup e Exploração

**Meta:** entender os dados antes de transformá-los.

Conceitos-chave:
- `SHOW TABLES IN <schema>` — lista tabelas.
- `DESCRIBE TABLE <tabela>` — mostra colunas e tipos.
- Profiling: contagens, distribuição de status, checagem de integridade.

⚠️ **Descoberta importante:** repare que existem beneficiários **sem pessoa
correspondente** (órfãos). Guarde isso — vamos tratar no módulo 02.

---

## Módulo 01 — Bronze

**Meta:** materializar uma cópia bronze no seu schema.

- `CREATE OR REPLACE TABLE ... AS SELECT` (CTAS) copia dados.
- Adicionamos `_dt_ingestao = CURRENT_TIMESTAMP()` para rastreabilidade.
- `CREATE OR REPLACE` é **idempotente**: rodar de novo não duplica.

---

## Módulo 02 — Silver: Usuário + Pessoa

**Meta:** `slv_usuario_pessoa`, base limpa e conformada.

As **4 camadas de qualidade** desta etapa:

1. **Tipagem** — os dados vêm como `decimal(38,10)`; convertemos para
   `BIGINT`, `INT`, `DATE`, `DECIMAL(18,2)`.
2. **Filtro de exclusão** — `WHERE FL_EXCLUIDO = 0`.
3. **Deduplicação** — a mesma chave pode ter várias versões:
   ```sql
   QUALIFY ROW_NUMBER() OVER (PARTITION BY NU_USUARIO ORDER BY dt_carga_bronze DESC) = 1
   ```
4. **Integridade referencial** — `INNER JOIN` mantém só beneficiários com
   cadastro; os **órfãos** vão para `qua_usuario_orfao` (quarentena), com motivo.

> **Por que quarentena e não `WHERE`?** Descartar em silêncio esconde problemas.
> Registrar os órfãos permite investigar a origem do dado ruim.

---

## Módulo 03 — Silver: Eventos e Vigências (SCD2)

**Meta:** reconstruir a linha do tempo de cada beneficiário.

Passos:
1. **Unificar eventos**: `UNION ALL` entre o histórico (auditoria) e o estado
   atual (com `CURRENT_DATE()` como data do evento).
2. **Calcular vigências**:
   - `DT_FIM_VIGENCIA` = data do evento;
   - `DT_INICIO_VIGENCIA` = `COALESCE(LAG(DT_AUDIT) OVER (...), DT_CADASTRAMENTO, DT_AUDIT)`.
3. **Preencher atributos nulos** com `FIRST_VALUE(col, true)` (o `true` ignora nulos).
4. **Qualidade**: manter só `DT_FIM_VIGENCIA > DT_INICIO_VIGENCIA`.

⚠️ **Armadilha de qualidade (AND/OR):** ao filtrar a auditoria, o bloco de
condições `OR` **precisa** de parênteses; senão a precedência do SQL faz o
`AND FL_EXCLUIDO = 0` ser ignorado. Compare:

```sql
-- ERRADO: o filtro de exclusão "se perde"
WHERE FL_EXCLUIDO = 0 AND a IS NOT NULL OR b IS NOT NULL

-- CERTO
WHERE FL_EXCLUIDO = 0 AND (a IS NOT NULL OR b IS NOT NULL)
```

---

## Módulo 04 — Gold: Tabela Enriquecida

**Meta:** `gold_beneficiario_enriquecida`, pronta para o modelo de churn.

- Junta vigências (`slv_beneficiario_vigencia`) com cadastro (`slv_usuario_pessoa`).
- **Surrogate key**: `XXHASH64(NU_USUARIO, DT_INICIO_VIGENCIA)` — única por vigência.
- **Features derivadas**:
  - `IDADE = FLOOR(DATEDIFF(DT_FIM_VIGENCIA, DT_NASCIMENTO) / 365.25)`
  - `FL_CHURN = CASE WHEN FL_STATUS_USUARIO = 4 THEN 1 ELSE 0 END`
- **Qualidade**: a contagem de linhas deve bater com a de SKs distintas.

---

## Módulo 05 — Qualidade de Dados

**Meta:** consolidar as regras num painel `dq_metricas` (porta de qualidade).

Cada linha é uma métrica com uma **severidade** (`ok`, `informativo`, `atencao`,
`erro`). Se houver qualquer `erro` (ex.: SK duplicada, idade inválida), o
pipeline não deveria seguir para produção.

---

## Módulo 06 — Lakeflow Declarative Pipeline

**Meta:** reescrever o pipeline de forma **declarativa**.

Em vez de dizer *como* (ordem de CREATE TABLEs), você declara *o que* cada
tabela é. O Lakeflow resolve dependências, materializa e aplica qualidade via
`CONSTRAINT ... EXPECT ... ON VIOLATION DROP ROW`.

- Materialized Views: `CREATE OR REFRESH MATERIALIZED VIEW ...`
- Referências internas ao pipeline usam o prefixo `LIVE.`
- Execução: crie um **Pipeline** apontando para o notebook 06.

---

## Módulo 07 — Consumo e Orquestração

**Meta:** responder perguntas de negócio e discutir orquestração.

- `vw_beneficiario_atual`: só a vigência mais recente por beneficiário.
- Análises: churn por plano/faixa etária/sexo, ticket médio.
- **Job vs. Pipeline**: quando usar cada um (veja tabela comparativa no gabarito).

---

## Regras de ouro

1. Escreva **sempre** no seu schema (`workshop_dev.<seu_usuario>`).
2. Nos exercícios ⭐, use o **Assistant** com o prompt sugerido — e **revise** o
   SQL gerado antes de rodar.
3. Rode as células **em ordem** — cada módulo depende do anterior.
4. Confira o gabarito (`respostas/`) só depois de tentar.
5. Em caso de dúvida, chame o instrutor. 🙂
