#!/usr/bin/env bash
set -uo pipefail

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

echo "Verification pre-commit..."

ACTIONLINT_BIN="$(command -v actionlint.exe || command -v actionlint || true)"
GITLEAKS_BIN="$(command -v gitleaks.exe || command -v gitleaks || true)"

if [[ -z "$ACTIONLINT_BIN" && -x "/mnt/c/Users/jonat/AppData/Local/UniGetUI/Chocolatey/bin/actionlint.exe" ]]; then
    ACTIONLINT_BIN="/mnt/c/Users/jonat/AppData/Local/UniGetUI/Chocolatey/bin/actionlint.exe"
fi

if [[ -z "$GITLEAKS_BIN" && -x "/mnt/c/Users/jonat/AppData/Local/UniGetUI/Chocolatey/bin/gitleaks.exe" ]]; then
    GITLEAKS_BIN="/mnt/c/Users/jonat/AppData/Local/UniGetUI/Chocolatey/bin/gitleaks.exe"
fi

if [[ -z "$ACTIONLINT_BIN" ]]; then
    echo -e "${RED}Erreur : actionlint est introuvable. Installe actionlint avant de commit.${RESET}"
    exit 1
fi

if [[ -z "$GITLEAKS_BIN" ]]; then
    echo -e "${RED}Erreur : gitleaks est introuvable. Installe gitleaks avant de commit.${RESET}"
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
        echo -e "${RED}Securite : Tentative de commit d'un fichier de configuration ou d'une cle en clair. Operation annulee.${RESET}"
        exit 1
    fi
done <<< "$staged_files"

if [[ -z "$staged_files" ]]; then
    echo -e "${GREEN}Aucun fichier staged a verifier pour la structure.${RESET}"
fi
echo -e "${GREEN}Aucun fichier interdit detecte${RESET}"

echo "Validation GitHub Actions avec actionlint..."
"$ACTIONLINT_BIN"
echo -e "${GREEN}actionlint OK${RESET}"

echo "Scan des secrets staged avec gitleaks..."
if "$GITLEAKS_BIN" detect --help 2>/dev/null | grep -q -- "--staged"; then
    "$GITLEAKS_BIN" detect --staged --config gitleaks.toml --verbose </dev/null
elif "$GITLEAKS_BIN" protect --help 2>/dev/null | grep -q -- "--staged"; then
    "$GITLEAKS_BIN" protect --staged --config gitleaks.toml --verbose </dev/null
elif [[ -n "$staged_files" ]]; then
    git diff --cached --name-only -z --diff-filter=ACMR |
        while IFS= read -r -d '' file; do
            git show ":$file" | "$GITLEAKS_BIN" stdin --config gitleaks.toml --verbose
        done
else
    echo "Aucun fichier staged a scanner avec gitleaks."
fi
echo -e "${GREEN}gitleaks OK${RESET}"

echo -e "${GREEN}Commit autorise OK${RESET}"
