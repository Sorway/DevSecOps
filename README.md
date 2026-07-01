<div align="center">

# 🛡️ SecureWallet — Industrialisation, durcissement & architecture CI/CD

**Transformer une SPA statique et une API Node.js manipulant des données sensibles
en une chaîne de livraison auditable, hermétique et infalsifiable.**

[![CI CD durcie](https://img.shields.io/badge/CI%2FCD-durcie-26c6da)](.github/workflows/ci-cd.yml)
[![Node](https://img.shields.io/badge/Node.js-20-3c873a)](backend/package.json)
[![Security](https://img.shields.io/badge/SAST-CodeQL-7c4dff)](.github/workflows/ci-cd.yml)
[![Secrets](https://img.shields.io/badge/Secrets-SOPS%20%2B%20age-26e0a8)](.github/secrets-prod.yaml)
[![Registry](https://img.shields.io/badge/Images-GHCR-24292e)](.github/workflows/ci-cd.yml)
[![Made with](https://img.shields.io/badge/theme-Zensical-26c6da)](https://astronas.github.io/ynov-virtu/)

📄 **Vitrine du projet (GitHub Page)** : publiée depuis la branche `preprod` — dossier [`docs/`](docs/index.html)
🎓 *Dernier cours de DevSecOps avancé — Sophia Ynov Campus*

</div>

---

## 📌 Contexte

L'équipe de développement confie le dépôt d'une application scindée en deux composants distincts
au sein d'un même dépôt. Notre mission : **structurer la gouvernance Git pour interdire toute action
non auditée** et bâtir un flux où le code de production est *techniquement* validé avant son déploiement.

| Composant | Description | Livraison |
|-----------|-------------|-----------|
| [`frontend/`](frontend/) | Single Page Application entièrement statique (HTML/CSS/JS moderne) consommant l'API | GitHub Pages (OIDC) |
| [`backend/`](backend/) | API REST Node.js / Express manipulant des données sensibles (clés d'API, infra externes) | Docker → GHCR + Vercel |

> Le frontend est aussi copié dans [`backend/public/`](backend/public/) afin que le backend reste autonome
> lors des builds Docker et des déploiements Vercel.

---

## 🗂️ Sommaire

1. [Architecture du dépôt](#-1-architecture-du-dépôt)
2. [Gouvernance Git & branches](#-2-gouvernance-git--branches)
3. [Durcissement local — Shift-Left](#-3-durcissement-local--shift-left)
4. [Gestion des secrets par enveloppe (SOPS/age)](#-4-gestion-des-secrets-par-enveloppe-sopsage)
5. [Conteneurisation multi-stage & GHCR](#-5-conteneurisation-multi-stage--ghcr)
6. [Pipeline CI durci & interruption absolue](#-6-pipeline-ci-durci--interruption-absolue)
7. [Composite Action — Trivy SBOM](#-7-composite-action--trivy-sbom)
8. [Déploiement continu](#-8-déploiement-continu)
9. [Robustesse, concurrence & rollback](#-9-robustesse-concurrence--rollback)
10. [Démarrage local](#-10-démarrage-local)
11. [Configuration GitHub requise](#-11-configuration-github-requise)
12. [Livrables](#-12-livrables)

---

## 📁 1. Architecture du dépôt

```text
.
├── frontend/                       # SPA statique → GitHub Pages
├── backend/
│   ├── src/app.js                  # API Express (routes /api/*)
│   ├── public/                     # copie du frontend (autonomie build/déploiement)
│   ├── tests/                      # unit · integration · e2e (Jest + supertest)
│   ├── Dockerfile                  # build multi-stage non-root
│   └── .dockerignore
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml               # pipeline principal durci (staging + main)
│   │   └── pages-preprod.yml       # déploiement de cette vitrine (preprod)
│   ├── actions/trivy-scan/         # composite action — scan SBOM CycloneDX
│   ├── branch-protection/main.yml  # politique de protection documentée
│   └── secrets-prod.yaml           # secrets chiffrés SOPS (valeurs ENC[...])
├── docs/index.html                 # GitHub Page — vitrine du projet (preprod)
├── scripts/install-hooks.sh        # installation du hook pre-commit local
├── scripts/install-hooks.ps1       # installation du hook pre-commit local sous PowerShell
├── scripts/pre-commit.sh           # source versionnée du hook Shift-Left
├── gitleaks.toml                   # règle SECWALLET_ sur-mesure
├── scripts/frontend-smoke-test.js  # test de fumée du frontend
└── README.md
```

---

## 🔀 2. Gouvernance Git & branches

La politique de sécurité est **lisible directement dans le YAML** : à la simple lecture du workflow,
un auditeur constate qu'un déploiement sur `main` exige le succès absolu des jobs de validation exécutés au préalable.

| Branche | Rôle | Règles |
|---------|------|--------|
| `staging` | Branche pivot d'intégration | La CI s'exécute **entièrement** à chaque push et pull request |
| `main` | État stable en production | Push directs **strictement interdits**, PR review + status checks stricts, environnement `production` |
| `preprod` | Préproduction / vitrine | Publie la GitHub Page de présentation (`docs/`) |

La stratégie de promotion est rendue visible par trois mécanismes combinés dans [`ci-cd.yml`](.github/workflows/ci-cd.yml) :

```yaml
on:
  push:
    branches: [staging, main]        # déclenché sur les deux branches
  pull_request:
    branches: [staging, main]

jobs:
  deploy-frontend:
    if: github.ref == 'refs/heads/main'                     # bloc conditionnel de niveau job
    needs: [test, gitleaks, codeql, sbom-scan, docker-image] # matrice de dépendance stricte
    environment: production                                  # environnement GitHub nommé
```

> 📋 La politique cible (interdiction de push direct, status checks requis, environnement) est
> documentée de façon transparente dans [`.github/branch-protection/main.yml`](.github/branch-protection/main.yml).

---

## 🧱 3. Durcissement local — Shift-Left

Avant qu'une seule ligne de code n'atteigne GitHub, le hook **`.git/hooks/pre-commit`** garantit
l'intégrité des commits sur le poste de travail. Il valide **séquentiellement** :

1. **`actionlint`** sur l'ensemble des fichiers de `.github/workflows/`.
2. Un **scan `gitleaks` local** focalisé *uniquement* sur les modifications indexées (staged).
3. Un **contrôle de structure strict** : si un fichier `.env`, `.pem` ou `.key` est présent dans l'index,
   le commit est avorté immédiatement avec un message d'erreur rouge explicite :

   > **Sécurité : Tentative de commit d'un fichier de configuration ou d'une clé en clair. Opération annulée.**

Le hook Git installé dans `.git/hooks/` n'est pas versionné par Git. Sa source est donc conservée dans
[`scripts/pre-commit.sh`](scripts/pre-commit.sh) et peut être réinstallée sur un nouveau clone avec :

```bash
bash scripts/install-hooks.sh
```

Sous PowerShell :

```powershell
.\scripts\install-hooks.ps1
```

### Règle Gitleaks sur-mesure — [`gitleaks.toml`](gitleaks.toml)

Une expression régulière personnalisée intercepte les jetons d'accès internes de l'entreprise :
préfixe `SECWALLET_` suivi d'**exactement 24 caractères alphanumériques majuscules**, combinée à une
vérification d'entropie.

```toml
[[rules]]
id = "secwallet-internal-token"
regex = '''SECWALLET_[A-Z0-9]{24}'''
entropy = 3.5
keywords = ["SECWALLET_"]
```

---

## 🔐 4. Gestion des secrets par enveloppe (SOPS/age)

La philosophie GitOps exige qu'**aucun secret de production ne soit stocké en clair**, tout en
laissant l'équipe Ops auditer les structures de fichiers.

1. Une paire de clés asymétriques est générée via **`age`**. La clé privée est nommée **`ops.txt`** (ignorée par Git).
2. [`.github/secrets-prod.yaml`](.github/secrets-prod.yaml) contient les clés de production actuelles et futures
   (`DATABASE_URL`, `JWT_SECRET`, `API_KEY`).
3. Le chiffrement **SOPS** est *sélectif* : seules les valeurs applicatives deviennent des blocs `ENC[...]`,
   tandis que les clés structurelles YAML restent lisibles pour des `git diff` propres.

```bash
# 1) génération de la paire de clés age (privée → ops.txt, ignorée par Git)
age-keygen -o ops.txt

# 2) chiffrement des SEULES valeurs applicatives (encrypted-regex)
sops --age "$(grep -o 'age1.*' ops.txt)" \
     --encrypt --encrypted-regex '^(DATABASE_URL|JWT_SECRET|API_KEY)$' \
     .github/secrets-prod.yaml > .github/secrets-prod.enc.yaml
Move-Item .github/secrets-prod.enc.yaml .github/secrets-prod.yaml
```

> Dans GitHub, la clé privée est stockée dans le secret **`SOPS_AGE_KEY`**. Le déchiffrement en CD se fait
> **en mémoire RAM** — aucun fichier en clair n'est jamais écrit sur le disque du runner (voir §8).

---

## 🐳 5. Conteneurisation multi-stage & GHCR

L'artefact serveur du backend est automatiquement construit et publié sous forme d'image Docker sécurisée.

- **[`Dockerfile`](backend/Dockerfile) multi-stage** : étape `deps` (`npm ci --omit=dev`) puis étape `runtime`
  Alpine minimale exécutée sous un utilisateur non-root dédié (`nodeapp`).
- **Filtrage de chemins** : `dorny/paths-filter` ne (re)construit l'image que si `backend/**` a été modifié.
- **Scan de sécurité de l'image** : avant toute publication, Trivy scanne l'image locale
  (`trivy image --exit-code 1 --severity HIGH,CRITICAL`).
- **Publication conditionnelle** : l'image n'est poussée sur **GHCR** (taggée au **SHA du commit**) que si
  le scan réussit **et** sur la branche `main`, via une authentification dynamique au registre.

```yaml
- name: Scan backend image
  if: steps.filter.outputs.backend == 'true'
  run: trivy image --exit-code 1 --severity HIGH,CRITICAL "${{ steps.meta.outputs.image }}"
- uses: docker/login-action@v3
  if: github.ref == 'refs/heads/main' && steps.filter.outputs.backend == 'true'
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

---

## ⛓️ 6. Pipeline CI durci & interruption absolue

Le workflow principal [`ci-cd.yml`](.github/workflows/ci-cd.yml) agit comme une **barrière**.

```text
validate-workflows ─▶ test ─┬─▶ gitleaks ─┐
                            ├─▶ codeql ────┼─▶ docker-image ─┬─▶ deploy-frontend  (main)
                            └─▶ sbom-scan ─┘                 └─▶ deploy-backend   (main)
```

- **Moindre privilège** : `permissions: contents: read` au niveau global. Aucun job n'hérite de droits d'écriture.
  Les privilèges requis (`packages: write`, `pages: write`, `id-token: write`) sont **isolés au job concerné**.
- **Optimisation** : mise en cache des dépendances Node via `actions/setup-node` (`cache: npm`) sur les deux lockfiles.
- **Analyse statique (SAST)** : le moteur **CodeQL** analyse le JavaScript (`security-extended`) et **téléverse le SARIF**.
  Le job échoue si une vulnérabilité `error` ou de `security-severity ≥ 7.0` est détectée.

### Politique d'interruption stricte

| Contrôle | Comportement bloquant |
|----------|----------------------|
| **Testing** | `npm test` doit réussir pour poursuivre le pipeline |
| **Gitleaks** | Code de sortie non nul si un secret est découvert |
| **CodeQL / SAST** | Échec si une vulnérabilité majeure (High/Error) est trouvée dans le backend |
| **Scan image Docker** | Échec sur toute vulnérabilité HIGH/CRITICAL |

> ⛔ L'usage de **`continue-on-error: true` est interdit**. Si Gitleaks lève une alerte, si CodeQL trouve
> une faille, ou si le scan d'image échoue, le pipeline s'arrête **immédiatement** et bloque tout déploiement.

---

## 🧩 7. Composite Action — Trivy SBOM

Pour centraliser la gouvernance de la sécurité et éviter la redondance, les scanners de dépendances au
format SBOM sont isolés dans une **action composite** locale : [`.github/actions/trivy-scan/action.yml`](.github/actions/trivy-scan/action.yml).

- Type **`composite`**, s'exécutant dans le contexte du job appelant.
- Entrée obligatoire : `sbom-path` — le chemin du SBOM **CycloneDX JSON** généré en amont.
- Exécute Trivy en **mode analyse de SBOM** (`trivy sbom`).

| Sévérité détectée | Conséquence |
|-------------------|-------------|
| `CRITICAL` | ❌ **Échec** du build (`--exit-code 1`) |
| `HIGH` / `MEDIUM` | ⚠️ **Avertissement** dans le résumé du workflow (`$GITHUB_STEP_SUMMARY`), le pipeline continue |

---

## 🚀 8. Déploiement continu

Le déploiement ne se déclenche **que si l'intégralité des jobs de la CI sont validés**, et uniquement lors
d'un push/merge validé sur `main`.

### Frontend → GitHub Pages via artefacts éphémères

- Source des Pages définie sur **« GitHub Actions »** (Paramètres > Pages).
- Job `deploy-frontend` exécuté **uniquement sur `main`**, avec privilèges **OIDC** explicites
  (`pages: write` + `id-token: write`).
- `actions/upload-pages-artifact` package le dossier `/frontend`, puis `actions/deploy-pages` propulse le
  site de manière **hermétique**, sans laisser de trace de build dans l'historique Git.

### Backend → Vercel (machine-to-machine)

- Job `deploy-backend` exigeant le succès complet des jobs de sécurité et de livraison.
- **Déchiffrement au runtime** : `SOPS_AGE_KEY` déchiffre `.github/secrets-prod.yaml` **en RAM** ; les valeurs
  sont injectées **à la volée** dans la commande `vercel deploy` (`--env=...`). Aucun secret en clair sur disque.

```yaml
env:
  SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
  VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
  VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
  VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
```

---

## 🛟 9. Robustesse, concurrence & rollback

- **Gestion de la concurrence** : deux commits coup sur coup ? Le pipeline du premier est annulé
  immédiatement (`concurrency.cancel-in-progress: true`) pour économiser les ressources et éviter la
  concurrence lors des déploiements.
- **Diagnostic serverless** : la route `/api/debug-ping` évite l'ICMP système et utilise une validation
  IP / DNS compatible avec Vercel.
- **Healthcheck post-déploiement** : une fois Vercel terminé, l'URL de production générée dynamiquement est
  sondée par un `curl` de diagnostic vers `/api/health`. Tout code ≠ `200 OK` fait **échouer le job**,
  notifiant immédiatement l'équipe d'une anomalie.

```yaml
- name: Healthcheck
  run: curl --fail --silent --show-error "${{ steps.vercel.outputs.url }}/api/health"
```

---

## 💻 10. Démarrage local

```bash
npm install     # installe le workspace (backend inclus)
npm test        # tests Jest du backend + smoke-test du frontend
npm run lint    # node --check + lint du backend
```

La route `/api/health` peut etre testee directement apres deploiement pour verifier que les secrets de production
sont bien injectes dans l'environnement Vercel.

Les contributions de documentation passent par des PR courtes afin de conserver un historique Git lisible.

Pour prévisualiser la vitrine localement, ouvrez [`docs/index.html`](docs/index.html) dans un navigateur.

---

## ⚙️ 11. Configuration GitHub requise

| Élément | Où | Valeur |
|---------|-----|--------|
| Source des Pages | Settings > Pages | **GitHub Actions** |
| Protection de branche | Settings > Branches (`main`) | Interdire les push directs, exiger les status checks de §2 |
| Secret `SOPS_AGE_KEY` | Settings > Secrets and variables > Actions | Clé privée `age` (contenu d'`ops.txt`) |
| Secret `VERCEL_TOKEN` | idem | Jeton d'API Vercel |
| Secret `VERCEL_PROJECT_ID` | idem | Identifiant du projet Vercel |
| Secret `VERCEL_ORG_ID` | idem | Identifiant de l'organisation Vercel |

---

## 📦 12. Livrables

Un unique fichier texte déposé sur Moodle contenant :

- **L'URL de la GitHub Page** (frontend + [vitrine `docs/`](docs/index.html)).
- **L'URL Vercel** de l'API backend (avec son endpoint `/api/health`).
- **L'URL du dépôt GitHub public** exposant l'arborescence complète et fonctionnelle : frontend, backend,
  hooks locaux personnalisés et la structure `.github/` au complet — montrant clairement la protection des
  branches, les conditions de filtrage Docker et le chaînage logique des dépendances (`needs`).

<div align="center">

---

*Made with **Zensical** ✨ — thème inspiré de [astronas.github.io/ynov-virtu](https://astronas.github.io/ynov-virtu/)*

</div>
