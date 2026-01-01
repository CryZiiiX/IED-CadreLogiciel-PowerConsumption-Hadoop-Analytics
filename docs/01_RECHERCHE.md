# Phase 1 : Recherche - Analyse Big Data de la Consommation Électrique

## 1. Justification du Sujet Choisi

### Problématique Métier

L'analyse de la consommation électrique est un enjeu majeur du 21ème siècle face aux défis énergétiques :
- **Optimisation de la production** : Comprendre les patterns de consommation pour adapter la production d'électricité
- **Réduction des pics de charge** : Identifier les moments de forte consommation pour mettre en place des stratégies de lissage
- **Planification énergétique** : Anticiper les besoins futurs grâce à l'analyse historique
- **Transition énergétique** : Analyser l'impact des changements comportementaux sur la consommation

### Pertinence Big Data

Ce projet est parfaitement adapté au Big Data car :
- **Volume** : Les données de consommation électrique sont générées en continu, créant des datasets de plusieurs GB/TB
- **Vélocité** : Données générées en temps réel (mesures toutes les minutes/heures)
- **Variété** : Données structurées (CSV) avec timestamps, régions, types de consommation
- **Valeur** : Insights métier clairs (optimisation, prédiction, détection d'anomalies)

### Conformité Académique

- **Aucun Machine Learning requis** - Focus sur l'ingénierie Big Data
- **Technologies Hadoop complètes** - HDFS, MapReduce, YARN, Hive
- **Démonstration claire** - Résultats facilement visualisables et interprétables

---

## 2. Sources de Données Identifiées

### Source Principale : UCI Machine Learning Repository

**Dataset :** Household Electric Power Consumption
- **URL :** https://archive.ics.uci.edu/ml/datasets/individual+household+electric+power+consumption
- **Volume :** 133 MB (2+ millions de mesures)
- **Période :** Décembre 2006 à Novembre 2010 (47 mois)
- **Fréquence :** 1 mesure par minute

**Structure des données :**
```
Date;Time;Global_active_power;Global_reactive_power;Voltage;Global_intensity;Sub_metering_1;Sub_metering_2;Sub_metering_3
16/12/2006;17:24:00;4.216;0.418;234.840;18.400;0.000;1.000;17.000
```

**Colonnes :**
- `Date` : Date au format DD/MM/YYYY
- `Time` : Heure au format HH:MM:SS
- `Global_active_power` : Puissance active moyenne (kilowatts)
- `Global_reactive_power` : Puissance réactive moyenne (kilowatts)
- `Voltage` : Tension moyenne (volts)
- `Global_intensity` : Intensité moyenne (ampères)
- `Sub_metering_1` : Sous-compteur cuisine (watt-heure)
- `Sub_metering_2` : Sous-compteur lave-linge/climatisation (watt-heure)
- `Sub_metering_3` : Sous-compteur chauffe-eau/climatisation (watt-heure)

### Sources Alternatives (pour extension future)

1. **RTE Open Data (France)**
   - URL : https://opendata.reseaux-energies.fr/
   - Données régionales de consommation française
   - API REST disponible

2. **ENTSO-E Transparency Platform (Europe)**
   - URL : https://transparency.entsoe.eu/
   - Données de consommation européenne
   - Format CSV/XML

3. **Kaggle Energy Consumption Datasets**
   - Divers datasets de consommation énergétique
   - Formats variés (CSV, JSON, Parquet)

---

## 3. Technologies Hadoop Sélectionnées

### 3.1 HDFS (Hadoop Distributed File System)

**Rôle :** Stockage distribué des fichiers CSV volumineux

**Utilisation dans le projet :**
- Stockage des données brutes (`/user/projet/data/raw/`)
- Stockage des données traitées par MapReduce (`/user/projet/data/processed/`)
- Stockage des résultats intermédiaires et finaux

**Avantages :**
- Tolérance aux pannes (réplication 3x par défaut)
- Scalabilité horizontale
- Accès optimisé pour MapReduce

**Commandes principales :**
```bash
hdfs dfs -mkdir -p /user/projet/data/raw
hdfs dfs -put data/raw/*.csv /user/projet/data/raw/
hdfs dfs -ls /user/projet/data/
```

### 3.2 MapReduce

**Rôle :** Traitement distribué et parallélisé des données

**Jobs MapReduce développés :**

1. **Job 1 : Agrégation par jour**
   - Mapper : Extraire (date, consommation)
   - Reducer : Calculer moyenne/jour

2. **Job 2 : Détection des pics journaliers**
   - Mapper : Extraire (date, consommation)
   - Reducer : Identifier MAX par jour

3. **Job 3 : Comparaison semaine/week-end**
   - Mapper : Classifier jour + extraire consommation
   - Reducer : Agréger par type de jour

**Avantages :**
- Traitement parallèle sur plusieurs nœuds
- Tolérance aux pannes
- Scalabilité automatique

### 3.3 YARN (Yet Another Resource Negotiator)

**Rôle :** Gestionnaire de ressources et ordonnanceur des jobs

**Configuration dans le projet :**
- Allocation mémoire (RAM) pour Mappers/Reducers
- Allocation CPU (vcores)
- Gestion de la file d'attente des jobs
- Monitoring via YARN UI (port 8088)

**Fichiers de configuration :**
- `yarn-site.xml` : Configuration Resource Manager et Node Manager

**Monitoring :**
- Interface web : `http://localhost:8088`
- Commandes CLI : `yarn application -list`, `yarn application -status <app_id>`

### 3.4 Hive

**Rôle :** Data warehouse SQL sur Hadoop

**Utilisation dans le projet :**
- Création de tables externes pointant vers HDFS
- Requêtes SQL analytiques (GROUP BY, JOIN, fonctions d'agrégation)
- Export des résultats pour visualisation

**Tables créées :**
- `consumption_raw` : Table externe sur données brutes HDFS
- `conso_par_jour` : Résultats Job 1 MapReduce
- `pics_journaliers` : Résultats Job 2 MapReduce
- `comparaison_jours` : Résultats Job 3 MapReduce

**Requêtes analytiques :**
- Consommation moyenne par jour
- Évolution temporelle (tendance mensuelle)
- Distribution horaire (heures de pointe)
- Comparaison jour de semaine vs week-end

**Avantages :**
- Interface SQL familière
- Optimisation automatique des requêtes
- Intégration avec outils BI

---

## 4. Justification Technique

### Pourquoi cette stack technologique ?

**HDFS** : Nécessaire pour stocker les gros volumes (133 MB+ qui deviendront GB après traitement)

**MapReduce** : Obligatoire académiquement, permet de démontrer le traitement distribué avec 3 jobs distincts

**YARN** : Technologie requise, permet de monitorer et optimiser l'utilisation des ressources

**Hive** : Facilite l'analyse avec SQL, permet des requêtes complexes sur les résultats MapReduce

### Flux de Traitement

```
Données CSV brutes
    ↓
Upload HDFS (/user/projet/data/raw/)
    ↓
MapReduce Jobs (Agrégation, Pics, Week-end)
    ↓
Résultats dans HDFS (/user/projet/output/)
    ↓
Tables Hive pointant vers résultats
    ↓
Requêtes SQL analytiques
    ↓
Export CSV/JSON pour visualisation
```

---

## 5. Références et Documentation

- **Hadoop 3.3.6 Documentation :** https://hadoop.apache.org/docs/r3.3.6/
- **Hive Documentation :** https://hive.apache.org/
- **UCI Dataset :** https://archive.ics.uci.edu/ml/datasets/individual+household+electric+power+consumption
- **RTE Open Data :** https://opendata.reseaux-energies.fr/

---

**Date de rédaction :** Décembre 2024  
**Auteur :** [Votre Nom]  
**Projet :** Analyse Big Data de la Consommation Électrique avec Hadoop

