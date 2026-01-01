# Jobs MapReduce - Analyse Consommation Électrique

## Description

Ce module contient 3 jobs MapReduce pour analyser les données de consommation électrique :

1. **Job 1 : Agrégation par jour** (`RegionAvgDriver`)
   - Calcule la consommation moyenne, min, max par jour
   - Output : `date,avg_consumption,min_consumption,max_consumption,count`

2. **Job 2 : Détection des pics** (`PeakDetectionDriver`)
   - Identifie les 3 plus hauts pics de consommation par jour
   - Output : `date,peak1_time,peak1_value,peak2_time,peak2_value,peak3_time,peak3_value`

3. **Job 3 : Comparaison week-end** (`WeekendComparisonDriver`)
   - Compare la consommation entre jours de semaine et week-end
   - Output : `day_type,avg,min,max,count`

## Build

### Prérequis
- Java JDK 8 (compatible avec Hadoop 3.3.6)
- Maven 3.6+
- Hadoop 3.3.6

### Compilation
```bash
cd mapreduce/
mvn clean package
```

Le JAR sera généré dans `target/mapreduce-consumption-1.0.jar`

## Exécution

### Exécution individuelle

#### Job 1 : Agrégation par jour
```bash
hadoop jar target/mapreduce-consumption-1.0.jar \
  com.projet.RegionAvgDriver \
  /user/projet/data/raw \
  /user/projet/output/job1_region_avg
```

#### Job 2 : Détection des pics
```bash
hadoop jar target/mapreduce-consumption-1.0.jar \
  com.projet.PeakDetectionDriver \
  /user/projet/data/raw \
  /user/projet/output/job2_peaks
```

#### Job 3 : Comparaison week-end
```bash
hadoop jar target/mapreduce-consumption-1.0.jar \
  com.projet.WeekendComparisonDriver \
  /user/projet/data/raw \
  /user/projet/output/job3_weekend
```

### Exécution avec script
```bash
cd scripts/execution/
./build_mapreduce.sh              # Build le JAR
./run_mapreduce_jobs.sh           # Exécute les 3 jobs
```

## Format des Données

### Input
- Format : CSV avec séparateur `;`
- Colonnes : `Date;Time;Global_active_power;Global_reactive_power;Voltage;...`
- Exemple : `16/12/2006;17:24:00;4.216;0.418;234.840;...`

### Output Job 1
```
16/12/2006    1.6780,0.1940,9.2720,1440
17/12/2006    1.5234,0.2150,8.4560,1440
...
```

### Output Job 2
```
16/12/2006    18:05:00,6.7520,18:04:00,6.4740,18:06:00,6.3080
17/12/2006    19:23:00,7.2340,19:22:00,7.1230,19:24:00,7.0450
...
```

### Output Job 3
```
weekday    1.6780,0.1940,9.2720,1500000
weekend    1.5234,0.2150,8.4560,500000
```

## Configuration YARN

Les jobs sont configurés pour utiliser :
- **Mapper Memory** : 1024 MB
- **Reducer Memory** : 1024 MB
- **Application Master Memory** : 1024 MB

Configuration détaillée dans `config/yarn-site.xml`

## Monitoring

### Via YARN UI
Accéder à : http://localhost:8088

### Via ligne de commande
```bash
# Lister les applications
yarn application -list

# Voir le statut d'une application
yarn application -status <app_id>

# Voir les logs
yarn logs -applicationId <app_id>
```

## Vérification des Résultats

```bash
# Voir les résultats Job 1
hdfs dfs -cat /user/projet/output/job1_region_avg/part-r-* | head -20

# Voir les résultats Job 2
hdfs dfs -cat /user/projet/output/job2_peaks/part-r-* | head -20

# Voir les résultats Job 3
hdfs dfs -cat /user/projet/output/job3_weekend/part-r-*
```

## Structure du Code

```
mapreduce/
├── pom.xml
└── src/main/java/com/projet/
    ├── RegionAvgMapper.java          # Job 1 Mapper
    ├── RegionAvgReducer.java         # Job 1 Reducer
    ├── RegionAvgDriver.java          # Job 1 Driver
    ├── PeakDetectionMapper.java      # Job 2 Mapper
    ├── PeakDetectionReducer.java     # Job 2 Reducer
    ├── PeakDetectionDriver.java      # Job 2 Driver
    ├── WeekendComparisonMapper.java  # Job 3 Mapper
    ├── WeekendComparisonReducer.java # Job 3 Reducer
    └── WeekendComparisonDriver.java  # Job 3 Driver
```

## Troubleshooting

### Erreur : JAR non trouvé
```bash
# Rebuilder le projet
mvn clean package
```

### Erreur : OutOfMemoryError
Ajuster la configuration mémoire dans les Drivers ou `yarn-site.xml`

### Erreur : Input path does not exist
Vérifier que les données sont uploadées dans HDFS :
```bash
hdfs dfs -ls /user/projet/data/raw/
```

## Documentation Complète

Voir `docs/03_ARCHITECTURE.md` pour plus de détails sur l'architecture MapReduce.

