-- ==========================================================
-- 👥 BloodMulticharacter (bl_multicharacter) - SQL Import
-- ==========================================================
-- Ce script SQL est optionnel si vous possédez déjà une base ESX Legacy standard.
-- Il permet d'ajouter les colonnes recommandées et la table optionnelle pour le staff.

-- 1. Ajout des colonnes de téléphone, SSN et temps de jeu si elles n'existent pas dans la table users
ALTER TABLE `users` 
    ADD COLUMN IF NOT EXISTS `phone_number` VARCHAR(20) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `ssn` VARCHAR(20) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `playtime` INT DEFAULT 0;

-- 2. (Optionnel) Table de gestion du STAFF / ADMINS pour les permissions d'emplacements
-- Si vous gérez déjà vos staffs via le groupe ESX (`group` dans `users`) ou via config.lua, cette table n'est pas obligatoire.
CREATE TABLE IF NOT EXISTS `bl_staff` (
    `identifier` VARCHAR(60) NOT NULL,
    `grade` VARCHAR(50) NOT NULL DEFAULT 'mod',
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
