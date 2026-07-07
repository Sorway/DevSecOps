# Composite Action : Trivy SBOM

Pour centraliser la gouvernance de sécurité et éviter la redondance, le scan de dépendances au format
SBOM est isolé dans une **action composite** locale, réutilisable en boîte noire.

## Qu'est-ce qu'une action composite

Une action composite empaquette plusieurs `steps` dans une action réutilisable, avec son propre
`action.yml`, s'exécutant dans le contexte du job appelant. Elle masque la complexité opérationnelle
et expose des entrées / sorties strictes.

## L'action `trivy-scan`

![Trivy](assets/trivy.png){ height="24" }

Fichier [`.github/actions/trivy-scan/action.yml`](https://github.com/Sorway/DevSecOps/blob/main/.github/actions/trivy-scan/action.yml).

```yaml
name: Trivy SBOM scan
inputs:
  sbom-path:
    description: Path to the CycloneDX JSON SBOM.
    required: true                 # ← entrée obligatoire
  trivy-version:
    required: false
    default: "0.72.0"
runs:
  using: composite
  steps:
    - name: Ensure Trivy is installed   # ← auto-suffisante (boîte noire)
      shell: bash
      run: |
        command -v trivy >/dev/null 2>&1 || { curl -sfL … | tar … ; sudo install trivy /usr/local/bin/ ; }
    - name: Scan CRITICAL vulnerabilities
      shell: bash
      run: trivy sbom --exit-code 1 --severity CRITICAL --format table "${{ inputs.sbom-path }}"
    - name: Summarize HIGH and MEDIUM     # ← avertissement, non bloquant
      shell: bash
      run: |
        trivy sbom --exit-code 0 --severity HIGH,MEDIUM --format table "${{ inputs.sbom-path }}" >> "$GITHUB_STEP_SUMMARY"
```

!!! abstract "Politique de criticité"
    | Sévérité | Conséquence |
    |----------|-------------|
    | `CRITICAL` | :octicons-x-circle-16: **Échec** du build (`--exit-code 1`) |
    | `HIGH` / `MEDIUM` | :octicons-alert-16: **Avertissement** dans le résumé du workflow, le pipeline continue |

!!! success "Boîte noire portable"
    L'action **installe Trivy elle-même** (étape idempotente) : elle ne dépend pas du job appelant et
    peut être réutilisée telle quelle dans un autre workflow.

## Appel depuis le pipeline

Le SBOM CycloneDX est généré en amont, puis passé à l'action :

```yaml
- name: Generate CycloneDX SBOM
  run: trivy fs --format cyclonedx --output sbom-backend.json backend
- name: Scan SBOM with local composite action
  uses: ./.github/actions/trivy-scan
  with:
    sbom-path: sbom-backend.json
```
