# Backlog de Implementação do App (Flutter) — Meu Caderno

Documento de acompanhamento com todas as tarefas necessárias para equiparar o aplicativo Flutter (`app/`) à versão Web (`client/` + `server/`), separado em **Configurações**, **Telas** e **Funcionalidades**.

---

## 1. Configurações, Pacotes e Infraestrutura

### 1.1. Dependências (`app/pubspec.yaml`)
- [x] Adicionar `flutter_localizations` (SDK) para suporte completo ao idioma `pt_BR` em componentes nativos (como `DatePicker`).
- [x] Adicionar pacote de cliente HTTP e persistência de sessão/cookies (`dio`, `dio_cookie_manager`, `cookie_jar`) para autenticar com o `express-session` do backend.
- [x] Adicionar solução de gerenciamento de estado (`provider`, `riverpod` ou `bloc`).
- [x] Adicionar pacote de armazenamento local (`shared_preferences` ou `hive`) para cache offline, tema e persistência da gamificação.
- [x] Adicionar pacote de gráficos (`fl_chart`) para a tela de Relatórios.
- [x] Adicionar pacotes de exportação e compartilhamento (`pdf`, `printing`, `csv`, `path_provider`, `share_plus`).
- [x] Adicionar pacotes de notificações locais (`flutter_local_notifications`, `permission_handler`).

### 1.2. Ambiente e Plataforma Nativa
- [x] Configurar URL base da API (ex.: `http://10.0.2.2:5000/api` no emulador Android / variável de ambiente).
- [x] Adicionar permissão `<uses-permission android:name="android.permission.INTERNET"/>` e `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` no `AndroidManifest.xml`.
- [x] Configurar permissões equivalentes de notificação e compartilhamento no `Info.plist` (iOS).
- [x] Inicializar formatação de datas no `main.dart` com `WidgetsFlutterBinding.ensureInitialized()` e `await initializeDateFormatting('pt_BR', null)`.

### 1.3. Tema, Tipografia e Pendências Visuais (`TODO`s)
- [x] Adicionar cor `0xFF3F3024` (destaque/item selecionado da sidebar) em `app/lib/themes/app_colors.dart` (resolvendo `//TODO: adicionar cor em app_colors` em `drawer_app.dart`).
- [x] Ajustar a cor do `Divider()` no `drawer_app.dart` (resolvendo `//TODO: trocar cor`).
- [x] Remover a duplicação do ícone de sino entre a `AppBar` do `main_layout.dart` e o topo da `home_page.dart` (resolvendo `//TODO: mudar posicao`).
- [x] Corrigir os nomes de fontes em `home_page.dart` (substituir `'Cursive'` por `'Caveat'` e `'Serif'` por `'Playfair Display'`).
- [x] Implementar `AppTheme.darkTheme` em `app/lib/themes/app_theme.dart` e controle dinâmico de `ThemeMode` (Light/Dark).

---

## 2. Telas (UI e Modais)

### 2.1. Autenticação (`AuthPage`)
- [x] Criar tela de Login e Cadastro (`app/lib/pages/auth_page.dart`) seguindo o visual de `client/src/pages/Auth.tsx`.
- [x] Adicionar campos de `Usuário` e `Senha` com validação.
- [x] Adicionar botão de alternância entre os modos **Entrar** e **Criar Conta**.
- [x] Criar estado visual de carregamento (*Splash / Loading*) enquanto verifica se o usuário já está autenticado.

### 2.2. Visão Geral / Dashboard (`HomePage`)
- [x] Adicionar banner de alerta de notificações críticas/urgentes (`NotificationAlert`) no topo do conteúdo.
- [x] Criar card de **Progresso Geral** com barra de progresso animada e percentual de tarefas concluídas.
- [x] Criar seção **Próximos Prazos** (lista das próximas 5 tarefas pendentes com prazo, categoria, badge de prioridade e indicador de atraso) com botão *"Ver todas"*.
- [x] Criar seção **Notas Fixadas** (lista das até 3 notas fixadas com título e resumo) com botão *"Ver todas"*.
- [x] Criar seção **Tarefas Recentes** (lista das 5 tarefas ativas mais recentes com badge de status) com botão *"Gerenciar"*.
- [x] Tornar a tela rolável (`SingleChildScrollView` / `CustomScrollView`) para acomodar todas as novas seções abaixo do grid de cards.

