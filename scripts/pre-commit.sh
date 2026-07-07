#!/usr/bin/env bash
set -uo pipefail

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

echo "Verification pre-commit..."

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_BIN_DIR="$HOOK_DIR/bin"

ACTIONLINT_BIN="$(command -v actionlint.exe || command -v actionlint || true)"
GITLEAKS_BIN="$(command -v gitleaks.exe || command -v gitleaks || true)"

if [[ -z "$ACTIONLINT_BIN" && -x "$HOOK_BIN_DIR/actionlint.exe" ]]; then
    ACTIONLINT_BIN="$HOOK_BIN_DIR/actionlint.exe"
fi

if [[ -z "$ACTIONLINT_BIN" && -x "$HOOK_BIN_DIR/actionlint" ]]; then
    ACTIONLINT_BIN="$HOOK_BIN_DIR/actionlint"
fi

if [[ -z "$GITLEAKS_BIN" && -x "$HOOK_BIN_DIR/gitleaks.exe" ]]; then
    GITLEAKS_BIN="$HOOK_BIN_DIR/gitleaks.exe"
fi

if [[ -z "$GITLEAKS_BIN" && -x "$HOOK_BIN_DIR/gitleaks" ]]; then
    GITLEAKS_BIN="$HOOK_BIN_DIR/gitleaks"
fi

if [[ -z "$ACTIONLINT_BIN" ]]; then
    echo -e "${RED}Erreur : actionlint est introuvable. Lance .\\scripts\\install-hook-tools.ps1 puis recommence le commit.${RESET}"
    exit 1
fi

if [[ -z "$GITLEAKS_BIN" ]]; then
    echo -e "${RED}Erreur : gitleaks est introuvable. Lance .\\scripts\\install-hook-tools.ps1 puis recommence le commit.${RESET}"
    exit 1
fi

staged_files="$(git diff --cached --name-only --diff-filter=ACMR)"

echo "Controle de structure..."
while IFS= read -r file; do
    file="${file%$'\r'}"

    if [[ -z "$file" ]]; then
        continue
    fi

    if [[ "$file" == ".env" || "$file" == */.env || "$file" == *.env || "$file" == *.pem || "$file" == *.key ]]; then
        echo -e "${RED}Sécurité : Tentative de commit d'un fichier de configuration ou d'une clé en clair. Opération annulée.${RESET}"
        exit 1
    fi
done <<< "$staged_files"

if [[ -z "$staged_files" ]]; then
    echo -e "${GREEN}Aucun fichier staged a verifier pour la structure.${RESET}"
fi
echo -e "${GREEN}Aucun fichier interdit detecte${RESET}"

echo "Validation GitHub Actions avec actionlint..."
if ! "$ACTIONLINT_BIN"; then
    echo -e "${RED}actionlint a detecte des erreurs dans les workflows. Commit annule.${RESET}"
    exit 1
fi
echo -e "${GREEN}actionlint OK${RESET}"

echo "Scan des secrets staged avec gitleaks..."
gitleaks_status=0
if "$GITLEAKS_BIN" detect --help 2>/dev/null | grep -q -- "--staged"; then
    "$GITLEAKS_BIN" detect --staged --config gitleaks.toml --verbose </dev/null || gitleaks_status=$?
elif "$GITLEAKS_BIN" protect --help 2>/dev/null | grep -q -- "--staged"; then
    "$GITLEAKS_BIN" protect --staged --config gitleaks.toml --verbose </dev/null || gitleaks_status=$?
elif [[ -n "$staged_files" ]]; then
    while IFS= read -r -d '' file; do
        git show ":$file" | "$GITLEAKS_BIN" stdin --config gitleaks.toml --verbose || gitleaks_status=$?
    done < <(git diff --cached --name-only -z --diff-filter=ACMR)
else
    echo "Aucun fichier staged a scanner avec gitleaks."
fi
if [[ "$gitleaks_status" -ne 0 ]]; then
    echo -e "${RED}gitleaks a detecte un secret dans les fichiers staged. Commit annule.${RESET}"
    exit 1
fi
echo -e "${GREEN}gitleaks OK${RESET}"

echo -e "${GREEN}Commit autorise OK${RESET}"
