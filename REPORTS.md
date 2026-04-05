# Sistema de Relatórios e Análises

## Visão Geral

O sistema de relatórios fornece visualizações abrangentes de produtividade, progresso de tarefas e análises detalhadas. Inclui gráficos interativos, métricas de desempenho e estatísticas por período.

## Funcionalidades

### Visualizações de Dados

#### 1. Tarefas por Dia (Últimos 30 dias)
- Gráfico de linhas mostrando tarefas concluídas, pendentes e em andamento
- Permite identificar padrões de produtividade diária
- Dados agregados por data de criação

#### 2. Distribuição por Prioridade
- Gráfico de pizza mostrando proporção de tarefas por prioridade
- Categorias: Alta, Média, Baixa
- Ajuda a identificar balanceamento de carga

#### 3. Tarefas por Período
- **Semanal**: Últimas 4 semanas com dados agregados
- **Mensal**: Últimos 12 meses com dados agregados
- **Anual**: Todos os meses do ano
- Gráficos de barras com status (Concluída, Pendente, Em andamento)

#### 4. Taxa de Conclusão por Categoria
- Gráfico de barras horizontal mostrando % de conclusão por categoria
- Identifica quais categorias têm melhor desempenho
- Apenas categorias com tarefas são exibidas

#### 5. Medidor de Taxa de Conclusão
- Visualização circular mostrando taxa geral de conclusão
- Cores variam conforme a taxa (verde para alta, vermelho para baixa)

### Métricas e Estatísticas

#### Estatísticas Gerais
- **Total de Tarefas**: Número total de tarefas criadas
- **Taxa de Conclusão**: Percentual de tarefas concluídas
- **Esta Semana**: Tarefas concluídas na semana atual
- **Produtividade**: Score de 0-100 baseado em múltiplos fatores

#### Estatísticas Detalhadas
- Tarefas Concluídas
- Tarefas Pendentes
- Tarefas Em Andamento
- Concluídas Esta Semana
- Concluídas Este Mês
- Tendência de Produtividade (Subindo/Caindo/Estável)

### Indicadores de Desempenho

#### Produtividade Score
- Baseado em: taxa de conclusão, atividade recente, tendência
- Escala: 0-100
- Níveis: Muito Baixo, Baixo, Moderado, Bom, Excelente

#### Tendência de Produtividade
- Compara tarefas concluídas esta semana vs semana passada
- Indicadores: 📈 Subindo, 📉 Caindo, ➡️ Estável

## Funções de Análise

### Arquivo: `client/src/lib/analytics.ts`

#### Funções Principais

**getDailyStats(tasks, days)**
- Retorna estatísticas diárias para os últimos N dias
- Agregação por data de criação

**getWeeklyStats(tasks, weeks)**
- Retorna estatísticas semanais para as últimas N semanas
- Semanas começam na segunda-feira

**getMonthlyStats(tasks, months)**
- Retorna estatísticas mensais para os últimos N meses
- Agregação por mês completo

**getPriorityStats(tasks)**
- Retorna estatísticas agrupadas por prioridade (Alta, Média, Baixa)
- Inclui contagem de tarefas por status

**getCategoryStats(tasks, categories)**
- Retorna estatísticas por categoria
- Inclui taxa de conclusão por categoria
- Apenas categorias com tarefas

**getOverallStats(tasks)**
- Retorna estatísticas gerais consolidadas
- Inclui métricas de produtividade e tendências

**getProductivityScore(stats)**
- Calcula score de produtividade (0-100)
- Baseado em taxa de conclusão, atividade e tendência

**getProductivityLevel(score)**
- Retorna nível descritivo baseado no score
- Níveis: Muito Baixo, Baixo, Moderado, Bom, Excelente

## Componentes de Gráficos

### Arquivo: `client/src/components/Charts.tsx`

#### Componentes Disponíveis

**DailyTasksChart**
- Gráfico de linhas com dados diários
- Props: `data` (DailyStats[]), `height`, `className`

**WeeklyTasksChart**
- Gráfico de barras com dados semanais
- Props: `data` (WeeklyStats[]), `height`, `className`

**MonthlyTasksChart**
- Gráfico de barras com dados mensais
- Props: `data` (MonthlyStats[]), `height`, `className`

**PriorityChart**
- Gráfico de pizza com distribuição por prioridade
- Props: `data` (PriorityStats[]), `height`, `className`

**CategoryCompletionChart**
- Gráfico de barras horizontal com taxa de conclusão
- Props: `data` (CategoryStats[]), `height`, `className`

**CompletionGauge**
- Medidor circular de taxa de conclusão
- Props: `rate` (number), `className`

## Paleta de Cores

```typescript
const COLORS = {
  done: '#4A7C59',      // Verde-musgo (tarefas concluídas)
  pending: '#B45309',   // Terracota (tarefas pendentes)
  inProgress: '#C0533A', // Terracota escuro (em andamento)
  high: '#C0533A',      // Vermelho (prioridade alta)
  medium: '#B45309',    // Laranja (prioridade média)
  low: '#4A7C59',       // Verde (prioridade baixa)
};
```

## Filtros de Período

A página de Relatórios oferece três opções de período:

1. **Semana**: Mostra últimas 4 semanas
2. **Mês** (padrão): Mostra últimos 12 meses
3. **Ano**: Mostra todos os meses do ano

Os filtros afetam apenas o gráfico de tarefas por período. Outras visualizações mostram dados consolidados.

## Cálculos e Agregações

### Data de Referência
- Todos os cálculos usam a data/hora atual como referência
- Semanas começam na segunda-feira (padrão português)

### Agregação por Status
- **Concluídas**: tasks com status === 'done'
- **Pendentes**: tasks com status === 'pending'
- **Em Andamento**: tasks com status === 'in_progress'

### Período de Atividade
- Tarefas são agrupadas pela data de **criação** (para histórico)
- Tarefas concluídas usam data de **atualização** (para tendências)

## Limitações e Considerações

1. **Performance**: Com muitas tarefas (>1000), os cálculos podem ser lentos
2. **Dados Históricos**: Relatórios baseiam-se apenas em tarefas existentes
3. **Sincronização**: Relatórios atualizam em tempo real conforme tarefas são modificadas
4. **Precisão de Datas**: Agregações dependem da precisão dos timestamps

## Próximas Melhorias Possíveis

- [ ] Exportar relatórios em PDF
- [ ] Comparação período a período (mês vs mês anterior)
- [ ] Previsões de conclusão baseadas em tendências
- [ ] Alertas quando produtividade cai abaixo de limiar
- [ ] Relatórios agendados por email
- [ ] Análise de tempo médio para conclusão por categoria
- [ ] Gráficos de burndown para sprints
