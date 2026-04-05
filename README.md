# 📓 Meu Caderno - Task & Notes Management App

Um aplicativo moderno e elegante para gerenciar tarefas e anotações com design inspirado em cadernos analógicos. Inclui gamificação, notificações, relatórios e muito mais!

## ✨ Funcionalidades

### Core Features
- ✅ **Gerenciamento de Tarefas** - Criar, editar, deletar e organizar tarefas
- 📝 **Anotações** - Escrever e organizar notas livremente
- 🏷️ **Categorias** - Organizar tarefas e anotações por categoria
- 📊 **Dashboard** - Visão geral de todas as atividades

### Advanced Features
- 🔔 **Notificações** - Alertas automáticos para tarefas com prazo próximo
- 📋 **Kanban Board** - Visualização tipo quadro com drag-and-drop
- 📤 **Exportação** - Exportar tarefas em PDF ou CSV
- 🔄 **Tarefas Recorrentes** - Criar tarefas que se repetem (diária, semanal, mensal)

### Analytics
- 📈 **Relatórios** - Gráficos de produtividade e análises detalhadas
- 📊 **Estatísticas** - Acompanhe seu progresso ao longo do tempo
- 🎯 **Análise por Categoria** - Veja o desempenho de cada categoria

### Gamification
- ⭐ **Pontos** - Ganhe pontos completando tarefas
- 🏆 **Medalhas** - Desbloqueie 15+ medalhas diferentes
- 📈 **Níveis** - Suba de nível conforme acumula pontos
- 🔥 **Sequências** - Mantenha uma sequência de dias com atividade

## 🎨 Design

Utiliza a estética **Warm Paper Notebook** com:
- Cores quentes e acolhedoras (pergaminho, terracota, verde-musgo)
- Tipografia elegante (Playfair Display + Lora)
- Sidebar com textura de couro
- Interface responsiva para mobile e desktop

## 🚀 Quick Start

### Requisitos
- Node.js 18+ (recomendado v20 LTS)
- pnpm 10.4.1+ (ou npm/yarn)
- Git

### Instalação

```bash
# 1. Clonar o repositório
git clone https://github.com/seu-usuario/task-notes-app.git
cd task-notes-app

# 2. Instalar dependências
pnpm install

# 3. Rodar em desenvolvimento
pnpm dev
```

A aplicação abrirá em `http://localhost:5173`

### Comandos

```bash
pnpm dev       # Inicia servidor de desenvolvimento
pnpm build     # Compila para produção
pnpm preview   # Visualiza build de produção
pnpm check     # Verifica erros de TypeScript
pnpm format    # Formata código
```

## 📁 Estrutura do Projeto

```
client/src/
├── pages/              # Páginas da aplicação
│   ├── Dashboard.tsx
│   ├── Tasks.tsx
│   ├── Notes.tsx
│   ├── Categories.tsx
│   ├── Reports.tsx
│   └── Achievements.tsx
├── components/         # Componentes reutilizáveis
├── contexts/          # Contextos React
├── hooks/             # Hooks customizados
├── lib/               # Utilitários
└── index.css          # Estilos globais
```

## 💾 Dados

Todos os dados são armazenados no **localStorage** do navegador:
- Tarefas
- Anotações
- Categorias
- Pontos e medalhas
- Sequências

Nenhum servidor externo necessário! Os dados persistem entre sessões.

## 🛠️ Stack Tecnológico

- **Frontend**: React 19 + TypeScript
- **Styling**: Tailwind CSS 4 + shadcn/ui
- **Routing**: Wouter
- **Forms**: React Hook Form
- **Charts**: Recharts
- **Build**: Vite
- **Package Manager**: pnpm

## 📚 Documentação

- [SETUP_LOCAL.md](./SETUP_LOCAL.md) - Guia detalhado de instalação
- [GAMIFICATION.md](./GAMIFICATION.md) - Sistema de gamificação
- [RECURRENCE.md](./RECURRENCE.md) - Tarefas recorrentes
- [REPORTS.md](./REPORTS.md) - Relatórios e análises
- [NOTIFICATIONS.md](./NOTIFICATIONS.md) - Sistema de notificações

## 🎯 Roadmap

- [ ] Backend com autenticação
- [ ] Sincronização em nuvem
- [ ] Compartilhamento de tarefas
- [ ] Aplicativo mobile
- [ ] Integração com calendário
- [ ] Sugestões com IA
- [ ] Modo escuro

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](./LICENSE) para detalhes.

## 🙋 Suporte

Se tiver dúvidas ou encontrar problemas:

1. Verifique a documentação em `SETUP_LOCAL.md`
2. Abra uma issue no GitHub
3. Consulte a seção de Troubleshooting

## 🎓 Aprendizado

Este projeto foi desenvolvido como um exemplo de:
- Aplicação React moderna com TypeScript
- Gerenciamento de estado com Context API
- Persistência de dados com localStorage
- Design responsivo com Tailwind CSS
- Componentes reutilizáveis com shadcn/ui
- Gamificação e engajamento do usuário

---

Desenvolvido com ❤️ usando React, Tailwind CSS e muito café ☕
