-- /*****************************************************************************************************
-- Nom : hive/queries/Q2_daily_peaks.hql
-- Rôle : Requête HiveQL Q2 - Évolution mensuelle de la consommation électrique
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f Q2_daily_peaks.hql
-- ******************************************************************************************************/

USE consommation_elec;

SELECT 
    CONCAT(
        YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
        '-',
        LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
    ) AS year_month,
    AVG(avg_consumption) AS consommation_moyenne_mensuelle,
    MIN(min_consumption) AS consommation_min_mensuelle,
    MAX(max_consumption) AS consommation_max_mensuelle,
    SUM(`count`) AS total_mesures
FROM conso_par_jour
WHERE `date` IS NOT NULL AND UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy') IS NOT NULL
GROUP BY CONCAT(
    YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
    '-',
    LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
)
ORDER BY year_month;

