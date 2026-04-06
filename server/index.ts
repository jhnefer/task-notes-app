import express, { type Request, Response, NextFunction } from "express";
import path from "path";
import { fileURLToPath } from "url";
import { setupAuth } from "./auth.ts";
import { registerRoutes } from "./routes.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  app.use(express.json());
  app.use(express.urlencoded({ extended: false }));

  // Middleware de Log para auxiliar o desenvolvimento
  app.use((req, res, next) => {
    const start = Date.now();
    const path = req.path;
    res.on("finish", () => {
      const duration = Date.now() - start;
      if (path.startsWith("/api")) {
        console.log(`${req.method} ${path} ${res.statusCode} in ${duration}ms`);
      }
    });
    next();
  });

  // Configurar Autenticação
  setupAuth(app);

  // Registrar Rotas da API e criar Servidor HTTP
  const server = registerRoutes(app);

  // Middleware Global de Erro
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Erro Interno do Servidor";
    res.status(status).json({ message });
    console.error(err);
  });

  // Configuração de arquivos estáticos (Frontend)
  const staticPath = process.env.NODE_ENV === "production"
    ? path.resolve(__dirname, "public")
    : path.resolve(__dirname, "..", "dist", "public");

  app.use(express.static(staticPath));

  // Fallback para SPA (Single Page Application)
  app.get("*", (req, res, next) => {
    if (req.path.startsWith("/api")) return next();
    res.sendFile(path.join(staticPath, "index.html"));
  });

  // Porta 5000 para desenvolvimento, PORT do ambiente para produção
  const port = process.env.NODE_ENV === "production" 
    ? Number(process.env.PORT) || 3000 
    : 5000;

  server.listen(port, "0.0.0.0", () => {
    console.log(`Backend rodando em http://localhost:${port}/ (API /api)`);
  });
}

startServer().catch(console.error);
