# Contexte & consignes

## Le sujet

**Industrialisation, durcissement et architecture CI/CD.** Une équipe de développement nous confie
le dépôt d'une application scindée en deux composants au sein d'un même dépôt :

- **`frontend/`** : une Single Page Application entièrement statique (HTML, CSS, JavaScript moderne)
  qui consomme l'API.
- **`backend/`** : une API REST Node.js / Express manipulant des **données hautement sensibles**,
  nécessitant des clés d'API et des accès à des infrastructures externes.

!!! quote "Objectif"
    Structurer la gouvernance Git pour **interdire toute action non auditée** et bâtir un flux où le
    code de production est **techniquement validé** avant son déploiement.

## Les exigences, par thème

=== "Gouvernance"

    - `staging` = branche pivot d'intégration (CI complète à chaque événement).
    - `main` = production, **push directs interdits**.
    - Workflow déclenché sur `staging` **et** `main`, blocs `if: github.ref == 'refs/heads/main'`,
      matrice `needs` stricte, job de prod lié à un `environment` nommé.

=== "Durcissement local"

    - Hook `pre-commit` : `actionlint` sur les workflows + `gitleaks` sur les modifications indexées.
    - Règle Gitleaks sur-mesure : jetons `SECWALLET_` + 24 caractères + entropie.
    - Refus des fichiers `.env` / `.pem` / `.key` dans l'index (message rouge, commit avorté).

=== "Secrets"

    - Paire de clés **age** (privée nommée `ops.txt`).
    - `.github/secrets-prod.yaml` chiffré via **SOPS** : seules les **valeurs** deviennent `ENC[...]`,
      les **clés** YAML restent lisibles (`git diff` propres).

=== "Conteneurisation"

    - `Dockerfile` multi-stage (bonnes pratiques).
    - Build Docker conditionné au **filtrage de chemins**.
    - Scan de l'image (Trivy) **avant** publication.
    - Publication sur **GHCR** seulement si le scan réussit, image taggée au **SHA** du commit.

=== "CI durci"

    - `permissions: contents: read` global ; privilèges d'écriture isolés au job.
    - Cache des dépendances Node.
    - **CodeQL** (SARIF) ; échec si vulnérabilité `High`/`Error`.
    - Tests bloquants ; Gitleaks exit ≠ 0 ; **`continue-on-error: true` interdit**.

=== "Composite Action"

    - `.github/actions/trivy-scan/action.yml` de type **composite**.
    - Entrée obligatoire : chemin du SBOM **CycloneDX JSON**.
    - Échec **uniquement** sur `CRITICAL` ; `HIGH`/`MEDIUM` → avertissement dans le résumé.

=== "Déploiement & robustesse"

    - Frontend → **GitHub Pages** (OIDC, artefacts éphémères).
    - Backend → **Vercel** (déchiffrement SOPS en RAM, aucun secret sur disque).
    - Concurrence annulante ; **healthcheck** `/api/health` post-déploiement.

## Livrables

Un fichier texte avec les **URLs Vercel et GitHub Pages** et l'URL du **dépôt public** contenant
l'arborescence complète (frontend, backend, hooks locaux, structure `.github/`) montrant la
protection des branches, le filtrage Docker et le chaînage des dépendances.

!!! success "Vérification"
    La page [Conformité aux consignes](conformite.md) reprend chaque exigence et pointe vers son
    implémentation dans le dépôt.
