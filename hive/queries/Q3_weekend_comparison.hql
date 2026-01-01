-- /*****************************************************************************************************
-- Nom : hive/queries/Q3_weekend_comparison.hql
-- Rôle : Requête HiveQL Q3 - Comparaison de consommation entre semaine et week-end
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f Q3_weekend_comparison.hql
-- ******************************************************************************************************/

USE consommation_elec;

SELECT 
    day_type AS type_jour,
    avg_consumption AS consommation_moyenne,
    min_consumption AS consommation_min,
    max_consumption AS consommation_max,
    `count` AS nombre_mesures,
    CASE 
        WHEN day_type = 'weekend' THEN
            ROUND(((avg_consumption - 
                (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) /
                (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) * 100, 2)
        ELSE NULL
    END AS difference_pourcent_vs_semaine
FROM comparaison_jours
ORDER BY day_type;

