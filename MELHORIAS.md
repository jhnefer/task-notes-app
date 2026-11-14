# Relatório de melhorias: app de notas e tarefas com IA

Preparado em 12/11/2026 para Jhenefer Amorim, com base na conversa sobre o projeto (ainda em localhost) e a preparação para a trilha AI Builder do iFood.

## 1. Contexto e objetivo

O app transforma notas e transcrições de reunião em tarefas. A API do Gemini já é usada para decompor tarefas grandes em subtarefas. Problema observado: quando a nota diz “até o dia 10”, a IA resume, mas o **prazo** e a **prioridade** não chegam aos campos do app.

Objetivo deste relatório: listar as melhorias que resolvem esse problema e, ao mesmo tempo, geram evidências concretas para o portfólio e para as entrevistas (medição, validação e decisões justificadas).

**Nota:** este relatório parte do que foi descrito na conversa. O código do repositório não pôde ser lido, então ajuste os itens ao que já existe.

## 2. Resumo das prioridades

| # | Melhoria | Esforço | Impacto |
| --- | --- | --- | --- |
| 1 | Saída estruturada (JSON com campos do app) | Baixo | Muito alto |
| 2 | Data de hoje e regras de datas no prompt | Baixo | Muito alto |
| 3 | Regras de prioridade e de “não inventar” (null) | Baixo | Alto |
| 4 | Validação do JSON antes de gravar | Médio | Alto |
| 5 | Confirmação da pessoa antes de salvar | Médio | Alto |
| 6 | Conjunto de testes e medição da qualidade | Médio | Muito alto (portfólio) |
| 7 | Métrica de produto (taxa de aceitação) | Baixo | Alto (portfólio) |
| 8 | Falhas, custo e segurança da chave | Médio | Médio, essencial antes de publicar |
| 9 | Versão mobile (PWA) | Médio | Médio, pode esperar |

Ordem sugerida: 1, 2, 3 resolvem o problema atual. 4 e 5 tornam a solução confiável. 6 e 7 provam que funciona. 8 e 9 vêm quando o app sair do localhost.

## 3. Melhorias detalhadas

### 3.1 Saída estruturada

**Problema:** o modelo devolve texto livre. Prazo e prioridade ficam escondidos no texto e o app não tem como lê-los.

**Solução:** peça uma resposta em JSON com os mesmos campos do app e use o modo de saída estruturada do Gemini (confira na documentação atual da API o nome exato dos parâmetros, pois mudam entre versões). Exemplo de formato:

```json
{
  "titulo": "string",
  "resumo": "string",
  "prazo": "AAAA-MM-DD ou null",
  "prioridade": "alta | media | baixa | null",
  "subtarefas": [
    { "titulo": "string", "prazo": "AAAA-MM-DD ou null" }
  ],
  "observacoes_incertas": ["string"]
}
```

O código então lê `prazo` e `prioridade` e preenche os campos do app.

### 3.2 Datas: o modelo precisa saber que dia é hoje

**Problema:** sem a data atual, expressões como “dia 10”, “sexta” ou “semana que vem” não viram datas.

**Solução:** envie sempre no prompt algo como: “Hoje é 12/11/2026 (quinta-feira). Fuso: America/Fortaleza.” Gere esse texto no código, nunca fixo. Regras a incluir:

- “Dia 10” sem mês: usar o próximo dia 10 que ainda não passou.
- Dias da semana e “amanhã”: calcular a partir de hoje.
- Sempre responder em AAAA-MM-DD.
- Se houver duas datas na nota, associar cada uma à tarefa certa e registrar a dúvida em `observacoes_incertas`.

### 3.3 Prioridade e a regra “não invente”

**Problema:** modelos tendem a preencher campos mesmo sem informação.

**Solução:** escreva no prompt: “Se a nota não disser prazo ou prioridade, devolva null. Não invente.” Dê critérios claros para prioridade, por exemplo: “urgente”, “bloqueia outra tarefa”, “hoje” ou prazo em até 2 dias indicam alta; “sem pressa” indica baixa; sem sinal, null.

### 3.4 Estrutura do prompt

Organize o prompt em blocos fixos:

1. Papel e objetivo (“você extrai tarefas de notas de reunião”).
2. Data de hoje e regras de datas.
3. Formato de saída (o JSON acima).
4. Regras de prioridade e de null.
5. Limites (número máximo de subtarefas, subtarefas acionáveis e sem repetição).
6. Dois ou três exemplos de entrada e saída corretas, incluindo um sem nenhuma data.

Versione o prompt (v1, v2, v3) para conseguir comparar resultados.

### 3.5 Validação antes de gravar

Antes de preencher qualquer campo, o código deve verificar:

- O JSON é válido e tem os campos esperados?
- A data existe de verdade e não está no passado (se estiver, sinalize em vez de gravar em silêncio)?
- A prioridade é um dos valores permitidos?
- O número e o tamanho das subtarefas estão dentro do limite?

Se falhar: tente de novo uma vez, e se persistir deixe o campo vazio e mostre um aviso claro. Nunca grave um valor errado sem avisar.

### 3.6 Pessoa no controle

Preencha prazo e prioridade como **sugestão**, destacada visualmente, e permita aceitar, editar, apagar ou regenerar cada item antes de salvar. Mostre `observacoes_incertas` (“Entendi prazo 10/12, mas a nota não diz o mês”). Transcrições de reunião são ambíguas por natureza, e isso aumenta a confiança de quem usa.

