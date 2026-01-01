#!/usr/bin/env python3
"""
/*****************************************************************************************************
Nom : scripts/data/validate_format.py
Rôle : Script de validation du format de données pour HDFS/Hive
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : N/A (script interprété)
    Pour executer : python3 validate_format.py
******************************************************************************************************/
"""

import os
import pandas as pd

# Configuration
CLEANED_FILE = "../../data/processed/household_power_consumption_cleaned.csv"
ORIGINAL_FILE = "../../household_power_consumption.txt"
SEPARATOR = ";"

def validate_separator(file_path, expected_sep=';'):
    """
    Fonction : validate_separator
    Rôle     : Vérifie que le séparateur CSV est correct et cohérent dans le fichier
    Param    : file_path - chemin du fichier à valider, expected_sep - séparateur attendu (défaut: ';')
    Retour   : bool - True si valide, False sinon
    """
    print(f"[OK] Vérification du séparateur '{expected_sep}'...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        first_line = f.readline()
        count = first_line.count(expected_sep)
        
        print(f"  - Nombre de séparateurs dans l'en-tête: {count}")
        
        # Vérifier quelques lignes supplémentaires
        sample_lines = [f.readline() for _ in range(10)]
        for i, line in enumerate(sample_lines, 1):
            line_count = line.count(expected_sep)
            if line_count != count:
                print(f"  [WARNING] Ligne {i+1}: {line_count} séparateurs (attendu: {count})")
                return False
        
        print(f"  [OK] Séparateur cohérent sur toutes les lignes")
        return True

def validate_encoding(file_path):
    """
    Fonction : validate_encoding
    Rôle     : Vérifie l'encodage du fichier en testant plusieurs encodages courants
    Param    : file_path - chemin du fichier à valider
    Retour   : str - nom de l'encodage détecté ou None si non trouvé
    """
    print(f"[OK] Vérification de l'encodage...")
    
    encodings = ['utf-8', 'iso-8859-1', 'latin-1']
    
    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                f.read(1000)  # Lire un échantillon
            print(f"  [OK] Encodage {encoding} valide")
            return encoding
        except UnicodeDecodeError:
            continue
    
    print(f"  [WARNING] Encodage non détecté automatiquement")
    return None

def validate_schema(file_path):
    """
    Fonction : validate_schema
    Rôle     : Vérifie que le schéma (nombre de colonnes) est cohérent dans tout le fichier
    Param    : file_path - chemin du fichier à valider
    Retour   : bool - True si valide, False sinon
    """
    print(f"[OK] Vérification du schéma...")
    
    df_sample = pd.read_csv(file_path, sep=SEPARATOR, nrows=1000)
    
    num_cols = len(df_sample.columns)
    print(f"  - Nombre de colonnes: {num_cols}")
    print(f"  - Colonnes: {list(df_sample.columns)[:10]}...")  # Afficher les 10 premières
    
    # Vérifier la cohérence
    with open(file_path, 'r', encoding='utf-8') as f:
        header = f.readline().strip()
        header_cols = header.split(SEPARATOR)
        
        if len(header_cols) == num_cols:
            print(f"  [OK] Schéma cohérent")
            return True
        else:
            print(f"  [WARNING] Incohérence: {len(header_cols)} colonnes dans l'en-tête, {num_cols} dans les données")
            return False

def validate_numeric_columns(file_path):
    """
    Fonction : validate_numeric_columns
    Rôle     : Vérifie que les colonnes numériques attendues sont bien formatées
    Param    : file_path - chemin du fichier à valider
    Retour   : bool - True si valide, False sinon
    """
    print(f"[OK] Vérification des colonnes numériques...")
    
    df_sample = pd.read_csv(file_path, sep=SEPARATOR, nrows=10000)
    
    # Colonnes numériques attendues (selon le dataset)
    numeric_cols = [
        'Global_active_power',
        'Global_reactive_power',
        'Voltage',
        'Global_intensity',
        'Sub_metering_1',
        'Sub_metering_2',
        'Sub_metering_3'
    ]
    
    issues = []
    for col in numeric_cols:
        if col in df_sample.columns:
            # Vérifier si la colonne est numérique
            try:
                pd.to_numeric(df_sample[col], errors='raise')
                print(f"  [OK] {col}: format numérique valide")
            except (ValueError, TypeError):
                issues.append(col)
                print(f"  [WARNING] {col}: format numérique invalide")
    
    if issues:
        print(f"  [WARNING] Colonnes avec problèmes: {issues}")
        return False
    
    return True

def validate_file_size(file_path):
    """
    Fonction : validate_file_size
    Rôle     : Vérifie la taille du fichier et recommande le partitionnement si nécessaire
    Param    : file_path - chemin du fichier à valider
    Retour   : bool - True si le fichier existe, False sinon
    """
    print(f"[OK] Vérification de la taille...")
    
    if os.path.exists(file_path):
        size_bytes = os.path.getsize(file_path)
        size_mb = size_bytes / (1024**2)
        
        print(f"  - Taille: {size_mb:.2f} MB")
        
        if size_mb > 1000:  # > 1 GB
            print(f"  [WARNING] Fichier volumineux, considérer le partitionnement pour HDFS")
        else:
            print(f"  [OK] Taille appropriée pour HDFS")
        
        return True
    else:
        print(f"  [ERREUR] Fichier non trouvé")
        return False

def check_hive_compatibility(file_path):
    """
    Fonction : check_hive_compatibility
    Rôle     : Vérifie la compatibilité globale du fichier avec Hive (séparateur, format, caractères spéciaux)
    Param    : file_path - chemin du fichier à valider
    Retour   : bool - True si compatible, False sinon
    """
    print(f"[OK] Vérification compatibilité Hive...")
    
    checks = []
    
    # Séparateur
    if validate_separator(file_path, SEPARATOR):
        checks.append("[OK] Séparateur compatible (;)")
    else:
        checks.append("[ERREUR] Séparateur incompatible")
    
    # Pas de retours à la ligne dans les données
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = [f.readline() for _ in range(100)]
        multiline_issues = sum(1 for line in lines if line.count('\n') > 1)
        if multiline_issues == 0:
            checks.append("[OK] Format de ligne correct")
        else:
            checks.append(f"[WARNING] {multiline_issues} lignes avec problèmes de format")
    
    # Caractères spéciaux
    special_chars = ['\t', '\r']
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read(10000)
        found_special = [char for char in special_chars if char in content]
        if not found_special:
            checks.append("[OK] Pas de caractères spéciaux problématiques")
        else:
            checks.append(f"[WARNING] Caractères spéciaux détectés: {found_special}")
    
    print("\n  " + "\n  ".join(checks))
    
    return all("[OK]" in check for check in checks)

def generate_hive_schema(file_path):
    """
    Fonction : generate_hive_schema
    Rôle     : Génère un exemple de schéma Hive CREATE TABLE basé sur la structure du fichier
    Param    : file_path - chemin du fichier à analyser
    Retour   : void (affiche le schéma à l'écran)
    """
    print(f"\n" + "="*70)
    print("SCHÉMA HIVE RECOMMANDÉ")
    print("="*70)
    
    df_sample = pd.read_csv(file_path, sep=SEPARATOR, nrows=100)
    
    print("\n```sql")
    print("CREATE EXTERNAL TABLE consumption_raw (")
    
    # Générer les colonnes avec types
    columns = []
    for col in df_sample.columns:
        dtype = df_sample[col].dtype
        
        if pd.api.types.is_integer_dtype(dtype):
            hive_type = "INT"
        elif pd.api.types.is_float_dtype(dtype):
            hive_type = "DOUBLE"
        elif pd.api.types.is_datetime64_any_dtype(dtype):
            hive_type = "STRING"
        else:
            hive_type = "STRING"
        
        columns.append(f"    {col.lower()} {hive_type}")
    
    print(",\n".join(columns))
    print(")")
    print("ROW FORMAT DELIMITED")
    print(f"FIELDS TERMINATED BY '{SEPARATOR}'")
    print("STORED AS TEXTFILE")
    print("LOCATION '/user/projet/data/raw';")
    print("```")

def main():
    """
    Fonction : main
    Rôle     : Fonction principale orchestrant toutes les validations du format de fichier
    Param    : aucun
    Retour   : void
    """
    print("="*70)
    print("VALIDATION DU FORMAT POUR HDFS/HIVE")
    print("="*70)
    
    # Vérifier quel fichier utiliser
    if os.path.exists(CLEANED_FILE):
        file_to_validate = CLEANED_FILE
        print(f"\n[INFO] Utilisation du fichier nettoyé: {file_to_validate}")
    elif os.path.exists(ORIGINAL_FILE):
        file_to_validate = ORIGINAL_FILE
        print(f"\n[INFO] Utilisation du fichier original: {file_to_validate}")
        print("[WARNING] Note: Utiliser le fichier nettoyé est recommandé")
    else:
        print(f"[ERREUR] Aucun fichier trouvé pour validation")
        return
    
    print("\n" + "-"*70)
    
    # Validations
    validate_separator(file_to_validate)
    encoding = validate_encoding(file_to_validate)
    validate_schema(file_to_validate)
    validate_numeric_columns(file_to_validate)
    validate_file_size(file_to_validate)
    hive_ok = check_hive_compatibility(file_to_validate)
    
    # Générer schéma Hive
    generate_hive_schema(file_to_validate)
    
    print("\n" + "="*70)
    if hive_ok:
        print("[OK] VALIDATION TERMINÉE - Fichier compatible avec Hive/HDFS")
    else:
        print("[WARNING] VALIDATION TERMINÉE - Vérifier les avertissements ci-dessus")
    print("="*70)
    
    print(f"\nProchaines étapes:")
    print(f"1. Upload dans HDFS: ../hdfs/upload_to_hdfs.sh")
    print(f"2. Créer les tables Hive: ../../hive/scripts/02_create_tables.hql")

if __name__ == "__main__":
    main()

