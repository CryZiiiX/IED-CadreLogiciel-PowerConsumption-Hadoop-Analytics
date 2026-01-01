# PowerConsumption-Hadoop-Analytics

## Résumé

Ce projet d'analyse Big Data traite un dataset de consommation électrique de plus de 2 millions de mesures (période 2006-2010, source UCI Machine Learning Repository) en utilisant l'écosystème Hadoop. L'objectif est d'identifier des patterns temporels de consommation (heures de pointe, évolution mensuelle, différences semaine/week-end) à travers un pipeline complet allant du stockage distribué HDFS aux analyses SQL avec Hive, en passant par le traitement distribué MapReduce. Les résultats sont ensuite visualisés via des scripts Python pour produire des insights exploitables.

## Fonctionnalités

- **Stockage distribué** : Chargement du dataset dans HDFS avec structuration des répertoires
- **Traitement MapReduce** : 3 jobs MapReduce implémentés en Java
  - Agrégation de la consommation par jour (moyenne, min, max, nombre de mesures)
  - Détection des 3 pics journaliers de consommation
  - Comparaison statistique entre jours de semaine et week-end
- **Analyses Hive** : 5 requêtes analytiques SQL pour identifier les patterns de consommation
- **Export et visualisation** : Export des résultats en CSV puis génération de graphiques Python

## Architecture

Le pipeline suit une architecture séquentielle standard Big Data :

1. **Ingestion** : Upload du dataset CSV (`household_power_consumption.txt`) vers HDFS
2. **Traitement MapReduce** : Exécution des 3 jobs MapReduce sur les données brutes stockées dans HDFS
3. **Stockage des résultats** : Les sorties MapReduce sont stockées dans HDFS sous forme de fichiers texte délimités
4. **Data Warehouse Hive** : Création de tables externes Hive pointant vers les résultats MapReduce et les données brutes
5. **Requêtes analytiques** : Exécution de requêtes HiveQL pour les analyses avancées (TOP 10, agrégations mensuelles, distributions horaires)
6. **Export** : Export des résultats Hive vers HDFS puis copie locale en CSV
7. **Visualisation** : Scripts Python (pandas, matplotlib, seaborn) pour générer les graphiques finaux

### Structure du projet

