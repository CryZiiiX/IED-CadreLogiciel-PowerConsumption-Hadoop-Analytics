# Phase 3 : Architecture Technique - Projet Hadoop

## 1. Vue d'Ensemble de l'Architecture

### Architecture Distribuée Hadoop

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (Notre Machine)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Scripts    │  │ MapReduce    │  │   Hive CLI   │      │
│  │   Python     │  │   Jobs (JAR) │  │   / Beeline  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ API Calls
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  CLUSTER HADOOP (Pseudo-Distribué)          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              YARN (Resource Manager)                │    │
│  │  - Ordonnancement des jobs MapReduce               │    │
│  │  - Gestion des ressources (CPU, RAM)               │    │
│  │  - Monitoring (UI: http://localhost:8088)          │    │
│  └────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            │ Resource Allocation             │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │           MapReduce Application Master              │    │
│  │  - Job 1: Agrégation par jour                      │    │
│  │  - Job 2: Détection des pics                       │    │
│  │  - Job 3: Comparaison week-end                     │    │
│  └────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            │ Map/Reduce Tasks                │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │              HDFS (Stockage Distribué)              │    │
│  │                                                      │    │
│  │  ┌──────────────┐         ┌──────────────┐         │    │
│  │  │  NameNode    │         │  DataNode    │         │    │
│  │  │  (Metadata)  │◄───────►│  (Données)   │         │    │
│  │  └──────────────┘         └──────────────┘         │    │
│  │                                                      │    │
│  │  /user/projet/data/raw/                            │    │
│  │  /user/projet/output/job1/                         │    │
│  │  /user/projet/output/job2/                         │    │
│  │  /user/projet/output/job3/                         │    │
│  └────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            │ Tables Externes                 │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │              HIVE (Data Warehouse)                  │    │
│  │  - Metastore (PostgreSQL ou Embedded)              │    │
│  │  - HiveServer2 (Thrift Server)                     │    │
│  │  - Requêtes SQL → Jobs MapReduce                   │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Composants Détaillés

### 2.1 HDFS (Hadoop Distributed File System)

**Rôle :** Système de fichiers distribué pour stocker les gros volumes de données

**Composants :**
- **NameNode :** Gère les métadonnées (structure des fichiers, répertoires)
- **DataNode :** Stocke les blocs de données réels

**Structure HDFS du Projet :**
```
/user/projet/
├── data/
│   ├── raw/
│   │   └── household_power_consumption.txt  (données brutes)
│   └── processed/
│       └── (données nettoyées si nécessaire)
└── output/
    ├── job1_region_avg/
    │   └── part-r-00000
    ├── job2_peaks/
    │   └── part-r-00000
    └── job3_weekend/
        └── part-r-00000
```

**Configuration clé :**
- Mode pseudo-distribué (1 nœud) pour ce projet
- Réplication : 1 (suffisant pour développement)
- Taille de bloc : 128 MB (défaut Hadoop 3.x)

**Commandes principales :**
```bash
# Créer répertoire
hdfs dfs -mkdir -p /user/projet/data/raw

# Upload fichier
hdfs dfs -put household_power_consumption.txt /user/projet/data/raw/

# Lister contenu
hdfs dfs -ls /user/projet/data/raw/

# Voir taille
hdfs dfs -du -h /user/projet/data/raw/
```

---

### 2.2 MapReduce

**Rôle :** Framework de traitement distribué pour analyser les données en parallèle

**Architecture MapReduce :**

```
Input Data (HDFS)
    │
    ├─► Split 1 ──► Mapper 1 ──► [key1, value1], [key2, value2], ...
    │
    ├─► Split 2 ──► Mapper 2 ──► [key1, value1], [key3, value3], ...
    │
    └─► Split N ──► Mapper N ──► [key2, value2], [key1, value1], ...
    
        Shuffle & Sort (par clé)
        
    [key1, [value1, value1, ...]] ──► Reducer 1 ──► Output 1
    [key2, [value2, value2, ...]] ──► Reducer 2 ──► Output 2
    [key3, [value3, value3, ...]] ──► Reducer 3 ──► Output 3
```

**Jobs MapReduce du Projet :**

#### Job 1 : Agrégation par jour
- **Input :** `/user/projet/data/raw/household_power_consumption.txt`
- **Mapper :** Extrait `(date, consommation_active)`
- **Reducer :** Calcule `(moyenne, min, max)` par jour
- **Output :** `/user/projet/output/job1_region_avg/`

#### Job 2 : Détection des pics
- **Input :** `/user/projet/data/raw/household_power_consumption.txt`
- **Mapper :** Extrait `(date, heure, consommation)`
- **Reducer :** Identifie les 3 pics journaliers
- **Output :** `/user/projet/output/job2_peaks/`

#### Job 3 : Comparaison week-end
- **Input :** `/user/projet/data/raw/household_power_consumption.txt`
- **Mapper :** Classe jour (weekday/weekend) + extrait consommation
- **Reducer :** Statistiques par type de jour
- **Output :** `/user/projet/output/job3_weekend/`

**Fichiers Java :**
- `Mapper.java` : Extrait et transforme les données
- `Reducer.java` : Agrége les valeurs par clé
- `Driver.java` : Configure et lance le job

---

### 2.3 YARN (Yet Another Resource Negotiator)

**Rôle :** Gestionnaire de ressources et ordonnanceur des applications

**Composants YARN :**

```
ResourceManager (Master)
    │
    ├─► Application Master (par job MapReduce)
    │       │
    │       └─► Container Allocation Requests
    │
    └─► NodeManager (Worker)
            │
            ├─► Container 1 (Mapper Task)
            ├─► Container 2 (Reducer Task)
            └─► Container N
```

**Configuration YARN (yarn-site.xml) :**
```xml
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>4096</value>  <!-- RAM totale disponible -->
</property>
<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>2048</value>  <!-- RAM max par container -->
</property>
<property>
  <name>yarn.nodemanager.resource.cpu-vcores</name>
  <value>4</value>  <!-- CPUs disponibles -->
</property>
```

**Allocation Ressources par Job :**
- Mapper : 1024 MB RAM, 1 vcore
- Reducer : 1024 MB RAM, 1 vcore
- Application Master : 512 MB RAM

**Monitoring :**
- UI Web : `http://localhost:8088`
- Commandes CLI :
  ```bash
  yarn application -list
  yarn application -status <app_id>
  yarn node -list
  ```

---

### 2.4 Hive

**Rôle :** Data warehouse SQL sur Hadoop pour requêtes analytiques

**Architecture Hive :**

```
Hive CLI / Beeline
    │
    │ SQL Query
    │
    ▼
HiveServer2 (Thrift Server)
    │
    ├─► Metastore (PostgreSQL/Embedded)
    │   └─► Schémas des tables, partitions
    │
    └─► Hive Driver
            │
            ├─► Compiler (convertit SQL → MapReduce)
            │
            └─► Execution Engine
                    │
                    └─► Lance Job MapReduce
                            │
                            └─► YARN ResourceManager
```

**Tables Hive du Projet :**

#### Table Externe : `consumption_raw`
```sql
CREATE EXTERNAL TABLE consumption_raw (
    date STRING,
    time STRING,
    global_active_power DOUBLE,
    global_reactive_power DOUBLE,
    voltage DOUBLE,
    global_intensity DOUBLE,
    sub_metering_1 DOUBLE,
    sub_metering_2 DOUBLE,
    sub_metering_3 DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION '/user/projet/data/raw';
```

#### Table : `conso_par_jour`
```sql
CREATE TABLE conso_par_jour (
    date STRING,
    avg_consumption DOUBLE,
    min_consumption DOUBLE,
    max_consumption DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/user/projet/output/job1_region_avg';
```

**Requêtes Analytiques :**
- Q1 : Consommation moyenne par jour (TOP 10)
- Q2 : Évolution mensuelle
- Q3 : Comparaison semaine/week-end
- Q4 : Distribution horaire
- Q5 : Pic de consommation annuel

---

## 3. Flux de Traitement des Données

### Pipeline Complet

```
1. DONNÉES BRUTES
   └─► household_power_consumption.txt (133 MB, 2M+ lignes)
            │
            │ Upload
            ▼
2. HDFS
   └─► /user/projet/data/raw/household_power_consumption.txt
            │
            │ MapReduce Jobs
            ├─► Job 1: Agrégation par jour
            │   └─► /user/projet/output/job1_region_avg/
            │
            ├─► Job 2: Détection pics
            │   └─► /user/projet/output/job2_peaks/
            │
            └─► Job 3: Comparaison week-end
                └─► /user/projet/output/job3_weekend/
                        │
                        │ Tables Hive
                        ▼
3. HIVE TABLES
   ├─► consumption_raw (externe)
   ├─► conso_par_jour
   ├─► pics_journaliers
   └─► comparaison_jours
            │
            │ Requêtes SQL
            ▼
4. ANALYSES
   ├─► Q1: Consommation moyenne par jour
   ├─► Q2: Évolution mensuelle
   ├─► Q3: Comparaison semaine/week-end
   ├─► Q4: Distribution horaire
   └─► Q5: Pic annuel
            │
            │ Export
            ▼
5. RÉSULTATS
   └─► CSV/JSON pour visualisation
       └─► Graphiques Python (matplotlib/seaborn)
```

---

## 4. Diagramme de Séquence (Exécution Job MapReduce)

```
Client          YARN RM        App Master      NodeManager      HDFS
  │                │                │               │            │
  │ submit job     │                │               │            │
  ├───────────────►│                │               │            │
  │                │                │               │            │
  │                │ allocate AM    │               │            │
  │                ├───────────────►│               │            │
  │                │                │               │            │
  │                │                │ get splits    │            │
  │                │                ├───────────────────────────►│
  │                │                │◄───────────────────────────┤
  │                │                │               │            │
  │                │                │ allocate maps │            │
  │                │                ├──────────────►│            │
  │                │                │               │            │
  │                │                │               │ read data  │
  │                │                │               ├───────────►│
  │                │                │               │◄───────────┤
  │                │                │               │            │
  │                │                │               │ map()      │
  │                │                │               │            │
  │                │                │ allocate red  │            │
  │                │                ├──────────────►│            │
  │                │                │               │            │
  │                │                │               │ reduce()   │
  │                │                │               │            │
  │                │                │               │ write out  │
  │                │                │               ├───────────►│
  │                │                │               │            │
  │                │                │               │            │
  │                │ job complete   │               │            │
  │                │◄───────────────┤               │            │
  │                │                │               │            │
  │◄───────────────┤                │               │            │
```

---

## 5. Configuration Réseau et Ports

### Ports Utilisés (Mode Pseudo-Distribué)

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| HDFS NameNode | 9870 | http://localhost:9870 | Web UI HDFS (Hadoop 3.x) |
| HDFS NameNode RPC | 9000 | hdfs://localhost:9000 | API HDFS |
| HDFS DataNode | 50075 | http://localhost:50075 | Web UI DataNode |
| YARN ResourceManager | 8088 | http://localhost:8088 | Web UI YARN |
| YARN NodeManager | 8042 | http://localhost:8042 | Web UI NodeManager |
| MapReduce History | 19888 | http://localhost:19888 | Web UI History Server |
| HiveServer2 | 10000 | jdbc:hive2://localhost:10000 | Hive Thrift Server |
| Hive Metastore | 9083 | thrift://localhost:9083 | Hive Metastore |

---

## 6. Schéma de Base de Données Hive

```
Database: consommation_elec
│
├─► consumption_raw (EXTERNAL)
│   ├─► date: STRING
│   ├─► time: STRING
│   ├─► global_active_power: DOUBLE
│   ├─► global_reactive_power: DOUBLE
│   ├─► voltage: DOUBLE
│   ├─► global_intensity: DOUBLE
│   ├─► sub_metering_1: DOUBLE
│   ├─► sub_metering_2: DOUBLE
│   └─► sub_metering_3: DOUBLE
│
├─► conso_par_jour (MANAGED)
│   ├─► date: STRING
│   ├─► avg_consumption: DOUBLE
│   ├─► min_consumption: DOUBLE
│   └─► max_consumption: DOUBLE
│
├─► pics_journaliers (MANAGED)
│   ├─► date: STRING
│   ├─► peak_consumption: DOUBLE
│   ├─► peak_time: STRING
│   └─► rank: INT
│
└─► comparaison_jours (MANAGED)
    ├─► day_type: STRING (weekday/weekend)
    ├─► avg_consumption: DOUBLE
    ├─► min_consumption: DOUBLE
    ├─► max_consumption: DOUBLE
    └─► count: BIGINT
```

---

## 7. Optimisations et Bonnes Pratiques

### HDFS
- Utiliser la compression (gzip, snappy) pour réduire le stockage
- Partitionner les données par date/mois si volumétrie importante
- Configurer la réplication selon les besoins (1 pour dev, 3 pour prod)

### MapReduce
- Utiliser des Combiners pour réduire le trafic réseau
- Optimiser le nombre de Reducers (1 reducer = 1 fichier de sortie)
- Utiliser la compression des sorties intermédiaires

### YARN
- Allouer les ressources selon la taille des données
- Monitorer via YARN UI pour identifier les goulots d'étranglement
- Ajuster la taille des containers selon la RAM disponible

### Hive
- Créer des partitions par date pour accélérer les requêtes
- Utiliser des formats optimisés (ORC, Parquet) plutôt que TEXTFILE
- Analyser les tables régulièrement (`ANALYZE TABLE`)

---

**Date de rédaction :** Décembre 2024  
**Version Hadoop :** 3.3.6  
**Version Hive :** 3.1.3  
**Architecture :** Pseudo-Distribué (1 nœud)

