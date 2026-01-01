#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/validation/validate_mapreduce_output.sh
# Rôle : Script de validation des sorties MapReduce - Tests de validation
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./validate_mapreduce_output.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/tests/results"

mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "VALIDATION - Sorties MapReduce"
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
if ! command_exists hdfs; then
    echo "[ERREUR] Commande hdfs non trouvée"
    exit 1
fi

if ! hdfs dfsadmin -report &>/dev/null; then
    echo "[ERREUR] HDFS n'est pas accessible"
    exit 1
fi

# Validation Job 1
echo "[INFO] Validation Job 1: Agrégation par jour..."
JOB1_OUTPUT="/user/projet/output/job1_region_avg"
JOB1_VALID=0

if hdfs dfs -test -d "$JOB1_OUTPUT" 2>/dev/null; then
    FILE_COUNT=$(hdfs dfs -ls "$JOB1_OUTPUT/part-r-*" 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        LINE_COUNT=$(hdfs dfs -cat "$JOB1_OUTPUT/part-r-*" 2>/dev/null | wc -l)
        echo "  [INFO] Nombre de lignes: $LINE_COUNT"
        
        # Vérifier le format
        INVALID_FORMAT=0
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                continue
            fi
            if [[ ! "$line" == *$'\t'* ]]; then
                INVALID_FORMAT=$((INVALID_FORMAT + 1))
            fi
        done < <(hdfs dfs -cat "$JOB1_OUTPUT/part-r-*" 2>/dev/null | head -10)
        
        if [ "$INVALID_FORMAT" -eq 0 ]; then
            echo "  [OK] Format de sortie valide"
            JOB1_VALID=1
        else
            echo "  [ERREUR] $INVALID_FORMAT ligne(s) avec format invalide"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo "  [ERREUR] Aucun fichier de sortie trouvé"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    echo "  [ERREUR] Répertoire de sortie n'existe pas"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ "$JOB1_VALID" -eq 1 ]; then
    echo "[OK] Job 1 validé"
else
    echo "[ERREUR] Job 1 non valide"
fi
echo ""

# Validation Job 2
echo "[INFO] Validation Job 2: Détection des pics..."
JOB2_OUTPUT="/user/projet/output/job2_peaks"
JOB2_VALID=0

if hdfs dfs -test -d "$JOB2_OUTPUT" 2>/dev/null; then
    FILE_COUNT=$(hdfs dfs -ls "$JOB2_OUTPUT/part-r-*" 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        LINE_COUNT=$(hdfs dfs -cat "$JOB2_OUTPUT/part-r-*" 2>/dev/null | wc -l)
        echo "  [INFO] Nombre de lignes: $LINE_COUNT"
        
        # Vérifier le format
        INVALID_FORMAT=0
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                continue
            fi
            if [[ ! "$line" == *$'\t'* ]]; then
                INVALID_FORMAT=$((INVALID_FORMAT + 1))
            fi
        done < <(hdfs dfs -cat "$JOB2_OUTPUT/part-r-*" 2>/dev/null | head -10)
        
        if [ "$INVALID_FORMAT" -eq 0 ]; then
            echo "  [OK] Format de sortie valide"
            JOB2_VALID=1
        else
            echo "  [ERREUR] $INVALID_FORMAT ligne(s) avec format invalide"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo "  [ERREUR] Aucun fichier de sortie trouvé"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    echo "  [ERREUR] Répertoire de sortie n'existe pas"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ "$JOB2_VALID" -eq 1 ]; then
    echo "[OK] Job 2 validé"
else
    echo "[ERREUR] Job 2 non valide"
fi
echo ""

# Validation Job 3
echo "[INFO] Validation Job 3: Comparaison week-end..."
JOB3_OUTPUT="/user/projet/output/job3_weekend"
JOB3_VALID=0

if hdfs dfs -test -d "$JOB3_OUTPUT" 2>/dev/null; then
    FILE_COUNT=$(hdfs dfs -ls "$JOB3_OUTPUT/part-r-*" 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        LINE_COUNT=$(hdfs dfs -cat "$JOB3_OUTPUT/part-r-*" 2>/dev/null | wc -l)
        echo "  [INFO] Nombre de lignes: $LINE_COUNT"
        
        # Vérifier qu'on a au moins weekday et weekend
        HAS_WEEKDAY=$(hdfs dfs -cat "$JOB3_OUTPUT/part-r-*" 2>/dev/null | grep -c "^weekday" || echo "0")
        HAS_WEEKEND=$(hdfs dfs -cat "$JOB3_OUTPUT/part-r-*" 2>/dev/null | grep -c "^weekend" || echo "0")
        
        if [ "$HAS_WEEKDAY" -gt 0 ] && [ "$HAS_WEEKEND" -gt 0 ]; then
            echo "  [OK] Les deux types de jours sont présents"
        else
            echo "  [WARNING] Types de jours manquants (weekday=$HAS_WEEKDAY, weekend=$HAS_WEEKEND)"
        fi
        
        # Vérifier le format
        INVALID_FORMAT=0
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                continue
            fi
            if [[ ! "$line" == *$'\t'* ]]; then
                INVALID_FORMAT=$((INVALID_FORMAT + 1))
            fi
        done < <(hdfs dfs -cat "$JOB3_OUTPUT/part-r-*" 2>/dev/null)
        
        if [ "$INVALID_FORMAT" -eq 0 ]; then
            echo "  [OK] Format de sortie valide"
            JOB3_VALID=1
        else
            echo "  [ERREUR] $INVALID_FORMAT ligne(s) avec format invalide"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo "  [ERREUR] Aucun fichier de sortie trouvé"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    echo "  [ERREUR] Répertoire de sortie n'existe pas"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if [ "$JOB3_VALID" -eq 1 ]; then
    echo "[OK] Job 3 validé"
else
    echo "[ERREUR] Job 3 non valide"
fi
echo ""

# Générer un rapport de validation
REPORT_FILE="$RESULTS_DIR/validation_mapreduce_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Rapport de validation MapReduce"
    echo "Date: $(date)"
    echo ""
    echo "Job 1 (Agrégation par jour): $([ $JOB1_VALID -eq 1 ] && echo 'VALIDE' || echo 'NON VALIDE')"
    echo "Job 2 (Détection des pics): $([ $JOB2_VALID -eq 1 ] && echo 'VALIDE' || echo 'NON VALIDE')"
    echo "Job 3 (Comparaison week-end): $([ $JOB3_VALID -eq 1 ] && echo 'VALIDE' || echo 'NON VALIDE')"
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

