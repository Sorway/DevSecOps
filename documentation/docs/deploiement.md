# Déploiement continu

Le déploiement ne se déclenche **que si toute la CI est verte** et **uniquement sur `main`**.

## Frontend → GitHub Pages

![GitHub Pages](assets/github_pages.png){ height="24" }

Publication hermétique via **OIDC**, sans laisser de trace de build dans l'historique Git.

```yaml
deploy-frontend:
  if: github.ref == 'refs/heads/main'
  needs: [test, gitleaks, codeql, sbom-scan, docker-image]
  environment:
    name: github-pages
    url: ${{ steps.deployment.outputs.page_url }}   # ← URL exposée
  permissions:
    pages: write
    id-token: write                                  # ← OIDC
  steps:
    - name: Upload frontend artifact
      uses: actions/upload-pages-artifact@v5
      with: { path: frontend }
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v5
```

:material-web: **En ligne** : [sorway.github.io/DevSecOps](https://sorway.github.io/DevSecOps/)
· :material-book-open-variant: cette documentation est publiée en sous-chemin `/docs/`.

## Backend → Vercel

![Node.js](assets/nodejs.png){ height="24" }
![Vercel](assets/vercel.png){ height="24" }

Déploiement piloté **en ligne de commande** dans GitHub Actions, secrets déchiffrés **en RAM**.

```yaml
deploy-backend:
  if: github.ref == 'refs/heads/main'
  needs: [test, gitleaks, codeql, sbom-scan, docker-image]
  environment: production
  steps:
    - name: Deploy backend to Vercel
      env:
        SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
        VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
      run: |
        export SOPS_AGE_KEY
        secrets_json="$(sops -d --output-type json .github/secrets-prod.yaml)"   # ← RAM
        mapfile -t env_args < <(node -e '…--env=K=V…' "$secrets_json")
        vercel pull --yes --environment=production --token "$VERCEL_TOKEN"
        vercel deploy backend --prod --yes --token "$VERCEL_TOKEN" "${env_args[@]}"
```

Les secrets (`DATABASE_URL`, `JWT_SECRET`, `API_KEY`) sont injectés **à la volée** via `--env`, sans
qu'aucun fichier en clair ne touche le disque du runner (voir [Secrets](secrets.md)).

:material-server: **En ligne** : [projet-final-inky-iota.vercel.app](https://projet-final-inky-iota.vercel.app)

!!! info "Authentification machine-to-machine"
    Les secrets GitHub `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_ORG_ID` et `SOPS_AGE_KEY` sont
    stockés chiffrés dans le dépôt et injectés uniquement à l'exécution.
