# Sistema de Gamificação

## Visão Geral

O sistema de gamificação oferece um ambiente motivador e envolvente para completar tarefas. Inclui pontos, níveis, medalhas, sequências e um painel de conquistas para rastrear progresso.

## Componentes Principais

### 1. Sistema de Pontos

Cada tarefa concluída gera pontos baseados em vários fatores:

**Pontos Base:** 10 pontos por tarefa

**Bônus de Prioridade:**
- Alta prioridade: +50% (15 pontos)
- Média prioridade: +50% (15 pontos)
- Baixa prioridade: 0% (10 pontos)

**Bônus de Velocidade:** +5 pontos se concluir no mesmo dia que criou

**Bônus de Sequência:** +5 pontos por cada dia consecutivo de atividade

**Bônus de Categoria:** +2 pontos por cada 5 tarefas concluídas na mesma categoria

**Exemplo:**
- Tarefa de alta prioridade concluída no mesmo dia: 10 + 5 (prioridade) + 5 (velocidade) = 20 pontos
- Com sequência de 3 dias: 20 + 15 (3 × 5) = 35 pontos

### 2. Níveis

Acumule pontos para subir de nível:
- **Limiar por nível:** 100 pontos
- **Nível 1:** 0-100 pontos
- **Nível 2:** 100-200 pontos
- **Nível 3:** 200-300 pontos
- E assim por diante...

Cada nível desbloqueado é uma conquista pessoal e mostra progresso contínuo.

### 3. Sequências (Streaks)

Mantenha uma sequência completando tarefas em dias consecutivos:
- **Sequência de 1 dia:** Comece sua jornada
- **Sequência de 3 dias:** Desbloqueie medalha "Sequência de 3"
- **Sequência de 7 dias:** Desbloqueie medalha "Semana Perfeita"
- **Sequência de 30 dias:** Desbloqueie medalha "Mês Implacável"

A sequência reseta se não completar nenhuma tarefa em um dia.

### 4. Medalhas (Badges)

Existem 15 medalhas diferentes, cada uma com raridade e critério de desbloqueio:

#### Medalhas de Conclusão
- **Conquistador** (Comum): Conclua sua primeira tarefa
- **Cinco Vitórias** (Incomum): Conclua 5 tarefas
- **Dez Vezes Campeão** (Incomum): Conclua 10 tarefas
- **Mestre das Tarefas** (Raro): Conclua 50 tarefas
- **Lenda Viva** (Lendário): Conclua 100 tarefas

#### Medalhas de Sequência
- **Sequência de 3** (Incomum): 3 dias consecutivos
- **Semana Perfeita** (Raro): 7 dias consecutivos
- **Mês Implacável** (Épico): 30 dias consecutivos

#### Medalhas de Especialização
- **Domador de Prioridades** (Raro): 10 tarefas de alta prioridade
- **Especialista em Categorias** (Incomum): 5 tarefas na mesma categoria
- **Demônio da Velocidade** (Raro): Conclua uma tarefa em menos de 1 hora
- **Perfeccionista** (Incomum): Conclua tarefa de alta prioridade com prazo
- **Coruja Noturna** (Incomum): Conclua tarefa entre 22h e 6h
- **Madrugador** (Incomum): Conclua tarefa entre 5h e 8h

#### Raridade das Medalhas
- **Comum:** Fácil de desbloquear, para iniciantes
- **Incomum:** Requer dedicação moderada
- **Raro:** Desafio significativo
- **Épico:** Muito desafiador
- **Lendário:** Extremamente raro e prestigioso

## Página de Conquistas

A página de Conquistas (`/achievements`) exibe:

### Seção de Estatísticas
- Nível atual com barra de progresso
- Pontos totais
- Sequência atual em dias
- Progresso geral (medalhas desbloqueadas/total)

### Seção de Medalhas
- **Medalhas Desbloqueadas:** Grid com todas as medalhas conquistadas
- **Próximas Medalhas:** Grid com medalhas bloqueadas e seus critérios
- Cada medalha mostra: ícone, nome, raridade, data de desbloqueio

### Seção Educacional
- Como desbloquear cada medalha
- Sistema de pontos explicado
- Dicas para maximizar pontos

## Arquitetura

### Arquivos Principais

**`client/src/hooks/useGamification.ts`**
- Hook customizado com toda a lógica de gamificação
- Gerencia estado de pontos, níveis, medalhas e sequências
- Persiste dados no localStorage

