# 📊 Portfólio de Análise de Dados — Olist E-commerce

Projetos de análise de dados construídos sobre o dataset público da **Olist**
(plataforma brasileira de e-commerce), disponível no Kaggle.

O dataset contém **~100 mil pedidos** realizados entre 2016 e 2018, com informações
de clientes, vendedores, produtos, pagamentos, entregas e avaliações.

---

## Projetos

| # | Projeto | Ferramentas | Nível |
|---|---------|-------------|-------|
| 1 | [KPIs Básicos de Vendas](#1-kpis-básicos-de-vendas) | SQL | ⭐⭐ |
| 2 | [Análise Avançada com SQL](#2-análise-avançada-com-sql) | SQL (CTEs, Window Functions) | ⭐⭐⭐ |
| 3 | [Dashboard Executivo](#3-dashboard-executivo) | Excel | ⭐⭐⭐ |
| 4 | [Segmentação RFM](#4-segmentação-rfm) | Python · Pandas · Seaborn | ⭐⭐⭐ |
| 5 | [Dashboard 360°](#5-dashboard-360) | Power BI | ⭐⭐⭐⭐ |

---

## 1. KPIs Básicos de Vendas

**Arquivo:** `01-sql-kpis-basicos/projeto1_kpis_basicos.sql`

Análise exploratória inicial do negócio respondendo às perguntas fundamentais:
- Qual o faturamento total e ticket médio?
- Como evoluíram as vendas mês a mês?
- Quais categorias e estados geram mais receita?
- Como os clientes avaliam os pedidos?

**Técnicas SQL:** `JOIN`, `GROUP BY`, `HAVING`, `ORDER BY`, `CASE WHEN`,
funções de agregação (`SUM`, `AVG`, `COUNT`), `COALESCE`

---

## 2. Análise Avançada com SQL

**Arquivo:** `02-sql-avancado/projeto2_analise_avancada.sql`

Análises mais profundas usando recursos avançados de SQL:
- Crescimento mês a mês (MoM) com `LAG()`
- Ranking de vendedores com `RANK() OVER()`
- Análise de SLA de entrega (no prazo vs atrasado)
- Identificação de clientes recorrentes com subqueries
- Market share por categoria com `SUM() OVER()`
- Score de performance ponderado dos vendedores

**Técnicas SQL:** CTEs (`WITH`), Window Functions (`LAG`, `RANK`, `DENSE_RANK`,
`SUM OVER`), subqueries, `JULIANDAY` para cálculo de datas

---

## 3. Dashboard Executivo

**Arquivo:** `03-excel-dashboard/projeto3_dashboard_olist.xlsx`

Dashboard executivo em Excel com 5 abas:
- **Dashboard** — KPIs gerais com fórmulas dinâmicas
- **Vendas Mensais** — tabela + gráfico de linha com evolução mensal
- **Top 10 Categorias** — tabela + gráfico de barras horizontal
- **Formas de Pagamento** — tabela + gráfico de pizza
- **Por Estado** — tabela com performance por UF

**Técnicas Excel:** Formatação condicional, fórmulas entre abas
(`='Vendas Mensais'!B25`), gráficos (linha, barra, pizza), tabelas formatadas

---

## 4. Segmentação RFM

**Arquivo:** `04-python-rfm/projeto4_rfm_analysis.ipynb`

Segmentação de clientes usando a metodologia RFM (Recência, Frequência, Valor):

1. Extração dos dados direto do SQLite com `sqlite3`
2. Cálculo de R, F, M por cliente com `pandas`
3. Scoring por quintis com `pd.qcut()`
4. Classificação em 8 segmentos (Campeão, Fiel, Em Risco, etc.)
5. Visualizações com `matplotlib` e `seaborn`
6. Exportação para CSV para uso no Power BI

**Saídas:** `rfm_completo.csv`, `rfm_segmentos.png`, `rfm_scatter.png`

**Principais achados:**
- A maioria dos clientes compra apenas 1 vez (característica de marketplace)
- Clientes "Campeão" e "Fiel" representam uma pequena % da base mas concentram grande parte da receita
- Segmentação permite priorizar campanhas de retenção e reativação

---

## 5. Dashboard 360°

**Arquivos:** `05-powerbi/GUIA_POWERBI.md` + `05-powerbi/data/*.csv`

Dashboard interativo no Power BI com arquitetura Star Schema:
- `fato_pedidos.csv` — tabela fato com todas as transações
- `dim_clientes.csv`, `dim_vendedores.csv`, `dim_produtos.csv` — dimensões
- `dim_calendario.csv` — tabela de datas para análise temporal

**Métricas DAX:** Receita Total, Ticket Médio, Nota Média, % Entrega no Prazo,
Crescimento MoM, % Clientes Recorrentes

**Visualizações:** Mapa do Brasil por estado, gráfico de linha temporal,
barras por categoria, tabela de vendedores com condicional

---

## Dataset

**Fonte:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle

| Tabela | Registros |
|--------|-----------|
| orders | 99.441 |
| order_items | 112.650 |
| order_payments | 103.886 |
| order_reviews | 100.000 |
| products | 32.951 |
| sellers | 3.095 |
| customers | 99.441 |

---

## Como executar

### SQL
Qualquer cliente SQLite (DB Browser for SQLite, DBeaver, ou linha de comando):
```bash
sqlite3 db_olist.sqlite < 01-sql-kpis-basicos/projeto1_kpis_basicos.sql
```

### Python
```bash
pip install pandas matplotlib seaborn jupyter
# Abra o notebook e atualize o caminho do banco de dados
jupyter notebook 04-python-rfm/projeto4_rfm_analysis.ipynb
```

### Power BI
Siga o `05-powerbi/GUIA_POWERBI.md` para importar os CSVs e montar o modelo.
