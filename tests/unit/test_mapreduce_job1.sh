#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/unit/test_mapreduce_job1.sh
# Rôle : Script de test unitaire pour le Job 1 MapReduce (Agrégation par jour) - Tests unitaires
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./test_mapreduce_job1.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/tests/results"

# Créer le répertoire de résultats si nécessaire
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "TEST UNITAIRE - Job 1 MapReduce"
echo "Agrégation par jour"
echo "=========================================="
echo ""

# Variables
TEST_OUTPUT="$RESULTS_DIR/test_job1_output.txt"
TEST_ERRORS=0

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

if ! command_exists java; then
    echo "[ERREUR] Commande java non trouvée"
    exit 1
fi

# Vérifier que HDFS est accessible
if ! hdfs dfsadmin -report &>/dev/null; then
    echo "[ERREUR] HDFS n'est pas accessible"
    exit 1
fi

# Vérifier que le JAR existe
JAR_FILE="$PROJECT_ROOT/mapreduce/target/mapreduce-consumption-1.0.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo "[ERREUR] JAR non trouvé: $JAR_FILE"
    echo "Compilez d'abord avec: cd mapreduce && mvn clean package"
    exit 1
fi

# Configurer le classpath Hadoop
export HADOOP_CLASSPATH=$(hadoop classpath)

# Définir les chemins de test
TEST_INPUT="/user/projet/data/raw"
TEST_OUTPUT_HDFS="/user/projet/output/test_job1"

# Supprimer l'output de test précédent si existe
hdfs dfs -rm -r "$TEST_OUTPUT_HDFS" 2>/dev/null

echo "[INFO] Exécution du Job 1 avec les données de test..."
echo ""

# Exécuter le job
java -cp "$JAR_FILE:$HADOOP_CLASSPATH" com.projet.RegionAvgDriver "$TEST_INPUT" "$TEST_OUTPUT_HDFS" 2>&1 | tee "$TEST_OUTPUT"

JOB_EXIT_CODE=${PIPESTATUS[0]}

if [ $JOB_EXIT_CODE -ne 0 ]; then
    echo "[ERREUR] Le job a échoué avec le code $JOB_EXIT_CODE"
    TEST_ERRORS=$((TEST_ERRORS + 1))