**`client/src/contexts/GamificationContext.tsx`**
- Contexto global para acesso ao sistema de gamificação
- Fornece estado e funções para toda a aplicação

**`client/src/components/GamificationWidgets.tsx`**
- Componentes reutilizáveis:
  - `LevelDisplay`: Mostra nível e progresso
  - `StreakDisplay`: Mostra sequência atual
  - `BadgeGrid`: Grid de medalhas
  - `BadgeCard`: Cartão individual de medalha
  - `PointsBreakdownDisplay`: Detalhamento de pontos
  - `AchievementNotification`: Notificação de conquista

**`client/src/pages/Achievements.tsx`**
- Página completa de conquistas
- Exibe todas as estatísticas e medalhas
- Interface educacional

### Integração

O sistema está integrado em:
- **App.tsx**: GamificationProvider envolve toda a aplicação
- **AppLayout.tsx**: Link para página de Conquistas na sidebar
- **Tasks.tsx**: Pode ser estendido para chamar `awardPoints()` ao completar tarefas

## Uso no Código

### Acessar o Contexto de Gamificação

```typescript
import { useGamificationContext } from '@/contexts/GamificationContext';

function MyComponent() {
  const { state, awardPoints, unlockBadge } = useGamificationContext();
  
  // state.totalPoints - pontos totais
  // state.currentLevel - nível atual
  // state.streakDays - dias de sequência
  // state.badges - medalhas desbloqueadas
}
```

### Calcular Pontos para uma Tarefa

```typescript
const { calculatePoints } = useGamificationContext();
const breakdown = calculatePoints(task, allTasks);
console.log(breakdown.totalPoints); // pontos ganhos
```

### Conceder Pontos

```typescript
const { awardPoints } = useGamificationContext();
awardPoints(50); // concede 50 pontos
```

### Desbloquear Medalha

```typescript
const { unlockBadge } = useGamificationContext();
unlockBadge('first_completion'); // desbloqueia medalha específica
```

### Verificar Medalhas

```typescript
const { checkBadges } = useGamificationContext();
checkBadges(allTasks); // verifica e desbloqueia medalhas baseado em tarefas
```

### Atualizar Sequência

```typescript
const { updateStreak } = useGamificationContext();
updateStreak(allTasks); // atualiza sequência baseado em atividade recente
```

## Persistência de Dados

Todos os dados de gamificação são salvos no localStorage sob a chave `task-notes-app-gamification`:

```json
{
  "totalPoints": 350,
  "currentLevel": 3,
  "pointsToNextLevel": 50,
  "badges": [
    {
      "id": "first_completion",
      "name": "Conquistador",
      "unlockedAt": "2026-04-05T20:00:00.000Z"
    }
  ],
  "streakDays": 5,
  "lastActivityDate": "2026-04-05"
}
```

## Próximas Melhorias Possíveis

- [ ] Notificações visuais ao desbloquear medalhas
- [ ] Leaderboard comparando com outros usuários (se sincronizado)
- [ ] Desafios semanais com bônus de pontos
- [ ] Temas de medalhas (sazonal, temático)
- [ ] Integração com Dashboard mostrando progresso
- [ ] Sistema de "power-ups" para multiplicadores de pontos
- [ ] Histórico de conquistas com timeline
- [ ] Compartilhamento de conquistas
- [ ] Badges especiais por eventos ou datas (aniversário, etc)
- [ ] Sistema de "títulos" baseado em níveis

## Dicas para Maximizar Pontos

1. **Prioridades:** Foque em tarefas de alta prioridade para ganhar mais pontos
2. **Velocidade:** Complete tarefas no mesmo dia que as cria para bônus
3. **Sequência:** Mantenha uma sequência consistente - é melhor completar 1 tarefa todos os dias que 7 em um dia
4. **Categorias:** Especialize-se em categorias para ganhar bônus
5. **Combinação:** Combine alta prioridade + velocidade + sequência para máximo de pontos

## Feedback e Engajamento

O sistema de gamificação foi projetado para:
- **Motivar:** Mostrar progresso visual e recompensas
- **Engajar:** Criar objetivos de curto e longo prazo
- **Recompensar:** Reconhecer diferentes tipos de conquistas
- **Inspirar:** Incentivar consistência e dedicação
