#!/usr/bin/env python3
"""
/*****************************************************************************************************
Nom : scripts/data/clean_and_normalize.py
Rôle : Script de nettoyage et normalisation du dataset de consommation électrique
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : N/A (script interprété)
    Pour executer : python3 clean_and_normalize.py
******************************************************************************************************/
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime

# Configuration
INPUT_FILE = "../../household_power_consumption.txt"
OUTPUT_FILE = "../../data/processed/household_power_consumption_cleaned.csv"
SEPARATOR = ";"
NA_VALUES = ["?", "nan", "NaN", ""]
CHUNK_SIZE = 100000  # Traiter par chunks pour gérer la mémoire

def clean_chunk(chunk):
    """
    Fonction : clean_chunk
    Rôle     : Nettoie un chunk de données en convertissant les valeurs numériques
    Param    : chunk - DataFrame pandas représentant un chunk de données
    Retour   : DataFrame pandas nettoyé
    """
    # Remplacer les valeurs manquantes
    # Pour les colonnes numériques, utiliser interpolation ou moyenne
    numeric_cols = chunk.select_dtypes(include=[np.number]).columns.tolist()
    
    # Remplacer ? par NaN
    for col in numeric_cols:
        chunk[col] = pd.to_numeric(chunk[col], errors='coerce')
    
    # Option 1: Supprimer les lignes avec valeurs manquantes
    # chunk = chunk.dropna()
    
    # Option 2: Remplacer par 0 (pour ce projet, on garde les NaN pour Hive)
    # chunk = chunk.fillna(0)
    
    # Option 3: Interpolation (pour séries temporelles)
    # chunk[numeric_cols] = chunk[numeric_cols].interpolate(method='linear')
    
    # Pour ce projet, on garde les NaN et on laisse Hive les gérer
    # ou on remplace par NULL dans le fichier final
    
    return chunk

def normalize_dates(chunk):
    """
    Fonction : normalize_dates
    Rôle     : Normalise les dates et heures en créant des colonnes temporelles dérivées
    Param    : chunk - DataFrame pandas avec colonnes Date et Time
    Retour   : DataFrame pandas avec colonnes temporelles ajoutées
    """
    try:
        # Créer une colonne DateTime combinée
        chunk['DateTime'] = pd.to_datetime(
            chunk['Date'] + ' ' + chunk['Time'],
            format='%d/%m/%Y %H:%M:%S',
            errors='coerce'
        )
        
        # Extraire des informations utiles
        chunk['Year'] = chunk['DateTime'].dt.year
        chunk['Month'] = chunk['DateTime'].dt.month
        chunk['Day'] = chunk['DateTime'].dt.day
        chunk['Hour'] = chunk['DateTime'].dt.hour
        chunk['DayOfWeek'] = chunk['DateTime'].dt.dayofweek  # 0=Monday, 6=Sunday
        chunk['IsWeekend'] = chunk['DayOfWeek'].isin([5, 6]).astype(int)
        
    except Exception as e:
        print(f"[WARNING] Erreur lors de la normalisation des dates: {e}")
    
    return chunk

def process_file():
    """
    Fonction : process_file
    Rôle     : Traite le fichier complet par chunks pour gérer la mémoire efficacement
    Param    : aucun
    Retour   : bool - True en cas de succès, False en cas d'erreur
    """
    print("="*70)
    print("NETTOYAGE ET NORMALISATION DU DATASET")
    print("="*70)
    
    if not os.path.exists(INPUT_FILE):
        print(f"[ERREUR] Erreur: Fichier d'entrée non trouvé: {INPUT_FILE}")
        return False
    
    # Créer le répertoire de sortie
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    # Colonnes du dataset
    column_names = [
        'Date',
        'Time',
        'Global_active_power',
        'Global_reactive_power',
        'Voltage',
        'Global_intensity',
        'Sub_metering_1',
        'Sub_metering_2',
        'Sub_metering_3'
    ]
    
    print(f"\n[INFO] Fichier d'entrée: {INPUT_FILE}")
    print(f"[INFO] Fichier de sortie: {OUTPUT_FILE}")
    print(f"[INFO] Taille des chunks: {CHUNK_SIZE:,} lignes")
    
    # Compter le nombre total de lignes (approximatif)
    print("\n[INFO] Comptage des lignes...")
    with open(INPUT_FILE, 'r') as f:
        total_lines = sum(1 for line in f) - 1  # -1 pour l'en-tête
    
    print(f"[OK] Nombre total de lignes: {total_lines:,}")
    
    # Traiter le fichier par chunks
    print("\n[INFO] Traitement du fichier...")
    
    chunks_processed = 0
    total_rows_processed = 0
    total_rows_cleaned = 0
    
    # Ouvrir le fichier de sortie
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as outfile:
        # Écrire l'en-tête
        header = column_names + ['Year', 'Month', 'Day', 'Hour', 'DayOfWeek', 'IsWeekend']
        outfile.write(SEPARATOR.join(header) + '\n')
        
        # Lire et traiter par chunks
        for chunk in pd.read_csv(
            INPUT_FILE,
            sep=SEPARATOR,
            names=column_names,
            skiprows=1,  # Skip header
            na_values=NA_VALUES,
            chunksize=CHUNK_SIZE,
            low_memory=False
        ):
            chunks_processed += 1
            rows_in_chunk = len(chunk)
            total_rows_processed += rows_in_chunk
            
            # Nettoyer le chunk
            chunk = clean_chunk(chunk)
            chunk = normalize_dates(chunk)
            
            # Écrire le chunk nettoyé
            # Sélectionner les colonnes dans l'ordre correct
            output_cols = column_names + ['Year', 'Month', 'Day', 'Hour', 'DayOfWeek', 'IsWeekend']
            chunk[output_cols].to_csv(
                outfile,
                sep=SEPARATOR,
                mode='a',
                header=False,
                index=False,
                na_rep='NULL'  # Remplacer NaN par NULL pour compatibilité Hive
            )
            
            total_rows_cleaned += len(chunk)
            
            # Afficher la progression
            if chunks_processed % 10 == 0:
                progress = (total_rows_processed / total_lines) * 100
                print(f"  Traité: {chunks_processed} chunks, {total_rows_processed:,} lignes ({progress:.1f}%)")
    
    print(f"\n[OK] Traitement terminé:")
    print(f"  - Chunks traités: {chunks_processed}")
    print(f"  - Lignes traitées: {total_rows_processed:,}")
    print(f"  - Lignes nettoyées: {total_rows_cleaned:,}")
    
    # Vérifier la taille du fichier de sortie
    if os.path.exists(OUTPUT_FILE):
        size_mb = os.path.getsize(OUTPUT_FILE) / (1024**2)
        print(f"  - Taille du fichier de sortie: {size_mb:.2f} MB")
    
    return True

def validate_cleaned_file():
    """
    Fonction : validate_cleaned_file
    Rôle     : Valide le fichier nettoyé en vérifiant sa structure et ses valeurs
    Param    : aucun
    Retour   : void
    """
    print("\n" + "="*70)
    print("VALIDATION DU FICHIER NETTOYÉ")
    print("="*70)
    
    if not os.path.exists(OUTPUT_FILE):
        print(f"[ERREUR] Fichier non trouvé: {OUTPUT_FILE}")
        return
    
    # Charger un échantillon
    df = pd.read_csv(OUTPUT_FILE, sep=SEPARATOR, nrows=1000)
    
    print(f"\n[OK] Fichier chargé: {len(df)} lignes (échantillon)")
    print(f"\nColonnes: {list(df.columns)}")
    print(f"\nTypes de données:")
    print(df.dtypes)
    
    # Vérifier les valeurs NULL
    null_counts = df.isnull().sum()
    if null_counts.sum() > 0:
        print(f"\n[WARNING] Valeurs NULL détectées:")
        print(null_counts[null_counts > 0])
    else:
        print("\n[OK] Aucune valeur NULL")
    
    # Vérifier les dates
    if 'Year' in df.columns:
        print(f"\n[OK] Années: {df['Year'].min()} - {df['Year'].max()}")
        print(f"[OK] Week-end détectés: {df['IsWeekend'].sum()} lignes ({df['IsWeekend'].mean()*100:.1f}%)")
    
    print("\n[OK] Validation terminée")

def main():
    """
    Fonction : main
    Rôle     : Fonction principale orchestrant le nettoyage et la normalisation du dataset
    Param    : aucun
    Retour   : void
    """
    start_time = datetime.now()
    
    success = process_file()
    
    if success:
        validate_cleaned_file()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print("\n" + "="*70)
        print("[OK] NETTOYAGE TERMINÉ")
        print("="*70)
        print(f"Durée: {duration:.1f} secondes")
        print(f"\nFichier nettoyé: {OUTPUT_FILE}")
        print(f"\nProchaines étapes:")
        print(f"1. Valider le format: python3 validate_format.py")
        print(f"2. Upload dans HDFS: ../hdfs/upload_to_hdfs.sh")
    else:
        print("\n[ERREUR] Échec du nettoyage")

if __name__ == "__main__":
    main()

