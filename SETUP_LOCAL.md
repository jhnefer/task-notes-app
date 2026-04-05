# Guia de Setup Local - Meu Caderno (Task Notes App)

Este documento descreve todos os requisitos e passos necessários para rodar o projeto **task-notes-app** na sua máquina local.

## Requisitos do Sistema

### Requisitos Obrigatórios

**Sistema Operacional**
- Windows 10+ (com WSL2 recomendado)
- macOS 11+
- Linux (Ubuntu 18+, Fedora 30+, ou similar)

**Node.js e npm/pnpm**
- Node.js: **v18.0.0 ou superior** (recomendado v20 LTS ou v22)
- npm: **v9.0.0 ou superior** (incluído com Node.js)
- pnpm: **v10.4.1 ou superior** (gerenciador de pacotes recomendado)

**Git**
- Git: **v2.0 ou superior** (para clonar o repositório)

### Requisitos Recomendados

**Editor de Código**
- Visual Studio Code (recomendado)
- WebStorm
- Sublime Text
- Ou qualquer editor de sua preferência

**Extensões VSCode Recomendadas**
- ES7+ React/Redux/React-Native snippets
- Prettier - Code formatter
- Tailwind CSS IntelliSense
- TypeScript Vue Plugin
- ESLint

**Navegador Web**
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## Instalação de Dependências

### 1. Instalar Node.js

