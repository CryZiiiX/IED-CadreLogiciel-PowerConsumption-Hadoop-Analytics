# Tests - Projet Hadoop Analyse Consommation Électrique

## Vue d'ensemble

Ce répertoire contient tous les tests pour valider le fonctionnement du projet Hadoop. Les tests sont organisés en trois catégories :

- **Tests unitaires** (`unit/`) : Tests des jobs MapReduce individuels
- **Tests d'intégration** (`integration/`) : Tests de l'intégration entre les composants
- **Tests de validation** (`validation/`) : Validation des résultats et formats

## Structure

```
tests/
├── unit/              # Tests unitaires MapReduce
├── integration/       # Tests d'intégration HDFS/Hive
├── validation/        # Validation des résultats
├── results/           # Résultats des tests (générés)
└── README.md          # Ce fichier
```

## Tests unitaires

Les tests unitaires vérifient le bon fonctionnement de chaque job MapReduce individuellement.

### Scripts disponibles

- `test_mapreduce_job1.sh` : Test du Job 1 (Agrégation par jour)
- `test_mapreduce_job2.sh` : Test du Job 2 (Détection des pics)
- `test_mapreduce_job3.sh` : Test du Job 3 (Comparaison week-end)

### Exécution

```bash
# Tous les tests unitaires
cd tests/unit/
./test_mapreduce_job1.sh
./test_mapreduce_job2.sh
./test_mapreduce_job3.sh
```

### Ce qui est testé

- Exécution du job avec succès
- Existence des fichiers de sortie
- Format de sortie correct (séparateurs, colonnes)
- Cohérence logique des résultats (min <= avg <= max)
- Validation des types de données

## Tests d'intégration

Les tests d'intégration vérifient que les différents composants fonctionnent ensemble correctement.

### Scripts disponibles

- `test_hdfs_integration.sh` : Test de l'intégration HDFS
- `test_hive_integration.sh` : Test de l'intégration Hive

### Exécution

```bash
cd tests/integration/
./test_hdfs_integration.sh
./test_hive_integration.sh
```

### Test HDFS

Vérifie :
- Accessibilité de HDFS
- Structure des répertoires
- Présence des données brutes
- Présence des résultats MapReduce
- Permissions de lecture/écriture

### Test Hive

Vérifie :
- Accessibilité de Hive
- Existence de la base de données
- Existence des tables
- Contenu des tables
- Structure des colonnes
- Présence des exports

## Tests de validation

Les tests de validation vérifient la qualité et la cohérence des résultats produits.

### Scripts disponibles

- `validate_mapreduce_output.sh` : Validation des sorties MapReduce
- `validate_hive_tables.sh` : Validation des tables Hive
- `validate_hive_queries.sh` : Validation des requêtes analytiques

### Exécution

```bash
cd tests/validation/
./validate_mapreduce_output.sh
./validate_hive_tables.sh
./validate_hive_queries.sh
```

### Validation MapReduce

Vérifie :
- Format des fichiers de sortie
- Présence des résultats pour chaque job
- Cohérence des données (formats, types)

### Validation Tables Hive

Vérifie :
- Existence de toutes les tables
- Contenu des tables (non vide)
- Structure des colonnes
- Cohérence logique (min <= avg <= max)

### Validation Requêtes Hive

Vérifie :
- Exécution réussie de chaque requête (Q1-Q5)
- Nombre de résultats attendus
- Présence des exports dans HDFS

## Résultats des tests

Les rapports de validation sont sauvegardés dans le répertoire `results/` avec un horodatage.

Format des fichiers : `validation_<type>_YYYYMMDD_HHMMSS.txt`

## Exécution de tous les tests

Pour exécuter tous les tests dans l'ordre :

```bash
# Tests unitaires
cd tests/unit/
for test in *.sh; do
    echo "Exécution de $test..."
    ./"$test"
done

# Tests d'intégration
cd ../integration/
for test in *.sh; do
    echo "Exécution de $test..."
    ./"$test"
done

# Tests de validation
cd ../validation/
for test in *.sh; do
    echo "Exécution de $test..."
    ./"$test"
done
```

## Prérequis

Avant d'exécuter les tests, assurez-vous que :

1. **Hadoop est démarré** :
   ```bash
   start-dfs.sh
   start-yarn.sh
   ```

2. **Hive Metastore est démarré** (si nécessaire) :
   ```bash
   hive --service metastore &
   ```

3. **Les données sont chargées dans HDFS** :
   ```bash
   scripts/hdfs/upload_to_hdfs.sh
   ```

4. **Les jobs MapReduce ont été exécutés** :
   ```bash
   scripts/execution/run_mapreduce_jobs.sh
   ```

5. **Les tables Hive ont été créées** :
   ```bash
   cd hive/scripts/
   hive -f 01_create_database.hql
   hive -f 02_create_tables.hql
   hive -f 03_load_data.hql
   ```

## Interprétation des résultats

### Codes de sortie

- `0` : Tous les tests ont réussi
- `> 0` : Au moins un test a échoué (le nombre correspond au nombre d'erreurs)

### Messages

- `[OK]` : Test réussi
- `[INFO]` : Information
- `[WARNING]` : Avertissement (non bloquant)
- `[ERREUR]` : Erreur (test échoué)

## Dépannage

### HDFS non accessible

```bash
# Vérifier que HDFS est démarré
jps | grep -E "NameNode|DataNode"

# Démarrer HDFS si nécessaire
start-dfs.sh
```

### Hive non accessible

```bash
# Vérifier que le Metastore est démarré
jps | grep MetaStore

# Démarrer le Metastore si nécessaire
hive --service metastore &
```

### Tables Hive manquantes

```bash
# Recréer les tables
cd hive/scripts/
hive -f 01_create_database.hql
hive -f 02_create_tables.hql
hive -f 03_load_data.hql
```

### Résultats MapReduce manquants

```bash
# Exécuter les jobs MapReduce
cd scripts/execution/
./run_mapreduce_jobs.sh
```

## Notes

- Les tests d'intégration et de validation nécessitent que les données et résultats soient déjà présents
- Les tests unitaires créent des répertoires temporaires qui sont nettoyés automatiquement
- Les rapports de validation sont sauvegardés avec horodatage pour traçabilité