## 4. Medir a qualidade (o que mais destaca no portfólio)

### 4.1 Conjunto de testes

Crie de 15 a 20 notas de teste (podem ser inventadas ou trechos anonimizados de reuniões reais), cada uma com a resposta esperada escrita por você. Inclua casos difíceis:

- Nota sem nenhuma data ou prioridade.
- Data relativa (“semana que vem”, “depois do feriado”).
- Duas datas diferentes na mesma nota.
- Prazo já vencido.
- Prioridade só implícita.
- Tarefa grande que exige decomposição em mais de 4 etapas.

Sugestão de tabela de resultados (uma linha por nota):

| Nota | Prazo esperado | Prazo obtido | Prioridade esperada | Prioridade obtida | JSON válido | Comentário |
| --- | --- | --- | --- | --- | --- | --- |

### 4.2 Critérios para a decomposição em subtarefas

Para cada resultado, avalie sim ou não:

- As subtarefas são acionáveis (começam com um verbo e dá para executar)?
- Juntas cobrem a tarefa inteira?
- Não há repetição nem sobreposição?
- O tamanho de cada etapa é razoável?
- A ordem faz sentido (dependências respeitadas)?

### 4.3 Ciclo de melhoria

1. Rode o conjunto de testes com o prompt v1 e anote a taxa de acerto.
2. Identifique o erro mais comum.
3. Mude uma coisa por vez no prompt (v2) e rode de novo.
4. Registre a comparação (por exemplo, “prazo correto em X de 20 antes e Y de 20 depois”).

Não invente números: use os que você realmente medir.

### 4.4 Métrica de produto

Registre quantas subtarefas e sugestões de prazo foram aceitas sem edição. A taxa de aceitação é uma métrica real de produto e vira uma frase forte de entrevista.

## 5. Falhas, custo e segurança (antes de publicar)

Como o projeto ainda está no localhost, isto não bloqueia o trabalho atual, mas planeje:

- **Chave da API:** nunca deixe no código do navegador. Quando for publicar, chame o Gemini por um backend ou função serverless e guarde a chave em variável de ambiente. Se a chave já foi enviada ao GitHub, revogue e crie outra.
- **Falhas:** trate limite de uso, tempo esgotado e resposta vazia, com mensagens claras.
- **Custo:** evite chamar o modelo duas vezes para a mesma nota (cache simples) e limite o tamanho do texto enviado.
- **Privacidade:** transcrições de reunião podem ter dados sensíveis. Avise a pessoa de que o texto é enviado a um serviço externo.

## 6. Funcionalidades futuras (escolha só uma)

- Transformar texto livre em lista de tarefas com responsável e prazo.
- Replanejar subtarefas quando a pessoa atrasar.
- Resumo de notas longas.
- Barra de progresso da tarefa-mãe, bloqueando a conclusão enquanto houver subtarefa aberta (a lógica já existe).

É melhor ter dois recursos de IA bem medidos do que cinco sem teste.

## 7. Do site ao celular

O caminho mais rápido é transformar o site em PWA (instalável no celular, sem precisar de loja). Um app nativo pode esperar: não é necessário para as entrevistas.

## 8. Como usar isso no processo seletivo (trilha AI Builder)

**No GitHub:** README com o problema, um GIF de demonstração, a stack, e uma seção “Como avaliei a IA” com a tabela de resultados e o que você mudou entre as versões do prompt.

**No currículo:** adicione uma seção “Projetos” com este app em 3 linhas: problema, o que construiu (decomposição e extração de prazo e prioridade com LLM) e o resultado medido.

**Na entrevista, uma história em 5 passos:**

1. Problema real: tarefas grandes e notas de reunião travavam meu planejamento.
2. Primeira solução: usei o Gemini para decompor, mas prazos e prioridades não chegavam ao app.
3. Diagnóstico: o pedido devolvia texto e o modelo não sabia a data de hoje.
4. Mudança: saída em JSON, data atual no prompt, regras de null e validação.
5. Resultado: medi em um conjunto de testes (use seus números reais) e mantive a pessoa no controle.

## 9. Plano sugerido

| Dia | Entrega |
| --- | --- |
| 1 | Definir o JSON, reescrever o prompt com data de hoje e regras, ligar `prazo` e `prioridade` aos campos |
| 2 | Validação do JSON, tratamento de erro e tela de confirmação |
| 3 | Montar as 15 a 20 notas de teste com respostas esperadas |
| 4 | Rodar v1, anotar resultados, ajustar o prompt (v2), comparar |
| 5 | Registrar taxa de aceitação, escrever o README e o texto do currículo |
| Depois | Backend para a chave, publicação, PWA |

## 10. Checklist final

- [ ] Resposta do modelo em JSON com os campos do app
- [ ] Data de hoje enviada em todo pedido
- [ ] Regras de prioridade e de null no prompt
- [ ] Validação de JSON, datas e prioridade
- [ ] Sugestões editáveis e observações de incerteza visíveis
- [ ] 15 a 20 notas de teste com respostas esperadas
- [ ] Resultados da v1 e da v2 registrados
- [ ] README com a seção de avaliação
- [ ] Projeto listado no currículo e no LinkedIn
- [ ] Chave da API protegida antes de publicar
