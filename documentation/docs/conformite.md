# Conformité aux consignes

Chaque exigence de l'énoncé, avec **sa preuve** : extrait de code réel, configuration, ou
déploiement en ligne. Les blocs « Preuve » sont repliés, cliquez pour les ouvrir.

[![CI CD durcie](https://github.com/Sorway/DevSecOps/actions/workflows/ci-cd.yml/badge.svg?branch=main)](https://github.com/Sorway/DevSecOps/actions/workflows/ci-cd.yml)

**Preuves en ligne :** [Frontend](https://sorway.github.io/DevSecOps/) ·
[API `/api/health`](https://projet-final-inky-iota.vercel.app/api/health) ·
[Dépôt](https://github.com/Sorway/DevSecOps) ·
[Image GHCR](https://github.com/Sorway/DevSecOps/pkgs/container/devsecops%2Fbackend)

## Gouvernance Git

- [x] `staging` pivot d'intégration, CI complète à chaque événement
- [x] `main` production, push directs interdits (ruleset `REVIEW_REQUIRED`)
- [x] Déclenché sur `staging` **et** `main`, `if` sur `main`, `needs` strict, `environment` nommé

??? example "Preuve : déclenchement, gating conditionnel et environnement (`ci-cd.yml`)"

    ```yaml
    on:
      push:
        branches: [staging, main]        # déclenché sur les deux branches
      pull_request:
        branches: [staging, main]

    jobs:
      deploy-backend:
        if: github.ref == 'refs/heads/main'                       # bloc conditionnel de job
        needs: [test, gitleaks, codeql, sbom-scan, docker-image]  # dépendance stricte
        environment: production                                   # environnement nommé
    ```

    La protection de `main` est **effective** : toute PR y est en état `REVIEW_REQUIRED` et ne peut
    être fusionnée sans revue (ruleset GitHub).

## Durcissement local (Shift-Left)

- [x] Hook `pre-commit` : `actionlint` + `gitleaks --staged` (bloquants)
- [x] Refus des fichiers `.env` / `.pem` / `.key` avec message rouge, commit avorté
- [x] Règle Gitleaks sur-mesure `SECWALLET_` + 24 caractères + entropie

??? example "Preuve : contrôle de structure du hook (`scripts/pre-commit.sh`)"

    ```bash
    if [[ "$file" == *.env || "$file" == *.pem || "$file" == *.key ]]; then
        echo -e "${RED}Sécurité : Tentative de commit d'un fichier de configuration ou d'une clé en clair. Opération annulée.${RESET}"
        exit 1
    fi
    ```

??? example "Preuve : règle Gitleaks sur-mesure (`gitleaks.toml`)"

    ```toml
    [[rules]]
    id       = "secwallet-internal-token"
    regex    = '''SECWALLET_[A-Z0-9]{24}'''
    entropy  = 3.5
    keywords = ["SECWALLET_"]
    ```

## Secrets par enveloppe (SOPS / age)

- [x] Paire de clés **age**, privée `ops.txt` (ignorée par Git)
- [x] Chiffrement SOPS **sélectif** : valeurs `ENC[...]`, clés lisibles
- [x] Déchiffrement runtime **en RAM**, aucun secret sur le disque

??? example "Preuve : chiffrement sélectif (`.github/secrets-prod.yaml`)"

    ```yaml
    production:
        DATABASE_URL: ENC[AES256_GCM,data:TCwiv...,type:str]   # valeur chiffrée
        JWT_SECRET:   ENC[AES256_GCM,data:5bSz4...,type:str]
        API_KEY:      ENC[AES256_GCM,data:oV5AU...,type:str]
    sops:
        encrypted_regex: ^(DATABASE_URL|JWT_SECRET|API_KEY)$   # seules ces valeurs
    ```

??? example "Preuve : déchiffrement en RAM, sans fichier (`ci-cd.yml`, job `deploy-backend`)"

    ```bash
    export SOPS_AGE_KEY                                                     # clé en mémoire seulement
    secrets_json="$(sops -d --output-type json .github/secrets-prod.yaml)"  # déchiffré en RAM
    # aucun mktemp, aucun SOPS_AGE_KEY_FILE : rien n'est écrit sur le disque du runner
    ```

## Conteneurisation & GHCR

- [x] `Dockerfile` multi-stage, non-root (`node:24-alpine`)
- [x] Build conditionné au filtrage de chemins
- [x] Scan Trivy de l'image avant publication
- [x] Publication GHCR conditionnelle (scan OK + `main`), tag = SHA

??? example "Preuve : Dockerfile multi-stage non-root (`backend/Dockerfile`)"

    ```dockerfile
    FROM node:24-alpine AS deps
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci --omit=dev

    FROM node:24-alpine AS runtime
    RUN apk upgrade --no-cache \
      && addgroup -S nodeapp && adduser -S nodeapp -G nodeapp
    COPY --from=deps /app/node_modules ./node_modules
    USER nodeapp
    ```

??? example "Preuve : filtrage, scan et push conditionnel (`ci-cd.yml`, job `docker-image`)"

    ```yaml
    - uses: dorny/paths-filter@v4
      id: filter
      with:
        filters: |
          backend:
            - 'backend/**'
            - '.github/workflows/ci-cd.yml'
    - name: Scan backend image
      if: steps.filter.outputs.backend == 'true'
      run: trivy image --exit-code 1 --severity HIGH,CRITICAL "${{ steps.meta.outputs.image }}"
    - name: Push backend image to GHCR
      if: github.ref == 'refs/heads/main' && steps.filter.outputs.backend == 'true'
      run: docker push "ghcr.io/${GITHUB_REPOSITORY,,}/backend:${GITHUB_SHA}"
    ```

## Pipeline CI durci

- [x] `permissions: contents: read` global, écritures isolées au job
- [x] Cache des dépendances Node
- [x] CodeQL + upload SARIF, échec sur `High`/`Error`
- [x] Tests bloquants, Gitleaks exit ≠ 0, **aucun `continue-on-error`**

??? example "Preuve : moindre privilège (`ci-cd.yml`)"

    ```yaml
    permissions:
      contents: read        # global : lecture seule

    jobs:
      docker-image:
        permissions:
          packages: write    # écriture isolée à ce job
      codeql:
        permissions:
          security-events: write
    ```

??? example "Preuve : CodeQL fait échouer sur une faille majeure (`ci-cd.yml`)"

    ```yaml
    - name: Fail on CodeQL high severity
      run: |
        jq -e '[ .runs[].results[]
          | select((.level=="error") or (.properties["security-severity"] // "0" | tonumber >= 7.0))
        ] | length == 0' codeql-results/javascript.sarif
    ```

## Composite Action

- [x] `.github/actions/trivy-scan/action.yml` de type composite
- [x] Entrée obligatoire = chemin du SBOM CycloneDX
- [x] `trivy sbom` : échec sur `CRITICAL`, avertissement sur `HIGH`/`MEDIUM`
- [x] Installe Trivy elle-même (boîte noire)

??? example "Preuve : action composite (`.github/actions/trivy-scan/action.yml`)"

    ```yaml
    inputs:
      sbom-path:
        required: true            # entrée obligatoire
    runs:
      using: composite
      steps:
        - name: Ensure Trivy is installed   # boîte noire : elle s'installe seule
          shell: bash
          run: command -v trivy >/dev/null 2>&1 || { curl -sfL ... ; sudo install trivy /usr/local/bin/ ; }
        - name: Scan CRITICAL vulnerabilities
          shell: bash
          run: trivy sbom --exit-code 1 --severity CRITICAL --format table "${{ inputs.sbom-path }}"
        - name: Summarize HIGH and MEDIUM     # avertissement seulement
          shell: bash
          run: trivy sbom --exit-code 0 --severity HIGH,MEDIUM ... >> "$GITHUB_STEP_SUMMARY"
    ```

## Déploiement continu

- [x] Frontend GitHub Pages, `main` uniquement, OIDC (`pages` + `id-token: write`)
- [x] `upload-pages-artifact` du `/frontend` + `deploy-pages` (hermétique)
- [x] Backend Vercel, `needs` sécurité + livraison, secrets en RAM

??? example "Preuve : frontend en OIDC (`ci-cd.yml`, job `deploy-frontend`)"

    ```yaml
    if: github.ref == 'refs/heads/main'
    needs: [test, gitleaks, codeql, sbom-scan, docker-image]
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    permissions:
      pages: write
      id-token: write
    ```

??? example "Preuve : backend Vercel, secrets injectés à la volée (`ci-cd.yml`)"

    ```bash
    vercel pull --yes --environment=production --token "$VERCEL_TOKEN"
    vercel deploy backend --prod --yes --token "$VERCEL_TOKEN" "${env_args[@]}"   # --env=K=V en RAM
    ```

## Robustesse

- [x] Concurrence annulante (`cancel-in-progress: true`)
- [x] Healthcheck `curl --fail /api/health`, échec si ≠ 200

??? example "Preuve : concurrence et healthcheck (`ci-cd.yml`)"

    ```yaml
    concurrency:
      group: ci-cd-${{ github.ref }}
      cancel-in-progress: true

    # ... en fin de job deploy-backend :
    - name: Healthcheck
      run: curl --fail --silent --show-error "${{ steps.vercel.outputs.url }}/api/health"
    ```
