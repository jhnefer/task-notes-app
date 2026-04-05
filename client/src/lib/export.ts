/**
 * Export utilities for tasks and notes
 * Design: Warm Paper Notebook
 */

import { Task, Note } from '@/hooks/useStore';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

/**
 * Export tasks to CSV format
 */
export function exportTasksToCSV(
  tasks: Task[],
  categories: { id: string; name: string }[],
  filename = 'tarefas.csv'
) {
  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  const headers = [
    'Título',
    'Descrição',
    'Prioridade',
    'Status',
    'Categoria',
    'Prazo',
    'Tags',
    'Criada em',
    'Atualizada em',
  ];

  const rows = tasks.map(task => [
    `"${task.title.replace(/"/g, '""')}"`,
    `"${(task.description ?? '').replace(/"/g, '""')}"`,
    task.priority === 'high' ? 'Alta' : task.priority === 'medium' ? 'Média' : 'Baixa',
    task.status === 'pending'
      ? 'Pendente'
      : task.status === 'in_progress'
        ? 'Em andamento'
        : 'Concluída',
    `"${getCategoryName(task.categoryId)}"`,
    task.dueDate
      ? format(new Date(task.dueDate), "dd/MM/yyyy HH:mm", { locale: ptBR })
      : '',
    task.tags.map(t => `#${t}`).join('; '),
    format(new Date(task.createdAt), "dd/MM/yyyy HH:mm", { locale: ptBR }),
    format(new Date(task.updatedAt), "dd/MM/yyyy HH:mm", { locale: ptBR }),
  ]);

  const csv = [headers.join(','), ...rows.map(row => row.join(','))].join('\n');

  downloadFile(csv, filename, 'text/csv;charset=utf-8;');
}

/**
 * Export notes to CSV format
 */
export function exportNotesToCSV(
  notes: Note[],
  categories: { id: string; name: string }[],
  filename = 'anotacoes.csv'
) {
  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  const headers = ['Título', 'Conteúdo', 'Categoria', 'Fixada', 'Criada em', 'Atualizada em'];

  const rows = notes.map(note => [
    `"${note.title.replace(/"/g, '""')}"`,
    `"${note.content.replace(/"/g, '""').replace(/\n/g, ' ')}"`,
    `"${getCategoryName(note.categoryId)}"`,
    note.pinned ? 'Sim' : 'Não',
    format(new Date(note.createdAt), "dd/MM/yyyy HH:mm", { locale: ptBR }),
    format(new Date(note.updatedAt), "dd/MM/yyyy HH:mm", { locale: ptBR }),
  ]);

  const csv = [headers.join(','), ...rows.map(row => row.join(','))].join('\n');

  downloadFile(csv, filename, 'text/csv;charset=utf-8;');
}

/**
 * Export tasks to PDF format
 */
