# Conformité aux consignes

Récapitulatif exigence par exigence, avec le lien vers l'implémentation. :material-check-decagram:

## Gouvernance Git

- [x] `staging` pivot d'intégration, CI complète à chaque événement — [détails](gouvernance.md)
- [x] `main` production, push directs interdits (ruleset `REVIEW_REQUIRED`)
- [x] `on: push/pull_request: [staging, main]`
- [x] Blocs `if: github.ref == 'refs/heads/main'` + matrice `needs` stricte
- [x] Job de production lié à un `environment` nommé (`production` / `github-pages`)

## Durcissement local

- [x] Hook `pre-commit` : `actionlint` + `gitleaks --staged` (bloquants) — [détails](shift-left.md)
- [x] Contrôle de structure `.env` / `.pem` / `.key` + message rouge, commit avorté
- [x] Règle Gitleaks sur-mesure `SECWALLET_[A-Z0-9]{24}` + entropie

## Secrets par enveloppe

- [x] Paire de clés **age** (privée `ops.txt`, ignorée par Git) — [détails](secrets.md)
- [x] `.github/secrets-prod.yaml` chiffré SOPS : valeurs `ENC[...]`, clés lisibles (`encrypted_regex`)
- [x] Déchiffrement runtime **en RAM**, aucun secret sur le disque du runner

## Conteneurisation & GHCR

- [x] `Dockerfile` multi-stage, non-root (`node:24-alpine`) — [détails](conteneurisation.md)
- [x] Build conditionné au filtrage de chemins (`dorny/paths-filter`)
- [x] Scan de l'image (Trivy `HIGH,CRITICAL`) avant publication
- [x] Publication GHCR conditionnelle (scan OK + `main`), tag = SHA du commit

## Pipeline CI durci

- [x] `permissions: contents: read` global, écritures isolées au job — [détails](ci.md)
- [x] Cache des dépendances Node
- [x] CodeQL + upload SARIF, échec sur `High`/`Error` — [détails](sast.md)
- [x] Tests bloquants ; Gitleaks exit ≠ 0 ; **aucun `continue-on-error: true`**

## Composite Action

- [x] `.github/actions/trivy-scan/action.yml` de type composite — [détails](composite-action.md)
- [x] Entrée obligatoire = chemin du SBOM CycloneDX JSON
- [x] `trivy sbom` : échec sur `CRITICAL`, avertissement sur `HIGH`/`MEDIUM`
- [x] Installe Trivy elle-même (boîte noire réutilisable)

## Déploiement continu

- [x] Frontend GitHub Pages, `main` uniquement, OIDC (`pages` + `id-token: write`) — [détails](deploiement.md)
- [x] `upload-pages-artifact` du `/frontend` + `deploy-pages` (hermétique)
- [x] Backend Vercel en CLI, `needs` sécurité + livraison
- [x] Déchiffrement SOPS en RAM, injection à la volée (`--env`)

## Robustesse

- [x] Concurrence annulante (`cancel-in-progress: true`) — [détails](robustesse.md)
- [x] Healthcheck `curl --fail /api/health`, échec si ≠ 200

---

!!! success "Livrables"
    - **Frontend** : [sorway.github.io/DevSecOps](https://sorway.github.io/DevSecOps/)
    - **API** : [projet-final-inky-iota.vercel.app](https://projet-final-inky-iota.vercel.app) (`/api/health`)
    - **Dépôt** : [github.com/Sorway/DevSecOps](https://github.com/Sorway/DevSecOps)
