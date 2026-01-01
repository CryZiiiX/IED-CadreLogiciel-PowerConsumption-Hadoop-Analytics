-- /*****************************************************************************************************
-- Nom : hive/queries/Q4_monthly_evolution.hql
-- Rôle : Requête HiveQL Q4 - Distribution horaire de consommation (heures de pointe)
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f Q4_monthly_evolution.hql
-- ******************************************************************************************************/

USE consommation_elec;

SELECT 
    SUBSTRING(`time`, 1, 2) AS heure,
    COUNT(*) AS nombre_mesures,
    AVG(global_active_power) AS consommation_moyenne,
    MAX(global_active_power) AS consommation_max,
    MIN(global_active_power) AS consommation_min
FROM consumption_raw
WHERE global_active_power IS NOT NULL
GROUP BY SUBSTRING(`time`, 1, 2)
ORDER BY consommation_moyenne DESC;

