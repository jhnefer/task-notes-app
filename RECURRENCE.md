# Sistema de Tarefas Recorrentes

## Visão Geral

O sistema de tarefas recorrentes permite criar tarefas que se repetem automaticamente em intervalos regulares (diários, semanais ou mensais). Cada ocorrência é criada como uma tarefa independente vinculada à tarefa recorrente original.

## Recursos

### Frequências Suportadas

- **Diária**: Repetir todos os dias
- **Semanal**: Repetir todas as semanas
- **Mensal**: Repetir todos os meses

### Configurações de Recorrência

#### Intervalo
Define quantos dias/semanas/meses entre cada ocorrência. Por exemplo:
- Intervalo 1 + Diária = todos os dias
- Intervalo 2 + Semanal = a cada 2 semanas
- Intervalo 3 + Mensal = a cada 3 meses

#### Limite de Ocorrências
Define o número máximo de ocorrências a serem geradas. Padrão: 12 ocorrências.

#### Data de Término
Alternativa ao limite de ocorrências. Define uma data final para parar de gerar novas ocorrências.

## Como Usar

### Criar uma Tarefa Recorrente

1. Navegue até a página **Tarefas**
2. Clique no botão **Recorrente** (ícone com setas circulares)
3. Preencha os detalhes:
   - **Título**: Nome da tarefa (obrigatório)
   - **Descrição**: Detalhes adicionais (opcional)
   - **Prioridade**: Alta, Média ou Baixa
   - **Categoria**: Organize por categoria
   - **Data de Início**: Quando a primeira ocorrência deve acontecer
4. Configure a recorrência:
   - Escolha a **Frequência** (Diária, Semanal, Mensal)
   - Defina o **Intervalo** (cada N dias/semanas/meses)
   - Escolha entre **Máximo de Ocorrências** ou **Data de Término**
5. Clique em **Criar Tarefa Recorrente**

### Gerenciar Tarefas Recorrentes

#### Visualizar Ocorrências
- A tarefa recorrente aparece na lista com um badge **Recorrente**
- Todas as ocorrências aparecem como tarefas individuais
- Você pode filtrar, buscar e organizar ocorrências normalmente

#### Editar Ocorrências
- Clique em uma ocorrência para editar seus detalhes
- As mudanças afetam apenas essa ocorrência, não a tarefa recorrente original

#### Marcar como Concluída
- Clique no checkbox para marcar uma ocorrência como concluída
- Isso não afeta outras ocorrências

#### Deletar Tarefas Recorrentes
- Deletar a tarefa recorrente original remove também todas as suas ocorrências
- Deletar uma ocorrência individual não afeta a tarefa recorrente

## Estrutura de Dados

### RecurrenceRule

```typescript
interface RecurrenceRule {
  frequency: 'daily' | 'weekly' | 'monthly';
  interval: number; // repeat every N days/weeks/months
  endDate?: string; // ISO date string - when to stop generating occurrences
  maxOccurrences?: number; // maximum number of occurrences to generate
}
```

### Task com Recorrência

```typescript
interface Task {
  // ... campos padrão ...
  recurrence?: RecurrenceRule; // se definido, é uma tarefa recorrente
  parentTaskId?: string; // se definido, é uma ocorrência de uma tarefa recorrente
  occurrenceDate?: string; // ISO date string - a data desta ocorrência
}
```

## Exemplos de Uso

### Exemplo 1: Exercício Diário
- Frequência: Diária
- Intervalo: 1
- Máximo de Ocorrências: 30
- Resultado: 30 tarefas de exercício, uma para cada dia

### Exemplo 2: Reunião Semanal
- Frequência: Semanal
- Intervalo: 1
- Data de Término: 31 de dezembro de 2026
- Resultado: Tarefas de reunião toda semana até o final do ano

### Exemplo 3: Revisão Mensal
- Frequência: Mensal
- Intervalo: 1
- Máximo de Ocorrências: 12
- Resultado: 12 tarefas de revisão, uma por mês

### Exemplo 4: Limpeza a Cada 2 Semanas
- Frequência: Semanal
- Intervalo: 2
- Máximo de Ocorrências: 26
- Resultado: 26 tarefas de limpeza, a cada 2 semanas

## Funções Utilitárias

O arquivo `client/src/lib/recurrence.ts` contém funções auxiliares:

- `generateOccurrences()`: Gera ocorrências para uma tarefa recorrente
- `getNextOccurrenceDate()`: Calcula a próxima data de ocorrência
- `getFrequencyLabel()`: Retorna o rótulo da frequência em português
- `getIntervalLabel()`: Retorna um resumo do intervalo
- `getRecurrenceSummary()`: Retorna um resumo completo da recorrência
- `isRecurringTask()`: Verifica se uma tarefa é recorrente
- `isTaskOccurrence()`: Verifica se uma tarefa é uma ocorrência
- `getTaskOccurrences()`: Retorna todas as ocorrências de uma tarefa recorrente
- `getParentTask()`: Retorna a tarefa recorrente original

## Limitações e Considerações

1. **Limite de Ocorrências**: Por padrão, no máximo 12 ocorrências são geradas. Você pode aumentar isso na configuração.

2. **Data de Término**: Se usar data de término, certifique-se de que é posterior à data de início.

3. **Edição em Massa**: Atualmente, não há suporte para editar todas as ocorrências de uma vez. Edições afetam apenas a ocorrência individual.

4. **Sincronização**: As ocorrências são geradas quando a tarefa recorrente é criada. Não há geração dinâmica de futuras ocorrências.

## Próximas Melhorias Possíveis

- [ ] Editar todas as ocorrências de uma tarefa recorrente
- [ ] Gerar ocorrências dinamicamente conforme o tempo passa
- [ ] Suporte a padrões de recorrência mais complexos (ex: "primeira segunda-feira do mês")
- [ ] Sincronização com calendários externos
- [ ] Notificações para próximas ocorrências