```
PROJET/
├── README.md                                    # Documentation principale du projet
├── requirements.txt                             # Dépendances Python (pandas, matplotlib, seaborn)
├── household_power_consumption.txt              # Dataset source (UCI, 2M+ lignes)
│
├── config/                                      # Configuration
│   └── yarn-site.xml                            # Configuration YARN pour allocation mémoire
│
├── data/                                        # Données et résultats
│   ├── raw/                                     # Données brutes (préparation)
│   ├── processed/                               # Données nettoyées (optionnel)
│   ├── export/                                  # Exports CSV depuis Hive
│   │   ├── Q1_Top10_Jours.csv                  # Top 10 jours consommation
│   │   ├── Q2_Evolution_Mensuelle.csv          # Évolution mensuelle
│   │   ├── Q3_Comparaison_Weekend.csv          # Comparaison semaine/week-end
│   │   ├── Q4_Distribution_Horaire.csv         # Distribution par heure
│   │   ├── Q5_Pic_Annuel.csv                   # Pics annuels
│   │   └── README.md                            # Documentation des exports
│   └── visualizations/                          # Graphiques générés
│       ├── Q1_Top10_Jours.png                  # Visualisation TOP 10
│       ├── Q2_Evolution_Mensuelle.png          # Graphique évolution
│       ├── Q3_Comparaison_Weekend.png          # Comparaison semaine/week-end
│       ├── Q4_Distribution_Horaire.png         # Distribution horaire
│       └── Q5_Pic_Annuel.png                   # Pics annuels
│
├── mapreduce/                                   # Module MapReduce (Java)
│   ├── pom.xml                                  # Configuration Maven
│   ├── README.md                                # Documentation MapReduce
│   └── src/main/java/com/projet/               # Code source Java
│       ├── RegionAvgDriver.java                 # Driver Job 1 : Agrégation par jour
│       ├── RegionAvgMapper.java                 # Mapper Job 1
│       ├── RegionAvgReducer.java                # Reducer Job 1
│       ├── PeakDetectionDriver.java             # Driver Job 2 : Détection pics
│       ├── PeakDetectionMapper.java             # Mapper Job 2
│       ├── PeakDetectionReducer.java            # Reducer Job 2
│       ├── WeekendComparisonDriver.java         # Driver Job 3 : Comparaison week-end
│       ├── WeekendComparisonMapper.java         # Mapper Job 3
│       └── WeekendComparisonReducer.java        # Reducer Job 3
│
├── hive/                                        # Module Hive (SQL)
│   ├── scripts/                                 # Scripts de configuration
│   │   ├── 01_create_database.hql              # Création base de données
│   │   ├── 02_create_tables.hql                # Création tables externes
│   │   ├── 03_load_data.hql                    # Vérification chargement données
│   │   └── 05_exports.hql                      # Export résultats vers HDFS
│   └── queries/                                 # Requêtes analytiques
│       ├── 04_requetes_analytiques.hql         # Toutes les requêtes (Q1-Q5)
│       ├── Q1_avg_consumption_by_region.hql    # Q1 : Top 10 jours
│       ├── Q2_daily_peaks.hql                  # Q2 : Pics journaliers
│       ├── Q3_weekend_comparison.hql           # Q3 : Comparaison week-end
│       ├── Q4_monthly_evolution.hql            # Q4 : Évolution mensuelle
│       └── Q5_hourly_distribution.hql          # Q5 : Distribution horaire
│
├── scripts/                                     # Scripts d'automatisation
│   ├── data/                                    # Scripts de traitement données
│   │   ├── explore_dataset.py                  # Exploration du dataset
│   │   ├── validate_format.py                  # Validation format CSV
│   │   └── clean_and_normalize.py              # Nettoyage données
│   ├── execution/                               # Scripts d'exécution
│   │   ├── build_mapreduce.sh                  # Compilation jobs MapReduce
│   │   └── run_mapreduce_jobs.sh               # Exécution des 3 jobs
│   ├── hdfs/                                    # Scripts HDFS
│   │   └── create_structure.sh                 # Création structure répertoires HDFS
│   ├── export/                                  # Scripts d'export
│   │   └── export_results.sh                   # Copie résultats HDFS → local
│   ├── visualization/                           # Scripts de visualisation
│   │   ├── generate_graphs.py                  # Génération graphiques Python
│   │   ├── requirements.txt                    # Dépendances Python
│   │   └── README.md                           # Documentation visualisations
│   └── demo/                                    # Scripts de démonstration
│       └── demo_script.sh                      # Affichage état projet (présentation)
│
├── tests/                                       # Tests et validation
│   ├── README.md                                # Documentation tests
│   ├── unit/                                    # Tests unitaires
│   │   ├── test_mapreduce_job1.sh              # Test Job 1 MapReduce
│   │   ├── test_mapreduce_job2.sh              # Test Job 2 MapReduce
│   │   └── test_mapreduce_job3.sh              # Test Job 3 MapReduce
│   ├── integration/                             # Tests d'intégration
│   │   ├── test_hdfs_integration.sh            # Test intégration HDFS
│   │   └── test_hive_integration.sh            # Test intégration Hive
│   ├── validation/                              # Scripts de validation
│   │   ├── validate_mapreduce_output.sh        # Validation sorties MapReduce
│   │   ├── validate_hive_tables.sh             # Validation tables Hive
│   │   └── validate_hive_queries.sh            # Validation requêtes Hive
│   └── results/                                 # Résultats des tests
│
└── docs/                                        # Documentation détaillée
    ├── RAPPORT/                                 # Rapport final
    └── VIDEO/                                   # Ressources vidéo 
```

## Stack technique

- **Hadoop 3.3.6** : Framework de traitement distribué
  - HDFS : Système de fichiers distribué
  - MapReduce : Modèle de programmation pour traitement distribué
  - YARN : Gestionnaire de ressources
- **Hive 3.1.3** : Data warehouse SQL sur Hadoop
- **Java 8** : Langage pour les implémentations MapReduce (Maven pour la compilation)
- **Python 3** : Langage pour les scripts de visualisation
  - pandas : Manipulation et analyse de données
  - matplotlib : Génération de graphiques
  - seaborn : Visualisations statistiques avancées
- **Maven 3.6+** : Outil de build et gestion des dépendances Java

## Prérequis

- Environnement Linux (Ubuntu/Debian recommandé)
- Java JDK 8 (compatible avec Hadoop 3.3.6)
- Hadoop 3.3.6 installé et configuré
- Hive 3.1.3 installé et configuré
- Maven 3.6+ installé
- Python 3.7+ avec les bibliothèques pandas, matplotlib, seaborn

## Installation

L'installation et la configuration de Hadoop et Hive ne sont pas détaillées dans ce dépôt. Pour garantir la reproductibilité et éviter les erreurs de configuration, référez-vous aux ressources suivantes :

