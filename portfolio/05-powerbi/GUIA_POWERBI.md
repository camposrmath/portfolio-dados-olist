# Projeto 5 — Power BI: Dashboard 360° | Olist E-commerce

## Arquivos incluídos

| Arquivo | Descrição |
|---------|-----------|
| `data/fato_pedidos.csv` | Tabela fato com todas as transações |
| `data/dim_clientes.csv` | Dimensão clientes |
| `data/dim_vendedores.csv` | Dimensão vendedores |
| `data/dim_produtos.csv` | Dimensão produtos e categorias |
| `data/dim_calendario.csv` | Tabela de datas (2017–2018) |

---

## PASSO 1 — Importar os dados

1. Abra o Power BI Desktop
2. Clique em **Obter Dados → Texto/CSV**
3. Importe **todos os 5 arquivos** da pasta `data/`
4. Em cada arquivo: clique em **Transformar Dados** e confirme os tipos de coluna

### Tipos de coluna a ajustar (Power Query)

**fato_pedidos:**
- `order_purchase_timestamp` → Data/hora
- `order_delivered_customer_date` → Data/hora
- `price`, `freight_value`, `payment_value` → Número decimal
- `payment_installments`, `review_score` → Número inteiro

**dim_calendario:**
- `data` → Data

---

## PASSO 2 — Criar o modelo (Star Schema)

Vá em **Exibição de Modelo** e crie as relações:

```
fato_pedidos[customer_unique_id]  → dim_clientes[customer_unique_id]   (Muitos:1)
fato_pedidos[seller_id]           → dim_vendedores[seller_id]           (Muitos:1)
fato_pedidos[order_purchase_timestamp] → dim_calendario[data]          (Muitos:1)
```

> ⚠️ A relação com dim_calendario usa a coluna de data. Configure como
> "única" e garanta que a direção do filtro seja de dim_calendario → fato_pedidos.

---

## PASSO 3 — Medidas DAX

Crie uma **tabela vazia** chamada `_Medidas` para organizar todas as métricas:
> Modelagem → Nova Tabela → `_Medidas = {}`

### KPIs Principais

```dax
-- Total de pedidos
Total Pedidos =
DISTINCTCOUNT(fato_pedidos[order_id])

-- Receita total
Receita Total =
SUM(fato_pedidos[payment_value])

-- Ticket médio
Ticket Médio =
DIVIDE([Receita Total], [Total Pedidos])

-- Total de clientes únicos
Clientes Únicos =
DISTINCTCOUNT(fato_pedidos[customer_unique_id])

-- Nota média dos clientes
Nota Média =
AVERAGEX(
    FILTER(fato_pedidos, fato_pedidos[review_score] > 0),
    fato_pedidos[review_score]
)
```

### Análise de Entrega

```dax
-- Total de pedidos no prazo
Pedidos No Prazo =
COUNTROWS(
    FILTER(fato_pedidos, fato_pedidos[status_entrega] = "No prazo")
)

-- % de entrega no prazo
% Entrega No Prazo =
DIVIDE([Pedidos No Prazo], [Total Pedidos])

-- Tempo médio de entrega (dias)
Tempo Médio Entrega (dias) =
AVERAGE(fato_pedidos[dias_ate_entrega])
```

### Análise Temporal (MoM)

```dax
-- Receita do mês anterior
Receita Mês Anterior =
CALCULATE(
    [Receita Total],
    PREVIOUSMONTH(dim_calendario[data])
)

-- Crescimento MoM
Crescimento MoM % =
DIVIDE(
    [Receita Total] - [Receita Mês Anterior],
    [Receita Mês Anterior]
)
```

### Segmentação de Clientes

```dax
-- Clientes com mais de 1 pedido (recorrentes)
Clientes Recorrentes =
COUNTROWS(
    FILTER(
        SUMMARIZE(fato_pedidos, fato_pedidos[customer_unique_id], "Pedidos", [Total Pedidos]),
        [Pedidos] > 1
    )
)

-- % de clientes recorrentes
% Clientes Recorrentes =
DIVIDE([Clientes Recorrentes], [Clientes Únicos])
```

---

## PASSO 4 — Layout do Dashboard

Crie **3 páginas**:

### Página 1: Visão Geral

| Visual | Posição | Configuração |
|--------|---------|--------------|
| **Cartão** | Topo esquerda | Métrica: `Total Pedidos` |
| **Cartão** | Topo centro | Métrica: `Receita Total` (formato R$) |
| **Cartão** | Topo direita | Métrica: `Ticket Médio` (formato R$) |
| **Cartão** | Linha 2 esq. | Métrica: `Nota Média` (1 decimal) |
| **Cartão** | Linha 2 dir. | Métrica: `% Entrega No Prazo` (%) |
| **Gráfico de linhas** | Centro | Eixo X: `dim_calendario[ano_mes]`, Valores: `Receita Total` |
| **Gráfico de barras** | Baixo esq. | Eixo Y: `categoria`, Valores: `Receita Total` (top 10) |
| **Mapa preenchido** | Baixo dir. | Local: `customer_state`, Valores: `Receita Total` |

### Página 2: Análise de Entrega

- Gráfico de rosca: `status_entrega` vs contagem
- Gráfico de barras: `customer_state` vs `Tempo Médio Entrega (dias)`
- Tabela: Estado, Pedidos, % No Prazo, Tempo Médio

### Página 3: Performance por Categoria e Vendedor

- Gráfico de barras: top 10 categorias por receita
- Gráfico de dispersão: Receita vs Nota Média por categoria
- Tabela de vendedores: seller_id, seller_state, Pedidos, Receita, Nota Média

---

## PASSO 5 — Segmentações (Slicers)

Adicione em todas as páginas:
- **Slicer de Ano**: campo `dim_calendario[ano]`
- **Slicer de Estado**: campo `fato_pedidos[customer_state]`
- **Slicer de Categoria**: campo `fato_pedidos[categoria]`

Configure todos como **sincronizados** (Exibição → Sincronizar Segmentações).

---

## Paleta de Cores Sugerida

| Uso | Cor | Hex |
|-----|-----|-----|
| Principal | Azul Olist | `#003566` |
| Destaque | Azul médio | `#2E75B6` |
| Positivo | Verde | `#1D9E75` |
| Alerta | Laranja | `#BA7517` |
| Negativo | Vermelho | `#A32D2D` |
| Fundo | Cinza claro | `#F4F6F9` |

---

## Dicas Finais

- Formate os cartões de KPI com **fundo branco, borda arredondada** e sombra leve
- Use **formatação condicional** na tabela de estados para destacar os maiores valores
- Adicione **tooltips personalizados** nos gráficos com métricas extras
- O mapa requer que os estados estejam no formato de sigla (SP, RJ, MG...) — já está correto nos dados
