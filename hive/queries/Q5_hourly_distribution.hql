-- /*****************************************************************************************************
-- Nom : hive/queries/Q5_hourly_distribution.hql
-- Rôle : Requête HiveQL Q5 - Pic de consommation annuel par année
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f Q5_hourly_distribution.hql
-- ******************************************************************************************************/

USE consommation_elec;

-- CORRECTION : Utiliser consumption_raw pour obtenir le vrai pic annuel
SELECT 
    CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))) AS STRING) AS annee,
    MAX(global_active_power) AS pic_annuel,
    AVG(global_active_power) AS consommation_moyenne_annuelle,
    MIN(global_active_power) AS consommation_min_annuelle,
    COUNT(DISTINCT `date`) AS nombre_jours
FROM consumption_raw
WHERE `date` IS NOT NULL 
  AND UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy') IS NOT NULL
  AND global_active_power IS NOT NULL
GROUP BY CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))) AS STRING)
ORDER BY annee;

