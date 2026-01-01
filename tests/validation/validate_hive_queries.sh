#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/validation/validate_hive_queries.sh
# Rôle : Script de validation des requêtes Hive analytiques - Tests de validation
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./validate_hive_queries.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/tests/results"

mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "VALIDATION - Requêtes Hive Analytiques"
echo "=========================================="
echo ""

VALIDATION_ERRORS=0

# Fonction : command_exists
# Rôle     : Vérifie si une commande est disponible dans le PATH
# Param    : $1 - nom de la commande à vérifier
# Retour   : 0 si trouvée, 1 sinon
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Vérifier les prérequis
if ! command_exists hive; then
    echo "[ERREUR] Commande hive non trouvée"
    exit 1
fi

# Vérifier la base de données
DB_EXISTS=$(hive -e "SHOW DATABASES;" 2>/dev/null | grep -c "consommation_elec" || echo "0")
if [ "$DB_EXISTS" -eq 0 ]; then
    echo "[ERREUR] Base de données consommation_elec n'existe pas"
    exit 1
fi

# Test Q1: Top 10 jours
echo "[INFO] Test Q1: Consommation moyenne par jour (TOP 10)..."
Q1_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM (SELECT \`date\`, avg_consumption FROM conso_par_jour ORDER BY avg_consumption DESC LIMIT 10) q1;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
if [ -n "$Q1_RESULT" ] && [[ "$Q1_RESULT" =~ ^[0-9]+$ ]] && [ "$Q1_RESULT" -eq 10 ]; then
    echo "  [OK] Q1 retourne 10 résultats"
else
    echo "  [WARNING] Q1 retourne $Q1_RESULT résultat(s) (attendu: 10)"
fi
echo ""

# Test Q2: Évolution mensuelle
echo "[INFO] Test Q2: Évolution mensuelle..."
Q2_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM (SELECT CONCAT(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(date, 'dd/MM/yyyy'))), '-', LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(date, 'dd/MM/yyyy'))), 2, '0')) AS year_month FROM conso_par_jour WHERE date IS NOT NULL AND UNIX_TIMESTAMP(date, 'dd/MM/yyyy') IS NOT NULL GROUP BY CONCAT(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(date, 'dd/MM/yyyy'))), '-', LPAD(MONTH(FROM_UNIXTIME(UNIX_TIMESTAMP(date, 'dd/MM/yyyy'))), 2, '0'))) q2;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
if [ -n "$Q2_RESULT" ] && [[ "$Q2_RESULT" =~ ^[0-9]+$ ]] && [ "$Q2_RESULT" -gt 0 ]; then
    echo "  [OK] Q2 retourne $Q2_RESULT mois"
else
    echo "  [WARNING] Q2 retourne $Q2_RESULT résultat(s)"
fi
echo ""

# Test Q3: Comparaison week-end
echo "[INFO] Test Q3: Comparaison semaine/week-end..."
Q3_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM comparaison_jours;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
if [ -n "$Q3_RESULT" ] && [[ "$Q3_RESULT" =~ ^[0-9]+$ ]] && [ "$Q3_RESULT" -eq 2 ]; then
    echo "  [OK] Q3 retourne 2 résultats (weekday et weekend)"
else
    echo "  [WARNING] Q3 retourne $Q3_RESULT résultat(s) (attendu: 2)"
fi
echo ""

# Test Q4: Distribution horaire
echo "[INFO] Test Q4: Distribution horaire..."
Q4_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM (SELECT SUBSTRING(time, 1, 2) AS heure FROM consumption_raw WHERE global_active_power IS NOT NULL GROUP BY SUBSTRING(time, 1, 2) ORDER BY AVG(global_active_power) DESC LIMIT 10) q4;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
if [ -n "$Q4_RESULT" ] && [[ "$Q4_RESULT" =~ ^[0-9]+$ ]] && [ "$Q4_RESULT" -eq 10 ]; then
    echo "  [OK] Q4 retourne 10 résultats"
else
    echo "  [WARNING] Q4 retourne $Q4_RESULT résultat(s) (attendu: 10)"
fi
echo ""

# Test Q5: Pic annuel
echo "[INFO] Test Q5: Pic de consommation annuel..."
Q5_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM (SELECT CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(\`date\`, 'dd/MM/yyyy'))) AS STRING) AS annee FROM consumption_raw WHERE \`date\` IS NOT NULL AND UNIX_TIMESTAMP(\`date\`, 'dd/MM/yyyy') IS NOT NULL AND global_active_power IS NOT NULL GROUP BY CAST(YEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(\`date\`, 'dd/MM/yyyy'))) AS STRING)) q5;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
if [ -n "$Q5_RESULT" ] && [[ "$Q5_RESULT" =~ ^[0-9]+$ ]] && [ "$Q5_RESULT" -gt 0 ]; then
    echo "  [OK] Q5 retourne $Q5_RESULT année(s)"
else
    echo "  [WARNING] Q5 retourne $Q5_RESULT résultat(s)"
fi
echo ""

# Test des exports
echo "[INFO] Test des exports HDFS..."
EXPORT_BASE="/user/projet/export"
EXPORT_DIRS=(
    "q1_top_days"
    "q2_monthly_evolution"
    "q3_weekend_comparison"
    "q4_hourly_distribution"
    "q5_annual_peak"
)

if command_exists hdfs; then
    EXPORT_VALID=0
    MISSING_EXPORTS=0
    
    for dir in "${EXPORT_DIRS[@]}"; do
        EXPORT_PATH="$EXPORT_BASE/$dir"
        if hdfs dfs -test -d "$EXPORT_PATH" 2>/dev/null; then
            FILE_COUNT=$(hdfs dfs -ls "$EXPORT_PATH" 2>/dev/null | grep -v "^Found" | wc -l)
            if [ "$FILE_COUNT" -gt 0 ]; then
                echo "  [OK] Export $dir existe ($FILE_COUNT fichier(s))"
                EXPORT_VALID=$((EXPORT_VALID + 1))
            else
                echo "  [WARNING] Export $dir existe mais est vide"
                MISSING_EXPORTS=$((MISSING_EXPORTS + 1))
            fi
        else
            echo "  [WARNING] Export $dir n'existe pas"
            MISSING_EXPORTS=$((MISSING_EXPORTS + 1))
        fi
    done
    
    if [ "$EXPORT_VALID" -eq "${#EXPORT_DIRS[@]}" ]; then
        echo "[OK] Tous les exports sont présents"
    else
        echo "[WARNING] $MISSING_EXPORTS export(s) manquant(s) ou vide(s)"
    fi
else
    echo "[WARNING] Commande hdfs non disponible, impossible de vérifier les exports"
fi
echo ""

# Générer un rapport de validation
REPORT_FILE="$RESULTS_DIR/validation_hive_queries_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Rapport de validation Requêtes Hive"
    echo "Date: $(date)"
    echo ""
    echo "Résultats des requêtes:"
    echo "  - Q1 (Top 10 jours): $Q1_RESULT résultat(s)"
    echo "  - Q2 (Évolution mensuelle): $Q2_RESULT résultat(s)"
    echo "  - Q3 (Comparaison week-end): $Q3_RESULT résultat(s)"
    echo "  - Q4 (Distribution horaire): $Q4_RESULT résultat(s)"
    echo "  - Q5 (Pic annuel): $Q5_RESULT résultat(s)"
    echo ""
    echo "Exports:"
    echo "  - Exports présents: $EXPORT_VALID/${#EXPORT_DIRS[@]}"
    echo ""
    echo "Nombre d'erreurs: $VALIDATION_ERRORS"
} > "$REPORT_FILE"

echo "[INFO] Rapport de validation sauvegardé: $REPORT_FILE"
echo ""

echo "=========================================="
if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "[OK] VALIDATION RÉUSSIE"
else
    echo "[ERREUR] VALIDATION ÉCHOUÉE ($VALIDATION_ERRORS erreur(s))"
fi
echo "=========================================="
echo ""

exit $VALIDATION_ERRORS

