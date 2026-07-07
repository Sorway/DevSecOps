# SAST & scan d'images

Deux moteurs d'analyse de sécurité, chacun **bloquant** selon sa criticité.

## CodeQL (analyse statique)

Le job `codeql` analyse le JavaScript avec le pack `security-extended`, **téléverse le SARIF**, puis
**échoue** si une vulnérabilité majeure est détectée.

```yaml
codeql:
  needs: test
  permissions:
    contents: read
    security-events: write        # isolé à ce job
  steps:
    - uses: github/codeql-action/init@v4
      with:
        languages: javascript-typescript
        queries: security-extended
    - uses: github/codeql-action/analyze@v4
      with: { output: codeql-results, upload: false }
    - uses: github/codeql-action/upload-sarif@v4
      with: { sarif_file: codeql-results/javascript.sarif }
    - name: Fail on CodeQL high severity
      run: |
        jq -e '[ .runs[].results[]
          | select((.level=="error") or (.properties["security-severity"] // "0" | tonumber >= 7.0))
        ] | length == 0' codeql-results/javascript.sarif
```

!!! failure "Critère d'échec"
    Le `jq -e` renvoie un code non nul (job en échec) dès qu'un résultat est de niveau `error` **ou**
    de `security-severity ≥ 7.0` (High/Critical). Une faille de sécurité majeure **bloque** donc la CD.

## Trivy (SBOM + image)

Trivy intervient à deux endroits, avec des politiques distinctes :

| Cible | Étape | Politique |
|-------|-------|-----------|
| **SBOM** (CycloneDX) | job `sbom-scan` via la [composite action](composite-action.md) | échec sur `CRITICAL` ; `HIGH`/`MEDIUM` → avertissement |
| **Image Docker** | job `docker-image` | échec sur `HIGH` **ou** `CRITICAL` avant publication |

```yaml
- name: Scan backend image
  if: steps.filter.outputs.backend == 'true'
  run: trivy image --exit-code 1 --severity HIGH,CRITICAL "${{ steps.meta.outputs.image }}"
```

## Conséquence sur la CD

Les jobs de déploiement dépendent (`needs`) de `codeql`, `gitleaks`, `sbom-scan` et `docker-image`.
Si **CodeQL trouve une faille**, si **Gitleaks lève une alerte**, ou si le **scan d'image échoue**,
le pipeline s'arrête et **bloque tout déploiement**.
