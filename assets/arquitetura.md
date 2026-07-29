# Arquitetura do Workshop — Diagrama

Fluxo medalhão do caso de uso de churn:

```
┌─────────────────────────────┐
│  hapvida_dev.bronze (RO)    │   Fonte — somente leitura
│  • raw_hap_tb_pessoa        │
│  • raw_hap_tb_usuario       │
│  • raw_hap_au_usuario       │
└──────────────┬──────────────┘
               │  (leitura)
               ▼
┌─────────────────────────────────────────────────────────────┐
│  workshop_dev.<usuario>  (leitura/escrita)                   │
│                                                              │
│  BRONZE   brz_pessoa / brz_usuario / brz_auditoria           │  mód. 01
│    │                                                         │
│    ▼                                                         │
│  SILVER   slv_usuario_pessoa  ──► qua_usuario_orfao          │  mód. 02 (qualidade)
│           slv_eventos                                        │  mód. 03
│           slv_beneficiario_vigencia (SCD2)                   │  mód. 03
│    │                                                         │
│    ▼                                                         │
│  GOLD     gold_beneficiario_enriquecida (+ SK, idade, churn) │  mód. 04
│    │                                                         │
│    ▼                                                         │
│  DQ       dq_metricas (porta de qualidade)                   │  mód. 05
│  CONSUMO  vw_beneficiario_atual → análises de churn          │  mód. 07
└─────────────────────────────────────────────────────────────┘

Módulo 06: o mesmo pipeline reescrito como Lakeflow Declarative Pipeline (SQL),
com CONSTRAINT ... EXPECT no lugar das checagens manuais.
```

> Substitua este arquivo por um diagrama visual (PNG/SVG) se desejar, mantendo o
> mesmo fluxo de camadas.
