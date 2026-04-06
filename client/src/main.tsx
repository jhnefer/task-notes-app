import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import { registerSW } from 'virtual:pwa-register';

// Registra o Service Worker para suporte Offline e PWA
registerSW({ immediate: true });

createRoot(document.getElementById("root")!).render(<App />);
