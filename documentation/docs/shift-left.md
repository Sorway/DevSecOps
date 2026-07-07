# Durcissement local (Shift-Left)

Avant qu'une seule ligne n'atteigne GitHub, le hook **`scripts/pre-commit.sh`** garantit l'intégrité
des commits sur le poste de travail. Il agit comme une **barrière locale**.

![GitHub Actions](assets/github_actions.png){ height="52" }

## Installation

Le hook est **versionné** (donc auditable et réinstallable). Sur un nouveau clone :

=== "Bash / Git Bash"

    ```bash
    git config core.hooksPath scripts/hooks
    # ou
    bash scripts/install-hooks.sh
    ```

=== "PowerShell"

    ```powershell
    .\scripts\install-hooks.ps1
    .\scripts\install-hook-tools.ps1
    ```

## Les trois contrôles séquentiels

Le hook **bloque le commit** (`exit ≠ 0`) si l'un des trois échoue :

1. **`actionlint`** sur l'ensemble de `.github/workflows/` — bloque en cas d'erreur de workflow.
2. **`gitleaks`** sur les modifications **indexées uniquement** (`--staged`) — bloque si un secret est trouvé.
3. **Contrôle de structure strict** : si un fichier `.env` / `.pem` / `.key` est présent dans l'index,
   le commit est **avorté immédiatement** avec un message rouge explicite.

!!! danger "Message d'erreur (contrôle de structure)"
    ```
    Sécurité : Tentative de commit d'un fichier de configuration ou d'une clé en clair. Opération annulée.
    ```

!!! note "Barrière réellement bloquante"
    Le hook capture le code de retour d'`actionlint` et de `gitleaks` : un échec **interrompt** le
    commit (il n'affiche pas « OK » à tort). Les trois contrôles sont donc de vraies barrières.

## Règle Gitleaks sur-mesure

![Gitleaks](assets/Gitleaks.png){ height="46" }

Fichier [`gitleaks.toml`](https://github.com/Sorway/DevSecOps/blob/main/gitleaks.toml) : interception
des jetons internes de l'entreprise, préfixe `SECWALLET_` suivi d'**exactement 24 caractères
alphanumériques majuscules**, combinée à une vérification d'**entropie**.

```toml
[[rules]]
id       = "secwallet-internal-token"
regex    = '''SECWALLET_[A-Z0-9]{24}'''
entropy  = 3.5
keywords = ["SECWALLET_"]
```

La même règle est réutilisée par le job Gitleaks en CI (voir [Pipeline CI durci](ci.md)),
garantissant une détection cohérente entre le poste et le pipeline.
