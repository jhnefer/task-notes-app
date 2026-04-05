# Sistema de Notificações — Meu Caderno

## Visão Geral

O sistema de notificações alerta você sobre tarefas com prazos próximos. Ele funciona em três níveis:

1. **Badges na Sidebar** — Mostram o número de tarefas urgentes
2. **Alertas Visuais no Dashboard** — Banners destacados para tarefas críticas
3. **Notificações do Navegador** — Alertas do sistema operacional (com permissão)

---

## Níveis de Urgência

As notificações são categorizadas por urgência:

| Nível | Cor | Condição | Ícone |
|-------|-----|----------|-------|
| **Crítico** | Vermelho | Tarefa em atraso ou vence em < 1 hora | ⚠️ |
| **Urgente** | Âmbar | Vence em 1-6 horas | 🔔 |
| **Próximo** | Primário | Vence em 6-24 horas | ⏰ |
| **Baixo** | Cinza | Vence em 24-48 horas | 📅 |

---

## Como Usar

### Ativar Notificações do Navegador

1. Clique no ícone de sino (🔔) no canto superior direito do Dashboard
2. Clique em "Ativar" na seção "Notificações do Navegador"
3. Confirme a permissão no seu navegador
4. Você receberá alertas do sistema quando tarefas críticas ou urgentes se aproximarem

### Ver Todas as Notificações

1. Clique no ícone de sino (🔔)
2. Uma janela mostrará todas as tarefas com prazos próximos
3. As tarefas são ordenadas por urgência (mais urgentes primeiro)

### Badges na Sidebar

- **Visão Geral** e **Tarefas** mostram um badge com o número de tarefas críticas/urgentes
- O badge fica vermelho para tarefas críticas, âmbar para urgentes
- Clique no ícone de sino para ver detalhes

### Alerta no Dashboard

- Se houver tarefas críticas ou urgentes, um banner aparece no topo do Dashboard
- O banner descreve quantas tarefas precisam de atenção
- Clique em "Ver todas" para ir para a página de Tarefas

---

## Configurações

### Permissão de Notificações

O navegador pedirá permissão para enviar notificações. Você pode:

- **Permitir**: Receber notificações do sistema
- **Bloquear**: Desabilitar notificações (pode reativar nas configurações do navegador)
- **Ignorar**: Continuar sem notificações

### Frequência de Verificação

As notificações são verificadas:
- Quando você abre ou atualiza a página
- Quando você cria, edita ou marca uma tarefa como concluída
- A cada vez que você navega entre páginas

---

## Exemplos

### Exemplo 1: Tarefa Crítica

Uma tarefa "Enviar proposta ao cliente" com prazo em 45 minutos:

- **Badge na Sidebar**: Mostra "1" em vermelho
- **Alerta no Dashboard**: "1 tarefa em atraso ou vencendo em breve!"
- **Notificação do Navegador**: "⏰ Prazo Próximo — Enviar proposta ao cliente — Vence em menos de 1 hora"

### Exemplo 2: Tarefa Urgente

Uma tarefa "Revisar relatório mensal" com prazo em 3 horas:

- **Badge na Sidebar**: Mostra "1" em âmbar (se não houver críticas)
- **Painel de Notificações**: Lista a tarefa com ícone de relógio
- **Notificação do Navegador**: "⏰ Prazo Próximo — Revisar relatório mensal — Vence em 3h"

### Exemplo 3: Sem Notificações

Todas as tarefas têm prazos longos ou estão concluídas:

- **Badge na Sidebar**: Não aparece
- **Alerta no Dashboard**: Não aparece
- **Painel de Notificações**: "Nenhuma notificação — Todas as tarefas estão em dia!"

---

## Dicas

1. **Ativar notificações do navegador** para não perder prazos importantes
2. **Verificar o painel regularmente** para ver tarefas próximas
3. **Usar a página de Tarefas** para gerenciar prazos e prioridades
4. **Criar tarefas com prazos realistas** para evitar sobrecarga de notificações

---

## Troubleshooting

### Notificações não aparecem

1. Verifique se você ativou as notificações do navegador
2. Verifique as configurações de notificação do seu sistema operacional
3. Recarregue a página (F5 ou Cmd+R)
4. Tente criar uma tarefa com prazo em 30 minutos para testar

### Badges não atualizam

1. Recarregue a página
2. Crie ou edite uma tarefa para forçar atualização
3. Verifique se o localStorage está habilitado no seu navegador

### Notificações aparecem atrasadas

As notificações são verificadas quando você interage com a página. Se você deixar a aba aberta sem interagir, as notificações podem aparecer quando você voltar.

---

## Dados Técnicos

- **Armazenamento**: localStorage (dados persistem entre sessões)
- **Atualização**: Em tempo real quando você interage com a página
- **Permissões**: Requer consentimento do navegador para notificações do sistema
- **Privacidade**: Todas as notificações são processadas localmente no seu navegador
