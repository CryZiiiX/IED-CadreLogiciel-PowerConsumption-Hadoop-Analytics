# PowerConsumption-Hadoop-Analytics
## Application Hadoop (HDFS/YARN/MapReduce/Hive)

**Auteur :** Maxime BRONNY  
**UE :** Cadre logiciel pour le Big Data  
**Date :** Janvier 2025  
**Deadline :** 05 janvier 2025  

---

# Résumé Exécutif

Ce projet implémente une application Big Data complète sur l'écosystème Hadoop pour analyser la consommation électrique d'un dataset **Household Power Consumption** (2 075 260 lignes, 127 MB). Les données sont ingérées dans **HDFS** sous `/user/projet/data/raw`, puis traitées via **3 jobs MapReduce** exécutés sur **YARN** (agrégation journalière, détection de pics, comparaison semaine/week-end). Les résultats MapReduce sont stockés dans **HDFS** (`/user/projet/output/...`) et exploités via **Hive** (base `consommation_elec`, tables + requêtes analytiques Q1–Q5). Les requêtes Hive produisent des exports dans `/user/projet/export/...`, ensuite rapatriés en CSV local (`data/export/`) puis visualisés par un script Python qui génère les graphes finaux (`data/visualizations/`). Le rapport documente la planification, l'architecture du cluster, l'implémentation MapReduce, la modélisation Hive, les tests/validations et une démonstration vidéo reproductible, en s'appuyant sur des preuves (captures UI YARN/NameNode, logs, extraits HQL, sorties `hdfs dfs -ls`).

**Mots-clés :** HDFS, YARN, MapReduce, Hive, ETL, exports, visualisation, consommation électrique

---

# Table des matières