### 2.3. Tarefas (`TasksPage`)
- [x] Criar tela principal de Tarefas (`app/lib/pages/tasks_page.dart`).
- [x] Implementar cabeçalho com contador (`X de Y tarefas`) e botões de ação: **Exportar**, **Recorrente** e **Nova Tarefa**.
- [x] Implementar barra de ferramentas com alternador de visão (**Lista** / **Kanban**), campo de **Busca** e botão de **Filtros** (com badge de filtros ativos).
- [x] Criar painel expansível de filtros por **Prioridade**, **Status**, **Categoria** e botão *"Limpar filtros"*.
- [x] Implementar **Visão em Lista**:
  - [x] Agrupamento por seções (`Em andamento`, `Pendente`, `Concluída`).
  - [x] Card de tarefa com checkbox, título, descrição, categoria, tags, prazo, badge de recorrência e botões de editar/excluir.
  - [x] Seção expansível de **Submetas** dentro do card com contador (`X/Y`), barra de progresso e checkboxes individuais.
- [x] Implementar **Visão Kanban (`KanbanBoard`)**:
  - [x] Três colunas (`Pendente`, `Em Andamento`, `Concluída`) com contagem de itens.
  - [x] Cards arrastáveis (*drag-and-drop*) ou com menu rápido para mudança de coluna.
- [x] Criar **Modal de Nova/Editar Tarefa (`TaskDialog`)**:
  - [x] Campos de Título, Descrição, Prioridade, Status, Categoria, Prazo (`DatePicker`) e Tags.
  - [x] Lista interativa de Submetas (adicionar manual, marcar/desmarcar e excluir).
  - [x] Componente **Sugestão Inteligente — Gemini IA (`AiBreakdownModal`)** com botão *"Decompor Meta"*, preview das subtarefas geradas e botão *"Adicionar à Tarefa"*.
- [x] Criar **Modal de Tarefa Recorrente (`RecurringTaskDialog`)**:
  - [x] Campos básicos da tarefa + Data de início obrigatória.
  - [x] Configuração de frequência (`Diariamente`, `Semanalmente`, `Mensalmente`) e intervalo numérico.
  - [x] Seleção entre *Máximo de ocorrências* ou *Data de término* com resumo da regra.

### 2.4. Anotações (`NotesPage`)
- [x] Criar tela de Anotações (`app/lib/pages/notes_page.dart`).
- [x] Implementar cabeçalho com contador, menu **Exportar** e botão **Nova Anotação**.
- [x] Adicionar barra de busca por texto/tags e seletor de filtro por Categoria.
- [x] Implementar listagem separada em **Fixadas** e **Outras Anotações**.
- [x] Criar componente `NoteCard` exibindo título, prévia do conteúdo (até 3 linhas), categoria, `#tags`, data de atualização e ações (fixar/desafixar, editar, excluir).
- [x] Criar **Modal de Nova/Editar Anotação (`NoteDialog`)** com título, campo de conteúdo estilo papel pautado, seletor de categoria, tags e botão de fixar nota.

### 2.5. Categorias (`CategoriesPage`)
- [x] Criar tela de Categorias (`app/lib/pages/categories_page.dart`).
- [x] Implementar grid de cards de categorias exibindo avatar colorido com inicial, nome, ícone, contadores de **Tarefas** e **Notas**, barra de progresso de conclusão e botão de excluir.
- [x] Criar **Modal de Nova Categoria (`CategoryDialog`)** com campo de nome, seletor de 15 cores, seletor de 15 ícones e caixa de *Preview* em tempo real.

### 2.6. Relatórios (`ReportsPage`)
- [x] Criar tela de Relatórios (`app/lib/pages/reports_page.dart`).
- [x] Adicionar filtro de período (`Semana`, `Mês`, `Ano`).
- [x] Criar os 4 cards superiores: **Total de Tarefas**, **Taxa de Conclusão**, **Esta Semana** e **Produtividade (Score + Nível)**.
- [x] Implementar medidor visual circular/semicircular de **Taxa de Conclusão (`CompletionGauge`)**.
- [x] Implementar gráfico **Tarefas por Dia (Últimos 30 dias)**.
- [x] Implementar gráfico **Distribuição por Prioridade** (Alta, Média, Baixa).
- [x] Implementar gráfico **Tarefas por Semana / Mês**.
- [x] Implementar gráfico **Taxa de Conclusão por Categoria**.
- [x] Criar tabela de **Estatísticas Detalhadas** com todas as métricas e badge de **Tendência de Produtividade** (`📈 Subindo`, `📉 Caindo`, `➡️ Estável`).

