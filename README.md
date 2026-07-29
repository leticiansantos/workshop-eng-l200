# Workshop Hapvida x Databricks — Engenharia de Dados (L200)

Workshop **hands-on**, 100% **SQL**, de engenharia de dados em arquitetura
medalhão, com caso de uso de **predição de churn** de beneficiários de plano de saúde.

## Objetivo

Construir, camada a camada (bronze → silver → gold), a tabela
`gold_beneficiario_enriquecida` que alimenta um modelo de churn.

## Público-alvo

Times que trabalham com **SQL** (não é necessário Python). O único código Python
é o notebook de setup, rodado uma vez.

Os exercícios são resolvidos com o **Databricks Assistant**: o participante
escreve um prompt em português e a IA gera o SQL. Cada notebook tem poucos
exercícios (⭐), sempre nos pontos-chave; o restante já vem em células prontas.

## Estrutura do repositório

```
hapvida-saude-workshop/
├── 00-setup/
│   ├── gerar_dados_sinteticos.sql   # SOMENTE INSTRUTOR: popula hapvida_dev.bronze
│   └── setup_participantes.py       # cada participante roda 1x: cria seu schema
├── 01-engenharia-dados/
│   ├── apostila.md                  # guia do participante (leia primeiro)
│   ├── notebooks/                   # exercícios em branco (00 a 07)
│   └── respostas/                   # gabarito validado (00 a 07)
├── assets/                          # diagrama da arquitetura
├── databricks.yml                   # bundle (opcional) para deploy dos notebooks
├── deploy.sh                        # script de deploy p/ o workspace do instrutor
└── README.md
```

## Ambiente

| Recurso | Local | Acesso participante |
|--------|-------|---------------------|
| Origem (bronze) | `hapvida_dev.bronze` | somente leitura |
| Trabalho | `workshop_dev.<usuario>` | leitura/escrita |

## Passo a passo

### Instrutor (uma vez, antes do workshop)

1. **Popular a bronze** (só se o seu ambiente tiver pouca massa de dados):
   rode `00-setup/gerar_dados_sinteticos.sql` num SQL Warehouse.
   Ele **preserva** os dados existentes (append) e adiciona ~5.000 pessoas,
   ~5.000 beneficiários e ~10.000 eventos de auditoria, com integridade
   referencial e churn ~19%.
2. **Publicar os notebooks** no workspace: `./deploy.sh` (usa a CLI do Databricks).
3. Garantir que os participantes têm **leitura** em `hapvida_dev.bronze` e
   **escrita** em `workshop_dev`.

### Participante

1. Rodar `00-setup/setup_participantes.py` (cria `workshop_dev.<seu_usuario>`).
2. Abrir a `apostila.md` e seguir os módulos 00 → 07 usando os notebooks em
   `01-engenharia-dados/notebooks/`.
3. Conferir com o gabarito em `01-engenharia-dados/respostas/` **após** tentar.

## Notas técnicas

- Os notebooks SQL usam uma variável de sessão (`meu_schema`) + `IDENTIFIER()`
  para isolar o schema de cada participante sem editar código.
- O gerador de dados usa `hash()`/`pmod()` (determinístico e reprodutível),
  não `rand()`.
