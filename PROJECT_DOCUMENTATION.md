# Documentação do Projeto: Meu Caderno (Task & Notes App)

## 1. Visão Geral
O projeto **Meu Caderno** é uma aplicação web completa (Full-stack) projetada para o gerenciamento de tarefas e anotações, possuindo um design focado na estética "Warm Paper Notebook" (caderno analógico, cores acolhedoras). A aplicação vai além do básico, incorporando recursos avançados como gamificação, quadro Kanban, relatórios de produtividade, sistema de tarefas recorrentes, suporte Offline/PWA, e autenticação de usuários.

Apesar de a documentação original (`README.md`) citar que os dados são armazenados localmente no navegador, o projeto evoluiu para incluir um backend estruturado em Node.js com banco de dados SQLite, o que permite persistência real e sistema de contas.

## 2. Stack Tecnológica

### Frontend
- **Framework:** React 19 com TypeScript
- **Build Tool:** Vite
- **Estilização:** Tailwind CSS 4, componentes baseados em Radix UI e shadcn/ui
- **Roteamento:** Wouter
- **Gerenciamento de Estado/Cache:** TanStack React Query (com persistência via Sync Storage)
- **Formulários e Validação:** React Hook Form + Zod
- **Gráficos:** Recharts
- **PWA (Progressive Web App):** vite-plugin-pwa (suporte a Service Workers e cache offline)

### Backend
- **Servidor:** Node.js com Express
- **Autenticação:** Passport.js (Estratégia Local com armazenamento de sessões via `express-session` e `connect-sqlite3`)
- **Criptografia de Senhas:** bcryptjs
- **ORM:** Drizzle ORM
- **Banco de Dados:** SQLite (usando `@libsql/client`)

## 3. Estrutura do Projeto

A arquitetura do projeto segue o padrão monorepo simplificado, separando responsabilidades entre o cliente (frontend), o servidor (backend) e códigos compartilhados.

```text
task-notes-app/
├── client/                 # Aplicação Frontend (React + Vite)
│   ├── public/             # Assets estáticos (ícones PWA, manifest)
│   └── src/
│       ├── components/     # Componentes de UI e blocos de construção (ex: ui/, KanbanBoard, Charts)
│       ├── contexts/       # Provedores de contexto React (App, Gamification, Notification, Theme)
│       ├── hooks/          # Custom hooks (useAuth, useMobile, useGamification)
│       ├── lib/            # Utilitários globais (exportação de dados, analytics, recorrência)
│       ├── pages/          # Telas da aplicação (Dashboard, Notes, Tasks, Auth, etc.)
│       └── main.tsx        # Ponto de entrada do Frontend (onde ocorre o registro do PWA)
├── server/                 # Aplicação Backend (Express + Drizzle)
│   ├── auth.ts             # Configuração do Passport.js e sessão
│   ├── db.ts               # Conexão com o SQLite via Drizzle ORM
│   ├── index.ts            # Ponto de entrada do Backend e middlewares de rotas
│   └── routes.ts           # Definição dos endpoints da API REST
├── shared/                 # Código compartilhado entre Client e Server
│   ├── const.ts            # Constantes globais
│   └── schema.ts           # Definição dos schemas do Drizzle e Zod para validação
```

## 4. Funcionalidades Principais

1. **Gestão de Tarefas e Kanban:** Criação, edição, exclusão e visualização de tarefas em formato de lista ou Kanban. Suporte a tarefas recorrentes (diárias, semanais, mensais).
2. **Anotações (Notes):** Sistema de anotações livre integrado na mesma plataforma.
3. **Autenticação de Usuários:** Sistema de login/registro (Estratégia Local).
4. **Gamificação:** Sistema de níveis, experiência (XP), medalhas (achievements) e sequências (streaks) para incentivar a produtividade.
5. **Relatórios (Analytics):** Dashboard contendo gráficos sobre produtividade, divisão por categorias e progresso geral.
6. **Notificações:** Alertas sobre prazos de tarefas e sistema de badges.
7. **PWA e Modo Offline:** O aplicativo pode ser instalado no celular/desktop e utilizado offline graças às estratégias de cache de recursos estáticos e chamadas de API do Workbox configuradas no Vite.

## 5. Scripts e Configuração de Desenvolvimento

O arquivo `package.json` define os seguintes fluxos de trabalho usando `pnpm`:

- `pnpm run dev`: Inicia apenas o frontend usando o Vite na porta 3000.
- `pnpm run dev:server`: Inicia o backend em modo de observação usando `tsx`.
- `pnpm run fullstack`: Executa o frontend e o backend simultaneamente usando `concurrently`.
- `pnpm run build`: Compila o frontend (Vite) e o backend (esbuild) para a pasta `dist`.
- `pnpm run start`: Roda a versão de produção usando o Node.js (`node dist/index.js`).

## 6. Observações e Pontos de Atenção

- **Discrepância com o README.md:** O arquivo `README.md` menciona que a aplicação não possui backend e utiliza apenas `localStorage`. No entanto, a análise profunda revelou que o projeto possui um backend Express e SQLite para persistir informações (provavelmente a implementação do backend descrita no Roadmap foi concluída, mas o README não foi atualizado).
- **Tipagens do PWA:** Foi identificada uma ausência da tipagem do módulo virtual do PWA (`virtual:pwa-register`), que foi devidamente corrigida no `tsconfig.json` durante a análise atual, permitindo a correta verificação estática do Typescript.
- **Portas:** O Frontend geralmente roda na porta `3000` ou `5173` (dependendo de como o Vite mapeia), enquanto o Backend (API) roda internamente na porta `5000` em ambiente de desenvolvimento. O Vite gerencia um proxy de `/api` para `http://localhost:5000`.

---
*Documentação gerada automaticamente baseada na análise da base de código em abril de 2026.*
