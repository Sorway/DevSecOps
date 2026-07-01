const fs = require("node:fs");
const path = require("node:path");

const root = path.join(__dirname, "..", "frontend");
const html = fs.readFileSync(path.join(root, "index.html"), "utf8");

if (!html.includes("Plateforme d'Entraînement DevSecOps")) {
  throw new Error("Le frontend skeleton n'est pas present.");
}

if (!html.includes("/api/health") || !html.includes("/api/debug-ping") || !html.includes("/api/welcome")) {
  throw new Error("La maquette skeleton ne consomme pas les endpoints API attendus.");
}
