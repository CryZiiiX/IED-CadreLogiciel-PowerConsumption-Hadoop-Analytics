-- /*****************************************************************************************************
-- Nom : hive/scripts/05_exports.hql
-- Rôle : Script HiveQL d'export des résultats analytiques vers HDFS en format CSV
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f 05_exports.hql
-- ******************************************************************************************************/

USE consommation_elec;

-- Répertoire d'export
SET hive.exec.dynamic.partition.mode=nonstrict;

-- Export Q1 : Top 10 jours
INSERT OVERWRITE DIRECTORY '/user/projet/export/q1_top_days'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT 
    `date`,
    avg_consumption,
    min_consumption,
    max_consumption,
    `count`
FROM conso_par_jour
ORDER BY avg_consumption DESC
LIMIT 10;

-- Export Q2 : Évolution mensuelle
-- Utilisation de fonctions de date Hive pour garantir un format cohérent
INSERT OVERWRITE DIRECTORY '/user/projet/export/q2_monthly_evolution'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT 
    CONCAT(
        YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
        '-',
        LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
    ) AS year_month,
    AVG(avg_consumption) AS consommation_moyenne,
    MIN(min_consumption) AS consommation_min,
    MAX(max_consumption) AS consommation_max,
    SUM(`count`) AS total_mesures
FROM conso_par_jour
WHERE `date` IS NOT NULL AND UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy') IS NOT NULL
GROUP BY CONCAT(
    YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
    '-',
    LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
)
ORDER BY year_month;

-- Export Q3 : Comparaison week-end
INSERT OVERWRITE DIRECTORY '/user/projet/export/q3_weekend_comparison'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT 
    day_type,
    avg_consumption,
    min_consumption,
    max_consumption,
    `count`
FROM comparaison_jours
ORDER BY day_type;

-- Export Q4 : Distribution horaire
INSERT OVERWRITE DIRECTORY '/user/projet/export/q4_hourly_distribution'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT 
    SUBSTRING(`time`, 1, 2) AS heure,
    COUNT(*) AS nombre_mesures,
    AVG(global_active_power) AS consommation_moyenne,
    MAX(global_active_power) AS consommation_max
FROM consumption_raw
WHERE global_active_power IS NOT NULL
GROUP BY SUBSTRING(`time`, 1, 2)
ORDER BY consommation_moyenne DESC;

-- Export Q5 : Pic annuel
-- CORRECTION : Le problème est que max_consumption contient en fait le count (1440)
-- Solution : Utiliser directement la table consumption_raw pour calculer le vrai pic annuel
INSERT OVERWRITE DIRECTORY '/user/projet/export/q5_annual_peak'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT 
    CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))) AS STRING) AS annee,
    MAX(global_active_power) AS pic_annuel,
    AVG(global_active_power) AS consommation_moyenne
FROM consumption_raw
WHERE `date` IS NOT NULL 
  AND UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy') IS NOT NULL
  AND global_active_power IS NOT NULL
GROUP BY CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))) AS STRING)
ORDER BY annee;

-- Afficher les répertoires d'export créés
SELECT 'Exports terminés. Vérifier avec: hdfs dfs -ls /user/projet/export/' AS status;

