import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import { Express, Request, Response, NextFunction } from "express";
import session from "express-session";
import bcrypt from "bcryptjs";
import { db } from "./db.ts";
import { users } from "../shared/schema.ts";
import { eq } from "drizzle-orm";
import { nanoid } from "nanoid";
import fs from "fs";
import path from "path";

// Store de sessão persistente em arquivo local (evita perder o login quando o tsx reinicia o servidor)
class FileSessionStore extends session.Store {
  private filePath: string;
  private sessions: Record<string, any> = {};

  constructor(filePath = "./.sessions.json") {
    super();
    this.filePath = path.resolve(filePath);
    try {
      if (fs.existsSync(this.filePath)) {
        this.sessions = JSON.parse(fs.readFileSync(this.filePath, "utf-8"));
      }
    } catch {
      this.sessions = {};
    }
  }

  private save() {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(this.sessions), "utf-8");
    } catch {}
  }

  get(sid: string, callback: (err?: any, session?: any) => void) {
    const sess = this.sessions[sid];
    if (!sess) return callback(null, null);
    if (sess.cookie?.expires && new Date(sess.cookie.expires) < new Date()) {
      delete this.sessions[sid];
      this.save();
      return callback(null, null);
    }
    return callback(null, sess);
  }

  set(sid: string, sess: any, callback?: (err?: any) => void) {
    this.sessions[sid] = sess;
    this.save();
    if (callback) callback(null);
  }

  destroy(sid: string, callback?: (err?: any) => void) {
    delete this.sessions[sid];
    this.save();
    if (callback) callback(null);
  }
}

export function setupAuth(app: Express) {
  // Configuração de sessão persistente
  const sessionConfig: session.SessionOptions = {
    store: new FileSessionStore(),
    secret: process.env.SESSION_SECRET || "caderno-secreto-key",
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: false, // Seguro para localhost e HTTP
      sameSite: "lax",
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 dias
    },
  };

  app.use(session(sessionConfig));
  app.use(passport.initialize());
  app.use(passport.session());

  passport.use(
    new LocalStrategy(async (username, password, done) => {
      try {
        const [user] = await db.select().from(users).where(eq(users.username, username));
        if (!user) return done(null, false, { message: "Usuário não encontrado" });
        
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return done(null, false, { message: "Senha incorreta" });
        
        return done(null, user);
      } catch (err) {
        return done(err);
      }
    })
  );

  passport.serializeUser((user: any, done) => done(null, user.id));
  passport.deserializeUser(async (id: string, done) => {
    try {
      const [user] = await db.select().from(users).where(eq(users.id, id));
      done(null, user);
    } catch (err) {
      done(err);
    }
  });

  // --- Rotas de Auth ---

  app.post("/api/register", async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) return res.status(400).send("Usuário e senha são obrigatórios");

    const [existing] = await db.select().from(users).where(eq(users.username, username));
    if (existing) return res.status(400).send("Usuário já existe");

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = { id: nanoid(), username, password: hashedPassword };
    
    await db.insert(users).values(newUser);
    
    req.login(newUser, (err) => {
      if (err) return res.status(500).send("Erro ao logar após registro");
      const { password, ...userWithoutPassword } = newUser;
      res.status(201).json(userWithoutPassword);
    });
  });

  app.post("/api/login", passport.authenticate("local"), (req, res) => {
    const { password, ...userWithoutPassword } = req.user as any;
    res.json(userWithoutPassword);
  });

  app.post("/api/logout", (req, res, next) => {
    req.logout((err) => {
      if (err) return next(err);
      res.sendStatus(200);
    });
  });

  app.get("/api/user", (req, res) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    const { password, ...userWithoutPassword } = req.user as any;
    res.json(userWithoutPassword);
  });
}

// Middleware para proteger rotas
export function isAuthenticated(req: Request, res: Response, next: NextFunction) {
  if (req.isAuthenticated()) return next();
  res.status(401).json({ error: "Não autorizado" });
}
