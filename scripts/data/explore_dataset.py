#!/usr/bin/env python3
"""
/*****************************************************************************************************
Nom : scripts/data/explore_dataset.py
Rôle : Script d'exploration et d'analyse du dataset de consommation électrique
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : N/A (script interprété)
    Pour executer : python3 explore_dataset.py
******************************************************************************************************/
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime

# Configuration
DATA_FILE = "../../household_power_consumption.txt"
OUTPUT_REPORT = "../../docs/04_DONNEES.md"
SEPARATOR = ";"
NA_VALUES = ["?", "nan", "NaN"]

def load_data_sample(nrows=10000):
    """
    Fonction : load_data_sample
    Rôle     : Charge un échantillon des données pour exploration rapide
    Param    : nrows - nombre de lignes à charger (défaut: 10000)
    Retour   : DataFrame pandas ou None en cas d'erreur
    """
    print("[INFO] Chargement d'un échantillon du dataset...")
    
    # Colonnes du dataset selon la documentation UCI
    column_names = [
        'Date',
        'Time',
        'Global_active_power',      # kilowatts
        'Global_reactive_power',     # kilowatts
        'Voltage',                   # volts
        'Global_intensity',          # ampères
        'Sub_metering_1',            # watt-heure (cuisine)
        'Sub_metering_2',            # watt-heure (lave-linge/climatisation)
        'Sub_metering_3'             # watt-heure (chauffe-eau/climatisation)
    ]
    
    try:
        df = pd.read_csv(
            DATA_FILE,
            sep=SEPARATOR,
            na_values=NA_VALUES,
            nrows=nrows,
            low_memory=False,
            parse_dates={'DateTime': ['Date', 'Time']},
            date_parser=lambda x: pd.to_datetime(x, format='%d/%m/%Y %H:%M:%S', errors='coerce')
        )
        print(f"[OK] Échantillon chargé : {len(df)} lignes")
        return df
    except Exception as e:
        print(f"[ERREUR] Erreur lors du chargement : {e}")
        return None

def analyze_structure(df):
    """
    Fonction : analyze_structure
    Rôle     : Analyse la structure générale du dataset (lignes, colonnes, types)
    Param    : df - DataFrame pandas à analyser
    Retour   : dictionnaire contenant les informations de structure
    """
    print("\n" + "="*70)
    print("1. STRUCTURE DU DATASET")
    print("="*70)
    
    info = {
        'Nombre de lignes (échantillon)': len(df),
        'Nombre de colonnes': len(df.columns),
        'Taille mémoire': f"{df.memory_usage(deep=True).sum() / 1024**2:.2f} MB",
        'Colonnes': list(df.columns)
    }
    
    for key, value in info.items():
        print(f"{key}: {value}")
    
    print("\nTypes de données:")
    print(df.dtypes)
    
    return info

def analyze_missing_values(df):
    """
    Fonction : analyze_missing_values
    Rôle     : Analyse les valeurs manquantes dans le dataset
    Param    : df - DataFrame pandas à analyser
    Retour   : DataFrame contenant les statistiques des valeurs manquantes
    """
    print("\n" + "="*70)
    print("2. VALEURS MANQUANTES")
    print("="*70)
    
    missing = df.isnull().sum()
    missing_pct = (missing / len(df)) * 100
    
    missing_df = pd.DataFrame({
        'Colonne': missing.index,
        'Valeurs manquantes': missing.values,
        'Pourcentage': missing_pct.values
    })
    
    print(missing_df.to_string(index=False))
    
    if missing.sum() > 0:
        print(f"\n[WARNING] ATTENTION: {missing.sum()} valeurs manquantes au total")
    else:
        print("\n[OK] Aucune valeur manquante dans l'échantillon")
    
    return missing_df

def analyze_statistics(df):
    """
    Fonction : analyze_statistics
    Rôle     : Calcule les statistiques descriptives des colonnes numériques
    Param    : df - DataFrame pandas à analyser
    Retour   : DataFrame contenant les statistiques descriptives
    """
    print("\n" + "="*70)
    print("3. STATISTIQUES DESCRIPTIVES")
    print("="*70)
    
    # Colonnes numériques (exclure DateTime)
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    
    if 'DateTime' in df.columns:
        numeric_cols = [col for col in numeric_cols if col != 'DateTime']
    
    stats = df[numeric_cols].describe()
    print(stats)
    
    return stats

def analyze_temporal_coverage(df):
    """
    Fonction : analyze_temporal_coverage
    Rôle     : Analyse la couverture temporelle du dataset (période, répartition mensuelle)
    Param    : df - DataFrame pandas à analyser
    Retour   : DataFrame modifié avec colonnes temporelles ajoutées
    """
    print("\n" + "="*70)
    print("4. COUVERTURE TEMPORELLE")
    print("="*70)
    
    if 'DateTime' in df.columns:
        df['DateTime'] = pd.to_datetime(df['DateTime'], errors='coerce')
        valid_dates = df['DateTime'].dropna()
        
        if len(valid_dates) > 0:
            print(f"Date minimale: {valid_dates.min()}")
            print(f"Date maximale: {valid_dates.max()}")
            print(f"Période couverte: {(valid_dates.max() - valid_dates.min()).days} jours")
            
            # Répartition par mois
            df['Month'] = df['DateTime'].dt.to_period('M')
            monthly_counts = df['Month'].value_counts().sort_index()
            print(f"\nNombre de mesures par mois (échantillon):")
            print(monthly_counts.head(10))
        else:
            print("[WARNING] Aucune date valide trouvée")
    else:
        print("[WARNING] Colonne DateTime non trouvée")
    
    return df

def analyze_consumption_distribution(df):
    """
    Fonction : analyze_consumption_distribution
    Rôle     : Analyse la distribution de la consommation électrique (statistiques, quartiles, valeurs aberrantes)
    Param    : df - DataFrame pandas à analyser
    Retour   : DataFrame modifié
    """
    print("\n" + "="*70)
    print("5. DISTRIBUTION DE LA CONSOMMATION")
    print("="*70)
    
    if 'Global_active_power' in df.columns:
        consumption = df['Global_active_power'].dropna()
        
        print(f"Consommation active globale (kilowatts):")
        print(f"  Minimum: {consumption.min():.3f} kW")
        print(f"  Maximum: {consumption.max():.3f} kW")
        print(f"  Moyenne: {consumption.mean():.3f} kW")
        print(f"  Médiane: {consumption.median():.3f} kW")
        print(f"  Écart-type: {consumption.std():.3f} kW")
        
        # Quartiles
        q25 = consumption.quantile(0.25)
        q75 = consumption.quantile(0.75)
        print(f"  Q1 (25%): {q25:.3f} kW")
        print(f"  Q3 (75%): {q75:.3f} kW")
        
        # Valeurs aberrantes potentielles
        iqr = q75 - q25
        outliers_low = consumption[consumption < (q25 - 1.5 * iqr)]
        outliers_high = consumption[consumption > (q75 + 1.5 * iqr)]
        print(f"\n  Valeurs aberrantes (bas): {len(outliers_low)} ({len(outliers_low)/len(consumption)*100:.2f}%)")
        print(f"  Valeurs aberrantes (haut): {len(outliers_high)} ({len(outliers_high)/len(consumption)*100:.2f}%)")
    
    return df

def check_file_size():
    """
    Fonction : check_file_size
    Rôle     : Vérifie la taille et les informations du fichier de données complet
    Param    : aucun
    Retour   : dictionnaire contenant les informations du fichier ou None si erreur
    """
    print("\n" + "="*70)
    print("6. INFORMATIONS FICHIER")
    print("="*70)
    
    if os.path.exists(DATA_FILE):
        size_bytes = os.path.getsize(DATA_FILE)
        size_mb = size_bytes / (1024**2)
        size_gb = size_bytes / (1024**3)
        
        print(f"Fichier: {DATA_FILE}")
        print(f"Taille: {size_mb:.2f} MB ({size_gb:.3f} GB)")
        
        # Compter les lignes (approximatif)
        with open(DATA_FILE, 'r') as f:
            num_lines = sum(1 for line in f) - 1  # -1 pour l'en-tête
        
        print(f"Nombre de lignes (estimé): {num_lines:,}")
        print(f"Taille par ligne: {size_bytes / num_lines:.2f} bytes")
        
        return {
            'size_mb': size_mb,
            'size_gb': size_gb,
            'num_lines': num_lines
        }
    else:
        print(f"[ERREUR] Fichier non trouvé: {DATA_FILE}")
        return None

def generate_report(info, missing_df, stats, file_info):
    """
    Fonction : generate_report
    Rôle     : Génère un rapport markdown documentant l'analyse du dataset
    Param    : info - informations de structure, missing_df - DataFrame valeurs manquantes, stats - statistiques, file_info - informations fichier
    Retour   : void (écrit le rapport dans un fichier)
    """
    print("\n" + "="*70)
    print("7. GÉNÉRATION DU RAPPORT")
    print("="*70)
    
    report_content = f"""# Phase 4 : Description des Données

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

