# SecureWallet, une chaîne de livraison sécurisée ! ♾️

![CI/CD sécurisée](assets/ci-cd.webp){ .hero }

## Projet final DevSecOps · M1 Cloud, Sécurité & Infrastructure

<div class="hero-logos">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo_ynov_campus_sophia_white.png">
    <img src="assets/logo_ynov_campus_sophia.png" alt="Sophia Ynov Campus">
  </picture>
  <img src="assets/devsecops.png" alt="DevSecOps">
</div>

**SecureWallet** industrialise une SPA statique et une API **Node.js** ![Node.js](assets/nodejs.png){ .inline-logo } / Express en une **chaîne CI/CD durcie**, auditable et infalsifiable. L'image backend **Docker** ![Docker](assets/docker.png){ .inline-logo } (multi-stage, non-root) est scannée par **Trivy** ![Trivy](assets/trivy.png){ .inline-logo } puis publiée sur **GHCR**. Le code passe au crible de **CodeQL** ![CodeQL](assets/codeql.png){ .inline-logo }, les secrets sont traqués par **Gitleaks** ![Gitleaks](assets/Gitleaks.png){ .inline-logo } et chiffrés par enveloppe avec **SOPS** ![SOPS](assets/sops.png){ .inline-logo } + age.

Le tout est orchestré par **GitHub Actions** ![GitHub Actions](assets/github_actions.png){ .inline-logo } et déployé sur **GitHub Pages** ![GitHub Pages](assets/github_pages.png){ .inline-logo } (frontend, via OIDC) et **Vercel** ![Vercel](assets/vercel.png){ .inline-logo } (backend). Ce projet conclut un bloc de formation d'environ **28 h** de DevSecOps à Sophia Ynov Campus, en filière Cloud, Sécurité & Infrastructure.

[:material-web: Frontend](https://sorway.github.io/DevSecOps/){ .md-button .md-button--primary }
[:material-server: API](https://projet-final-inky-iota.vercel.app){ .md-button }
[:material-github: Dépôt](https://github.com/Sorway/DevSecOps){ .md-button }

## L'Équipe sur ce lab

<div class="team">
  <div class="member m-blue">
    <a href="https://github.com/astronas"><img src="https://avatars.githubusercontent.com/u/184748371?v=4" alt="Thibaut Gianola"></a>
    <strong>Thibaut Gianola</strong>
    <a class="handle" href="https://github.com/astronas">@astronas</a>
  </div>
  <div class="member m-purple">
    <a href="https://github.com/Sorway"><img src="https://avatars.githubusercontent.com/u/38928488?v=4" alt="Jonathan Panzer"></a>
    <strong>Jonathan Panzer</strong>
    <a class="handle" href="https://github.com/Sorway">@Sorway</a>
  </div>
  <div class="member m-green">
    <a href="https://github.com/Tiwen2"><img src="https://avatars.githubusercontent.com/u/238646488?v=4" alt="Redouane Kachour"></a>
    <strong>Redouane Kachour</strong>
    <a class="handle" href="https://github.com/Tiwen2">@tiwen2</a>
  </div>
</div>

## De quoi s'agit-il ?

Quand une entreprise met en ligne une application qui manipule des données sensibles (comptes, clés
d'accès, informations personnelles), le vrai danger n'est pas seulement dans le code lui-même : il
est dans **tout ce qui l'entoure**. Qui a le droit de modifier quoi ? Un mot de passe oublié dans un
fichier, une faille glissée sans le vouloir, une image serveur vulnérable... comment les repère-t-on
**avant** qu'ils n'arrivent chez les utilisateurs ?

Ce projet construit cette **chaîne de sécurité automatisée** autour d'une petite application web. À
chaque modification du code, une série de contrôles se lance toute seule : recherche de secrets
oubliés, analyse du code à la recherche de failles, scan des vulnérabilités, tests automatiques. Tant
que tout n'est pas au vert, rien n'est mis en ligne, et chaque action reste tracée et vérifiable.

Cette documentation raconte, étape par étape, **comment** on l'a construite. 

Elle s'adresse à trois publics :

- Au **correcteur**, pour vérifier point par point que le cahier des charges est respecté !
- A un **développeur curieux**, pour voir concrètement à quoi ressemble un pipeline
  DevSecOps industriel de bout en bout...
- A **nous**, l'équipe, comme mémoire technique du projet.

## Comment lire cette documentation ?


1. **[Contexte & consignes](contexte.md)** : Le travail qui nous a été demandé, l'analyse qu'on en a fait, et les projections faites...
2. **[Implémentation](architecture.md)** : Le détail technique de la production, section par section.
3. **[Conformité](conformite.md)** : La couverture de l'énoncé, exigence par exigence !

<div class="page-home"></div>
