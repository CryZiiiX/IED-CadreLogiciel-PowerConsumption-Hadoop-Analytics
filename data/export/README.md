# Documentation des Exports - Analyse de Consommation Électrique

## Introduction

Ce répertoire contient les fichiers CSV exportés depuis Hive suite aux analyses de consommation électrique. Ces fichiers représentent les résultats des requêtes analytiques exécutées sur les données de consommation électrique d'un foyer individuel (période : Décembre 2006 - Novembre 2010).

### Format des fichiers

- **Format** : CSV (Comma-Separated Values)
- **Séparateur** : Virgule (`,`)
- **Encodage** : UTF-8
- **Unité de mesure principale** : Kilowatts (kW) pour toutes les mesures de consommation
- **Format date** : DD/MM/YYYY (format européen)
- **Format heure** : HH (format 24 heures, 00-23)

---

## Q1_Top10_Jours.csv

### Description

Top 10 des jours avec la consommation moyenne journalière la plus élevée. Ce fichier identifie les jours de consommation record sur toute la période analysée.

### Source de données

- **Table source** : `conso_par_jour`
- **Origine** : Résultats du Job 1 MapReduce (Agrégation par jour)
- **Nombre de lignes** : 10 (top 10)

### Structure des colonnes

| Colonne | Type | Unité | Description |
|---------|------|-------|-------------|
| `date` | STRING | - | Date de la mesure au format DD/MM/YYYY (ex: 16/12/2006) |
| `avg_consumption` | DOUBLE | kW | Consommation moyenne journalière en kilowatts |
| `min_consumption` | DOUBLE | kW | Consommation minimale observée durant ce jour (kilowatts) |
| `max_consumption` | DOUBLE | kW | Consommation maximale observée durant ce jour (kilowatts) |
| `count` | BIGINT | nombre | Nombre de mesures effectuées ce jour |

### Interprétation

Ce fichier permet d'identifier :
- Les jours avec les plus fortes consommations moyennes
- L'amplitude des variations journalières (différence entre min et max)
- La fréquence des mesures pour chaque jour record

**Exemple d'utilisation** : Identifier les périodes critiques nécessitant une attention particulière pour la gestion de l'énergie.

---

## Q2_Evolution_Mensuelle.csv

### Description

Évolution mensuelle de la consommation électrique. Ce fichier présente les statistiques agrégées par mois, permettant d'analyser les tendances saisonnières et l'évolution temporelle sur plusieurs années.

### Source de données

- **Table source** : `conso_par_jour` (agrégation mensuelle)
- **Période couverte** : Décembre 2006 - Novembre 2010 (47 mois)
- **Tri** : Par ordre chronologique (year_month)

### Structure des colonnes

| Colonne | Type | Unité | Description |
|---------|------|-------|-------------|
| `year_month` | STRING | - | Période au format YYYY-MM (ex: 2007-01 pour janvier 2007) |
| `consommation_moyenne` | DOUBLE | kW | Consommation moyenne mensuelle en kilowatts |
| `consommation_min` | DOUBLE | kW | Consommation minimale observée durant le mois (kilowatts) |
| `consommation_max` | DOUBLE | kW | Consommation maximale observée durant le mois (kilowatts) |
| `total_mesures` | BIGINT | nombre | Nombre total de mesures agrégées pour ce mois |

### Interprétation

Ce fichier permet d'analyser :
- Les tendances saisonnières (hiver vs été)
- L'évolution de la consommation sur plusieurs années
- L'amplitude des variations mensuelles
- Les mois avec les plus fortes/moindres consommations

**Exemple d'utilisation** : Identifier les périodes saisonnières nécessitant une production d'électricité accrue.

---

## Q3_Comparaison_Weekend.csv

### Description

Comparaison des consommations entre les jours de semaine (weekday) et les week-ends (weekend). Ce fichier met en évidence les différences de comportement électrique selon le type de jour.

### Source de données

- **Table source** : `comparaison_jours`
- **Origine** : Résultats du Job 3 MapReduce (Comparaison semaine/week-end)
- **Nombre de lignes** : 2 (weekday et weekend)

### Structure des colonnes

| Colonne | Type | Unité | Description |
|---------|------|-------|-------------|
| `day_type` | STRING | - | Type de jour : "weekday" (jour de semaine) ou "weekend" (week-end) |
| `avg_consumption` | DOUBLE | kW | Consommation moyenne pour ce type de jour (kilowatts) |
| `min_consumption` | DOUBLE | kW | Consommation minimale observée (kilowatts) |
| `max_consumption` | DOUBLE | kW | Consommation maximale observée (kilowatts) |
| `count` | BIGINT | nombre | Nombre total de mesures pour ce type de jour |

### Interprétation

Ce fichier permet de :
- Comparer les niveaux de consommation entre semaine et week-end
- Identifier si le comportement est différent selon le type de jour
- Comprendre l'impact des habitudes de vie sur la consommation

**Exemple d'utilisation** : Adapter les stratégies de gestion énergétique selon le jour de la semaine.

---

## Q4_Distribution_Horaire.csv

### Description

Distribution horaire de la consommation électrique. Ce fichier présente les statistiques par heure de la journée, permettant d'identifier les heures de pointe de consommation.