### 2.7. Conquistas (`AchievementsPage`)
- [x] Criar tela de Conquistas (`app/lib/pages/achievements_page.dart`).
- [x] Criar os 3 cards principais: **Nível Atual (`LevelDisplay`)** com barra de XP, **Sequência (`StreakDisplay`)** em dias e **Progresso de Medalhas**.
- [x] Criar os 4 mini-cards de estatísticas: *Tarefas Concluídas*, *Prioridade Alta*, *Sequência* e *Pontos Totais*.
- [x] Implementar grids de **Medalhas Desbloqueadas** e **Próximas Medalhas (Bloqueadas)** (`BadgeCard` com cores por raridade).
- [x] Adicionar seções informativas *"Como Desbloquear Medalhas"* e *"Sistema de Pontos"*.

### 2.8. Painel de Notificações (`NotificationPanel`)
- [x] Criar modal/bottom-sheet de Notificações acionado pelo ícone de sino na `AppBar`.
- [x] Exibir botão para solicitar permissão de notificações nativas do dispositivo.
- [x] Exibir os 4 contadores de urgência (`Crítico`, `Urgente`, `Próximo`, `Baixo`) e a lista de tarefas próximas do prazo ou atrasadas.

---

## 3. Funcionalidades e Regras de Negócio

### 3.1. Navegação e Layout (`MainLayout` / `DrawerApp` / `AppNavigationBar`)
- [x] Conectar os 6 itens do `DrawerApp` (`Visão geral`, `Tarefas`, `Anotações`, `Categorias`, `Relatórios`, `Conquistas`) para alternar a página ativa no `MainLayout`.
- [x] Criar `AppNavigationBar` flutuante (estilo pílula/caderno) com as 4 páginas principais (`Início`, `Tarefas`, `Anotações`, `Relatórios`) sincronizada com o `DrawerApp`.
- [x] Atualizar dinamicamente o estado `selected` do item ativo no Drawer e na Navigation Bar.
- [x] Exibir badges de contagem de notificações críticas/altas nos itens *Visão geral* e *Tarefas* do Drawer, na Navigation Bar e no ícone da `AppBar`.
- [x] Configurar ação do `FloatingActionButton` na `HomePage` (ex.: abrir modal de criação rápida de tarefa/anotação).

### 3.2. Autenticação Opcional e Modo Offline-First
- [x] Permitir uso 100% offline do aplicativo sem exigir login inicial (Modo Local/Offline como padrão ao abrir o app).
- [x] Implementar serviço de autenticação opcional (`POST /api/login`, `POST /api/register`, `POST /api/logout`, `GET /api/user`) para quando o usuário desejar ativar sincronização na nuvem.
- [x] Migrar e enfileirar automaticamente todos os dados criados offline (`Categories`, `Tasks`, `Notes`) ao conectar ou criar uma conta posteriormente, sem perda de dados.
- [x] Exibir status de conta/sincronização no rodapé do `DrawerApp` (*"Sincronizar na nuvem"* quando offline ou *"Usar só offline / Sair"* quando conectado, mantendo dados locais).

### 3.3. Armazenamento Local, Sincronização em 2º Plano e Backend
- [x] Criar modelos de dados Dart (`User`, `Task`, `Subtask`, `RecurrenceRule`, `Note`, `Category`, `SyncOperation`) compatíveis com `shared/schema.ts` e serialização JSON completa.
- [x] Implementar banco de dados **SQLite embarcado (`meu_caderno.db`)** via `AppDatabase` e `LocalStorageService` como fonte única da verdade (com modo `WAL`, migração não-destrutiva por `PRAGMA table_info`, backup automático `.bak` antes de upgrades de versão e migração transparente do JSON legado).
- [x] Implementar `SyncService` com fila persistente (*Outbox Pattern*) e compactação de operações (*coalescing*), sincronizando silenciosamente em segundo plano (*debounce*, retomada do app e timer periódico).
- [x] Criar indicador visual sutil de sincronização (`SyncStatusIndicator`) na `AppBar` (animação discreta durante sync, confirmação suave e aviso não intrusivo de pendências offline).
- [x] Ajustar backend (`shared/schema.ts` e `server/routes.ts`) para aceitar IDs e timestamps gerados offline com *upsert* idempotente.
- [x] Implementar CRUD Offline-First + Sync de **Categorias** (`GET`, `POST`, `DELETE /api/categories`).
  - [x] Validar exclusão: bloquear exclusão de categoria que possua tarefas ou notas associadas.
