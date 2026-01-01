-- /*****************************************************************************************************
-- Nom : hive/scripts/03_load_data.hql
-- Rôle : Script HiveQL de chargement et vérification des données dans les tables Hive
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f 03_load_data.hql
-- ******************************************************************************************************/

USE consommation_elec;

-- ============================================================
-- Vérification des données dans les tables
-- ============================================================

-- Vérifier la table des données brutes
SELECT 'Vérification consumption_raw...' AS status;
SELECT COUNT(*) AS total_rows FROM consumption_raw;
SELECT `date`, `time`, global_active_power 
FROM consumption_raw 
LIMIT 10;

-- Vérifier la table conso_par_jour (Job 1)
SELECT 'Vérification conso_par_jour...' AS status;
SELECT COUNT(*) AS total_days FROM conso_par_jour;
SELECT * FROM conso_par_jour 
ORDER BY `date` 
LIMIT 10;

-- Vérifier la table pics_journaliers (Job 2)
SELECT 'Vérification pics_journaliers...' AS status;
SELECT COUNT(*) AS total_days FROM pics_journaliers;
SELECT * FROM pics_journaliers 
ORDER BY `date` 
LIMIT 10;

-- Vérifier la table comparaison_jours (Job 3)
SELECT 'Vérification comparaison_jours...' AS status;
SELECT * FROM comparaison_jours;

-- Statistiques de base sur les données brutes
SELECT 'Statistiques données brutes...' AS status;
SELECT 
    COUNT(*) AS total_mesures,
    COUNT(DISTINCT `date`) AS nombre_jours,
    MIN(global_active_power) AS consommation_min,
    MAX(global_active_power) AS consommation_max,
    AVG(global_active_power) AS consommation_moyenne
FROM consumption_raw
WHERE global_active_power IS NOT NULL;

