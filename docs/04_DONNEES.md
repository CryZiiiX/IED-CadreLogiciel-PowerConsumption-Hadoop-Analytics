# Phase 4 : Description des Données

## 1. Source des Données

**Dataset :** Household Electric Power Consumption  
**Source :** UCI Machine Learning Repository  
**URL :** https://archive.ics.uci.edu/ml/datasets/individual+household+electric+power+consumption  
**Fichier :** `household_power_consumption.txt`

## 2. Structure des Données

### 2.1 Format

- **Séparateur :** Point-virgule (`;`)
- **Format date :** DD/MM/YYYY
- **Format heure :** HH:MM:SS
- **Encodage :** UTF-8 ou ISO-8859-1
- **Valeurs manquantes :** Représentées par `?`

### 2.2 Colonnes

Le dataset contient 8 colonnes :

1. **Date** : Date de la mesure (format DD/MM/YYYY)
2. **Time** : Heure de la mesure (format HH:MM:SS)
3. **Global_active_power** : Puissance active globale moyenne (kilowatts)
4. **Global_reactive_power** : Puissance réactive globale moyenne (kilowatts)
5. **Voltage** : Tension moyenne (volts)
6. **Global_intensity** : Intensité globale moyenne (ampères)
7. **Sub_metering_1** : Sous-compteur 1 - Cuisine (watt-heure)
8. **Sub_metering_2** : Sous-compteur 2 - Lave-linge/Climatisation (watt-heure)
9. **Sub_metering_3** : Sous-compteur 3 - Chauffe-eau/Climatisation (watt-heure)

## 3. Volume des Données

- **Taille du fichier :** 126.80 MB (0.124 GB)
- **Nombre de lignes (estimé) :** 2,075,259
- **Nombre de colonnes :** 8
- **Taille mémoire (échantillon) :** 3.05 MB

## 4. Analyse des Valeurs Manquantes

| Colonne | Valeurs manquantes | Pourcentage |
|---------|-------------------|-------------|
| DateTime | 0 | 0.00% |
| Global_active_power | 5 | 0.01% |
| Global_reactive_power | 5 | 0.01% |
| Voltage | 5 | 0.01% |
| Global_intensity | 5 | 0.01% |
| Sub_metering_1 | 5 | 0.01% |
| Sub_metering_2 | 5 | 0.01% |
| Sub_metering_3 | 5 | 0.01% |

## 5. Statistiques Descriptives

Les statistiques descriptives des colonnes numériques sont présentées ci-dessous.

### Global_active_power (Consommation active globale)

- **Unité :** kilowatts
- **Description :** Mesure principale pour l'analyse de consommation

### Sub_metering (Sous-compteurs)

- **Unité :** watt-heure
- **Description :** Consommation détaillée par zone/appareil

## 6. Période de Collecte

- **Période :** Décembre 2006 - Novembre 2010 (47 mois)
- **Fréquence :** 1 mesure par minute
- **Durée totale :** ~4 ans de données

## 7. Qualité des Données

### Problèmes Potentiels

1. **Valeurs manquantes :** Représentées par `?` - nécessite nettoyage
2. **Format des dates :** Format européen (DD/MM/YYYY) - attention lors du parsing
3. **Format numérique :** Utilise le point (.) comme séparateur décimal
4. **Séparateur :** Point-virgule (;) comme séparateur de colonnes

### Traitements Nécessaires

1. Remplacer les `?` par `NULL` ou valeurs par défaut
2. Parser correctement les dates et heures
3. Convertir les colonnes numériques au bon type
4. Valider les plages de valeurs (ex: consommation > 0)

## 8. Utilisation pour le Projet Hadoop

### Préparation pour HDFS

- Le fichier est prêt pour upload dans HDFS après nettoyage
- Format CSV standard compatible avec Hive (séparateur `;`)
- Taille raisonnable pour traitement MapReduce (133 MB)

### Mapping pour MapReduce

- **Mapper :** Extraire Date, Time, Global_active_power
- **Clé :** Date (ou Date+Time selon le job)
- **Valeur :** Global_active_power

### Mapping pour Hive

Le schéma Hive peut être créé directement à partir de la structure :

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

---

**Date d'analyse :** {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}  
**Script utilisé :** `scripts/data/explore_dataset.py`
