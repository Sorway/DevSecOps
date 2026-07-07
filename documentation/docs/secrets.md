# Secrets par enveloppe (SOPS / age)

La philosophie GitOps exige qu'**aucun secret de production ne soit stocké en clair**, tout en
laissant l'équipe Ops **auditer les structures de fichiers**.

## Génération des clés

Une paire de clés asymétriques est générée avec **age**. La clé privée est nommée `ops.txt`
(ignorée par Git) ; la clé publique sert de destinataire du chiffrement.

```bash
age-keygen -o ops.txt   # privée → ops.txt (jamais commitée)
```

## Chiffrement sélectif

Le fichier [`.github/secrets-prod.yaml`](https://github.com/Sorway/DevSecOps/blob/main/.github/secrets-prod.yaml)
contient les clés de production. **SOPS** ne chiffre que les *valeurs* : les *clés* YAML restent
lisibles, pour des `git diff` propres et auditables.

```yaml
production:
    DATABASE_URL: ENC[AES256_GCM,data:…,type:str]   # ← valeur chiffrée
    JWT_SECRET:   ENC[AES256_GCM,data:…,type:str]
    API_KEY:      ENC[AES256_GCM,data:…,type:str]
sops:
    encrypted_regex: ^(DATABASE_URL|JWT_SECRET|API_KEY)$   # ← seules ces valeurs
```

!!! tip "Pourquoi `encrypted_regex`"
    Il cible les valeurs à chiffrer par leur clé. Les noms de champs (`DATABASE_URL`…) restent en
    clair, donc un reviewer voit *la structure* du fichier évoluer sans jamais voir les secrets.

## Déchiffrement au runtime — 100 % en RAM

En CD, le secret GitHub `SOPS_AGE_KEY` (la clé privée age) est fourni **en variable d'environnement**.
SOPS le lit **nativement en mémoire** ; le fichier est déchiffré en RAM et les valeurs sont injectées
à la volée dans la commande de déploiement Vercel.

```bash
# La clé privée reste UNIQUEMENT en mémoire (variable d'environnement).
SOPS_AGE_KEY="$(printf '%s' "$SOPS_AGE_KEY" | tr -d '\r')"
export SOPS_AGE_KEY
secrets_json="$(sops -d --output-type json .github/secrets-prod.yaml)"   # ← en RAM, aucun fichier
```

!!! danger "Aucun secret sur le disque du runner"
    Pas de `mktemp`, pas de `SOPS_AGE_KEY_FILE` : la clé privée n'est **jamais écrite** sur le disque
    du runner GitHub, conformément à la consigne. Le déchiffrement est purement en mémoire.

Voir la mise en œuvre complète dans [Déploiement continu](deploiement.md).
