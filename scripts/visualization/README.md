# Script de Visualisation - Graphiques des Exports CSV

## Description

Ce script génère automatiquement 5 graphiques à partir des fichiers CSV exportés depuis Hive. Les graphiques sont créés en utilisant seaborn et matplotlib pour un rendu esthétique et professionnel.

## Prérequis

### Bibliothèques Python requises

- `pandas` >= 1.3.0
- `seaborn` >= 0.11.0
- `matplotlib` >= 3.4.0
- `numpy` >= 1.21.0

### Installation des dépendances

```bash
pip install -r requirements.txt
```

Ou manuellement :

```bash
pip install pandas seaborn matplotlib numpy
```

## Utilisation

### Exécution du script

```bash
cd scripts/visualization
python3 generate_graphs.py
```

Le script :
1. Charge les fichiers CSV depuis `PROJET/data/export/`
2. Génère les 5 graphiques
3. Sauvegarde les graphiques en PNG (300 DPI) dans `PROJET/data/visualizations/`

### Fichiers CSV requis

Le script attend les fichiers suivants dans `PROJET/data/export/` :

- `Q1_Top10_Jours.csv`
- `Q2_Evolution_Mensuelle.csv`
- `Q3_Comparaison_Weekend.csv`
- `Q4_Distribution_Horaire.csv`
- `Q5_Pic_Annuel.csv`

Si un fichier est manquant, le script affiche un avertissement et continue avec les autres.

## Graphiques générés

### Q1 - Top 10 des Jours

**Fichier généré** : `Q1_Top10_Jours.png`

**Type** : Graphique en barres horizontales

**Description** : Affiche les 10 jours avec la consommation moyenne journalière la plus élevée. Les barres sont colorées avec un gradient (palette viridis) et les valeurs sont annotées sur chaque barre.

**Colonnes utilisées** :
- Date (axe Y)
- Consommation moyenne (axe X, en kW)

### Q2 - Évolution Mensuelle

**Fichier généré** : `Q2_Evolution_Mensuelle.png`

**Type** : Graphique linéaire temporel

**Description** : Visualise l'évolution de la consommation moyenne mensuelle sur toute la période. Si disponible, une zone ombragée indique la plage min-max pour chaque mois.

**Colonnes utilisées** :
- Année-Mois (axe X, format YYYY-MM)
- Consommation moyenne (axe Y, en kW)
- Consommation min/max (zone ombragée optionnelle)

### Q3 - Comparaison Week-End

**Fichier généré** : `Q3_Comparaison_Weekend.png`

**Type** : Graphique en barres groupées (côte à côte)

**Description** : Compare la consommation entre les jours de semaine (weekday) et les week-ends. Trois métriques sont affichées : moyenne, minimum et maximum.

**Colonnes utilisées** :
- Type de jour (weekday/weekend, axe X)
- Consommation moyenne, min, max (axe Y, en kW)

### Q4 - Distribution Horaire

**Fichier généré** : `Q4_Distribution_Horaire.png`

**Type** : Graphique en barres verticales

**Description** : Identifie les heures de pointe de consommation. Les heures sont triées par consommation moyenne décroissante, avec les 3 heures de pointe mises en évidence en orange.

**Colonnes utilisées** :
- Heure de la journée (axe X, format HH:00)
- Consommation moyenne (axe Y, en kW)

### Q5 - Pic Annuel

**Fichier généré** : `Q5_Pic_Annuel.png`

**Type** : Graphique linéaire

**Description** : Visualise l'évolution annuelle du pic de consommation. Le pic maximum est annoté sur le graphique.

**Colonnes utilisées** :
- Année (axe X)
- Pic annuel de consommation (axe Y, en kW)

## Répertoires

```
PROJET/
├── data/
│   ├── export/              # Fichiers CSV source (entrée)
│   └── visualizations/      # Graphiques générés (sortie)
└── scripts/
    └── visualization/
        ├── generate_graphs.py
        ├── requirements.txt
        └── README.md
```

## Personnalisation

### Style des graphiques

Le script utilise le style `whitegrid` de seaborn. Pour changer le style, modifiez la ligne suivante dans `generate_graphs.py` :

```python
sns.set_style("whitegrid")  # Options: "whitegrid", "darkgrid", "white", "dark", "ticks"
```

### Palette de couleurs

La palette par défaut est `husl`. Pour changer, modifiez :

```python
sns.set_palette("husl")  # Options: "viridis", "muted", "pastel", "husl", etc.
```

### Taille des graphiques

Les tailles par défaut sont définies dans chaque fonction de graphique avec `figsize=(largeur, hauteur)` (en pouces).

### Résolution

La résolution par défaut est 300 DPI. Pour changer, modifiez le paramètre `dpi` dans `plt.savefig()`.

## Gestion des erreurs

Le script gère automatiquement :
- Fichiers CSV manquants
- Format de colonnes inattendu
- Valeurs NULL (`\N`)
- Formats de séparation variés (TAB vs virgule)

En cas d'erreur, le script affiche un message explicite et continue avec les autres graphiques.

## Notes techniques

- Les fichiers CSV n'ont pas d'en-tête (header), les colonnes sont donc numérotées automatiquement
- Q1 et Q3 utilisent le séparateur TAB (`\t`)
- Q2, Q4 et Q5 utilisent la virgule (`,`)
- Les valeurs `\N` sont traitées comme NaN
- Les graphiques sont sauvegardés avec un fond transparent (pour intégration facile dans des documents)

