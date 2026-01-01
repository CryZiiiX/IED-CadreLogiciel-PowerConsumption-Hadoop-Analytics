# Phase 2 : Planification - Analyse Big Data de la Consommation Électrique

## 1. Objectifs du Projet

### Objectifs Généraux

1. **Analyser la consommation électrique à grande échelle**
   - Traiter un dataset de 2+ millions de lignes
   - Identifier les patterns temporels de consommation
   - Comprendre les variations journalières et hebdomadaires

2. **Démontrer la maîtrise de l'écosystème Hadoop**
   - Utiliser HDFS pour le stockage distribué
   - Implémenter des jobs MapReduce fonctionnels
   - Configurer et monitorer YARN
   - Créer des analyses avec Hive

3. **Produire des insights métier exploitables**
   - Détecter les heures de pointe
   - Comparer consommation semaine vs week-end
   - Visualiser l'évolution temporelle

### Objectifs Techniques

- Traiter 2+ millions de lignes avec MapReduce
- Créer 3 jobs MapReduce optimisés avec YARN
- Implémenter 5+ requêtes Hive analytiques
- Exporter et visualiser les résultats

---

## 2. Fonctionnalités Prévues

### 2.1 Acquisition et Préparation des Données

- [x] Dataset UCI disponible (`household_power_consumption.txt`)
- [ ] Exploration et analyse de la structure
- [ ] Nettoyage des valeurs manquantes (notées "?")
- [ ] Normalisation du format (dates, séparateurs)
- [ ] Validation du format pour HDFS

### 2.2 Stockage HDFS

- [ ] Upload des données brutes dans HDFS
- [ ] Organisation en répertoires logiques
- [ ] Vérification de l'intégrité (checksums)
- [ ] Documentation de la structure HDFS

### 2.3 Jobs MapReduce

**Job 1 : Agrégation par jour**
- Mapper : Extraire (date, consommation_active)
- Reducer : Calculer moyenne, min, max par jour
- Output : `conso_par_jour.csv`

**Job 2 : Détection des pics journaliers**
- Mapper : Extraire (date, heure, consommation)
- Reducer : Identifier les 3 pics journaliers
- Output : `pics_journaliers.csv`

**Job 3 : Comparaison semaine/week-end**
- Mapper : Classifier jour (weekday/weekend) + consommation
- Reducer : Statistiques par type de jour
- Output : `comparaison_jours.csv`

### 2.4 Configuration YARN

- [ ] Configuration `yarn-site.xml`
- [ ] Allocation mémoire Mappers/Reducers
- [ ] Monitoring via YARN UI
- [ ] Documentation des ressources utilisées

### 2.5 Base de Données Hive

**Tables à créer :**
- `consumption_raw` : Table externe sur données HDFS
- `conso_par_jour` : Résultats Job 1
- `pics_journaliers` : Résultats Job 2
- `comparaison_jours` : Résultats Job 3

### 2.6 Requêtes Hive Analytiques

1. **Q1 : Consommation moyenne par jour** (top 10 jours)
2. **Q2 : Évolution mensuelle** (tendance sur 47 mois)
3. **Q3 : Comparaison semaine/week-end** (différence en %)
4. **Q4 : Distribution horaire** (heures de pointe)
5. **Q5 : Pic de consommation annuel** (par année)

### 2.7 Export et Visualisation

- [ ] Export résultats en CSV
- [ ] Graphiques avec Python (matplotlib/seaborn)
- [ ] Préparation slides de présentation

---

## 3. Ressources Nécessaires

### 3.1 Infrastructure

**Cluster Hadoop :**
- **Version :** Hadoop 3.3.6
- **Configuration :** Mode pseudo-distribué (1 nœud) ou Docker
- **Stockage HDFS :** Minimum 500 MB (données + réplication)
- **RAM :** Minimum 4 GB (8 GB recommandé pour YARN)

**Docker (alternative) :**
- Images : `cloudera/quickstart` ou `bde2020/hadoop-namenode`
- RAM allouée : 4-8 GB
- Disque : 10+ GB

### 3.2 Logiciels

**Obligatoires :**
- Java JDK 8 (compatible avec Hadoop 3.3.6)
- Hadoop 3.3.6
- Hive 3.1.3 (compatible avec Hadoop 3.3.6)
- Maven 3.6+ (pour build MapReduce)

