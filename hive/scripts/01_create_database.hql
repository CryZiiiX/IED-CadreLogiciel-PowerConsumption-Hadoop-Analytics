-- /*****************************************************************************************************
-- Nom : hive/scripts/01_create_database.hql
-- Rôle : Script HiveQL de création de la base de données consommation_elec
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f 01_create_database.hql
-- ******************************************************************************************************/

-- Créer la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS consommation_elec
COMMENT 'Base de données pour l''analyse de consommation électrique'
LOCATION '/user/hive/warehouse/consommation_elec.db';

-- Utiliser la base de données
USE consommation_elec;

-- Afficher la confirmation
SHOW DATABASES LIKE 'consommation_elec';

