# SecureWallet

Chaîne de livraison **auditable, hermétique et infalsifiable** pour une SPA statique et une API
Node.js manipulant des données sensibles. Projet final du module DevSecOps avancé, Sophia Ynov Campus.

[:material-web: Frontend](https://sorway.github.io/DevSecOps/){ .md-button .md-button--primary }
[:material-server: API](https://projet-final-inky-iota.vercel.app){ .md-button }
[:material-github: Dépôt](https://github.com/Sorway/DevSecOps){ .md-button }

![Node.js](assets/nodejs.png){ .logo-strip }
![Docker](assets/docker.png){ .logo-strip }
![Trivy](assets/trivy.png){ .logo-strip }
![CodeQL](assets/codeql.png){ .logo-strip }
![Gitleaks](assets/Gitleaks.png){ .logo-strip }
![SOPS](assets/sops.png){ .logo-strip }
![GitHub Actions](assets/github_actions.png){ .logo-strip }
![GitHub Pages](assets/github_pages.png){ .logo-strip }
![Vercel](assets/vercel.png){ .logo-strip }

## En bref

Deux composants, une seule chaîne CI/CD durcie. Le code des développeurs passe par une branche
d'intégration, la production n'accepte que du code techniquement validé, et chaque secret reste
chiffré de bout en bout.

```mermaid
flowchart LR
    dev([Développeur]):::actor --> hook[Hook pre-commit]:::warn
    hook --> stg[(staging)]:::info
    stg --> pr[PR + revue]:::warn
    pr --> main[(main)]:::prod
    main --> ci[CI durcie]:::info
    ci --> deploy[Déploiement]:::ok
    classDef actor fill:#495057,stroke:#343a40,color:#fff;
    classDef info fill:#1c7ed6,stroke:#1971c2,color:#fff;
    classDef warn fill:#f59f00,stroke:#e8590c,color:#fff;
    classDef ok fill:#12b886,stroke:#0ca678,color:#fff;
    classDef prod fill:#0b7285,stroke:#095c6b,color:#fff;
```

| Composant | Rôle | Livraison |
|-----------|------|-----------|
| `frontend/` | SPA statique (HTML / CSS / JS moderne) qui consomme l'API | GitHub Pages (OIDC) |
| `backend/` | API REST Node.js / Express, données sensibles | Docker → GHCR + Vercel |

## Comment lire cette documentation

1. **[Contexte & consignes](contexte.md)** : ce qu'on nous demande, et comment on s'y prend.
2. **[Implémentation](architecture.md)** : le détail technique, section par section.
3. **[Conformité](conformite.md)** : la couverture de l'énoncé, exigence par exigence.
