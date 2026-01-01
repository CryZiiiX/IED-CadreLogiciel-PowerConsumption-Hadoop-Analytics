-- /*****************************************************************************************************
-- Nom : hive/queries/04_requetes_analytiques.hql
-- Rôle : Script HiveQL regroupant toutes les requêtes analytiques (Q1 à Q5)
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f 04_requetes_analytiques.hql
-- ******************************************************************************************************/

USE consommation_elec;

-- ============================================================
-- Q1 : Consommation moyenne par jour (TOP 10 jours)
-- ============================================================
SELECT 'Q1: Top 10 jours par consommation moyenne' AS query_name;

SELECT 
    `date`,
    avg_consumption,
    min_consumption,
    max_consumption,
    `count` AS nombre_mesures
FROM conso_par_jour
ORDER BY avg_consumption DESC
LIMIT 10;

-- ============================================================
-- Q2 : Évolution mensuelle de la consommation
-- ============================================================
SELECT 'Q2: Évolution mensuelle' AS query_name;

SELECT 
    -- Extraire année-mois de la date (format DD/MM/YYYY) avec fonctions de date Hive
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

-- ============================================================
-- Q3 : Comparaison semaine vs week-end
-- ============================================================
SELECT 'Q3: Comparaison semaine vs week-end' AS query_name;

SELECT 
    day_type,
    avg_consumption AS consommation_moyenne,
    min_consumption AS consommation_min,
    max_consumption AS consommation_max,
    `count` AS nombre_mesures,
    -- Calculer la différence en pourcentage
    CASE 
        WHEN day_type = 'weekend' THEN
            ROUND(((avg_consumption - 
                (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) /
                (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) * 100, 2)
        ELSE NULL
    END AS difference_pourcent
FROM comparaison_jours
ORDER BY day_type;

-- ============================================================
-- Q4 : Distribution horaire (heures de pointe)
-- ============================================================
SELECT 'Q4: Distribution horaire - heures de pointe' AS query_name;

SELECT 
    SUBSTRING(`time`, 1, 2) AS heure,
    COUNT(*) AS nombre_mesures,
    AVG(global_active_power) AS consommation_moyenne,
    MAX(global_active_power) AS consommation_max,
    MIN(global_active_power) AS consommation_min
FROM consumption_raw
WHERE global_active_power IS NOT NULL
GROUP BY SUBSTRING(`time`, 1, 2)
ORDER BY consommation_moyenne DESC
LIMIT 10;

-- ============================================================
-- Q5 : Pic de consommation annuel (par année)
-- ============================================================
SELECT 'Q5: Pic de consommation annuel' AS query_name;

-- CORRECTION : Utiliser consumption_raw pour obtenir le vrai pic annuel (max_consumption de conso_par_jour contient le count)
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

-- ============================================================
-- Requête Bonus : Analyse des pics journaliers
-- ============================================================
SELECT 'Bonus: Analyse des pics journaliers' AS query_name;

SELECT 
    `date`,
    peak1_value AS premier_pic,
    peak1_time AS heure_premier_pic,
    peak2_value AS deuxieme_pic,
    peak3_value AS troisieme_pic,
    (peak1_value - peak3_value) AS ecart_pics
FROM pics_journaliers
WHERE peak1_value IS NOT NULL
ORDER BY peak1_value DESC
LIMIT 20;

