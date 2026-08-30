<div align="center">
  <img src="https://img.shields.io/badge/FiveM-Script-orange?style=for-the-badge&logo=fivem&logoColor=white" />
  <img src="https://img.shields.io/badge/Framework-ESX-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Author-BloodLeak-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-All%20Rights%20Reserved-red?style=for-the-badge" />
  
  <h1>👥 BloodMulticharacter (bl_multicharacter)</h1>
  <p><i>Gestionnaire de personnages moderne, immersif et ultra-personnalisé pour serveurs FiveM</i></p>
</div>

---

## 📖 À propos

**BloodMulticharacter** est un système de sélection et création multi-personnages haut de gamme combinant une interface minimaliste et élégante, des transitions de caméra cinématiques inspirées de GTA Online, et une gestion avancée des privilèges **VIP** et **STAFF**.

Optimisé à 0.00ms au repos, il synchronise en temps réel la base de données SQL avec votre framework ESX tout en protégeant les scènes RP en cours.

---

## ✨ Fonctionnalités Clés

### 👑 Système d'Emplacements Distincts (Free, VIP & Staff)
- **Emplacement 01 (Public / Gratuit) :** Accessible à tous les joueurs dès leur première connexion.
- **Emplacements 02 & 03 (VIP — Édition Or Royal & Ambre) :** 
  - Dégradés or métalliques (`#ffd700` / `#ffc107`), bordures dorées et badges couronne `<i class="fa-solid fa-crown"></i>`.
  - Accessible aux membres VIP, Donateurs et au Staff.
- **Emplacement 04 (STAFF — Édition Cyber Crimson & Améthyste) :** 
  - Dégradés néon rouge rubis & améthyste (`#ff2a55` / `#a855f7`), barres néon éclatantes et badges bouclier `<i class="fa-solid fa-shield-halved"></i>`.
  - Strictement réservé aux membres de l'Administration / Modération / Direction.
- **Identité Visuelle Permanente :** Même une fois déverrouillés ou occupés par un personnage, les slots VIP et Staff conservent leurs bordures néon, leurs couleurs et leurs badges distinctifs.

### 🛡️ Détection & Sécurité Multi-Tables
- Détection multi-sources automatique :
  - **Table `bl_staff` (`bl_admin`)** via colonne `grade`.
  - **Table `users` / ESX** via colonne `group` et `xPlayer.getGroup()`.
  - **Whitelists manuelles** par licence Rockstar dans [config.lua](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_multicharacter/config.lua) (`Config.VIPLicenses` et `Config.StaffLicenses`).
- Sécurité côté serveur stricte interdisant toute création non autorisée sur les slots verrouillés.

### 📍 Sélecteur de Spawn & Dispersion Anti-Stacking
- Menu de destination immersif (Dernière position, Aéroport, Gare Centrale, Plage de Del Perro, Sandy Shores...).
- **Dispersion intelligente :** Décalage radial aléatoire (1.2m à 3.0m) et rotation naturelle pour éviter que plusieurs joueurs arrivant au même endroit ne se superposent ou ne bloquent les collisions.

### 👻 Protection de Spawn & Mode Fantôme (4 secondes)
- Dès l'arrivée dans le monde, le personnage passe en **mode semi-transparent fantôme** (`alpha 140`) et devient **invincible pendant 4 secondes**.
- Transition fluide d'opacité vers la visibilité normale afin de préserver l'immersion et éviter d'interrompre les scènes RP en cours.

### 📱 Attribution & Persistance du Numéro de Téléphone
- Générateur automatique de numéros de téléphone réalistes (`555-XXXX`).
- Attribution instantanée et sauvegarde en base de données lors de la création d'un citoyen ou au chargement de personnages existants.

### 🎬 Cinématique GTA Online & Masquage Intelligent des HUDs
- Interpolation fluide du ciel vers le sol avec chargement préalable des collisions dans le noir (élimine les chutes sous la map).
- Masquage automatique du radar, du chat, de la voix et de tous les HUDs serveur pendant l'utilisation de l'interface.

### 🔄 Changement de Personnage en Jeu (/mc)
- Commande `/mc` pour changer de personnage avec cooldown configurable (bypass automatique pour les membres VIP & Staff).

---

## 📋 Configuration (`config.lua`)

```lua
Config.Slots = {
    [1] = { type = 'free',  label = "Emplacement 1" },
    [2] = { type = 'vip',   label = "Emplacement 2 (VIP)" },
    [3] = { type = 'vip',   label = "Emplacement 3 (VIP)" },
    [4] = { type = 'staff', label = "Emplacement 4 (STAFF)" }
}

-- Grades autorisés pour les slots VIP (2 & 3)
Config.VIPGrades = {
    ['vip'] = true,
    ['vip_gold'] = true,
    ['vip_diamond'] = true,
    ['premium'] = true,
    ['donateur'] = true
}

-- Grades autorisés pour le slot STAFF (4) et slots VIP
Config.StaffGrades = {
    ['mod'] = true,
    ['moderateur'] = true,
    ['admin'] = true,
    ['superadmin'] = true,
    ['gerant'] = true,
    ['fondateur'] = true,
    ['owner'] = true,
    ['boss'] = true,
    ['responsable'] = true,
    ['staff'] = true,
    ['dev'] = true
}
```

---

## 🚀 Installation

1. Placez le dossier `bl_multicharacter` dans votre répertoire de ressources.
2. Ajoutez dans votre `server.cfg` :
   ```cfg
   ensure bl_multicharacter
   ```
3. Démarrez votre serveur.

---

## 🎮 Commandes & Événements

| Commande / Événement | Type | Description |
| :--- | :--- | :--- |
| `/mc` | Commande | Déconnexion propre du personnage en jeu pour ouvrir le multicharacter |
| `bl_multicharacter:relog` | Server Event | Déclenche la sauvegarde et la transition vers le menu de sélection |
| `bl_multicharacter:setupCharacters` | Client Event | Rafraîchit instantanément la liste des personnages dans le NUI |

---

<div align="center">
  <p><i>Développé avec passion par <b>BloodLeak</b>. Des designs haut de gamme et des performances optimisées pour votre communauté FiveM.</i></p>
</div>
