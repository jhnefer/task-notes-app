import dotenv from "dotenv";
dotenv.config();

import { extractTaskWithGemini } from "../server/aiService.ts";

interface TestCase {
  id: number;
  description: string;
  noteText: string;
  expectedDueDate: string | null;
  expectedPriority: "high" | "medium" | "low" | null;
  expectedUncertaintyMention?: boolean;
}

// Data de referência congelada para repetibilidade dos testes:
// Quinta-feira, 12 de novembro de 2026
const REFERENCE_DATE = "2026-11-12T14:00:00.000Z";
const TIME_ZONE = "America/Fortaleza";

export const TEST_CASES: TestCase[] = [
  {
    id: 1,
    description: "Sem data e sem prioridade",
    noteText: "Comprar cartuchos de tinta para a impressora e papel sulfite quando possível.",
    expectedDueDate: null,
    expectedPriority: null,
  },
  {
    id: 2,
    description: "Prazo relativo: amanhã com urgência explícita",
    noteText: "URGENTE: Enviar planilha de faturamento ajustada para a contabilidade até amanhã às 17h.",
    expectedDueDate: "2026-11-13",
    expectedPriority: "high",
  },
  {
    id: 3,
    description: "Prazo 'até dia 10' sem mês especificado (próximo dia 10)",
    noteText: "Revisar os contratos de prestação de serviços com o jurídico até o dia 10.",
    expectedDueDate: "2026-12-10",
    expectedPriority: null,
    expectedUncertaintyMention: true,
  },
  {
    id: 4,
    description: "Prazo relativo: próxima sexta-feira",
    noteText: "Apresentar a demonstração do novo módulo para o cliente na próxima sexta.",
    expectedDueDate: "2026-11-20", // 12/11 é quinta-feira -> próxima sexta é dia 20
    expectedPriority: null,
  },
  {
    id: 5,
    description: "Prioridade implícita por bloqueio crítico",
    noteText: "Corrigir falha no gateway de pagamento que está impedindo os clientes de finalizar compras.",
    expectedDueDate: null,
    expectedPriority: "high",
  },
  {
    id: 6,
    description: "Baixa prioridade / sem pressa",
    noteText: "Atualizar a foto de perfil da equipe no site institucional. Sem pressa, tarefa de backlog.",
    expectedDueDate: null,
    expectedPriority: "low",
  },
  {
    id: 7,
    description: "Data explícita em formato dia/mês/ano",
    noteText: "Entregar a documentação da API revisada até 25/11/2026.",
    expectedDueDate: "2026-11-25",
    expectedPriority: null,
  },
  {
    id: 8,
    description: "Duas datas na mesma nota (entrega preliminar e final)",
    noteText: "Elaborar relatório anual: enviar rascunho dia 18 e apresentação final no dia 28 de novembro.",
    expectedDueDate: "2026-11-28",
    expectedPriority: null,
    expectedUncertaintyMention: true,
  },
  {
    id: 9,
    description: "Transcrição de reunião com múltiplas ideias soltas",
    noteText: "Anotações da daily: Pedro comentou sobre a lentidão no relatório. Precisamos otimizar a query do banco até segunda-feira com alta prioridade para liberar a equipe.",
    expectedDueDate: "2026-11-16",
    expectedPriority: "high",
  },
  {
    id: 10,
    description: "Prazo 'hoje mesmo'",
    noteText: "Responder ao ticket de suporte do cliente VIP hoje mesmo antes do final do expediente.",
    expectedDueDate: "2026-11-12",
    expectedPriority: "high",
  },
  {
    id: 11,
    description: "Prazo para depois de amanhã",
    noteText: "Publicar o post do blog sobre tendências de IA depois de amanhã.",
    expectedDueDate: "2026-11-14",
    expectedPriority: null,
  },
  {
    id: 12,
    description: "Tarefa rotineira comum (média prioridade implícita ou null)",
    noteText: "Organizar as pastas do Google Drive do departamento financeiro.",
    expectedDueDate: null,
    expectedPriority: null,
  },
  {
    id: 13,
    description: "Data no início do próximo ano",
    noteText: "Planejar a conferência anual da empresa para 15/01/2027.",
    expectedDueDate: "2027-01-15",
    expectedPriority: null,
  },
  {
    id: 14,
    description: "Urgência por impacto regulatório / multa",
    noteText: "Enviar declaração fiscal para a Receita Federal impreterivelmente até dia 20 de novembro sob risco de multa pesada.",
    expectedDueDate: "2026-11-20",
    expectedPriority: "high",
  },
  {
    id: 15,
    description: "Nota curta com data abreviada",
    noteText: "Pagar boleto da internet - vencimento 16/11.",
    expectedDueDate: "2026-11-16",
    expectedPriority: null,
  },
  {
    id: 16,
    description: "Anotação de reunião técnica com decomposição em subtarefas",
    noteText: "Refatorar autenticação: substituir JWT antigo por sessões persistentes, criar testes de integração e atualizar documentação técnica até 30/11/2026.",
    expectedDueDate: "2026-11-30",
    expectedPriority: null,
  },
  {
    id: 17,
    description: "Sem urgência ('quando der tempo')",
    noteText: "Fazer limpeza no estoque e descartar cabos USB antigos quando sobrar tempo na semana.",
    expectedDueDate: null,
    expectedPriority: "low",
  },
  {
    id: 18,
    description: "Prazo 'semana que vem'",
    noteText: "Fazer o alinhamento individual de 1:1 com os estagiários semana que vem.",
    expectedDueDate: "2026-11-16", // Segunda-feira da semana seguinte
    expectedPriority: null,
  },
];

