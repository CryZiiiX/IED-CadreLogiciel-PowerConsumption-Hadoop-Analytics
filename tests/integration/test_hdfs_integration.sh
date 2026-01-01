#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/integration/test_hdfs_integration.sh
# Rôle : Script de test d'intégration HDFS - Tests d'intégration
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./test_hdfs_integration.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "TEST D'INTÉGRATION - HDFS"
echo "=========================================="
echo ""

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

# Test 1: Vérifier que HDFS est accessible
echo "[INFO] Test 1: Vérification de l'accessibilité de HDFS..."
if hdfs dfsadmin -report &>/dev/null; then
    echo "[OK] HDFS est accessible"
else
    echo "[ERREUR] HDFS n'est pas accessible"
    TEST_ERRORS=$((TEST_ERRORS + 1))
    exit 1
fi
echo ""

# Test 2: Vérifier la structure des répertoires
echo "[INFO] Test 2: Vérification de la structure des répertoires..."
REQUIRED_DIRS=(
    "/user/projet"
    "/user/projet/data"
    "/user/projet/data/raw"
    "/user/projet/output"
)

MISSING_DIRS=0
for dir in "${REQUIRED_DIRS[@]}"; do
    if hdfs dfs -test -d "$dir" 2>/dev/null; then
        echo "  [OK] $dir existe"
    else
        echo "  [ERREUR] $dir n'existe pas"
        MISSING_DIRS=$((MISSING_DIRS + 1))
        TEST_ERRORS=$((TEST_ERRORS + 1))
    fi
done

if [ "$MISSING_DIRS" -eq 0 ]; then
    echo "[OK] Tous les répertoires requis existent"
else
    echo "[ERREUR] $MISSING_DIRS répertoire(s) manquant(s)"
fi
echo ""

# Test 3: Vérifier la présence des données brutes
echo "[INFO] Test 3: Vérification de la présence des données brutes..."
DATA_DIR="/user/projet/data/raw"
if hdfs dfs -test -d "$DATA_DIR" 2>/dev/null; then
    FILE_COUNT=$(hdfs dfs -ls "$DATA_DIR" 2>/dev/null | grep -v "^Found" | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "[OK] Données trouvées dans $DATA_DIR ($FILE_COUNT fichier(s))"
        echo "  Liste des fichiers:"
        hdfs dfs -ls -h "$DATA_DIR" 2>/dev/null | tail -n +2 | while read line; do
            echo "    $line"
        done
    else
        echo "[WARNING] Aucun fichier trouvé dans $DATA_DIR"
    fi
else
    echo "[ERREUR] Répertoire $DATA_DIR n'existe pas"
    TEST_ERRORS=$((TEST_ERRORS + 1))
fi
echo ""

# Test 4: Vérifier les résultats MapReduce
echo "[INFO] Test 4: Vérification des résultats MapReduce..."
OUTPUT_DIRS=(
    "/user/projet/output/job1_region_avg"
    "/user/projet/output/job2_peaks"
    "/user/projet/output/job3_weekend"
)

MISSING_OUTPUTS=0
for dir in "${OUTPUT_DIRS[@]}"; do
    if hdfs dfs -test -d "$dir" 2>/dev/null; then
        FILE_COUNT=$(hdfs dfs -ls "$dir/part-r-*" 2>/dev/null | wc -l)
        if [ "$FILE_COUNT" -gt 0 ]; then
            echo "  [OK] $dir contient $FILE_COUNT fichier(s) de sortie"
        else
            echo "  [WARNING] $dir existe mais ne contient pas de fichiers part-r-*"
        fi
    else
        echo "  [WARNING] $dir n'existe pas (job peut ne pas avoir été exécuté)"
        MISSING_OUTPUTS=$((MISSING_OUTPUTS + 1))
    fi
done

if [ "$MISSING_OUTPUTS" -lt "${#OUTPUT_DIRS[@]}" ]; then
    echo "[OK] Au moins un répertoire de sortie MapReduce existe"
else
    echo "[WARNING] Aucun répertoire de sortie MapReduce trouvé"
fi
echo ""

# Test 5: Test de lecture/écriture
echo "[INFO] Test 5: Test de lecture/écriture..."
TEST_FILE="/user/projet/test_integration.txt"
TEST_CONTENT="test integration hdfs $(date +%s)"

# Écrire un fichier de test
if echo "$TEST_CONTENT" | hdfs dfs -put - "$TEST_FILE" 2>/dev/null; then
    echo "  [OK] Écriture réussie dans $TEST_FILE"
    
    # Lire le fichier de test
    READ_CONTENT=$(hdfs dfs -cat "$TEST_FILE" 2>/dev/null)
    if [ "$READ_CONTENT" == "$TEST_CONTENT" ]; then
        echo "  [OK] Lecture réussie, contenu vérifié"
    else
        echo "  [ERREUR] Contenu lu ne correspond pas au contenu écrit"
        TEST_ERRORS=$((TEST_ERRORS + 1))
    fi
    
    # Nettoyer
    hdfs dfs -rm "$TEST_FILE" 2>/dev/null
    echo "  [OK] Fichier de test supprimé"
else
    echo "  [ERREUR] Impossible d'écrire dans HDFS"
    TEST_ERRORS=$((TEST_ERRORS + 1))
fi
echo ""

# Test 6: Vérifier les permissions
echo "[INFO] Test 6: Vérification des permissions..."
PERM_TEST=0
if hdfs dfs -ls /user/projet &>/dev/null; then
    echo "  [OK] Permissions suffisantes pour lire /user/projet"
else
    echo "  [ERREUR] Permissions insuffisantes pour lire /user/projet"
    PERM_TEST=1
    TEST_ERRORS=$((TEST_ERRORS + 1))
fi

if [ "$PERM_TEST" -eq 0 ]; then
    echo "[OK] Permissions HDFS vérifiées"
fi
echo ""

# Résumé
echo "=========================================="
if [ $TEST_ERRORS -eq 0 ]; then
    echo "[OK] TOUS LES TESTS D'INTÉGRATION HDFS RÉUSSIS"
else
    echo "[ERREUR] TESTS D'INTÉGRATION HDFS ÉCHOUÉS ($TEST_ERRORS erreur(s))"
fi
echo "=========================================="
echo ""

exit $TEST_ERRORS

