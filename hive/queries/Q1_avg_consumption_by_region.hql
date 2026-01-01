-- /*****************************************************************************************************
-- Nom : hive/queries/Q1_avg_consumption_by_region.hql
-- Rôle : Requête HiveQL Q1 - Consommation moyenne par jour (TOP 10 jours)
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f Q1_avg_consumption_by_region.hql
-- ******************************************************************************************************/

USE consommation_elec;

SELECT 
    `date`,
    avg_consumption AS consommation_moyenne,
    min_consumption AS consommation_min,
    max_consumption AS consommation_max,
    `count` AS nombre_mesures
FROM conso_par_jour
ORDER BY avg_consumption DESC
LIMIT 10;

