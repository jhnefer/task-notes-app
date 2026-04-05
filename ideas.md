# Ideias de Design — Minhas Tarefas & Anotações

## Abordagem 1 — Editorial Minimalista

<response>
<text>
**Design Movement:** Swiss International Typographic Style (Estilo Tipográfico Internacional)

**Core Principles:**
- Hierarquia tipográfica rigorosa como principal elemento de organização
- Grade assimétrica com alinhamento à esquerda dominante
- Contraste extremo entre peso tipográfico e espaço em branco
- Funcionalidade como estética — cada elemento tem propósito claro

**Color Philosophy:**
- Fundo creme off-white (#F7F4EF) para reduzir fadiga visual
- Texto principal em grafite escuro (#1C1C1E)
- Acento único em âmbar queimado (#D97706) para CTAs e marcadores de prioridade
- Separadores em cinza muito claro para estrutura sem peso visual

**Layout Paradigm:**
- Sidebar estreita à esquerda (64px colapsada, 240px expandida) com ícones e rótulos
- Área de conteúdo principal dividida em dois painéis: lista (40%) + detalhe (60%)
- Cabeçalho fixo ultra-fino com breadcrumb e ações contextuais

**Signature Elements:**
- Linha vertical colorida à esquerda de cada card de tarefa indicando prioridade
- Tipografia display em peso 800 para títulos de seção
- Checkboxes customizados com animação de risco ao completar

**Interaction Philosophy:**
- Edição inline direta — clicar no texto o torna editável imediatamente
- Transições de slide horizontal entre seções
- Feedback tátil sutil em cada ação (micro-animações de 150ms)

**Animation:**
- Entrada de itens com fade + translateY(8px) em 200ms
- Checkbox completion: linha riscando o texto em 300ms
- Sidebar collapse/expand com ease-out em 250ms

**Typography System:**
- Display: DM Serif Display (títulos principais)
- Interface: DM Sans (corpo, labels, metadados)
- Mono: JetBrains Mono (datas, IDs, contadores)
</text>
<probability>0.07</probability>
</response>

---

## Abordagem 2 — Productivity Dark Studio

<response>
<text>
**Design Movement:** Dark Mode Productivity / Developer Aesthetic

**Core Principles:**
- Interface escura que reduz distrações e foca no conteúdo
- Hierarquia visual através de luminosidade, não cor
- Densidade de informação alta com espaçamento generoso entre grupos
- Sensação de "painel de controle" profissional

**Color Philosophy:**
- Background em slate profundo (#0F1117)
- Surface cards em #1A1D27
- Texto primário em #E8EAF0 (quase branco, não puro)
- Acento em verde-esmeralda (#10B981) para status "concluído"
- Acento em âmbar (#F59E0B) para prioridade alta
- Acento em violeta (#8B5CF6) para anotações

**Layout Paradigm:**
- Sidebar à esquerda com 3 níveis: ícones, categorias, subcategorias
- Área principal com visualização em kanban ou lista (alternável)
- Painel de detalhes deslizante da direita (drawer)

**Signature Elements:**
- Tags coloridas com fundo semi-transparente (backdrop-blur)
- Barra de progresso linear fina abaixo de cada projeto
- Indicadores de status como pontos pulsantes animados

**Interaction Philosophy:**
- Drag-and-drop entre colunas do kanban
- Atalhos de teclado visíveis ao passar o mouse
- Modo foco que esconde a sidebar e maximiza o editor

**Animation:**
- Cards aparecem com stagger de 50ms entre itens
- Transição de kanban para lista com flip 3D suave
- Hover em cards: elevação com sombra colorida

**Typography System:**
- Display: Space Grotesk (títulos, cabeçalhos)
- Interface: Inter (corpo — justificado aqui pela densidade)
- Mono: Fira Code (datas, contadores, atalhos)
</text>
<probability>0.08</probability>
</response>

---

## Abordagem 3 — Warm Paper Notebook

<response>
<text>
**Design Movement:** Analog-Digital Hybrid / Paper Craft

**Core Principles:**
- Metáfora de caderno físico digitalizado com textura e imperfeição intencional
- Calor visual através de tons terrosos e tipografia humanista
- Organização por abas e seções como um caderno real
- Contraste entre estrutura (tarefas) e liberdade (anotações)

**Color Philosophy:**
- Fundo em pergaminho quente (#FDF6E3)
- Superfícies em papel levemente amarelado (#FAF0D7)
- Texto em tinta escura (#2D2416)
- Acento principal em terracota (#C0533A) para prioridades
- Acento secundário em verde-musgo (#4A7C59) para concluído
- Bordas em sépia (#C4A882)

**Layout Paradigm:**
- Layout de "caderno aberto" com duas colunas principais
- Abas laterais coloridas para categorias (como divisórias de caderno)
- Área de anotações com linhas sutis de fundo (ruled paper effect)

**Signature Elements:**
- Textura de papel sutil no fundo (noise CSS ou SVG filter)
- Checkboxes estilo caixa desenhada à mão
- Títulos com sublinhado estilo caneta (border-bottom com cor de tinta)

**Interaction Philosophy:**
- Adicionar tarefa simula "escrever" com cursor piscando
- Completar tarefa: animação de tachado à mão
- Categorias como abas coloridas que "viram" ao clicar

**Animation:**
- Entrada de novas tarefas: aparecem como se estivessem sendo escritas
- Transição entre seções: flip de página suave
- Hover em cards: leve rotação de 1-2 graus (efeito papel)

**Typography System:**
- Display: Playfair Display (títulos de seção, cabeçalhos)
- Interface: Lora (corpo de texto, anotações — serifa humanista)
- Handwriting accent: Caveat (labels informais, datas)
</text>
<probability>0.09</probability>
</response>
