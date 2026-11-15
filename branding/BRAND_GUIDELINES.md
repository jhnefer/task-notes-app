# Meu Caderno — Guia Rápido da Marca (Gato Marcador)

## 1. Conceito
**Gato Marcador** combina a silhueta de um marcador de página de caderno com um gatinho minimalista, usando uma paleta inspirada na personagem de referência e alinhada à estética *Warm Paper Notebook*.

## 2. Paleta de Cores
| Papel | Nome | HEX | RGB |
|---|---|---|---|
| Primária (Tinta / Cabelo) | Verde-Floresta | `#1B3B36` | `27, 59, 54` |
| Secundária (Faixa / Traje) | Verde-Sálvia | `#589A67` | `88, 154, 103` |
| Destaque (Íris / Olhos) | Azul-Índigo | `#3B4990` | `59, 73, 144` |
| Fundo / Papel (Esclera / Tile) | Papel Marfim | `#F3EFE6` | `243, 239, 230` |

## 3. Arquivos Mestres e Variantes
- `final-symbol.svg` — Símbolo principal colorido (`256×256`).
- `final-symbol-small.svg` — Corte óptico simplificado para **16–24 px** (favicon e ícones pequenos).
- `final-horizontal.svg` / `final-stacked.svg` — Lockups horizontal e vertical *(nota: o wordmark usa `<text>` em `DejaVu Serif` / `Georgia`; converta para curvas em editor vetorial se for enviar para gráfica)*.
- `exports/symbol/` — Versões `black`, `white`, `mono-1b3b36`, `square`, `app-icon`, `favicon.ico`, `favicon.svg`, PNGs (`16`, `32`, `48`, `180`, `192`, `512`, `maskable-512`), `site.webmanifest` e `head-snippet.html`.
- `exports/horizontal/` — Lockup horizontal em `black`, `white` e `mono-1b3b36` (SVG + PNG 1200 px).

## 4. Espaço Livre e Tamanho Mínimo
- **Área de respiro:** Mantenha ao menos **0,25×** da largura do símbolo livre ao redor da marca.
- **Tamanho mínimo:** **16 px** (usar `final-symbol-small.svg` / `favicon-16.png`) para o símbolo; **120 px** de largura para o lockup horizontal.

## 5. Uso Correto e O que Evitar
- **Usar:** Fundo Papel Marfim (`#F3EFE6`), branco ou verde-floresta escuro (`#1B3B36` com a versão `final-symbol-white.svg`).
- **Evitar:** Distorcer proporções, adicionar sombras/gradientes ou colocar o símbolo colorido diretamente sobre fundos verdes ou escuros sem contraste.
