<div align="center">
  <img src="https://img.shields.io/badge/FiveM-Script-orange?style=for-the-badge&logo=fivem&logoColor=white" />
  <img src="https://img.shields.io/badge/Framework-ESX-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Author-BloodLeak-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-All%20Rights%20Reserved-red?style=for-the-badge" />
  
  <h1>👥 BloodMulticharacter (bl_multicharacter)</h1>
  <p><i>Gestionnaire de personnages moderne, fluide et immersif pour votre serveur FiveM</i></p>
</div>

---

## 📖 À propos

**BloodMulticharacter** est un système de sélection et création multi-personnages conçu avec une approche moderne (thème BloodLeak Red), des transitions de caméra immersives inspirées de GTA Online et une optimisation extrême (0.00ms au repos). Entièrement synchronisé avec la base de données SQL et votre framework ESX, il garantit une expérience utilisateur fluide dès la connexion au serveur.

---

## ✨ Fonctionnalités Clés

- 🎬 **Transition Caméra Cinématique :** Interpolation fluide du ciel vers le sol (style GTA Online) lors du spawn de personnage, évitant les crashs de streaming et le passage sous la map.
- 🎨 **Interface Moderne BloodLeak :** Design sombre aux accents rouges (`#E50914`), cartes de personnages dynamiques avec statut en ligne/hors-ligne, fiche d'identité complète (Job, Argent liquide, Banque, Date de naissance).
- 🧬 **Création de Personnage Intégrée :** Formulaire de création rapide (Prénom, Nom, Date de naissance, Sexe, Taille) lié directement au créateur d'apparence (`bl_appearance`).
- 🔢 **Gestion de Slots Dynamique :** Support configurable jusqu'à 4 slots de personnages par joueur avec permissions de déblocage.
- 🛡️ **Sécurité & Intégrité SQL :** Vérification stricte des identifiants et slots côté serveur pour empêcher toute duplication d'inventaire ou usurpation de personnage.
- 🔇 **Masquage Intelligent des HUDs :** Suppression automatique de la minimap, du chat, de la voix et des HUDs serveur (`bl_hud_player`, `esx_hud`, etc.) pendant la sélection de personnage.
- 🔄 **Système de Relog Intégré :** Commande `/mc` permettant aux joueurs de changer de personnage en jeu avec sauvegarde propre et déconnexion sécurisée ESX.

---

## 📋 Prérequis

Pour fonctionner de manière optimale, le script nécessite :
- [**es_extended**](https://github.com/esx-framework/esx-legacy) (Legacy ou versions ESX standards)
- [**oxmysql**](https://github.com/overextended/oxmysql) (ou mysql-async)
- [**bl_appearance**](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_appearance) (ou skinchanger / esx_skin)

---

## 🚀 Installation & Configuration

1. **Ressource :** Placez le dossier `bl_multicharacter` dans le répertoire `resources/` de votre serveur.
2. **Configuration :** Ajustez les coordonnées de spawn, positions de caméra et nombre de slots dans [config.lua](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_multicharacter/config.lua).
3. **Démarrage :** Ajoutez la ligne suivante dans votre fichier `server.cfg` (avant ou après vos scripts principaux) :
   ```cfg
   ensure bl_multicharacter
   ```

---

## 🎮 Commandes & Événements

- **`/mc` :** Permet à un joueur en jeu de se déconnecter proprement de son personnage actuel pour retourner au menu de sélection.
- **`bl_multicharacter:relog` (Server Event) :** Événement serveur déclenchant la sauvegarde des données et le retour au multicharacter.

---

<div align="center">
  <p><i>Développé avec passion par <b>BloodLeak</b>. Des designs haut de gamme et des performances optimisées pour votre communauté FiveM.</i></p>
</div>