- [x] Implementar CRUD Offline-First + Sync de **Tarefas** (`GET`, `POST`, `PATCH`, `DELETE /api/tasks`).
  - [x] Implementar busca textual (título, descrição, tags) e filtros combinados (prioridade, status, categoria).
  - [x] Implementar regra de submetas: ao marcar/desmarcar submetas, atualizar status da tarefa principal automaticamente para `done` (se todas completas) ou `in_progress`.
  - [x] Implementar trava de conclusão: impedir que uma tarefa com submetas pendentes seja marcada como `done` (exibindo alerta ao usuário).
- [x] Implementar CRUD Offline-First + Sync de **Anotações** (`GET`, `POST`, `PATCH`, `DELETE /api/notes`), incluindo toggle de `pinned`, busca e filtro por categoria.
- [x] Implementar integração com **IA Breakdown** (`POST /api/ai/breakdown`) enviando `{ goal: taskTitle }` e convertendo o retorno em submetas.
- [x] Implementar lógica de **Tarefas Recorrentes** (cálculo de próximas ocorrências e textos descritivos de intervalo equivalentes a `client/src/lib/recurrence.ts`).
- [x] Implementar função do botão **Resetar Dados** com diálogo de confirmação.

### 3.4. Dados Dinâmicos na Dashboard
- [x] Implementar função de saudação dinâmica baseada na hora atual (`Bom dia!`, `Boa tarde!`, `Boa noite!`).
- [x] Exibir a data atual formatada dinamicamente em português (`EEEE, d 'de' MMMM 'de' yyyy`).
- [x] Conectar os 4 `DashBoardCard`s (`Concluídas`, `Em andamento`, `Em atraso`, `Anotações`) aos contadores reais vindos do estado das tarefas e notas.

### 3.5. Sistema de Gamificação
- [ ] Portar lógica de `client/src/hooks/useGamification.ts` para o App:
  - [ ] Cálculo de pontos por tarefa concluída (10 pts base + multiplicador de prioridade + bônus de velocidade no mesmo dia + bônus de sequência + bônus de categoria).
  - [ ] Cálculo de nível (100 pontos por nível) e progresso percentual para o próximo nível.
  - [ ] Controle de sequência diária (`streakDays` e `lastActivityDate`).
  - [ ] Verificação e desbloqueio automático das 15 medalhas (`first_task`, `first_completion`, `five_completed`, `ten_completed`, `fifty_completed`, `hundred_completed`, `streak_3_days`, `streak_7_days`, `streak_30_days`, `high_priority_master`, `category_master`, `speed_demon`, `perfectionist`, `night_owl`, `early_bird`).

### 3.6. Motor de Analytics (Relatórios)
- [ ] Portar funções de `client/src/lib/analytics.ts` para Dart:
  - [ ] `getDailyStats` (últimos 30 dias), `getWeeklyStats` (últimas 12 semanas) e `getMonthlyStats` (últimos 12 meses).
  - [ ] `getPriorityStats`, `getCategoryStats` e `getOverallStats`.
  - [ ] `getProductivityScore` (0 a 100) e `getProductivityLevel` (`Excelente`, `Muito Bom`, `Bom`, `Regular`, `Baixo`).

### 3.7. Exportação de Dados (CSV e PDF)
- [ ] Implementar geração de arquivo **CSV** para Tarefas e para Anotações (equivalente a `exportTasksToCSV` e `exportNotesToCSV` em `client/src/lib/export.ts`).
- [ ] Implementar geração de arquivo **PDF** formatado para Tarefas e para Anotações (equivalente a `exportTasksToPDF` e `exportNotesToPDF`).
- [ ] Integrar abertura/compartilhamento do arquivo gerado no sistema operacional mobile.

### 3.8. Notificações de Prazos
- [ ] Portar lógica de `client/src/hooks/useNotifications.ts` para classificar tarefas pendentes com prazo em:
  - [ ] `critical`: atrasadas ou vencendo em ≤ 1h.
  - [ ] `high`: vencendo em ≤ 6h.
  - [ ] `medium`: vencendo em ≤ 24h.
  - [ ] `low`: vencendo entre 24h e 48h.
- [ ] Disparar notificações locais nativas para tarefas de urgência `critical` e `high` (evitando duplicatas na mesma sessão).