### Source de données

- **Table source** : `consumption_raw` (données brutes)
- **Agrégation** : Par heure (00 à 23)
- **Tri** : Par consommation moyenne décroissante (top 10 heures)
- **Filtre** : Uniquement les mesures où `global_active_power IS NOT NULL`

### Structure des colonnes

| Colonne | Type | Unité | Description |
|---------|------|-------|-------------|
| `heure` | STRING | heure | Heure de la journée au format HH (00-23), ex: "08" pour 8h du matin |
| `nombre_mesures` | BIGINT | nombre | Nombre de mesures agrégées pour cette heure sur toute la période |
| `consommation_moyenne` | DOUBLE | kW | Consommation moyenne observée à cette heure (kilowatts) |
| `consommation_max` | DOUBLE | kW | Consommation maximale observée à cette heure (kilowatts) |

### Interprétation

Ce fichier permet d'identifier :
- Les heures de pointe de consommation (heures avec la consommation moyenne la plus élevée)
- Les créneaux horaires critiques nécessitant une attention particulière
- Les patterns de consommation journaliers

**Exemple d'utilisation** : Optimiser la distribution d'électricité en anticipant les pics horaires. Planifier les opérations énergivores en dehors des heures de pointe.

**Note** : Le fichier contient uniquement le top 10 des heures avec la consommation moyenne la plus élevée (trié par consommation moyenne décroissante).

---

## Q5_Pic_Annuel.csv

### Description

Statistiques annuelles de consommation électrique. Ce fichier présente les pics et moyennes par année, permettant d'analyser l'évolution inter-annuelle.

### Source de données

- **Table source** : `conso_par_jour` (agrégation annuelle)
- **Période couverte** : 2007, 2008, 2009, 2010 (4 années complètes)
- **Tri** : Par ordre chronologique (année)

### Structure des colonnes

| Colonne | Type | Unité | Description |
|---------|------|-------|-------------|
| `annee` | STRING | - | Année au format YYYY (ex: "2007") |
| `pic_annuel` | DOUBLE | kW | Pic de consommation annuel (consommation maximale observée sur l'année) en kilowatts |
| `consommation_moyenne` | DOUBLE | kW | Consommation moyenne annuelle en kilowatts |

### Interprétation

Ce fichier permet d'analyser :
- L'évolution de la consommation sur plusieurs années
- Les années avec les pics de consommation les plus élevés
- Les tendances à long terme (augmentation, diminution, stabilité)

**Exemple d'utilisation** : Évaluer l'impact des changements de comportement ou d'équipements sur la consommation annuelle. Planifier la capacité de production nécessaire pour les années à venir.

---

## Informations techniques communes

### Unités de mesure

- **Consommation électrique** : Toutes les valeurs de consommation sont exprimées en **kilowatts (kW)**
  - 1 kW = 1000 watts
  - Ces valeurs représentent la puissance active globale mesurée

### Formats de données

- **Dates** : Format européen DD/MM/YYYY (ex: 16/12/2006)
- **Heures** : Format 24 heures HH (00-23, ex: "08" pour 8h, "20" pour 20h)
- **Nombres décimaux** : Utilisation du point (.) comme séparateur décimal

### Période de données

- **Début** : Décembre 2006
- **Fin** : Novembre 2010
- **Durée totale** : ~4 ans de données
- **Fréquence de mesure originale** : 1 mesure par minute
- **Source** : Foyer individuel (Household Electric Power Consumption - UCI Repository)

---

## Notes d'interprétation

### Conseils pour la visualisation

1. **Q1_Top10_Jours.csv** : Visualiser avec un graphique en barres ou colonnes pour comparer les consommations moyennes
2. **Q2_Evolution_Mensuelle.csv** : Utiliser un graphique linéaire temporel pour visualiser les tendances saisonnières
3. **Q3_Comparaison_Weekend.csv** : Comparer avec un graphique en barres côte à côte (weekday vs weekend)
4. **Q4_Distribution_Horaire.csv** : Graphique en barres pour identifier visuellement les heures de pointe
5. **Q5_Pic_Annuel.csv** : Graphique linéaire ou barres pour visualiser l'évolution annuelle

### Remarques importantes

- Les valeurs de consommation sont en **kilowatts (kW)**, représentant la puissance active
- Les données proviennent d'un **foyer individuel**, les valeurs peuvent donc sembler faibles par rapport à des données agrégées
- Les valeurs manquantes dans les données sources ont été exclues des calculs
- Les agrégations (moyennes, min, max) sont calculées sur toutes les mesures disponibles pour chaque période

### Utilisation pour l'analyse

Ces exports permettent de répondre à des questions métier telles que :
- Quand faut-il augmenter la production d'électricité ?
- Quelles sont les périodes critiques nécessitant une attention particulière ?
- Y a-t-il des patterns récurrents dans la consommation ?
- Comment la consommation évolue-t-elle dans le temps ?

---

**Date de génération** : Décembre 2024  
**Projet** : Analyse Big Data de la Consommation Électrique  
**Technologies** : Hadoop 3.3.6, Hive 3.1.3, MapReduce

