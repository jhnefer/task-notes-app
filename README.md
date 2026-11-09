# 📓 Meu Caderno - Task & Notes Management App

Um aplicativo **Full Stack** moderno, elegante e inteligente para gerenciar tarefas, submetas e anotações. Projetado sob a acolhedora estética analógica de cadernos de notas (*Warm Paper Notebook*), ele combina produtividade, **gamificação**, suporte **PWA/Offline** e assistência de **Inteligência Artificial (Google Gemini)** para decomposição de objetivos complexos.

---

## ✨ Funcionalidades

### 🎯 Gestão de Metas & Submetas
- ✅ **Gerenciamento Completo de Tarefas** — Criação, edição, exclusão, categorização e definição de prioridades (Alta, Média, Baixa).
- 🧩 **Submetas Agregadas** — Divida metas grandes em subtarefas menores com prioridades individuais.
- 📊 **Progresso Dinâmico** — Acompanhamento em tempo real da porcentagem de conclusão das submetas em cada tarefa.
- 🛡️ **Garantia de Integridade** — Regra inteligente que impede a finalização prematura de uma meta principal enquanto existirem submetas pendentes.
- ⚡ **Ações Rápidas** — Conclusão de submetas diretamente na listagem e no quadro Kanban sem necessidade de abrir formulários de edição.

### 🤖 Inteligência Artificial (Google Gemini)
- 💡 **Decomposição Inteligente de Metas** — Clique em *Decompor Meta* e a IA analisa o objetivo e gera automaticamente 3 subtarefas práticas e priorizadas.
- ⚡ **Alta Disponibilidade e Velocidade** — Pipeline otimizado com pool de modelos rápidos do Google Gemini (`gemini-3.5-flash`, `gemini-3.5-flash-lite`, `gemini-3.6-flash`), com fallback automático e timeout individual.

### 📝 Anotações & Organização
- 📖 **Anotações Livres** — Bloco de notas integrado para reflexões, ideias e rascunhos.
- 🏷️ **Categorias e Tags** — Organize tarefas e notas por áreas da vida (Trabalho, Pessoal, Estudos, etc.).
- 📊 **Dashboard Geral** — Visão panorâmica dos afazeres diários, taxas de conclusão e métricas de desempenho.

### 🚀 Recursos Avançados
- 🔒 **Autenticação Completa** — Cadastro e login com sessões seguras (`Passport.js`, `bcryptjs` e `express-session`).
- 📋 **Quadro Kanban Interativo** — Arraste e visualize o fluxo de trabalho (A Fazer, Em Progresso, Concluído) com suporte completo a submetas.
- 🔄 **Tarefas Recorrentes** — Automatize tarefas cíclicas (diárias, semanais ou mensais).
- 🔔 **Notificações** — Alertas de prazos próximos para nunca esquecer um compromisso.
- 📤 **Exportação de Dados** — Exporte suas tarefas e relatórios em PDF ou CSV.
- 📱 **PWA & Offline First** — Aplicativo instalável no desktop e smartphone com suporte a cache offline e sincronização em segundo plano.

### 🏆 Gamificação
- ⭐ **Pontos e Níveis** — Ganhe XP ao cumprir suas metas diárias e suba de nível.
- 🎖️ **15+ Medalhas Desbloqueáveis** — Conquistas por consistência, conclusão em lote e hábitos produtivos.
- 🔥 **Sequências (Streaks)** — Mantenha o hábito diário de planejar e executar.

---

## 🎨 Design

Inspirado no calor e na simplicidade de cadernos físicos (**Warm Paper Notebook**):
- Paleta acolhedora: tons de pergaminho, linho, terracota e verde-musgo.
- Tipografia editorial refinada (*Playfair Display* e *Lora*).
- Texturas sutis e interface altamente responsiva para computadores, tablets e smartphones.

---

## 🛠️ Stack Tecnológico

### Frontend
- **Framework:** React 19 com TypeScript
- **Estilização:** Tailwind CSS 4 + componentes shadcn/ui (Radix UI)
- **Roteamento:** Wouter
- **Gerenciamento de Estado & Cache:** TanStack React Query com Persistência
- **Formulários & Validação:** React Hook Form + Zod
- **Gráficos:** Recharts
- **PWA:** Vite PWA + Workbox (Service Worker para suporte offline)

### Backend & API
- **Ambiente:** Node.js com Express
- **Autenticação:** Passport.js (Estratégia Local), bcryptjs e express-session
- **ORM:** Drizzle ORM + Drizzle Zod
- **Banco de Dados:** SQLite (com `@libsql/client` e `connect-sqlite3`)
- **Inteligência Artificial:** Google GenAI SDK (`@google/genai`)

---

## 📁 Estrutura do Projeto

O repositório adota uma arquitetura full-stack organizada e modular:

