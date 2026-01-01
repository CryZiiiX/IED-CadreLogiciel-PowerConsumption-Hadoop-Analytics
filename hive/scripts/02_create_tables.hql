-- /*****************************************************************************************************
-- Nom : hive/scripts/02_create_tables.hql
-- Rôle : Script HiveQL de création des tables Hive pour l'analyse de consommation électrique
-- Auteur : Maxime BRONNY
-- Version : V1
-- Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
-- Usage :
--     Pour compiler : N/A (script HiveQL)
--     Pour executer : hive -f 02_create_tables.hql
-- ******************************************************************************************************/

USE consommation_elec;

-- ============================================================
-- Table 1 : consumption_raw
-- Table externe pointant vers les données brutes HDFS
-- ============================================================
DROP TABLE IF EXISTS consumption_raw;

CREATE EXTERNAL TABLE consumption_raw (
    `date` STRING COMMENT 'Date de la mesure (DD/MM/YYYY)',
    `time` STRING COMMENT 'Heure de la mesure (HH:MM:SS)',
    global_active_power DOUBLE COMMENT 'Puissance active globale (kilowatts)',
    global_reactive_power DOUBLE COMMENT 'Puissance réactive globale (kilowatts)',
    voltage DOUBLE COMMENT 'Tension moyenne (volts)',
    global_intensity DOUBLE COMMENT 'Intensité globale moyenne (ampères)',
    sub_metering_1 DOUBLE COMMENT 'Sous-compteur 1 - Cuisine (watt-heure)',
    sub_metering_2 DOUBLE COMMENT 'Sous-compteur 2 - Lave-linge/Climatisation (watt-heure)',
    sub_metering_3 DOUBLE COMMENT 'Sous-compteur 3 - Chauffe-eau/Climatisation (watt-heure)'
)
COMMENT 'Table externe contenant les données brutes de consommation électrique'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION '/user/projet/data/raw'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'serialization.null.format'='?'
);

-- ============================================================
-- Table 2 : conso_par_jour
-- Résultats du Job 1 MapReduce (Agrégation par jour)
-- ============================================================
DROP TABLE IF EXISTS conso_par_jour;

CREATE EXTERNAL TABLE conso_par_jour (
    `date` STRING COMMENT 'Date (DD/MM/YYYY)',
    avg_consumption DOUBLE COMMENT 'Consommation moyenne (kW)',
    min_consumption DOUBLE COMMENT 'Consommation minimale (kW)',
    max_consumption DOUBLE COMMENT 'Consommation maximale (kW)',
    `count` BIGINT COMMENT 'Nombre de mesures'
)
COMMENT 'Statistiques de consommation par jour (résultat Job 1 MapReduce)'
-- NOTE: Cette table a un problème d'alignement des colonnes due au format MapReduce
-- Format MapReduce: date<TAB>avg,min,max,count  
-- Pour Q5 (pic annuel), utiliser directement consumption_raw au lieu de cette table
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/projet/output/job1_region_avg';

-- ============================================================
-- Table 3 : pics_journaliers
-- Résultats du Job 2 MapReduce (Détection des pics)
-- ============================================================
DROP TABLE IF EXISTS pics_journaliers;

CREATE EXTERNAL TABLE pics_journaliers (
    `date` STRING COMMENT 'Date (DD/MM/YYYY)',
    peak1_time STRING COMMENT 'Heure du 1er pic',
    peak1_value DOUBLE COMMENT 'Valeur du 1er pic (kW)',
    peak2_time STRING COMMENT 'Heure du 2ème pic',
    peak2_value DOUBLE COMMENT 'Valeur du 2ème pic (kW)',
    peak3_time STRING COMMENT 'Heure du 3ème pic',
    peak3_value DOUBLE COMMENT 'Valeur du 3ème pic (kW)'
)
COMMENT 'Top 3 des pics de consommation par jour (résultat Job 2 MapReduce)'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/projet/output/job2_peaks';

-- ============================================================
-- Table 4 : comparaison_jours
-- Résultats du Job 3 MapReduce (Comparaison week-end)
-- ============================================================
DROP TABLE IF EXISTS comparaison_jours;

CREATE EXTERNAL TABLE comparaison_jours (
    day_type STRING COMMENT 'Type de jour: weekday ou weekend',
    avg_consumption DOUBLE COMMENT 'Consommation moyenne (kW)',
    min_consumption DOUBLE COMMENT 'Consommation minimale (kW)',
    max_consumption DOUBLE COMMENT 'Consommation maximale (kW)',
    `count` BIGINT COMMENT 'Nombre de mesures'
)
COMMENT 'Comparaison consommation semaine vs week-end (résultat Job 3 MapReduce)'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/projet/output/job3_weekend';

-- Afficher les tables créées
SHOW TABLES;

-- Afficher le schéma des tables
DESCRIBE consumption_raw;
DESCRIBE conso_par_jour;
DESCRIBE pics_journaliers;
DESCRIBE comparaison_jours;

