#!/usr/bin/env python3
"""
/*****************************************************************************************************
Nom : scripts/visualization/generate_graphs.py
Rôle : Script de génération de graphiques à partir des exports CSV Hive
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : N/A (script interprété)
    Pour executer : python3 generate_graphs.py
******************************************************************************************************/
"""

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
import numpy as np
import os
import sys
from pathlib import Path

# Configuration
BASE_DIR = Path(__file__).parent.parent.parent
EXPORT_DIR = BASE_DIR / "data" / "export"
OUTPUT_DIR = BASE_DIR / "data" / "visualizations"

# Style seaborn
sns.set_style("whitegrid")
sns.set_palette("husl")


def create_output_directory(output_dir):
    """
    Fonction : create_output_directory
    Rôle     : Crée le répertoire de sortie pour les graphiques s'il n'existe pas
    Param    : output_dir - chemin du répertoire à créer
    Retour   : void
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"[OK] Répertoire de sortie : {output_dir}")


def load_csv(file_path, sep=',', na_values=['\\N', '\\N\n', ''], header=None):
    """
    Fonction : load_csv
    Rôle     : Charge un fichier CSV avec gestion des valeurs NULL pour Hive
    Param    : file_path - chemin vers le fichier CSV, sep - séparateur, na_values - valeurs NULL, header - ligne d'en-tête
    Retour   : DataFrame pandas ou None en cas d'erreur
    """
    try:
        df = pd.read_csv(
            file_path,
            sep=sep,
            na_values=na_values,
            low_memory=False,
            header=header
        )
        # Supprimer les lignes complètement vides
        df = df.dropna(how='all')
        print(f"[OK] Chargé : {file_path.name} ({len(df)} lignes)")
        return df
    except Exception as e:
        print(f"[ERREUR] Erreur lors du chargement de {file_path.name}: {e}")
        return None


def plot_q1_top_days(df, output_dir):
    """
    Fonction : plot_q1_top_days
    Rôle     : Génère un graphique en barres horizontales pour le top 10 des jours de consommation
    Param    : df - DataFrame pandas contenant les données, output_dir - répertoire de sortie
    Retour   : void (sauvegarde le graphique dans un fichier PNG)
    """
    if df is None or df.empty:
        print("[ERREUR] Aucune donnée pour Q1")
        return
    
    # Le format réel est: première colonne = date, deuxième colonne = "avg,min,max,count"
    if len(df.columns) == 2:
        # Renommer les colonnes
        df.columns = ['date', 'values']
        # Parser les valeurs séparées par virgule
        values_split = df['values'].astype(str).str.split(',', expand=True)
        if len(values_split.columns) >= 4:
            df['avg_consumption'] = pd.to_numeric(values_split[0], errors='coerce')
            df['min_consumption'] = pd.to_numeric(values_split[1], errors='coerce')
            df['max_consumption'] = pd.to_numeric(values_split[2], errors='coerce')
            df['count'] = pd.to_numeric(values_split[3], errors='coerce')
        else:
            print("[ERREUR] Format des valeurs incorrect pour Q1")
            return
    else:
        print(f"[ERREUR] Format CSV inattendu pour Q1: {len(df.columns)} colonnes au lieu de 2")
        return
    
    # Nettoyer les dates
    df['date'] = df['date'].astype(str).str.strip()
    
    # Vérifier que les colonnes nécessaires existent
    if 'avg_consumption' not in df.columns:
        print("[ERREUR] Colonne avg_consumption non trouvée dans Q1")
        return
    
    # Trier par consommation moyenne décroissante et prendre le top 10
    df_sorted = df.sort_values('avg_consumption', ascending=True).tail(10)
    
    # Créer le graphique
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Barres horizontales avec gradient de couleur
    colors = plt.cm.viridis(np.linspace(0.2, 0.8, len(df_sorted)))
    bars = ax.barh(range(len(df_sorted)), df_sorted['avg_consumption'].values, color=colors)
    
    # Personnalisation
    ax.set_yticks(range(len(df_sorted)))
    ax.set_yticklabels(df_sorted['date'].values, fontsize=10)
    ax.set_xlabel('Consommation moyenne (kW)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Date', fontsize=12, fontweight='bold')
    ax.set_title('Top 10 des jours avec la consommation moyenne la plus élevée', 
                 fontsize=14, fontweight='bold', pad=20)
    
    # Ajouter les valeurs sur les barres
    for i, (idx, row) in enumerate(df_sorted.iterrows()):
        value = row['avg_consumption']
        ax.text(value + 0.05, i, f'{value:.2f} kW', 
                va='center', fontsize=9, fontweight='bold')
    
    # Ajouter une grille
    ax.grid(axis='x', alpha=0.3, linestyle='--')
    
    plt.tight_layout()
    
    # Sauvegarder
    output_path = output_dir / "Q1_Top10_Jours.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"[OK] Graphique sauvegardé : {output_path}")
    plt.close()


def plot_q2_monthly_evolution(df, output_dir):
    """
    Fonction : plot_q2_monthly_evolution
    Rôle     : Génère un graphique linéaire montrant l'évolution mensuelle de la consommation
    Param    : df - DataFrame pandas contenant les données, output_dir - répertoire de sortie
    Retour   : void (sauvegarde le graphique dans un fichier PNG)
    """
    if df is None or df.empty:
        print("[ERREUR] Aucune donnée pour Q2")
        return
    
    # Renommer les colonnes si nécessaire (pas de header)
    if len(df.columns) >= 2:
        df.columns = ['year_month', 'consommation_moyenne', 'consommation_min', 'consommation_max', 'total_mesures'][:len(df.columns)]
    
    # Vérifier les colonnes
    if 'year_month' not in df.columns or 'consommation_moyenne' not in df.columns:
        print(f"[ERREUR] Colonnes manquantes dans Q2. Colonnes disponibles: {df.columns.tolist()}")
        return
    
    # Nettoyer les données
    df['year_month'] = df['year_month'].astype(str).str.strip()
    df['consommation_moyenne'] = pd.to_numeric(df['consommation_moyenne'], errors='coerce')
    
    # Trier par date
    df_sorted = df.sort_values('year_month')
    
    # Créer le graphique
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Ligne principale pour la consommation moyenne
    ax.plot(df_sorted['year_month'], df_sorted['consommation_moyenne'], 
            marker='o', linewidth=2, markersize=6, label='Consommation moyenne', color='#2E86AB')
    
    # Zone ombragée pour min/max si disponibles
    if 'consommation_min' in df.columns and 'consommation_max' in df.columns:
        df_sorted['consommation_min'] = pd.to_numeric(df_sorted['consommation_min'], errors='coerce')
        df_sorted['consommation_max'] = pd.to_numeric(df_sorted['consommation_max'], errors='coerce')
        ax.fill_between(df_sorted['year_month'], 
                        df_sorted['consommation_min'], 
                        df_sorted['consommation_max'],
                        alpha=0.3, color='#A23B72', label='Plage (min-max)')
    
    # Personnalisation
    ax.set_xlabel('Période (Année-Mois)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Consommation moyenne (kW)', fontsize=12, fontweight='bold')
    ax.set_title('Évolution mensuelle de la consommation électrique', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.grid(True, alpha=0.3, linestyle='--')
    
    # Ajuster l'échelle de l'axe Y pour mieux visualiser les variations
    # Les valeurs sont très faibles (0.1-0.26 kW), on doit zoomer sur la plage réelle
    y_min = df_sorted['consommation_moyenne'].min()
    y_max = df_sorted['consommation_moyenne'].max()
    y_range = y_max - y_min
    
    # Ajouter un padding de 10% de chaque côté pour une meilleure visualisation
    # Mais ne pas commencer à 0 car cela aplatirait trop les variations
    padding = y_range * 0.1 if y_range > 0 else (y_max * 0.1 if y_max > 0 else 0.01)
    y_bottom = max(0, y_min - padding)
    y_top = y_max + padding
    
    # S'assurer que la plage minimale est d'au moins 15% pour voir les variations
    if y_range < (y_top - y_bottom) * 0.15:
        center = (y_min + y_max) / 2
        min_range = (y_top - y_bottom) * 0.15
        y_bottom = center - min_range / 2
        y_top = center + min_range / 2
        y_bottom = max(0, y_bottom)  # Ne pas aller en négatif
    
    ax.set_ylim(y_bottom, y_top)
    
    # Améliorer les ticks de l'axe Y pour une meilleure lisibilité
    # Utiliser un format avec 3 décimales pour les petites valeurs
    ax.yaxis.set_major_locator(MaxNLocator(nbins=8))
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x:.3f}'))
    
    # Rotation des labels X pour éviter le chevauchement
    plt.xticks(rotation=45, ha='right')
    
    plt.tight_layout()
    
    # Sauvegarder
    output_path = output_dir / "Q2_Evolution_Mensuelle.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"[OK] Graphique sauvegardé : {output_path}")
    plt.close()


def plot_q3_weekend_comparison(df, output_dir):
    """
    Fonction : plot_q3_weekend_comparison
    Rôle     : Génère un graphique en barres groupées comparant semaine et week-end
    Param    : df - DataFrame pandas contenant les données, output_dir - répertoire de sortie
    Retour   : void (sauvegarde le graphique dans un fichier PNG)
    """
    if df is None or df.empty:
        print("[ERREUR] Aucune donnée pour Q3")
        return
    
    # Le format réel est: première colonne = day_type, deuxième = "avg,min,max,count"
    if len(df.columns) == 2:
        # Première colonne = day_type, deuxième = valeurs séparées par virgule
        df.columns = ['day_type', 'values']
        # Parser les valeurs séparées par virgule
        values_split = df['values'].astype(str).str.split(',', expand=True)
        if len(values_split.columns) >= 4:
            df['avg_consumption'] = pd.to_numeric(values_split[0], errors='coerce')
            df['min_consumption'] = pd.to_numeric(values_split[1], errors='coerce')
            df['max_consumption'] = pd.to_numeric(values_split[2], errors='coerce')
            df['count'] = pd.to_numeric(values_split[3], errors='coerce')
        else:
            print(f"[ERREUR] Format des valeurs incorrect pour Q3")
            return
    else:
        print(f"[ERREUR] Format CSV inattendu pour Q3: {len(df.columns)} colonnes (attendu: 2)")
        return
    
    # Nettoyer le day_type
    df['day_type'] = df['day_type'].astype(str).str.strip()
    
    required_cols = ['day_type', 'avg_consumption', 'min_consumption', 'max_consumption']
    if not all(col in df.columns for col in required_cols):
        print(f"[ERREUR] Colonnes manquantes dans Q3. Colonnes disponibles: {df.columns.tolist()}")
        return
    
    # Nettoyer les données
    df['day_type'] = df['day_type'].astype(str).str.strip()
    df['avg_consumption'] = pd.to_numeric(df['avg_consumption'], errors='coerce')
    df['min_consumption'] = pd.to_numeric(df['min_consumption'], errors='coerce')
    df['max_consumption'] = pd.to_numeric(df['max_consumption'], errors='coerce')
    
    # Créer le graphique
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # Préparer les données pour le graphique groupé
    x = np.arange(len(df))
    width = 0.25
    
    # Créer les barres groupées
    bars1 = ax.bar(x - width, df['avg_consumption'], width, label='Moyenne', color='#2E86AB')
    bars2 = ax.bar(x, df['min_consumption'], width, label='Minimum', color='#A23B72')
    bars3 = ax.bar(x + width, df['max_consumption'], width, label='Maximum', color='#F18F01')
    
    # Personnalisation
    ax.set_xlabel('Type de jour', fontsize=12, fontweight='bold')
    ax.set_ylabel('Consommation (kW)', fontsize=12, fontweight='bold')
    ax.set_title('Comparaison de consommation : Semaine vs Week-end', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xticks(x)
    ax.set_xticklabels(df['day_type'].str.title().values)
    ax.legend(loc='best', fontsize=10)
    ax.grid(axis='y', alpha=0.3, linestyle='--')
    
    # Ajouter les valeurs sur les barres
    for bars in [bars1, bars2, bars3]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.2f}',
                   ha='center', va='bottom', fontsize=9)
    
    plt.tight_layout()
    
    # Sauvegarder
    output_path = output_dir / "Q3_Comparaison_Weekend.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"[OK] Graphique sauvegardé : {output_path}")
    plt.close()


def plot_q4_hourly_distribution(df, output_dir):
    """
    Fonction : plot_q4_hourly_distribution
    Rôle     : Génère un graphique en barres montrant la distribution horaire de consommation
    Param    : df - DataFrame pandas contenant les données, output_dir - répertoire de sortie
    Retour   : void (sauvegarde le graphique dans un fichier PNG)
    """
    if df is None or df.empty:
        print("[ERREUR] Aucune donnée pour Q4")
        return
    
    # Renommer les colonnes si nécessaire (pas de header)
    if len(df.columns) >= 4:
        df.columns = ['heure', 'nombre_mesures', 'consommation_moyenne', 'consommation_max'][:len(df.columns)]
    
    if 'consommation_moyenne' not in df.columns:
        print(f"[ERREUR] Colonne consommation_moyenne non trouvée dans Q4. Colonnes disponibles: {df.columns.tolist()}")
        return
    
    # Nettoyer les données
    df['heure'] = df['heure'].astype(str).str.strip().str.zfill(2)  # Format HH
    df['consommation_moyenne'] = pd.to_numeric(df['consommation_moyenne'], errors='coerce')
    
    # Trier par consommation moyenne décroissante pour mettre en évidence les pics
    df_sorted = df.sort_values('consommation_moyenne', ascending=False)
    
    # Identifier le top 3 (heures de pointe)
    top3_mask = df_sorted.head(3).index
    
    # Créer le graphique
    fig, ax = plt.subplots(figsize=(14, 8))
    
    # Créer les barres avec couleur spéciale pour le top 3
    colors = ['#F18F01' if idx in top3_mask else '#2E86AB' for idx in df_sorted.index]
    bars = ax.bar(range(len(df_sorted)), df_sorted['consommation_moyenne'].values, color=colors)
    
    # Personnalisation
    ax.set_xlabel('Heure de la journée', fontsize=12, fontweight='bold')
    ax.set_ylabel('Consommation moyenne (kW)', fontsize=12, fontweight='bold')
    ax.set_title('Distribution horaire de la consommation électrique (triée par consommation décroissante)', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.set_xticks(range(len(df_sorted)))
    ax.set_xticklabels([f"{h}:00" for h in df_sorted['heure'].values], rotation=45, ha='right')
    ax.grid(axis='y', alpha=0.3, linestyle='--')
    
    # Ajouter une légende pour le top 3
    from matplotlib.patches import Patch
    legend_elements = [
        Patch(facecolor='#F18F01', label='Top 3 heures de pointe'),
        Patch(facecolor='#2E86AB', label='Autres heures')
    ]
    ax.legend(handles=legend_elements, loc='upper right', fontsize=10)
    
    # Ajouter les valeurs sur le top 3
    for i, (idx, row) in enumerate(df_sorted.head(3).iterrows()):
        value = row['consommation_moyenne']
        ax.text(i, value + 0.05, f'{value:.2f} kW', 
                ha='center', fontsize=9, fontweight='bold')
    
    plt.tight_layout()
    
    # Sauvegarder
    output_path = output_dir / "Q4_Distribution_Horaire.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"[OK] Graphique sauvegardé : {output_path}")
    plt.close()


def plot_q5_annual_peak(df, output_dir):
    """
    Fonction : plot_q5_annual_peak
    Rôle     : Génère un graphique linéaire montrant l'évolution annuelle du pic de consommation
    Param    : df - DataFrame pandas contenant les données, output_dir - répertoire de sortie
    Retour   : void (sauvegarde le graphique dans un fichier PNG)
    """
    if df is None or df.empty:
        print("[ERREUR] Aucune donnée pour Q5")
        return
    
    # Renommer les colonnes si nécessaire (pas de header)
    if len(df.columns) >= 3:
        df.columns = ['annee', 'pic_annuel', 'consommation_moyenne'][:len(df.columns)]
    
    if 'annee' not in df.columns or 'pic_annuel' not in df.columns:
        print(f"[ERREUR] Colonnes manquantes dans Q5. Colonnes disponibles: {df.columns.tolist()}")
        return
    
    # Nettoyer les données
    df['annee'] = df['annee'].astype(str).str.strip()
    df['pic_annuel'] = pd.to_numeric(df['pic_annuel'], errors='coerce')
    
    # Trier par année
    df_sorted = df.sort_values('annee')
    
    # Créer le graphique
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Ligne pour le pic annuel
    line = ax.plot(df_sorted['annee'], df_sorted['pic_annuel'], 
                   marker='o', linewidth=2.5, markersize=10, 
                   label='Pic annuel de consommation', color='#A23B72')
    
    # Annotation du pic maximum
    max_idx = df_sorted['pic_annuel'].idxmax()
    max_value = df_sorted.loc[max_idx, 'pic_annuel']
    max_year = df_sorted.loc[max_idx, 'annee']
    ax.annotate(f'Pic maximum\n{max_value:.2f} kW ({max_year})',
                xy=(df_sorted[df_sorted['annee'] == max_year].index[0], max_value),
                xytext=(10, 10), textcoords='offset points',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0'),
                fontsize=10, fontweight='bold')
    
    # Personnalisation
    ax.set_xlabel('Année', fontsize=12, fontweight='bold')
    ax.set_ylabel('Pic annuel de consommation (kW)', fontsize=12, fontweight='bold')
    ax.set_title('Évolution annuelle du pic de consommation électrique', 
                 fontsize=14, fontweight='bold', pad=20)
    ax.legend(loc='best', fontsize=10)
    ax.grid(True, alpha=0.3, linestyle='--')
    
    plt.tight_layout()
    
    # Sauvegarder
    output_path = output_dir / "Q5_Pic_Annuel.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"[OK] Graphique sauvegardé : {output_path}")
    plt.close()


def main():
    """
    Fonction : main
    Rôle     : Fonction principale orchestrant la génération de tous les graphiques
    Param    : aucun
    Retour   : void
    """
    print("=" * 70)
    print("Génération des graphiques à partir des exports CSV")
    print("=" * 70)
    print()
    
    # Créer le répertoire de sortie
    create_output_directory(OUTPUT_DIR)
    print()
    
    # Vérifier que le répertoire d'export existe
    if not EXPORT_DIR.exists():
        print(f"[ERREUR] Répertoire d'export non trouvé : {EXPORT_DIR}")
        sys.exit(1)
    
    # Définir les fichiers CSV à traiter
    csv_files = {
        'Q1': {
            'path': EXPORT_DIR / 'Q1_Top10_Jours.csv',
            'sep': '\t',
            'header': None,  # Pas de header
            'func': plot_q1_top_days
        },
        'Q2': {
            'path': EXPORT_DIR / 'Q2_Evolution_Mensuelle.csv',
            'sep': ',',
            'header': None,  # Pas de header
            'func': plot_q2_monthly_evolution
        },
        'Q3': {
            'path': EXPORT_DIR / 'Q3_Comparaison_Weekend.csv',
            'sep': '\t',  # Format réellement TAB-separated
            'header': None,  # Pas de header
            'func': plot_q3_weekend_comparison
        },
        'Q4': {
            'path': EXPORT_DIR / 'Q4_Distribution_Horaire.csv',
            'sep': ',',
            'header': None,  # Pas de header
            'func': plot_q4_hourly_distribution
        },
        'Q5': {
            'path': EXPORT_DIR / 'Q5_Pic_Annuel.csv',
            'sep': ',',
            'header': None,  # Pas de header
            'func': plot_q5_annual_peak
        }
    }
    
    # Traiter chaque fichier
    for q_name, config in csv_files.items():
        print(f"\n--- Traitement {q_name} ---")
        
        if not config['path'].exists():
            print(f"[WARNING] Fichier non trouvé : {config['path']}")
            continue
        
        # Charger les données
        df = load_csv(config['path'], sep=config['sep'], header=config.get('header', None))
        
        if df is not None and not df.empty:
            # Générer le graphique
            config['func'](df, OUTPUT_DIR)
        else:
            print(f"[ERREUR] Impossible de générer le graphique pour {q_name}")
    
    print()
    print("=" * 70)
    print("[OK] Génération des graphiques terminée")
    print(f"[OK] Graphiques sauvegardés dans : {OUTPUT_DIR}")
    print("=" * 70)


if __name__ == "__main__":
    main()