Le dataset contient {info.get('Nombre de colonnes', 'N/A')} colonnes :

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

- **Taille du fichier :** {file_info.get('size_mb', 'N/A'):.2f} MB ({file_info.get('size_gb', 'N/A'):.3f} GB)
- **Nombre de lignes (estimé) :** {file_info.get('num_lines', 'N/A'):,}
- **Nombre de colonnes :** {info.get('Nombre de colonnes', 'N/A')}
- **Taille mémoire (échantillon) :** {info.get('Taille mémoire', 'N/A')}

## 4. Analyse des Valeurs Manquantes

"""
    
    if missing_df is not None and len(missing_df) > 0:
        report_content += "| Colonne | Valeurs manquantes | Pourcentage |\n"
        report_content += "|---------|-------------------|-------------|\n"
        for _, row in missing_df.iterrows():
            report_content += f"| {row['Colonne']} | {row['Valeurs manquantes']} | {row['Pourcentage']:.2f}% |\n"
    else:
        report_content += "[OK] Aucune valeur manquante détectée dans l'échantillon analysé.\n"
    
    report_content += """
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
"""
    
    # Écrire le rapport
    with open(OUTPUT_REPORT, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"[OK] Rapport généré: {OUTPUT_REPORT}")

def main():
    """
    Fonction : main
    Rôle     : Fonction principale orchestrant l'exploration complète du dataset
    Param    : aucun
    Retour   : void
    """
    print("="*70)
    print("EXPLORATION DU DATASET - HOUSEHOLD POWER CONSUMPTION")
    print("="*70)
    
    # Vérifier l'existence du fichier
    if not os.path.exists(DATA_FILE):
        print(f"[ERREUR] Erreur: Fichier non trouvé: {DATA_FILE}")
        return
    
    # **************************************************
    # --- TRAITEMENT PRINCIPAL --- #
    # **************************************************
    # Informations fichier
    file_info = check_file_size()
    
    # Charger échantillon
    df = load_data_sample(nrows=50000)  # Charger 50k lignes pour analyse
    
    if df is None:
        return
    
    # Analyses
    info = analyze_structure(df)
    missing_df = analyze_missing_values(df)
    stats = analyze_statistics(df)
    df = analyze_temporal_coverage(df)
    df = analyze_consumption_distribution(df)
    
    # **************************************************
    # --- GENERATION DU RAPPORT --- #
    # **************************************************
    if file_info:
        generate_report(info, missing_df, stats, file_info)
    
    print("\n" + "="*70)
    print("[OK] EXPLORATION TERMINÉE")
    print("="*70)
    print(f"\nProchaines étapes:")
    print(f"1. Consulter le rapport: {OUTPUT_REPORT}")
    print(f"2. Nettoyer les données: python3 clean_and_normalize.py")
    print(f"3. Valider le format: python3 validate_format.py")

if __name__ == "__main__":
    main()