```text
task-notes-app/
├── client/                 # Frontend React (Vite + Tailwind + PWA)
│   ├── public/             # Manifest, ícones PWA e assets públicos
│   └── src/
│       ├── components/     # Componentes visuais (Kanban, Modais de IA, UI)
│       ├── contexts/       # Contextos React (Auth, Gamificação, Notificações)
│       ├── hooks/          # Custom hooks (useStore, useAuth, useGamification)
│       ├── lib/            # Utilitários (analytics, exportação, recorrência)
│       ├── pages/          # Telas (Dashboard, Tasks, Notes, Reports, Auth, etc.)
│       └── main.tsx        # Ponto de entrada do cliente e registro do Service Worker
├── server/                 # Backend Node.js / Express
│   ├── auth.ts             # Configurações de autenticação e sessão com Passport
│   ├── db.ts               # Inicialização da conexão com banco SQLite via Drizzle
│   ├── routes.ts           # Endpoints da API REST e integração com IA Gemini
│   └── index.ts            # Inicialização do servidor Express
├── shared/                 # Código e tipos compartilhados entre front e back
│   ├── const.ts            # Constantes da aplicação
│   └── schema.ts           # Schemas de dados Drizzle ORM e validações Zod
└── sqlite.db               # Base de dados SQLite local
```

---

## 💾 Persistência de Dados

Diferente de versões anteriores que dependiam puramente de `localStorage`:
- Todos os dados (usuários, tarefas, submetas, notas e categorias) são salvos de forma persistente e relacional no banco de dados **SQLite** através do **Drizzle ORM**.
- O frontend conta com cache resiliente via **TanStack Query Persist Client**, permitindo navegação fluida e capacidades offline enquanto sincroniza as requisições com o servidor.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- **Node.js** 18+ (recomendado Node.js 20 LTS ou superior)
- **pnpm** (recomendado `pnpm 10+`) ou npm/yarn
- Chave de API do **Google Gemini** ([Google AI Studio](https://aistudio.google.com/)) *(necessária apenas para recursos de IA)*

### Passo a Passo

1. **Clonar o Repositório:**
   ```bash
   git clone https://github.com/seu-usuario/task-notes-app.git
   cd task-notes-app
   ```

2. **Instalar Dependências:**
   ```bash
   pnpm install
   ```

3. **Configurar as Variáveis de Ambiente:**
   Copie o arquivo de exemplo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```
   Abra o arquivo `.env` e configure sua chave da API do Google Gemini:
   ```env
   GEMINI_API_KEY=sua_chave_aqui
   ```

4. **Executar a Aplicação Full Stack:**
   Para iniciar tanto o frontend quanto o backend em modo de desenvolvimento simultaneamente:
   ```bash
   pnpm fullstack
   ```

   - **Frontend:** `http://localhost:3000` (ou porta informada pelo Vite)
   - **Backend API:** `http://localhost:5000` (com proxy automático configurado no Vite)

---

## 📜 Comandos Disponíveis

| Comando | Descrição |
| :--- | :--- |
| `pnpm fullstack` | Inicia Frontend e Backend simultaneamente em modo desenvolvimento |
| `pnpm dev` | Inicia apenas o servidor de desenvolvimento do Vite (Frontend) |
| `pnpm dev:server` | Inicia apenas a API backend com monitoramento (`tsx --watch`) |
| `pnpm build` | Compila o Frontend (Vite) e empacota o Backend (esbuild) para a pasta `dist/` |
| `pnpm start` | Inicia o servidor consolidado de produção a partir de `dist/index.js` |
| `pnpm check` | Executa a verificação estática de tipos do TypeScript sem gerar build |
| `pnpm format` | Formata todo o código-fonte utilizando Prettier |

---

## 🎯 Roadmap & Evolução

- [x] Backend estruturado com Node.js e Express
- [x] Banco de dados persistente com SQLite e Drizzle ORM
- [x] Autenticação segura de usuários com sessões e senhas criptografadas
- [x] Progressive Web App (PWA) instalável e suporte offline
- [x] Decomposição de tarefas inteligente utilizando IA (Google Gemini)
- [x] Sistema de submetas com controle de progresso e regras de integridade
- [ ] Aplicativo mobile nativo para iOS/Android (suporte Capacitor em desenvolvimento)
- [ ] Compartilhamento colaborativo de listas e tarefas
- [ ] Integração com calendários externos (Google Calendar, iCal)
- [ ] Suporte a temas adicionais e personalização da textura de capa

---

## 📚 Documentação Complementar

Para guias de tópicos específicos:
- [PROJECT_DOCUMENTATION.md](./PROJECT_DOCUMENTATION.md) — Documentação técnica detalhada da arquitetura.
- [SETUP_LOCAL.md](./SETUP_LOCAL.md) — Guia aprofundado de configuração de ambiente.
- [GAMIFICATION.md](./GAMIFICATION.md) — Regras de pontuação, medalhas e níveis.
- [REPORTS.md](./REPORTS.md) — Métricas e gráficos de produtividade.
- [NOTIFICATIONS.md](./NOTIFICATIONS.md) — Sistema de lembretes e alertas.
- [RECURRENCE.md](./RECURRENCE.md) — Lógica de agendamento de tarefas recorrentes.

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas!
1. Faça um Fork do projeto.
2. Crie uma branch para sua funcionalidade (`git checkout -b feature/MinhaFuncionalidade`).
3. Commit suas alterações (`git commit -m 'feat: Adiciona MinhaFuncionalidade'`).
4. Envie para o GitHub (`git push origin feature/MinhaFuncionalidade`).
5. Abra um Pull Request.

---

## 📝 Licença

Distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](./LICENSE) para mais detalhes.