export function exportTasksToPDF(
  tasks: Task[],
  categories: { id: string; name: string }[]
) {
  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  let html = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Tarefas - Meu Caderno</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          color: #333;
          line-height: 1.6;
          background: #f5f1ed;
          padding: 20px;
        }
        .container {
          max-width: 900px;
          margin: 0 auto;
          background: white;
          padding: 40px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        h1 {
          color: #8B4513;
          margin-bottom: 10px;
          font-size: 28px;
        }
        .subtitle {
          color: #999;
          margin-bottom: 30px;
          font-size: 14px;
        }
        .summary {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 15px;
          margin-bottom: 30px;
        }
        .summary-item {
          padding: 15px;
          background: #f9f7f5;
          border-left: 4px solid #C0533A;
          border-radius: 4px;
        }
        .summary-item strong {
          display: block;
          font-size: 20px;
          color: #C0533A;
        }
        .summary-item span {
          font-size: 12px;
          color: #999;
        }
        .task-group {
          margin-bottom: 30px;
        }
        .task-group h2 {
          font-size: 18px;
          color: #333;
          border-bottom: 2px solid #C0533A;
          padding-bottom: 8px;
          margin-bottom: 15px;
        }
        .task-item {
          padding: 12px;
          margin-bottom: 10px;
          background: #fafaf8;
          border-left: 4px solid #ddd;
          border-radius: 4px;
          page-break-inside: avoid;
        }
        .task-item.high {
          border-left-color: #C0533A;
        }
        .task-item.medium {
          border-left-color: #B45309;
        }
        .task-item.low {
          border-left-color: #4A7C59;
        }
        .task-title {
          font-weight: 600;
          color: #333;
          margin-bottom: 5px;
        }
        .task-description {
          font-size: 13px;
          color: #666;
          margin-bottom: 8px;
        }
        .task-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          font-size: 12px;
        }
        .badge {
          display: inline-block;
          padding: 3px 8px;
          background: #f0f0f0;
          border-radius: 3px;
          color: #666;
        }
        .badge.priority-high {
          background: #C0533A;
          color: white;
        }
        .badge.priority-medium {
          background: #B45309;
          color: white;
        }
        .badge.priority-low {
          background: #4A7C59;
          color: white;
        }
        .badge.status-done {
          background: #4A7C59;
          color: white;
        }
        .badge.status-in_progress {
          background: #B45309;
          color: white;
        }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #ddd;
          text-align: center;
          font-size: 12px;
          color: #999;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>📋 Meu Caderno - Tarefas</h1>
        <p class="subtitle">Exportado em ${format(new Date(), "dd 'de' MMMM 'de' yyyy 'às' HH:mm", { locale: ptBR })}</p>
        
        <div class="summary">
          <div class="summary-item">
            <strong>${tasks.length}</strong>
            <span>Total de tarefas</span>
          </div>
          <div class="summary-item">
            <strong>${tasks.filter(t => t.status === 'done').length}</strong>
            <span>Concluídas</span>
          </div>
          <div class="summary-item">
            <strong>${tasks.filter(t => t.status === 'in_progress').length}</strong>
            <span>Em andamento</span>
          </div>
          <div class="summary-item">
            <strong>${tasks.filter(t => t.status === 'pending').length}</strong>
            <span>Pendentes</span>
          </div>
        </div>
  `;

  // Group tasks by status
  const groupedByStatus = {
    pending: tasks.filter(t => t.status === 'pending'),
    in_progress: tasks.filter(t => t.status === 'in_progress'),
    done: tasks.filter(t => t.status === 'done'),
  };

  const statusLabels = {
    pending: 'Pendentes',
    in_progress: 'Em Andamento',
    done: 'Concluídas',
  };

  Object.entries(groupedByStatus).forEach(([status, groupTasks]) => {
    if (groupTasks.length === 0) return;

    html += `<div class="task-group">
      <h2>${statusLabels[status as keyof typeof statusLabels]} (${groupTasks.length})</h2>`;

    groupTasks.forEach(task => {
      const priorityLabel =
        task.priority === 'high' ? 'Alta' : task.priority === 'medium' ? 'Média' : 'Baixa';
      const dueDate = task.dueDate
        ? format(new Date(task.dueDate), "dd/MM/yyyy", { locale: ptBR })
        : '';

      html += `
        <div class="task-item ${task.priority}">
          <div class="task-title">✓ ${task.title}</div>
          ${task.description ? `<div class="task-description">${task.description}</div>` : ''}
          <div class="task-meta">
            <span class="badge priority-${task.priority}">${priorityLabel}</span>
            ${getCategoryName(task.categoryId) ? `<span class="badge">${getCategoryName(task.categoryId)}</span>` : ''}
            ${dueDate ? `<span class="badge">📅 ${dueDate}</span>` : ''}
            ${task.tags.length > 0 ? `<span class="badge">${task.tags.map(t => `#${t}`).join(', ')}</span>` : ''}
          </div>
        </div>
      `;
    });

    html += '</div>';
  });

  html += `
        <div class="footer">
          <p>Meu Caderno - Sistema de Gerenciamento de Tarefas e Anotações</p>
          <p>Dados salvos localmente no seu navegador</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const blob = new Blob([html], { type: 'text/html;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `tarefas-${format(new Date(), 'yyyy-MM-dd-HHmm')}.html`);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * Export notes to PDF format
 */
export function exportNotesToPDF(
  notes: Note[],
  categories: { id: string; name: string }[]
) {
  const getCategoryName = (id?: string) =>
    categories.find(c => c.id === id)?.name ?? '';

  let html = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Anotações - Meu Caderno</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          color: #333;
          line-height: 1.6;
          background: #f5f1ed;
          padding: 20px;
        }
        .container {
          max-width: 900px;
          margin: 0 auto;
          background: white;
          padding: 40px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        h1 {
          color: #8B4513;
          margin-bottom: 10px;
          font-size: 28px;
        }
        .subtitle {
          color: #999;
          margin-bottom: 30px;
          font-size: 14px;
        }
        .note-item {
          padding: 20px;
          margin-bottom: 20px;
          background: #fafaf8;
          border-left: 4px solid #C0533A;
          border-radius: 4px;
          page-break-inside: avoid;
        }
        .note-title {
          font-size: 18px;
          font-weight: 600;
          color: #333;
          margin-bottom: 10px;
        }
        .note-content {
          font-size: 14px;
          color: #666;
          margin-bottom: 12px;
          white-space: pre-wrap;
          word-wrap: break-word;
        }
        .note-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          font-size: 12px;
          color: #999;
        }
        .badge {
          display: inline-block;
          padding: 3px 8px;
          background: #f0f0f0;
          border-radius: 3px;
          color: #666;
        }
        .pinned {
          color: #C0533A;
          font-weight: 600;
        }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #ddd;
          text-align: center;
          font-size: 12px;
          color: #999;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>📝 Meu Caderno - Anotações</h1>
        <p class="subtitle">Exportado em ${format(new Date(), "dd 'de' MMMM 'de' yyyy 'às' HH:mm", { locale: ptBR })}</p>
        <p class="subtitle">Total de anotações: ${notes.length}</p>
  `;

  notes.forEach(note => {
    html += `
      <div class="note-item">
        <div class="note-title">
          ${note.pinned ? '<span class="pinned">📌</span>' : ''} ${note.title}
        </div>
        <div class="note-content">${note.content}</div>
        <div class="note-meta">
          ${getCategoryName(note.categoryId) ? `<span class="badge">${getCategoryName(note.categoryId)}</span>` : ''}
          <span class="badge">Criada: ${format(new Date(note.createdAt), "dd/MM/yyyy HH:mm", { locale: ptBR })}</span>
        </div>
      </div>
    `;
  });

  html += `
        <div class="footer">
          <p>Meu Caderno - Sistema de Gerenciamento de Tarefas e Anotações</p>
          <p>Dados salvos localmente no seu navegador</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const blob = new Blob([html], { type: 'text/html;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `anotacoes-${format(new Date(), 'yyyy-MM-dd-HHmm')}.html`);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * Helper function to download file
 */
function downloadFile(content: string, filename: string, type: string) {
  const blob = new Blob([content], { type });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