1. [Introduction & objectifs](#1-introduction--objectifs)
2. [Recherche & planification](#2-recherche--planification)
3. [Données (dataset) & préparation](#3-données-dataset--préparation)
4. [Architecture & déploiement Hadoop](#4-architecture--déploiement-hadoop)
5. [Ingestion HDFS & organisation des données](#5-ingestion-hdfs--organisation-des-données)
6. [Développement MapReduce (sous YARN)](#6-développement-mapreduce-sous-yarn)
7. [Data Warehouse Hive : schéma + requêtes analytiques](#7-data-warehouse-hive--schéma--requêtes-analytiques)
8. [Exports & visualisations](#8-exports--visualisations)
9. [Tests, validations & qualité](#9-tests-validations--qualité)
10. [Démonstration vidéo](#10-démonstration-vidéo)
11. [Conclusion, limites, perspectives](#11-conclusion-limites-perspectives)

---

# 1. Introduction & objectifs

## 1.1 Contexte et problématique

Ce projet analyse des mesures de consommation électrique domestique collectées à la minute (dataset *Household Power Consumption*).  
Le besoin est de produire des indicateurs interprétables à plusieurs granularités temporelles (heure, jour, mois, année) pour caractériser les variations de consommation.  
Le traitement visé est **batch** et doit être rejouable : l’objectif est de démontrer une chaîne Hadoop complète, reproductible et traçable.  
Les données sont ingérées et organisées dans HDFS sous une arborescence projet (`/user/projet/...`) afin de servir de source unique aux traitements.  
Les calculs sont exécutés en jobs MapReduce sous YARN, permettant le pilotage des ressources et l’audit de l’exécution (logs, état des applications).  
Les résultats sont interrogés et exportés via Hive, puis restitués sous forme d’exports CSV et de visualisations PNG.

## 1.2 Objectifs techniques

- **HDFS** : ingérer le dataset et standardiser les emplacements HDFS d’entrée/sortie (`/user/projet/data/raw`, `/user/projet/output`, `/user/projet/export`).  
- **YARN** : exécuter et suivre les applications de traitement (états, logs) via le ResourceManager (UI `http://localhost:8088`) (A VERIFIER).  
- **MapReduce (Java)** : implémenter 3 jobs batch (agrégation journalière, pics journaliers, comparaison semaine/week-end) et écrire les résultats dans HDFS.  
- **Hive** : créer la base `consommation_elec`, définir les tables externes sur HDFS, exécuter les requêtes Q1–Q5 et produire les exports.

## 1.3 Objectifs analytiques

- **Q1** : repérer les jours atypiques en classant les journées par consommation moyenne.  
- **Q2** : mettre en évidence tendance et saisonnalité via une agrégation mensuelle.  
- **Q3** : quantifier l’effet “week-end” en comparant des statistiques de consommation entre semaine et week-end.  
- **Q4** : identifier les heures de pointe à partir de la distribution horaire de la consommation.  
- **Q5** : comparer les pics annuels afin de caractériser l’évolution des maxima dans le temps.  

Ces analyses fournissent une lecture temporelle multi-échelle pour interpréter les variations de consommation, sans objectif prédictif.

## 1.4 Livrables

Les livrables produits sont :

- Code MapReduce (Java) + JAR compilé  
- Scripts Hive (`.hql`)  
- Scripts Bash d’exécution/orchestration  
- Exports CSV  
- Visualisations PNG  
- Vidéo de démonstration  
- Rapport PDF  

---

# 2. Recherche & planification

## 2.1 Démarche de recherche

Le sujet a été retenu pour répondre à un besoin simple et mesurable : analyser des variations de consommation électrique dans le temps.  
Le dataset UCI *Household Electric Power Consumption* a été choisi car il est public, documenté et exploitable en batch (fichier texte `;`, dates `DD/MM/YYYY`, valeurs manquantes `?`).  
Son volume (127 MB, 2 075 260 lignes) est suffisant pour justifier un traitement Hadoop tout en restant compatible avec un projet individuel.  
La temporalité (1 mesure/minute) permet de travailler sur plusieurs granularités (heure, jour, mois, année) sans enrichissement externe (A VERIFIER).  
La démarche a consisté à construire un pipeline reproductible HDFS → MapReduce/YARN → Hive → exports, puis à valider chaque étape par des commandes et sorties de scripts.

## 2.2 Découpage du projet

Le projet a été découpé en 5 phases, chacune reliée à une brique Hadoop ou à un livrable :

1. **Ingestion HDFS** : création de l’arborescence `/user/projet/...` et dépôt du dataset dans `/user/projet/data/raw`.  
2. **Packaging MapReduce** : compilation Maven et génération du JAR exécutable.  
3. **Traitements MapReduce sous YARN** : exécution des 3 jobs batch et écriture des résultats dans `/user/projet/output/...`.  
4. **Analyse Hive** : création de la base `consommation_elec`, tables externes sur HDFS et exécution des requêtes Q1–Q5.  
5. **Exports & restitution** : exports Hive dans `/user/projet/export/...`, consolidation en CSV locaux et génération des visualisations PNG.

## 2.3 Risques identifiés et mitigation

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Services HDFS/YARN/Hive non démarrés ou configuration incohérente | Bloquant | Vérifications “fail-fast” dans les scripts (`hdfs dfsadmin -report`, prérequis) + contrôle via UI YARN `http://localhost:8088` (A VERIFIER). |
| Formats d’entrée hétérogènes (séparateur `;`, en-tête, valeurs `?`) | Moyen | Paramétrage Hive (`skip.header.line.count`, `serialization.null.format`) + filtrage/validation côté MapReduce (et scripts de validation) (A VERIFIER). |
| Incompatibilité de formats MapReduce ↔ Hive/exports (TAB + valeurs concaténées) | Moyen | Documenter le format, adapter les tables externes et la chaîne export/visualisation (`hive/scripts/02_create_tables.hql`, `scripts/visualization/generate_graphs.py`). |
| Classpath/dépendances Hadoop au runtime (exécution du JAR) | Moyen | Script d’exécution qui résout les chemins, vérifie le JAR et initialise `HADOOP_CLASSPATH=$(hadoop classpath)` (`scripts/execution/run_mapreduce_jobs.sh`). |

## 2.4 Planning (A VERIFIER)

| Phase | Durée estimée | Livrable | Statut |
|-------|---------------|----------|--------|
| Recherche & choix du dataset | 0.5–1 j (A VERIFIER) | Cadrage + source de données | Terminé |
| Mise en place environnement Hadoop/Hive | 1–2 j (A VERIFIER) | Services opérationnels + config | Terminé (A VERIFIER) |
| Développement & packaging MapReduce (3 jobs) | 2–3 j (A VERIFIER) | JAR + scripts d’exécution | Terminé |
| Hive (tables + requêtes + exports) | 1–2 j (A VERIFIER) | Scripts `.hql` + exports HDFS | Terminé |
| Exports locaux + visualisations + validations | 0.5–1 j (A VERIFIER) | CSV + PNG + scripts de test | Terminé |
| Rédaction du rapport | 1–2 j (A VERIFIER) | PDF | En cours |
| Vidéo de démonstration | 0.5 j (A VERIFIER) | Fichier ou lien vidéo | À faire |

---

# 3. Données (dataset) & préparation

## 3.1 Source du dataset

Le dataset utilisé est **Individual household electric power consumption** (UCI Machine Learning Repository), fichier `household_power_consumption.txt`.  
Il est public, documenté et stable, ce qui facilite la reproductibilité du pipeline.  
Son format texte et sa série temporelle régulière sont adaptés à une ingestion HDFS et à un traitement batch Hadoop.

## 3.2 Volume et caractéristiques

- **Taille du fichier :** 127 MB  
- **Nombre de lignes :** 2 075 260 (en-tête inclus)  
- **Période couverte :** 16/12/2006 → 26/11/2010  
- **Fréquence :** 1 mesure par minute (A VERIFIER : régularité parfaite sur toute la période)

**Preuve (nombre de lignes) :**
```bash
$ wc -l household_power_consumption.txt
2075260 household_power_consumption.txt
```

## 3.3 Format et schéma des données

- **Séparateur** : `;`  
- **Date / heure** : `DD/MM/YYYY` et `HH:MM:SS`  
- **Valeurs manquantes** : `?` (converties en `NULL` côté Hive via `serialization.null.format='?'`)  

Le schéma est directement mappé vers une table externe Hive (`consumption_raw`) : deux champs temporels en `STRING` et des champs numériques en `DOUBLE`.

| Champ | Type (Hive) | Format / règle |
|------|-------------|----------------|
| `Date` | STRING | `DD/MM/YYYY` |
| `Time` | STRING | `HH:MM:SS` |
| `Global_active_power` | DOUBLE | décimal `.` ; `?` possible |
| `Global_reactive_power` | DOUBLE | décimal `.` ; `?` possible |
| `Voltage` | DOUBLE | décimal `.` ; `?` possible |
| `Global_intensity` | DOUBLE | décimal `.` ; `?` possible |
| `Sub_metering_1` | DOUBLE | décimal `.` ; `?` possible |
| `Sub_metering_2` | DOUBLE | décimal `.` ; `?` possible |
| `Sub_metering_3` | DOUBLE | décimal `.` ; `?` possible |

## 3.4 Préparation et nettoyage

Les traitements suivants sont appliqués au moment de la lecture (Hive et/ou jobs batch), sans “pré-traitement” lourd avant l’upload HDFS :

- **Ignorer l’en-tête** : via `skip.header.line.count='1'` (Hive) et filtrage côté jobs si la ligne correspond à l’en-tête.  
- **Filtrer les valeurs manquantes** : gestion de `?` (conversion en `NULL` côté Hive et exclusion des lignes non exploitables côté jobs).  
- **Parsing contrôlé** : découpage par `;`, suppression des espaces, vérification du nombre de champs attendus.  
- **Conversion de types** : conversion des champs numériques en `DOUBLE` (lignes non parsables ignorées et comptabilisées via compteurs Hadoop) (A VERIFIER : compteurs exacts).  
- **Validations simples** : exclusion des valeurs incohérentes (ex. puissance négative) (A VERIFIER : règles exactes par job).  

---

# 4. Architecture & déploiement Hadoop

## 4.1 Environnement de déploiement

**Mode de déploiement :** pseudo-distribué sur **1 nœud** (tous les services Hadoop sur la même machine).  
**Machine :** poste local / VM (A VERIFIER : CPU/RAM/disque).  
**Système d’exploitation :** Linux (Ubuntu/Debian) (A VERIFIER : version).  

Ce choix est pertinent pour un projet académique : il réduit la charge d’administration tout en démontrant l’usage réel de **HDFS**, **YARN**, **MapReduce** et **Hive** sur une chaîne de traitement complète.  
**Limites** : absence de cluster multi-nœuds (pas de distribution réelle ni de tolérance aux pannes à l’échelle d’un cluster), et performances dépendantes d’une seule machine.

## 4.2 Versions et dépendances logicielles

Les versions retenues assurent la compatibilité entre l’exécution Hadoop et le packaging Java des jobs MapReduce.

| Composant | Version | Rôle dans le projet |
|----------|---------|---------------------|
| Hadoop | 3.3.6 | HDFS + YARN + runtime MapReduce |
| Hive | 3.1.3 (A VERIFIER) | exécution SQL + exports sur données HDFS |
| Java | JDK 8 (A VERIFIER) | compilation/exécution des jobs MapReduce |
| Maven | 3.6+ (A VERIFIER) | packaging du JAR MapReduce |

**Preuve version Hadoop :**
```bash
$ hadoop version
Hadoop 3.3.6
Source code repository https://github.com/apache/hadoop.git -r 1be78238728da9266a4f88195058f08fd012bf9c
Compiled by ubuntu on 2023-06-18T08:22Z
```

## 4.3 Architecture des services Hadoop

L’application repose sur les services suivants (tous exécutés localement, en pseudo-distribué) :

- **HDFS (stockage)**  
  - **NameNode** : gestion de l’espace de noms HDFS et des métadonnées (répertoires/fichiers).  
  - **DataNode** : stockage des blocs de données.  
  - Usage projet : centraliser les entrées/sorties du pipeline sous `/user/projet/...` (dataset, outputs MapReduce, exports Hive).

- **YARN (orchestration / supervision)**  
  - **ResourceManager** : allocation des ressources et suivi des applications (jobs MapReduce).  
  - **NodeManager** : exécution des containers sur le nœud et remontée d’état.  
  - Usage projet : prouver l’exécution des traitements batch (états, logs) et contrôler l’allocation CPU/RAM.

- **Hive (métadonnées + requêtes + exports)**  
  - **Client Hive** : exécution des scripts `.hql`.  
  - **Metastore** : métadonnées des tables (A VERIFIER : backend/implémentation).  
  - Usage projet : déclarer des **tables externes** pointant vers HDFS (données brutes et résultats MapReduce) et produire des exports en répertoires HDFS.

**Interaction (flux simple)** : HDFS stocke les données → YARN exécute les jobs MapReduce qui lisent/écrivent sur HDFS → Hive référence ces emplacements via tables externes et exécute requêtes/exports → les exports HDFS sont consolidés en CSV locaux pour la restitution.  

**Schéma à insérer (recommandé)** : diagramme “1 nœud” montrant (NameNode/DataNode) + (ResourceManager/NodeManager) + (Hive client/metastore) et les flux HDFS ↔ MapReduce ↔ Hive (A INSERER : Figure d’architecture).

## 4.4 Configuration YARN (ressources)

La configuration YARN est dimensionnée pour un nœud unique afin d’éviter la sur-allocation tout en gardant des containers suffisamment grands pour exécuter les jobs. Les paramètres ci-dessous proviennent de `config/yarn-site.xml` (A VERIFIER : déployé dans la configuration Hadoop active).

- **Ressources NodeManager** : 4096 MB, 4 vcores  
- **Allocation containers** : min 256 MB, max 2048 MB  
- **ApplicationMaster MapReduce** : 1024 MB  
- **Scheduler** : `CapacityScheduler`  
- **Compression intermédiaire** : sorties mapper compressées (codec Snappy) (A VERIFIER : disponibilité du codec)

Justification : ces limites sont cohérentes avec une machine de quelques Go de RAM (A VERIFIER) et réduisent les risques d’échec par manque mémoire, tout en permettant d’observer l’allocation de ressources dans l’UI YARN.  

```
(A INSERER : sortie `yarn node -list` ou capture UI YARN “Nodes”)
```

## 4.5 Variables d’environnement et accès

Les scripts du projet appellent directement `hdfs`, `hadoop`, `yarn` et `hive`. Les variables suivantes garantissent la résolution des binaires et des bibliothèques :

- `JAVA_HOME` : nécessaire pour exécuter les démons Hadoop et les jobs Java.  
- `HADOOP_HOME` : accès aux binaires et à la configuration Hadoop.  
- `HIVE_HOME` : accès au client Hive et à sa configuration.  
- `PATH` : inclut `$HADOOP_HOME/bin`, `$HADOOP_HOME/sbin`, `$HIVE_HOME/bin`.  

À l’exécution, le classpath Hadoop est résolu dynamiquement (`HADOOP_CLASSPATH=$(hadoop classpath)`) afin d’exécuter les drivers Java avec les dépendances Hadoop correctes.

## 4.6 Interfaces web et supervision

Les interfaces web servent de preuves et d’outils de validation du bon fonctionnement des services :

- **NameNode UI** : `http://localhost:9870` (A VERIFIER : port exact)  
  - À insérer : capture montrant la présence de `/user/projet/data/raw` et des répertoires `/user/projet/output/...` (preuve HDFS).

- **YARN ResourceManager UI** : `http://localhost:8088`  
  - À insérer : capture de la liste des applications MapReduce + page de détail d’un job (état, logs, ressources) (preuve YARN).

Optionnel si activé : historique/logs agrégés (JobHistory) (A VERIFIER : URL/port, souvent `http://localhost:19888`).  

**Preuves à insérer :**
```
(A INSERER : capture UI NameNode)
(A INSERER : capture UI YARN ResourceManager)
```

---

# 5. Ingestion HDFS & organisation des données

## 5.1 Organisation HDFS du projet

L’arborescence HDFS est isolée sous `/user/projet` afin de séparer clairement données, résultats et exports :
- `/user/projet/data/raw` : données brutes (entrée du pipeline).  
- `/user/projet/data/processed` : zone optionnelle de préparation.  
- `/user/projet/output/` : sorties MapReduce, un répertoire par job (`job1_region_avg`, `job2_peaks`, `job3_weekend`).  
- `/user/projet/export/` : exports Hive, un répertoire par requête (`q1_top_days` … `q5_annual_peak`).  

## 5.2 Création de la structure HDFS

La structure est créée via le script `scripts/hdfs/create_structure.sh`, qui vérifie l’accès à HDFS puis crée les répertoires de manière idempotente (création si absent) (A VERIFIER : détail des permissions).  

```bash
cd scripts/hdfs
./create_structure.sh
```

**Preuve (répertoires racine) :**
```bash
$ hdfs dfs -ls /user/projet
drwxr-xr-x   - maxiiimax supergroup          0 2025-12-27 16:51 /user/projet/data
drwxr-xr-x   - maxiiimax supergroup          0 2026-01-01 20:24 /user/projet/output
drwxr-xr-x   - maxiiimax supergroup          0 2026-01-01 20:31 /user/projet/export
```

## 5.3 Chargement des données

Commande d’ingestion (fichier local → HDFS) :
```bash
hdfs dfs -put household_power_consumption.txt /user/projet/data/raw/
```

Vérification (présence + taille) :
```bash
$ hdfs dfs -ls /user/projet/data/raw/household_power_consumption.txt
-rwxr-xr-x   1 maxiiimax supergroup  132960755 2025-12-27 16:52 /user/projet/data/raw/household_power_consumption.txt
```

L’ingestion est considérée réussie lorsque le fichier est visible dans HDFS au bon emplacement.

---

# 6. Développement MapReduce (sous YARN)

## 6.1 Build et packaging des jobs

Les traitements sont implémentés en Java et packagés avec **Maven**. Le build produit un **JAR unique** contenant les drivers, mappers et reducers ; cet artefact est ensuite utilisé pour lancer les jobs sur le cluster YARN.

- **Script de build** : `scripts/execution/build_mapreduce.sh` (wrapper Maven)  
- **Commande** :

```bash
cd mapreduce
mvn clean package
```

- **Artefact généré** : `mapreduce/target/mapreduce-consumption-1.0.jar` (A VERIFIER : nom/taille exacte)

## 6.2 Exécution des jobs MapReduce

L’exécution est orchestrée par `scripts/execution/run_mapreduce_jobs.sh`. Le script :
- vérifie la disponibilité des commandes Hadoop et l’accès à HDFS ;
- vérifie la présence du répertoire d’entrée HDFS ;
- enchaîne les jobs dans un ordre déterministe et affiche un extrait des sorties en fin de job (validation rapide).

Commande (exécution standard) :

```bash
cd scripts/execution
./run_mapreduce_jobs.sh ../../mapreduce/target/mapreduce-consumption-1.0.jar
```

Entrée/sorties principales (valeurs par défaut du script) :
- **Input HDFS** : `/user/projet/data/raw`  
- **Output base HDFS** : `/user/projet/output` (répertoires `job1_region_avg`, `job2_peaks`, `job3_weekend`)

## 6.3 Description des traitements MapReduce

- **Job 1 — Agrégation journalière (`RegionAvgDriver`)** : calcule, pour chaque date, des statistiques sur `Global_active_power`. Le Mapper émet `(date, puissance)` ; le Reducer agrège en `(date, avg,min,max,count)`.  
  **Format de sortie** : `date<TAB>avg,min,max,count`.

  **Preuve (extrait HDFS)** :
  ```
  1/1/2007        1.9090,0.2040,3.5580,1440
  1/1/2008        1.9165,0.2260,5.6860,1440
  ```

- **Job 2 — Détection des pics journaliers (`PeakDetectionDriver`)** : extrait, pour chaque date, les trois pics de consommation (heure + valeur). Le Mapper émet `(date, time,puissance)` ; le Reducer conserve les top 3 valeurs pour produire une sortie compacte.  
  **Format de sortie** : `date<TAB>time1,val1,time2,val2,time3,val3`.

  **Preuve (extrait HDFS)** :
  ```
  1/1/2007        09:50:00,3.5580,09:49:00,3.5420,09:51:00,3.5420
  1/1/2008        11:38:00,5.6860,18:02:00,5.5400,18:01:00,5.5060
  ```

- **Job 3 — Comparaison semaine / week-end (`WeekendComparisonDriver`)** : regroupe les mesures selon `day_type ∈ {weekday, weekend}` (déduit de la date). Le Mapper émet `(day_type, puissance)` ; le Reducer calcule `(avg,min,max,count)` par groupe.  
  **Format de sortie** : `day_type<TAB>avg,min,max,count`.

  **Preuve (extrait HDFS)** :
  ```
  weekday  1.0355,0.0760,9.7320,1470428
  weekend  1.2342,0.0780,11.1220,578852
  ```

## 6.4 Exécution sous YARN et suivi

L’exécution MapReduce s’appuie sur **YARN** : le **ResourceManager** planifie les applications et le **NodeManager** exécute les containers sur le nœud (pseudo-distribué). Chaque job correspond à une application YARN distincte (A VERIFIER : IDs exacts).

- **Captures à insérer (UI YARN ResourceManager `http://localhost:8088`)** :  
  - page “Applications” montrant les 3 jobs (FINISHED) ;  
  - détail d’un job (counters, logs/diagnostics) (A VERIFIER : onglets disponibles selon configuration).

- **Logs (optionnel)** : extraction via `yarn logs -applicationId <APP_ID>` (A VERIFIER : log aggregation active).

## 6.5 Gestion des erreurs et validations

Les traitements intègrent des contrôles simples au niveau parsing, et des validations de présence de sorties :

- **Entrées invalides / valeurs manquantes** : lignes rejetées si en-tête, si champs manquants, ou si valeurs `?` sur les colonnes requises.  
- **Formats incorrects** : erreurs de conversion numérique capturées (ex. `NumberFormatException`).  
- **Dates** : contrôle spécifique dans le job week-end (dates invalides comptabilisées).  

**Compteurs Hadoop utilisés (preuves via UI YARN / logs)** :
- `MAPPER.INVALID_LINES`, `MAPPER.ERRORS` (jobs 1 et 2)  
- `MAPPER.INVALID_DATES`, `MAPPER.INVALID_CONSUMPTION`, `MAPPER.ERRORS` (job 3)  
- `REDUCER.INVALID_VALUES` + `REDUCER.PROCESSED_DAYS` / `REDUCER.PROCESSED_GROUPS` (selon job)

**Validation des sorties** :
- présence des fichiers `part-r-*` et du marqueur `_SUCCESS` dans les répertoires de sortie (A VERIFIER : listing exact) ;  
- affichage d’un extrait des résultats via `hdfs dfs -cat ... | head` dans le script d’exécution.

---

# 7. Data Warehouse Hive : schéma + requêtes analytiques

## 7.1 Création de la base de données

La base Hive utilisée est `consommation_elec`. Elle sert de **namespace** pour regrouper tables et requêtes, tout en laissant les données physiques sur HDFS (données brutes et outputs sous `/user/projet/...`).  
Création via `hive/scripts/01_create_database.hql` :

```sql
CREATE DATABASE IF NOT EXISTS consommation_elec
LOCATION '/user/hive/warehouse/consommation_elec.db';
USE consommation_elec;
```

## 7.2 Modélisation des tables Hive

Le projet s’appuie principalement sur des **tables externes** : Hive référence des répertoires HDFS existants (données brutes et sorties MapReduce) sans recopier les fichiers. Cela permet de rejouer le pipeline (jobs ré-exécutés → répertoires HDFS mis à jour) sans gestion de chargement interne côté Hive.

La table `consumption_raw` référence le dataset brut dans `/user/projet/data/raw` (TEXTFILE `;`). Les propriétés `skip.header.line.count` et `serialization.null.format` garantissent une lecture robuste (en-tête ignoré, `?` → `NULL`).

```sql
CREATE EXTERNAL TABLE consumption_raw (
  `date` STRING,
  `time` STRING,
  global_active_power DOUBLE,
  global_reactive_power DOUBLE,
  voltage DOUBLE,
  global_intensity DOUBLE,
  sub_metering_1 DOUBLE,
  sub_metering_2 DOUBLE,
  sub_metering_3 DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION '/user/projet/data/raw'
TBLPROPERTIES ('skip.header.line.count'='1', 'serialization.null.format'='?');
```

Les outputs MapReduce sont exposés via des tables externes pointant vers `/user/projet/output/...` (format TEXTFILE). Les schémas correspondent aux agrégations calculées par les jobs :

- `conso_par_jour` (Job 1) : `date`, `avg_consumption`, `min_consumption`, `max_consumption`, `count` → `/user/projet/output/job1_region_avg`  
- `pics_journaliers` (Job 2) : `date`, `peak1_time/value`, `peak2_time/value`, `peak3_time/value` → `/user/projet/output/job2_peaks`  
- `comparaison_jours` (Job 3) : `day_type`, `avg_consumption`, `min_consumption`, `max_consumption`, `count` → `/user/projet/output/job3_weekend`  

**Point d’attention (format MapReduce → Hive)** : les sorties Job 1 et Job 3 sont de la forme `cle<TAB>valeurs_csv`. La modélisation Hive doit donc être cohérente avec ce séparateur “TAB + CSV” (A VERIFIER : alignement exact des colonnes pour les requêtes Q1/Q2/Q3).  

**Preuves à insérer** :
```
(A INSERER : `SHOW TABLES;` dans consommation_elec)
(A INSERER : `DESCRIBE FORMATTED consumption_raw;` montrant LOCATION '/user/projet/data/raw')
```

## 7.3 Requêtes analytiques

Les requêtes sont regroupées dans `hive/queries/04_requetes_analytiques.hql`. Elles s’exécutent dans la base `consommation_elec` et s’appuient sur les tables externes définies en 7.2.

- **Q1 — Top 10 jours (statistiques journalières)**  
  Tables : `conso_par_jour`. Logique : tri décroissant sur `avg_consumption` et limitation à 10 lignes (A VERIFIER : cohérence du champ `avg_consumption` avec le format d’output MapReduce).  

```sql
SELECT `date`, avg_consumption, min_consumption, max_consumption, `count`
FROM conso_par_jour
ORDER BY avg_consumption DESC
LIMIT 10;
```

- **Q2 — Évolution mensuelle**  
  Tables : `conso_par_jour`. Logique : construction d’un `year_month` à partir de `date` (format `dd/MM/yyyy`) puis agrégations mensuelles.  

```sql
SELECT
  CONCAT(
    YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
    '-',
    LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
  ) AS year_month,
  AVG(avg_consumption) AS consommation_moyenne,
  SUM(`count`) AS total_mesures
FROM conso_par_jour
WHERE `date` IS NOT NULL
  AND UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy') IS NOT NULL
GROUP BY CONCAT(
  YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))),
  '-',
  LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(`date`, 'dd/MM/yyyy'))), 2, '0')
)
ORDER BY year_month;
```

- **Q3 — Comparaison semaine vs week-end**  
  Tables : `comparaison_jours`. Logique : lecture des deux groupes (`weekday`, `weekend`) et calcul optionnel d’un écart en pourcentage (A VERIFIER : cohérence des colonnes avec l’output MapReduce).  

```sql
SELECT
  day_type,
  avg_consumption,
  CASE
    WHEN day_type = 'weekend' THEN
      ROUND(((avg_consumption -
        (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) /
        (SELECT avg_consumption FROM comparaison_jours WHERE day_type = 'weekday')) * 100, 2)
    ELSE NULL
  END AS difference_pourcent
FROM comparaison_jours
ORDER BY day_type;
```

- **Q4 — Distribution horaire**  
  Tables : `consumption_raw`. Logique : agrégation par heure (`SUBSTRING(time,1,2)`) sur les mesures valides.  

```sql
SELECT
  SUBSTRING(`time`, 1, 2) AS heure,
  COUNT(*) AS nombre_mesures,
  AVG(global_active_power) AS consommation_moyenne
FROM consumption_raw
WHERE global_active_power IS NOT NULL
GROUP BY SUBSTRING(`time`, 1, 2)
ORDER BY consommation_moyenne DESC
LIMIT 10;
```

- **Q5 — Pic annuel**  
  Tables : `consumption_raw`. Logique : extraction de l’année depuis `date`, puis `MAX(global_active_power)` (pic) et `AVG(global_active_power)` (niveau moyen).  
  Cette requête s’appuie sur `consumption_raw` pour éviter toute ambiguïté liée au format des sorties agrégées (A VERIFIER).  

```sql
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
```

## 7.4 Interprétation synthétique des résultats

- **Q1** : met en évidence les journées extrêmes (top consommation moyenne), utiles pour cibler des dates à analyser plus finement (ex. 28/9/2010 avec 1.639 kW de moyenne).  
- **Q2** : fournit une série mensuelle pour comparer les périodes dans le temps (variabilité et tendances), en sécurisant le parsing du format `dd/MM/yyyy`.  
- **Q3** : montre une différence entre les groupes `weekday` et `weekend` ; sur les sorties du projet, le week-end est plus élevé en moyenne (1.234 kW) que la semaine (1.036 kW).  
- **Q4** : identifie les heures les plus consommatrices en moyenne ; dans les exports, le début de soirée ressort (20h avec 1.899 kW en moyenne, suivi de 21h avec 1.878 kW).  
- **Q5** : compare les pics annuels ; les maxima observés sont de l’ordre de 9–11 kW, avec un maximum en 2009 (11.122 kW) sur l’export courant.

---

# 8. Exports & visualisations

## 8.1 Exports Hive vers HDFS

Les résultats Hive sont exportés en HDFS via le script `hive/scripts/05_exports.hql`, en utilisant `INSERT OVERWRITE DIRECTORY`.  
Chaque export est écrit dans un répertoire dédié sous `/user/projet/export/` (un par analyse) : `q1_top_days`, `q2_monthly_evolution`, `q3_weekend_comparison`, `q4_hourly_distribution`, `q5_annual_peak`.  
Le format généré est un fichier texte (type CSV) ; les valeurs `NULL` sont représentées par `\\N` dans les exports (observé).  
(A VERIFIER) : séparateur exact des exports Q1/Q3 si la table source conserve un format `cle<TAB>valeurs` issu de MapReduce.

**Preuve (exports présents dans HDFS) :**
```bash
$ hdfs dfs -ls -R /user/projet/export | head
drwxr-xr-x   - maxiiimax supergroup          0 2026-01-01 20:31 /user/projet/export/q1_top_days
-rw-r--r--   1 maxiiimax supergroup        383 2026-01-01 20:30 /user/projet/export/q1_top_days/000000_0
drwxr-xr-x   - maxiiimax supergroup          0 2026-01-01 20:31 /user/projet/export/q2_monthly_evolution
-rw-r--r--   1 maxiiimax supergroup       2034 2026-01-01 20:31 /user/projet/export/q2_monthly_evolution/000000_0
```

## 8.2 Rapatriement local des résultats

Le rapatriement est automatisé via `scripts/export/export_results.sh`. Le script utilise `hdfs dfs -getmerge` pour fusionner les fichiers d’un export HDFS en un fichier CSV local unique.

Organisation locale : les fichiers sont générés dans `data/export/` (un CSV par analyse).

**Preuve (fichiers CSV présents) :**
```bash
$ ls -lh data/export/
-rw-rw-r-- 1 maxiiimax maxiiimax  383 janv.  1 20:31 Q1_Top10_Jours.csv
-rw-rw-r-- 1 maxiiimax maxiiimax 2034 janv.  1 20:31 Q2_Evolution_Mensuelle.csv
... (3 autres CSV : Q3, Q4, Q5)
```

## 8.3 Génération des visualisations

Les visualisations sont générées en local via `scripts/visualization/generate_graphs.py` (Python), à partir des CSV de `data/export/`.  
Bibliothèques principales : `pandas`, `matplotlib`, `seaborn`. Le script gère le marqueur `\\N` (NULL Hive) et les séparateurs attendus (A VERIFIER : cas Q1/Q3).  

Fichiers PNG produits dans `data/visualizations/` :
- `Q1_Top10_Jours.png`  
- `Q2_Evolution_Mensuelle.png`  
- `Q3_Comparaison_Weekend.png`  
- `Q4_Distribution_Horaire.png`  
- `Q5_Pic_Annuel.png`  

**Preuve (fichiers présents) :**
```bash
$ ls -lh data/visualizations/
-rw-rw-r-- 1 maxiiimax maxiiimax 204K janv.  1 20:33 Q1_Top10_Jours.png
-rw-rw-r-- 1 maxiiimax maxiiimax 437K janv.  1 20:33 Q2_Evolution_Mensuelle.png
... (3 autres PNG : Q3, Q4, Q5)
```

**À insérer dans le PDF** : les 5 fichiers PNG ci-dessus (une figure par analyse).

---

# 9. Tests, validations & qualité

## 9.1 Tests réalisés

Les vérifications suivantes ont été effectuées sur la chaîne complète (HDFS → MapReduce → exports Hive → rapatriement local → visualisations) :

- **Structure HDFS** : création/contrôle des répertoires projet via `scripts/hdfs/create_structure.sh`.  
- **Exécution MapReduce** : lancement des 3 jobs via `scripts/execution/run_mapreduce_jobs.sh` et contrôle d’existence des sorties HDFS.  
- **Exports Hive** : génération des répertoires `/user/projet/export/...` via `hive/scripts/05_exports.hql`.  
- **Rapatriement & visualisation** : génération des CSV via `scripts/export/export_results.sh`, puis des PNG via `scripts/visualization/generate_graphs.py`.  

## 9.2 Validations fonctionnelles

- **Sorties MapReduce** : présence des fichiers `part-r-*` et du marqueur `_SUCCESS` dans chaque répertoire de job (ex. `job1_region_avg`).  
- **Exports & restitution** : présence des 5 CSV dans `data/export/` et des 5 PNG dans `data/visualizations/`.  

Exemples de commandes de contrôle (à rejouer) :
```bash
hdfs dfs -ls /user/projet/output/job1_region_avg
ls -lh data/export data/visualizations
```

## 9.3 Indicateurs de qualité et limites

- **Complétude** : tous les artefacts attendus sont présents (3 outputs MapReduce, 5 répertoires d’export HDFS, 5 CSV locaux, 5 PNG).  
- **Cohérence de format** : dates au format `dd/MM/yyyy` et gestion des `NULL` Hive via `\\N`. Certains exports contiennent des champs `\\N` (ex. en fin de ligne), ce qui indique un alignement colonnes/format à vérifier entre outputs MapReduce et tables Hive (A VERIFIER).  
- **Limites** : les métriques d’exécution (temps, ressources YARN) ne sont pas relevées précisément dans ce rapport (A VERIFIER) ; elles peuvent être documentées via captures de l’UI YARN si exigé.  

---

# 10. Démonstration vidéo

## 10.1 Scénario de la démonstration

La vidéo présente un enchaînement bout en bout, reproductible, sur le même environnement que celui décrit dans le rapport :

1. **Vérification des services** : démontrer que HDFS et YARN sont démarrés (commande `jps` et/ou accès aux UIs NameNode/YARN) (A VERIFIER).  
2. **Structure HDFS** : afficher la présence de l’arborescence `/user/projet` et du dataset dans `/user/projet/data/raw`.  
3. **Exécution MapReduce** : lancer `scripts/execution/run_mapreduce_jobs.sh` et montrer la création des sorties HDFS des 3 jobs.  
4. **Exécution Hive** : exécuter les scripts Hive (`hive -f ...`) pour les requêtes analytiques et les exports (sans détailler les résultats).  
5. **Exports & visualisations** : lancer `scripts/export/export_results.sh`, puis `scripts/visualization/generate_graphs.py` et montrer l’apparition des CSV/PNG en local.

## 10.2 Éléments de preuve présentés

Preuves visibles dans la vidéo :

- **Commandes** : `hdfs dfs -ls /user/projet/...`, lancement `./run_mapreduce_jobs.sh`, exécution `hive -f ...`, exécution `./export_results.sh`, exécution `python3 generate_graphs.py`.  
- **Interfaces web** : UI NameNode (présence des chemins HDFS du projet) et UI YARN ResourceManager (applications MapReduce) (A VERIFIER : ports exacts).  
- **Résultats de pipeline** : présence des outputs MapReduce dans HDFS, des exports dans `/user/projet/export/`, des CSV dans `data/export/` et des PNG dans `data/visualizations/`.

## 10.3 Fichier vidéo

**Nom :** (A VERIFIER)  
**Format :** (mp4, mkv, autre) (A VERIFIER)  
**Durée approximative :** (A VERIFIER)  
**Lieu de dépôt :** (Moodle / lien / répertoire) (A VERIFIER)  

---

# 11. Conclusion, limites, perspectives

## 11.1 Bilan du projet

Ce projet met en place une chaîne Hadoop complète **HDFS → MapReduce sous YARN → Hive → exports → visualisations** appliquée à un dataset de consommation électrique.  
Les objectifs principaux sont atteints : ingestion maîtrisée dans HDFS, exécution de 3 jobs MapReduce, modélisation Hive via tables externes, requêtes analytiques Q1–Q5, exports HDFS puis rapatriement local et génération des graphes.  
Le livrable final combine scripts d’exécution, scripts Hive et éléments de preuve (présence des répertoires HDFS, outputs, exports CSV et PNG).  
Cette approche fournit un pipeline reproductible et cohérent avec les exigences du cours, sans prétention d’optimisation avancée.

## 11.2 Limites identifiées

- **Mode pseudo-distribué** : exécution sur un seul nœud, donc pas de validation de scalabilité ni de tolérance aux pannes multi-nœuds.  
- **Formats de stockage** : tables en `TEXTFILE` (pas de format colonne type ORC/Parquet ni compression au niveau table Hive).  
- **Mesures de performance** : temps d’exécution et ressources YARN non documentés précisément dans le rapport (A VERIFIER).  
- **Formats et parsing** : dépendance au format de date `dd/MM/yyyy` (parsing via `UNIX_TIMESTAMP`) et à l’alignement “TAB + CSV” des outputs MapReduce → Hive (A VERIFIER).  
- **Volumétrie** : dataset de 127 MB, représentatif d’un traitement batch mais limité pour évaluer des gains de performance à grande échelle.

## 11.3 Perspectives d'amélioration

1. **Optimisation Hive (stockage et requêtes)** : convertir les tables en ORC/Parquet et partitionner par période (ex. année/mois) afin de réduire l’I/O et accélérer les agrégations temporelles (A VERIFIER : faisable dans l’environnement).  
2. **Robustesse des formats MapReduce ↔ Hive** : standardiser le format de sortie (délimiteur unique, schéma stable) pour supprimer les ambiguïtés “TAB + CSV” et fiabiliser les exports.  
3. **Optimisation MapReduce** : introduire un combiner lorsque applicable et systématiser la compression des sorties intermédiaires (déjà activée côté configuration YARN) (A VERIFIER : impact réel).  
4. **Orchestration et reproductibilité** : regrouper les étapes (ingestion, jobs, Hive, exports, graphes) dans un script “pipeline” avec gestion d’erreurs, nettoyage des outputs et reprise (A VERIFIER : besoin).  
5. **Montée en charge** : exécuter sur un cluster multi-nœuds et/ou sur un volume plus important pour valider la distribution réelle et documenter des métriques d’exécution via YARN.

---

# Annexes

## Annexe A : Listing des scripts HQL

(A INSERER : contenu complet ou références aux fichiers)

- `hive/scripts/01_create_database.hql`
- `hive/scripts/02_create_tables.hql`
- `hive/scripts/03_load_data.hql`
- `hive/scripts/05_exports.hql`
- `hive/queries/04_requetes_analytiques.hql`

## Annexe B : Structure du projet

(A INSERER : arborescence complète ou référence au README.md)

## Annexe C : Extraits de logs

(A INSERER : logs MapReduce/YARN si disponibles)

## Annexe D : Captures d'écran supplémentaires

(A INSERER : captures UI NameNode, YARN détaillées, etc.)

---

**Fin du rapport**