- **Vidéo 1** : https://www.youtube.com/watch?v=eBlDBUy_610
- **Vidéo 2** : https://www.youtube.com/watch?v=LMrW2BFeRh8

Les descriptions de ces vidéos contiennent un lien vers un Google Drive proposant les commandes prêtes à l'emploi pour installer et configurer Hadoop et Hive. Cette approche assure une installation correcte et reproductible de l'environnement Big Data.

## Configuration

Les variables d'environnement suivantes doivent être configurées :

- `JAVA_HOME` : Chemin vers l'installation Java
- `HADOOP_HOME` : Chemin vers l'installation Hadoop
- `HIVE_HOME` : Chemin vers l'installation Hive
- `PATH` : Doit inclure `$HADOOP_HOME/bin`, `$HADOOP_HOME/sbin`, `$HIVE_HOME/bin`

[À compléter] : Détails de configuration spécifiques (fichiers de configuration Hadoop/Hive modifiés)

## Utilisation

Le projet fournit un guide de démarrage détaillé dans `START.md`. Résumé des étapes principales :

### 1. Compilation MapReduce

```bash
cd scripts/execution
./build_mapreduce.sh
```

Le JAR est généré dans `mapreduce/target/mapreduce-consumption-1.0.jar`

### 2. Création de la structure HDFS

```bash
cd scripts/hdfs
./create_structure.sh
```

### 3. Chargement des données

```bash
hdfs dfs -put household_power_consumption.txt /user/projet/data/raw/
```

### 4. Exécution des jobs MapReduce

```bash
cd scripts/execution
./run_mapreduce_jobs.sh ../../mapreduce/target/mapreduce-consumption-1.0.jar
```

### 5. Configuration Hive

```bash
cd hive/scripts
hive -f 01_create_database.hql
hive -f 02_create_tables.hql
hive -f 03_load_data.hql
```

### 6. Requêtes analytiques

```bash
cd hive/queries
hive -f 04_requetes_analytiques.hql
```

### 7. Export des résultats

```bash
cd hive/scripts
hive -f 05_exports.hql
cd ../../scripts/export
./export_results.sh
```

### 8. Génération des visualisations

```bash
cd scripts/visualization
python3 generate_graphs.py
```

Les graphiques sont générés dans `data/visualizations/`

## Données

**Source** : UCI Machine Learning Repository  
**Dataset** : Household Electric Power Consumption  
**URL** : https://archive.ics.uci.edu/ml/datasets/individual+household+electric+power+consumption

**Caractéristiques** :
  
  - Format : CSV avec séparateur point-virgule (`;`)
  - Volume : 133 MB, plus de 2 millions de lignes
  - Période : Décembre 2006 - Novembre 2010 (47 mois)
  - Fréquence : 1 mesure par minute
  - Colonnes principales : Date, Time, Global_active_power (kilowatts), sous-compteurs

**Organisation HDFS** :

- Données brutes : `/user/projet/data/raw/`
- Résultats MapReduce : `/user/projet/output/job1_region_avg`, `job2_peaks`, `job3_weekend`
- Exports Hive : `/user/projet/export/`

## Résultats et analyses

Les analyses produites permettent d'identifier plusieurs patterns de consommation :

- **TOP 10 des jours** avec la consommation moyenne la plus élevée
- **Évolution mensuelle** de la consommation sur la période 2006-2010
- **Comparaison semaine/week-end** avec calcul des différences en pourcentage
- **Distribution horaire** des consommations pour identifier les heures de pointe
- **Pics annuels** de consommation par année

Les résultats sont disponibles en CSV dans `data/export/` et en graphiques PNG dans `data/visualizations/`.

## Limites et pistes d'amélioration

**Limites actuelles** :

- Traitement en mode pseudo-distribué (mono-nœud), non adapté à de très gros volumes
- Pipeline séquentiel non orchestré (exécution manuelle étape par étape)
- Pas de gestion d'erreurs robuste dans les scripts
- Format de sortie MapReduce avec alignement de colonnes à améliorer


**Pistes d'amélioration** :

- Migration vers Apache Spark pour un traitement plus performant et flexible
- Automatisation complète du pipeline (Apache Airflow, Oozie)
- Optimisation des requêtes Hive (partitionnement)
- Ajout de tests automatisés pour la validation des résultats
- Implémentation de la gestion des erreurs et de la reprise sur erreur


## Auteur

**Maxime BRONNY**  
Master 1 Informatique - Spécialisation Big Data  
Réalisé dans le cadre du cours "Cadre logiciel pour le big data"  
Année universitaire 2025-2026