**Recommandés :**
- Python 3.7+ (pour scripts d'exploration et visualisation)
- Pandas, Matplotlib, Seaborn (pour analyses)
- Git (versionning)
- Un IDE Java (IntelliJ IDEA, Eclipse, VS Code)

### 3.3 Datasets

**Principal :**
- `household_power_consumption.txt` : 133 MB, 2M+ lignes - Disponible

**Format attendu :**
- CSV avec séparateur `;`
- Encodage UTF-8 ou ISO-8859-1

---

## 4. Planning Temporel Estimé

### Phase 0 : Recherche et Planification (2-3h)
- [x] Recherche du sujet et justification
- [x] Planification détaillée
- [ ] Setup environnement Hadoop 3.3.6

### Phase 1 : Acquisition des Données (1-2h)
- [ ] Exploration dataset existant
- [ ] Nettoyage et normalisation
- [ ] Validation format

### Phase 2 : Configuration HDFS (1-2h)
- [ ] Configuration HDFS
- [ ] Upload des données
- [ ] Vérification intégrité

### Phase 3 : Développement MapReduce (4-6h)
- [ ] Job 1 : Agrégation par jour (1.5h)
- [ ] Job 2 : Détection pics (1.5h)
- [ ] Job 3 : Comparaison week-end (1.5h)
- [ ] Configuration YARN (1h)
- [ ] Tests et debug (1h)

### Phase 4 : Configuration Hive (2-3h)
- [ ] Création base de données
- [ ] Création tables (0.5h)
- [ ] Chargement données (0.5h)
- [ ] Tests tables (1h)

### Phase 5 : Analyses Hive (3-4h)
- [ ] Développement 5 requêtes (2h)
- [ ] Optimisation requêtes (1h)
- [ ] Export résultats (0.5h)
- [ ] Visualisations (0.5h)

### Phase 6 : Tests et Démonstration (3-4h)
- [ ] Tests unitaires MapReduce (1h)
- [ ] Tests d'intégration (1h)
- [ ] Script de démonstration (1h)
- [ ] Préparation vidéo (1h)

### Phase 7 : Documentation et Livrables (4-6h)
- [ ] Rapport PDF complet (3h)
- [ ] Scripts Hive livrables (0.5h)
- [ ] Script vidéo démonstration (0.5h)
- [ ] README et documentation (1h)
- [ ] Relecture et finalisation (1h)

**TOTAL ESTIMÉ : 20-30 heures**

---

## 5. Risques et Contingences

### Risques Identifiés

1. **Compatibilité Java avec Hadoop 3.3.6**
   - **Note :** Hadoop 3.3.6 supporte Java 8, 11 et 17
   - **Note :** Java 8 est compatible avec Hadoop 3.3.6

2. **Hadoop 3.3.6 non dans PATH**
   - **Risque :** Commandes `hadoop`, `hdfs`, `yarn` non disponibles
   - **Solution :** Configurer variables d'environnement (`HADOOP_HOME`, `PATH`)

3. **Volume de données trop important**
   - **Risque :** Jobs MapReduce trop longs
   - **Solution :** Extraire un échantillon (1-3 mois) pour tests rapides

4. **Complexité configuration Hive**
   - **Risque :** Metastore non configuré
   - **Solution :** Utiliser Hive embarqué (embedded metastore) pour début

### Stratégies de Mitigation

- Tester chaque phase indépendamment avant d'enchainer
- Garder des backups des données et configurations
- Documenter chaque étape pour faciliter le debug
- Utiliser Docker comme alternative si installation locale échoue

---

## 6. Critères de Succès

### Techniques
- Tous les jobs MapReduce s'exécutent sans erreur
- YARN UI accessible et montrant l'exécution des jobs
- Toutes les requêtes Hive retournent des résultats cohérents
- Les exports CSV sont exploitables

### Académiques
- Rapport PDF complet (15-20 pages)
- Scripts Hive livrables documentés
- Vidéo démonstration (5-7 min)
- Code source commenté et lisible

### Métier
- Insights exploitables (pics, tendances, comparaisons)
- Visualisations claires et interprétables
- Réponses aux questions analytiques posées

---

## 7. Prochaines Étapes

1. **Immédiat :** Configuration environnement Hadoop 3.3.6
2. **Court terme :** Exploration et préparation du dataset
3. **Moyen terme :** Développement des jobs MapReduce
4. **Long terme :** Analyses Hive et finalisation livrables

---

**Date de rédaction :** Décembre 2024  
**Auteur :** [Votre Nom]  
**Projet :** Analyse Big Data de la Consommation Électrique avec Hadoop