else
    echo ""
    echo "[OK] Job exécuté avec succès"
    echo ""
    
    # Vérifier que l'output existe
    if ! hdfs dfs -test -d "$TEST_OUTPUT_HDFS" 2>/dev/null; then
        echo "[ERREUR] Le répertoire de sortie n'existe pas: $TEST_OUTPUT_HDFS"
        TEST_ERRORS=$((TEST_ERRORS + 1))
    else
        echo "[OK] Répertoire de sortie créé"
        
        # Vérifier qu'il y a des fichiers de sortie
        FILE_COUNT=$(hdfs dfs -ls "$TEST_OUTPUT_HDFS/part-r-*" 2>/dev/null | wc -l)
        if [ "$FILE_COUNT" -eq 0 ]; then
            echo "[ERREUR] Aucun fichier de sortie trouvé"
            TEST_ERRORS=$((TEST_ERRORS + 1))
        else
            echo "[OK] Fichiers de sortie trouvés: $FILE_COUNT"
            
            # Récupérer un échantillon de résultats pour validation
            echo ""
            echo "[INFO] Échantillon des résultats (premiers 5):"
            hdfs dfs -cat "$TEST_OUTPUT_HDFS/part-r-*" 2>/dev/null | head -5
            echo ""
            
            # Valider le format de chaque ligne
            echo "[INFO] Validation du format de sortie..."
            VALID_LINES=0
            INVALID_LINES=0
            
            while IFS= read -r line; do
                if [ -z "$line" ]; then
                    continue
                fi
                
                # Format attendu: date<TAB>avg,min,max,count
                # Vérifier qu'il y a une tabulation
                if [[ "$line" == *$'\t'* ]]; then
                    # Séparer date et valeurs
                    DATE=$(echo "$line" | cut -f1)
                    VALUES=$(echo "$line" | cut -f2)
                    
                    # Vérifier le format de la date (D/MM/YYYY ou DD/MM/YYYY)
                    if [[ "$DATE" =~ ^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$ ]]; then
                        # Vérifier qu'il y a 4 valeurs séparées par des virgules
                        COMMA_COUNT=$(echo "$VALUES" | tr -cd ',' | wc -c)
                        if [ "$COMMA_COUNT" -eq 3 ]; then
                            # Extraire les valeurs
                            AVG=$(echo "$VALUES" | cut -d',' -f1)
                            MIN=$(echo "$VALUES" | cut -d',' -f2)
                            MAX=$(echo "$VALUES" | cut -d',' -f3)
                            COUNT=$(echo "$VALUES" | cut -d',' -f4)
                            
                            # Vérifier que les valeurs sont numériques
                            if [[ "$AVG" =~ ^[0-9]+\.?[0-9]*$ ]] && \
                               [[ "$MIN" =~ ^[0-9]+\.?[0-9]*$ ]] && \
                               [[ "$MAX" =~ ^[0-9]+\.?[0-9]*$ ]] && \
                               [[ "$COUNT" =~ ^[0-9]+$ ]]; then
                                VALID_LINES=$((VALID_LINES + 1))
                            else
                                echo "[WARNING] Ligne avec valeurs non numériques: $line"
                                INVALID_LINES=$((INVALID_LINES + 1))
                            fi
                        else
                            echo "[WARNING] Format invalide (pas 4 valeurs): $line"
                            INVALID_LINES=$((INVALID_LINES + 1))
                        fi
                    else
                        echo "[WARNING] Format de date invalide: $DATE"
                        INVALID_LINES=$((INVALID_LINES + 1))
                    fi
                else
                    echo "[WARNING] Ligne sans tabulation: $line"
                    INVALID_LINES=$((INVALID_LINES + 1))
                fi
            done < <(hdfs dfs -cat "$TEST_OUTPUT_HDFS/part-r-*" 2>/dev/null)
            
            echo "[INFO] Lignes valides: $VALID_LINES"
            if [ "$INVALID_LINES" -gt 0 ]; then
                echo "[WARNING] Lignes invalides: $INVALID_LINES"
            else
                echo "[OK] Toutes les lignes sont au format correct"
            fi
            
            # Vérifier la cohérence logique (min <= avg <= max)
            echo ""
            echo "[INFO] Vérification de la cohérence logique (min <= avg <= max)..."
            INCONSISTENT=0
            
            while IFS= read -r line; do
                if [ -z "$line" ]; then
                    continue
                fi
                VALUES=$(echo "$line" | cut -f2)
                AVG=$(echo "$VALUES" | cut -d',' -f1)
                MIN=$(echo "$VALUES" | cut -d',' -f2)
                MAX=$(echo "$VALUES" | cut -d',' -f3)
                
                # Comparaison numérique avec awk
                if ! awk "BEGIN {exit !($MIN <= $AVG && $AVG <= $MAX)}"; then
                    echo "[WARNING] Incohérence détectée: min=$MIN, avg=$AVG, max=$MAX"
                    INCONSISTENT=$((INCONSISTENT + 1))
                fi
            done < <(hdfs dfs -cat "$TEST_OUTPUT_HDFS/part-r-*" 2>/dev/null | head -10)
            
            if [ "$INCONSISTENT" -eq 0 ]; then
                echo "[OK] Cohérence logique vérifiée"
            else
                echo "[WARNING] Incohérences détectées: $INCONSISTENT"
            fi
        fi
    fi
fi

# Nettoyer
hdfs dfs -rm -r "$TEST_OUTPUT_HDFS" 2>/dev/null

echo ""
echo "=========================================="
if [ $TEST_ERRORS -eq 0 ]; then
    echo "[OK] TEST UNITAIRE RÉUSSI"
else
    echo "[ERREUR] TEST UNITAIRE ÉCHOUÉ ($TEST_ERRORS erreur(s))"
fi
echo "=========================================="
echo ""

exit $TEST_ERRORS