**Windows:**
1. Acesse [nodejs.org](https://nodejs.org)
2. Baixe a versão LTS (Long Term Support)
3. Execute o instalador e siga as instruções
4. Verifique a instalação:
   ```bash
   node --version
   npm --version
   ```

**macOS (com Homebrew):**
```bash
brew install node
node --version
npm --version
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
```

### 2. Instalar pnpm (Recomendado)

pnpm é mais rápido e eficiente que npm. Instale globalmente:

```bash
npm install -g pnpm
pnpm --version
```

Ou use cURL:

```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

### 3. Instalar Git

**Windows:**
- Baixe em [git-scm.com](https://git-scm.com)
- Execute o instalador

**macOS:**
```bash
brew install git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install git
```

Verifique a instalação:
```bash
git --version
```

## Clonar e Configurar o Projeto

### 1. Clonar o Repositório

```bash
git clone <URL-DO-REPOSITORIO> task-notes-app
cd task-notes-app
```

Ou, se você tiver o arquivo compactado:

```bash
unzip task-notes-app.zip
cd task-notes-app
```

### 2. Instalar Dependências

Com pnpm (recomendado):
```bash
pnpm install
```

Ou com npm:
```bash
npm install
```

**Nota:** A primeira instalação pode levar alguns minutos.

### 3. Verificar Instalação

```bash
pnpm check
```

Isso verifica se não há erros de TypeScript.

## Executar o Projeto

### Modo Desenvolvimento

```bash
pnpm dev
```

Isso iniciará:
- **Servidor Vite**: http://localhost:5173
- **Servidor Express**: http://localhost:3000

O navegador deve abrir automaticamente. Se não, acesse `http://localhost:5173`.

**Características do modo desenvolvimento:**
- Hot Module Replacement (HMR) - atualizações em tempo real
- Source maps para debugging
- Mensagens de erro detalhadas

### Modo Preview (Produção Local)

```bash
pnpm build
pnpm preview
```

Isso compila o projeto e exibe uma visualização de produção.

### Parar o Servidor

Pressione `Ctrl+C` no terminal.

## Estrutura do Projeto

```
task-notes-app/
├── client/                    # Frontend React
│   ├── public/               # Arquivos estáticos
│   ├── src/
│   │   ├── pages/           # Páginas da aplicação
│   │   ├── components/      # Componentes reutilizáveis
│   │   ├── contexts/        # Contextos React
│   │   ├── hooks/           # Hooks customizados
│   │   ├── lib/             # Utilitários
│   │   ├── App.tsx          # Componente raiz
│   │   ├── main.tsx         # Entrada da aplicação
│   │   └── index.css        # Estilos globais
│   ├── index.html           # HTML principal
│   └── tsconfig.json        # Configuração TypeScript
├── server/                   # Backend Express
│   └── index.ts             # Servidor Express
├── package.json             # Dependências do projeto
├── vite.config.ts           # Configuração Vite
├── tailwind.config.ts       # Configuração Tailwind CSS
└── tsconfig.json            # Configuração TypeScript global
```

## Dados e Armazenamento

### localStorage

Todos os dados (tarefas, anotações, categorias, pontos, medalhas) são armazenados no **localStorage** do navegador.

**Localização:**
- Chrome/Edge: DevTools → Application → Local Storage
- Firefox: DevTools → Storage → Local Storage
- Safari: Develop → Show Web Inspector → Storage → Local Storage

**Chaves armazenadas:**
- `task-notes-app-tasks`: Tarefas
- `task-notes-app-notes`: Anotações
- `task-notes-app-categories`: Categorias
- `task-notes-app-notifications`: Notificações
- `task-notes-app-gamification`: Pontos, medalhas, níveis

### Exportar Dados

Use a funcionalidade de exportação na aplicação:
1. Vá para **Tarefas** ou **Anotações**
2. Clique no botão de exportação (⋯)
3. Escolha **CSV** ou **PDF**

### Limpar Dados

Para resetar todos os dados:

**Via DevTools:**
1. Abra DevTools (F12)
2. Console → Execute:
   ```javascript
   localStorage.clear()
   location.reload()
   ```

**Via Aplicação:**
- Clique no botão "Resetar Dados" no Dashboard (se disponível)

## Troubleshooting

### Problema: "pnpm: command not found"

**Solução:**
```bash
npm install -g pnpm
```

### Problema: "Port 5173 already in use"

**Solução:**
```bash
# Use uma porta diferente
pnpm dev -- --port 3001
```

### Problema: Erros de TypeScript

**Solução:**
```bash
pnpm check
```

Se houver erros, verifique se você tem a versão correta do Node.js:
```bash
node --version  # Deve ser v18+
```

### Problema: Dependências não instaladas corretamente

**Solução:**
```bash
# Limpe o cache e reinstale
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### Problema: Mudanças não aparecem em tempo real

**Solução:**
1. Verifique se o servidor está rodando (`pnpm dev`)
2. Recarregue a página (Ctrl+R ou Cmd+R)
3. Limpe o cache do navegador (Ctrl+Shift+Delete)

### Problema: localStorage cheio

**Solução:**
Se receber erro de quota excedida:
```javascript
// No console do navegador
localStorage.clear()
```

## Variáveis de Ambiente

O projeto não requer variáveis de ambiente para modo desenvolvimento. Todos os dados são armazenados localmente.

Para produção, você pode criar um arquivo `.env`:

```env
VITE_APP_TITLE=Meu Caderno
VITE_APP_ID=task-notes-app
NODE_ENV=production
```

## Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `pnpm dev` | Inicia servidor de desenvolvimento |
| `pnpm build` | Compila para produção |
| `pnpm preview` | Visualiza build de produção |
| `pnpm check` | Verifica erros de TypeScript |
| `pnpm format` | Formata código com Prettier |

## Próximos Passos

1. **Explorar a Aplicação**
   - Crie algumas tarefas
   - Adicione anotações
   - Crie categorias
   - Experimente o Kanban

2. **Entender o Código**
   - Leia os comentários nos arquivos
   - Explore a estrutura de componentes
   - Verifique os hooks customizados

3. **Customizar**
   - Modifique cores em `client/src/index.css`
   - Adicione novas funcionalidades
   - Altere o design conforme necessário

4. **Fazer Deploy**
   - Veja as opções de deploy no Manus
   - Ou faça deploy em Vercel, Netlify, Railway, etc.

## Recursos Úteis

**Documentação**
- [React 19](https://react.dev)
- [Vite](https://vitejs.dev)
- [Tailwind CSS](https://tailwindcss.com)
- [TypeScript](https://www.typescriptlang.org)
- [Recharts](https://recharts.org)

**Tutoriais**
- [React Hooks](https://react.dev/reference/react)
- [Context API](https://react.dev/reference/react/useContext)
- [localStorage API](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)

**Ferramentas**
- [VS Code](https://code.visualstudio.com)
- [DevTools Chrome](https://developer.chrome.com/docs/devtools/)
- [React DevTools](https://react-devtools-tutorial.vercel.app)

## Suporte

Se encontrar problemas:

1. Verifique se todas as dependências estão instaladas: `pnpm install`
2. Verifique a versão do Node.js: `node --version`
3. Limpe o cache: `rm -rf node_modules pnpm-lock.yaml && pnpm install`
4. Recarregue o navegador: `Ctrl+Shift+R` (hard refresh)
5. Abra uma issue no repositório com detalhes do erro

## Licença

MIT - Veja LICENSE.txt para detalhes.
