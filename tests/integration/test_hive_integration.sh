#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/integration/test_hive_integration.sh
# Rôle : Script de test d'intégration Hive - Tests d'intégration
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./test_hive_integration.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "TEST D'INTÉGRATION - Hive"
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
if ! command_exists hive; then
    echo "[ERREUR] Commande hive non trouvée"
    echo "[INFO] Assurez-vous que HIVE_HOME est défini et dans PATH"
    exit 1
fi

# Test 1: Vérifier que Hive est accessible
echo "[INFO] Test 1: Vérification de l'accessibilité de Hive..."
if hive -e "SHOW DATABASES;" &>/dev/null; then
    echo "[OK] Hive est accessible"
else
    echo "[ERREUR] Hive n'est pas accessible"
    echo "[INFO] Vérifiez que le Metastore Hive est démarré"
    TEST_ERRORS=$((TEST_ERRORS + 1))
    exit 1
fi
echo ""

# Test 2: Vérifier la base de données
echo "[INFO] Test 2: Vérification de la base de données consommation_elec..."
DB_EXISTS=$(hive -e "SHOW DATABASES;" 2>/dev/null | grep -c "consommation_elec" || echo "0")
if [ "$DB_EXISTS" -gt 0 ]; then
    echo "[OK] Base de données consommation_elec existe"
else
    echo "[WARNING] Base de données consommation_elec n'existe pas"
    echo "[INFO] Créez-la avec: hive -f hive/scripts/01_create_database.hql"
fi
echo ""

# Test 3: Vérifier les tables
echo "[INFO] Test 3: Vérification des tables Hive..."
EXPECTED_TABLES=(
    "consumption_raw"
    "conso_par_jour"
    "pics_journaliers"
    "comparaison_jours"
)

hive -e "USE consommation_elec; SHOW TABLES;" 2>/dev/null > /tmp/hive_tables.txt
TABLE_CHECK_ERRORS=0

for table in "${EXPECTED_TABLES[@]}"; do
    if grep -q "^$table$" /tmp/hive_tables.txt 2>/dev/null; then
        echo "  [OK] Table $table existe"
        
        # Vérifier que la table a du contenu
        ROW_COUNT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM $table;" 2>/dev/null | tail -1 | tr -d ' ')
        if [ -n "$ROW_COUNT" ] && [[ "$ROW_COUNT" =~ ^[0-9]+$ ]] && [ "$ROW_COUNT" -gt 0 ]; then
            echo "    [OK] Table $table contient $ROW_COUNT ligne(s)"
        else
            echo "    [WARNING] Table $table existe mais semble vide ou inaccessible"
        fi
    else
        echo "  [WARNING] Table $table n'existe pas"
        TABLE_CHECK_ERRORS=$((TABLE_CHECK_ERRORS + 1))
    fi
done

rm -f /tmp/hive_tables.txt

if [ "$TABLE_CHECK_ERRORS" -eq 0 ]; then
    echo "[OK] Toutes les tables attendues existent"
else
    echo "[WARNING] $TABLE_CHECK_ERRORS table(s) manquante(s)"
fi
echo ""

# Test 4: Test de requête simple
echo "[INFO] Test 4: Test d'exécution d'une requête simple..."
QUERY_RESULT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM consumption_raw;" 2>/dev/null | tail -1 | tr -d ' ')
if [ -n "$QUERY_RESULT" ] && [[ "$QUERY_RESULT" =~ ^[0-9]+$ ]]; then
    echo "[OK] Requête exécutée avec succès"
    echo "  [INFO] Nombre de lignes dans consumption_raw: $QUERY_RESULT"
else
    echo "[WARNING] Impossible d'exécuter la requête de test"
fi
echo ""

# Test 5: Vérifier la structure de la table consumption_raw
echo "[INFO] Test 5: Vérification de la structure de consumption_raw..."
DESCRIBE_OUTPUT=$(hive -e "USE consommation_elec; DESCRIBE consumption_raw;" 2>/dev/null)
EXPECTED_COLUMNS=("date" "time" "global_active_power" "global_reactive_power" "voltage")

COLUMN_CHECK_ERRORS=0
for col in "${EXPECTED_COLUMNS[@]}"; do
    if echo "$DESCRIBE_OUTPUT" | grep -qi "$col"; then
        echo "  [OK] Colonne $col trouvée"
    else
        echo "  [WARNING] Colonne $col non trouvée"
        COLUMN_CHECK_ERRORS=$((COLUMN_CHECK_ERRORS + 1))
    fi
done

if [ "$COLUMN_CHECK_ERRORS" -eq 0 ]; then
    echo "[OK] Structure de la table consumption_raw vérifiée"
else
    echo "[WARNING] $COLUMN_CHECK_ERRORS colonne(s) manquante(s)"
fi
echo ""

# Test 6: Vérifier les exports
echo "[INFO] Test 6: Vérification des exports HDFS..."
EXPORT_BASE="/user/projet/export"
EXPORT_DIRS=(
    "q1_top_days"
    "q2_monthly_evolution"
    "q3_weekend_comparison"
    "q4_hourly_distribution"
    "q5_annual_peak"
)

if command_exists hdfs; then
    EXPORT_COUNT=0
    for dir in "${EXPORT_DIRS[@]}"; do
        EXPORT_PATH="$EXPORT_BASE/$dir"
        if hdfs dfs -test -d "$EXPORT_PATH" 2>/dev/null; then
            FILE_COUNT=$(hdfs dfs -ls "$EXPORT_PATH" 2>/dev/null | grep -v "^Found" | wc -l)
            if [ "$FILE_COUNT" -gt 0 ]; then
                echo "  [OK] Export $dir trouvé ($FILE_COUNT fichier(s))"
                EXPORT_COUNT=$((EXPORT_COUNT + 1))
            fi
        fi
    done
    
    if [ "$EXPORT_COUNT" -gt 0 ]; then
        echo "[OK] $EXPORT_COUNT export(s) trouvé(s)"
    else
        echo "[WARNING] Aucun export trouvé dans $EXPORT_BASE"
        echo "[INFO] Exécutez les exports avec: hive -f hive/scripts/05_exports.hql"
    fi
else
    echo "[WARNING] Commande hdfs non disponible, impossible de vérifier les exports"
fi
echo ""

# Résumé
echo "=========================================="
if [ $TEST_ERRORS -eq 0 ]; then
    echo "[OK] TOUS LES TESTS D'INTÉGRATION HIVE RÉUSSIS"
else
    echo "[ERREUR] TESTS D'INTÉGRATION HIVE ÉCHOUÉS ($TEST_ERRORS erreur(s))"
fi
echo "=========================================="
echo ""

exit $TEST_ERRORS

