# 🚀 Guia: Criar Repositório no GitHub e Clonar Localmente

Este guia mostra como criar um repositório no GitHub e clonar o projeto para sua máquina.

## Passo 1: Criar Repositório no GitHub

### 1.1 Acessar GitHub

1. Acesse [github.com](https://github.com) e faça login
2. Clique no ícone `+` no canto superior direito
3. Selecione **"New repository"**

### 1.2 Configurar o Repositório

Preencha os campos:

| Campo | Valor |
|-------|-------|
| **Repository name** | `task-notes-app` |
| **Description** | `Aplicativo moderno de gerenciamento de tarefas e anotações com gamificação` |
| **Visibility** | Public (ou Private, conforme preferir) |
| **Initialize this repository with** | Deixe em branco (não marque nada) |

### 1.3 Criar Repositório

Clique em **"Create repository"**

Você será redirecionado para uma página com instruções. Copie a URL do repositório (algo como `https://github.com/seu-usuario/task-notes-app.git`)

## Passo 2: Preparar Projeto Localmente

O projeto já possui `.gitignore`, `README.md` e `LICENSE`, então está pronto para ser enviado!

## Passo 3: Inicializar Git e Fazer Push

### 3.1 Abrir Terminal

Abra o terminal/PowerShell e navegue até a pasta do projeto:

```bash
cd /caminho/para/task-notes-app
```

### 3.2 Inicializar Git (se ainda não estiver)

```bash
git init
git add .
git commit -m "Initial commit: Task Notes App with gamification, notifications, and analytics"
```

### 3.3 Adicionar Remote e Fazer Push

Substitua `seu-usuario` pela sua conta GitHub:

```bash
git remote add origin https://github.com/seu-usuario/task-notes-app.git
git branch -M main
git push -u origin main
```

**Nota:** Você pode ser solicitado a autenticar. Use:
- **Usuário**: seu username do GitHub
- **Senha**: seu Personal Access Token (veja seção abaixo)

### 3.4 Gerar Personal Access Token (se necessário)

Se receber erro de autenticação:

1. Acesse [github.com/settings/tokens](https://github.com/settings/tokens)
2. Clique em **"Generate new token"** → **"Generate new token (classic)"**
3. Preencha:
   - **Note**: `Local Development`
   - **Expiration**: 90 days (ou conforme preferir)
   - **Scopes**: Marque `repo` (full control of private repositories)
4. Clique em **"Generate token"**
5. **Copie o token** (você não poderá vê-lo novamente!)
6. Use o token como senha ao fazer push

## Passo 4: Clonar para Sua Máquina

### 4.1 Escolher Local

Escolha uma pasta onde deseja clonar o projeto:

```bash
cd ~/Documentos  # ou qualquer outra pasta
```

### 4.2 Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/task-notes-app.git
cd task-notes-app
```

### 4.3 Instalar Dependências

```bash
pnpm install
```

### 4.4 Rodar o Projeto

```bash
pnpm dev
```

A aplicação abrirá em `http://localhost:5173`

## Passo 5: Fazer Commits Locais

Agora você pode fazer alterações e fazer commits:

```bash
# Ver status
git status

# Adicionar mudanças
git add .

# Fazer commit
git commit -m "Descrição clara da mudança"

# Enviar para GitHub
git push
```

## Comandos Git Úteis

| Comando | Descrição |
|---------|-----------|
| `git status` | Ver status do repositório |
| `git add .` | Adicionar todas as mudanças |
| `git commit -m "mensagem"` | Fazer commit com mensagem |
| `git push` | Enviar commits para GitHub |
| `git pull` | Baixar commits do GitHub |
| `git log` | Ver histórico de commits |
| `git branch` | Ver branches |
| `git checkout -b feature/nome` | Criar nova branch |

## Troubleshooting

### Erro: "fatal: not a git repository"

**Solução:**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/seu-usuario/task-notes-app.git
git push -u origin main
```

### Erro: "Permission denied (publickey)"

**Solução:**
1. Configure SSH (recomendado):
   ```bash
   ssh-keygen -t ed25519 -C "seu-email@example.com"
   ```
2. Adicione a chave pública no GitHub: [github.com/settings/keys](https://github.com/settings/keys)
3. Use URL SSH ao clonar: `git clone git@github.com:seu-usuario/task-notes-app.git`

### Erro: "remote origin already exists"

**Solução:**
```bash
git remote remove origin
git remote add origin https://github.com/seu-usuario/task-notes-app.git
```

### Erro: "Your branch is ahead of 'origin/main'"

**Solução:**
```bash
git push
```

## Próximos Passos

1. **Adicionar Colaboradores** (opcional)
   - Vá para Settings → Collaborators
   - Clique em "Add people"
   - Convide outros usuários

2. **Configurar Branch Protection** (opcional)
   - Vá para Settings → Branches
   - Clique em "Add rule"
   - Configure proteção para a branch `main`

3. **Configurar GitHub Actions** (opcional)
   - Crie workflows para CI/CD
   - Execute testes automaticamente
   - Faça deploy automático

4. **Criar Issues e Pull Requests**
   - Use Issues para rastrear bugs e features
   - Use Pull Requests para revisar código

## Recursos Úteis

- [GitHub Docs](https://docs.github.com)
- [Git Cheat Sheet](https://github.github.com/training-kit/downloads/github-git-cheat-sheet.pdf)
- [Pro Git Book](https://git-scm.com/book/en/v2)
- [GitHub CLI](https://cli.github.com) - Alternativa ao Git via linha de comando

## Dicas

1. **Commits frequentes**: Faça commits pequenos e frequentes com mensagens claras
2. **Branches para features**: Use branches separadas para cada feature
3. **Pull Requests**: Use PRs para revisar código antes de fazer merge
4. **Documentação**: Mantenha README.md e documentação atualizados
5. **Gitignore**: Verifique se `.gitignore` está funcionando corretamente

---

Pronto! Seu projeto está no GitHub e você pode cloná-lo em qualquer lugar! 🎉