async function runBenchmark() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("ERRO: GEMINI_API_KEY não encontrada no arquivo .env");
    process.exit(1);
  }

  console.log(`\n============================================================`);
  console.log(`🚀 INICIANDO BENCHMARK DE IA (EXTRATOR DE TAREFAS GEMINI)`);
  console.log(`Data de referência de teste: ${REFERENCE_DATE} (${TIME_ZONE})`);
  console.log(`Total de casos de teste: ${TEST_CASES.length}`);
  console.log(`============================================================\n`);

  let correctDueDateCount = 0;
  let correctPriorityCount = 0;
  let validJsonCount = 0;

  const results: Array<{
    id: number;
    description: string;
    expectedDate: string | null;
    obtainedDate: string | null;
    dateMatch: boolean;
    expectedPriority: string | null;
    obtainedPriority: string | null;
    priorityMatch: boolean;
    validJson: boolean;
    subtasksCount: number;
    uncertainties: string[];
  }> = [];

  for (const tc of TEST_CASES) {
    process.stdout.write(`[${tc.id}/${TEST_CASES.length}] Testando: "${tc.description}"... `);

    try {
      const extracted = await extractTaskWithGemini(apiKey, {
        text: tc.noteText,
        referenceDate: REFERENCE_DATE,
        timeZone: TIME_ZONE,
      });

      const dateMatch = (extracted.dueDate || null) === tc.expectedDueDate;
      const priorityMatch = (extracted.priority || null) === tc.expectedPriority;
      const validJson = true;

      if (dateMatch) correctDueDateCount++;
      if (priorityMatch) correctPriorityCount++;
      validJsonCount++;

      results.push({
        id: tc.id,
        description: tc.description,
        expectedDate: tc.expectedDueDate,
        obtainedDate: extracted.dueDate || null,
        dateMatch,
        expectedPriority: tc.expectedPriority,
        obtainedPriority: extracted.priority || null,
        priorityMatch,
        validJson,
        subtasksCount: extracted.subtasks?.length || 0,
        uncertainties: extracted.uncertainties || [],
      });

      console.log(`✓ OK (Prazo: ${dateMatch ? "✓" : "✗"} | Prioridade: ${priorityMatch ? "✓" : "✗"})`);
    } catch (err: any) {
      console.log(`✗ ERRO: ${err?.message || err}`);
      results.push({
        id: tc.id,
        description: tc.description,
        expectedDate: tc.expectedDueDate,
        obtainedDate: null,
        dateMatch: false,
        expectedPriority: tc.expectedPriority,
        obtainedPriority: null,
        priorityMatch: false,
        validJson: false,
        subtasksCount: 0,
        uncertainties: [err?.message || "Erro de execução"],
      });
    }

    // Intervalo de segurança para não atingir rate limits de API
    await new Promise((r) => setTimeout(r, 800));
  }

  const total = TEST_CASES.length;
  const dateAccuracy = ((correctDueDateCount / total) * 100).toFixed(1);
  const priorityAccuracy = ((correctPriorityCount / total) * 100).toFixed(1);
  const jsonAccuracy = ((validJsonCount / total) * 100).toFixed(1);

  console.log(`\n============================================================`);
  console.log(`📊 RESULTADOS DO BENCHMARK`);
  console.log(`============================================================`);
  console.log(`• Taxa de acerto de Prazo (Due Date): ${correctDueDateCount}/${total} (${dateAccuracy}%)`);
  console.log(`• Taxa de acerto de Prioridade:       ${correctPriorityCount}/${total} (${priorityAccuracy}%)`);
  console.log(`• Conformidade do Schema JSON:       ${validJsonCount}/${total} (${jsonAccuracy}%)`);
  console.log(`============================================================\n`);

  // Gerar tabela em formato Markdown para inclusão no README e Portfólio
  let markdownTable = `## Resultados da Avaliação da IA (Benchmark de Extração)\n\n`;
  markdownTable += `> Avaliação realizada em ${new Date().toISOString().substring(0, 10)} com ${total} casos de teste cobrindo ambiguidades temporais, prioridades implícitas e regras rígidas de \`null\`.\n\n`;
  markdownTable += `| # | Caso de Teste | Prazo Esperado | Prazo Obtido | Prioridade Esperada | Prioridade Obtida | JSON Válido | Subtarefas |\n`;
  markdownTable += `|---|---|---|---|---|---|---|---|\n`;

  for (const r of results) {
    const dateIcon = r.dateMatch ? "✅" : "❌";
    const prioIcon = r.priorityMatch ? "✅" : "❌";
    const jsonIcon = r.validJson ? "✅" : "❌";
    markdownTable += `| ${r.id} | ${r.description} | \`${r.expectedDate || "null"}\` | ${dateIcon} \`${r.obtainedDate || "null"}\` | \`${r.expectedPriority || "null"}\` | ${prioIcon} \`${r.obtainedPriority || "null"}\` | ${jsonIcon} | ${r.subtasksCount} |\n`;
  }

  markdownTable += `\n### Métricas Gerais:\n`;
  markdownTable += `- **Acurácia de Prazos:** ${dateAccuracy}%\n`;
  markdownTable += `- **Acurácia de Prioridade:** ${priorityAccuracy}%\n`;
  markdownTable += `- **Validade do Schema:** ${jsonAccuracy}%\n`;

  console.log(markdownTable);
}

runBenchmark().catch(console.error);
