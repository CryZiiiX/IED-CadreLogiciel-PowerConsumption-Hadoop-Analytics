#!/bin/bash
# /*****************************************************************************************************
# Nom : tests/validation/validate_hive_tables.sh
# Rôle : Script de validation des tables Hive - Tests de validation
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./validate_hive_tables.sh
# ******************************************************************************************************/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/tests/results"

mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "VALIDATION - Tables Hive"
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

# Test 1: Vérifier la base de données
echo "[INFO] Test 1: Vérification de la base de données..."
DB_EXISTS=$(hive -e "SHOW DATABASES;" 2>/dev/null | grep -c "consommation_elec" || echo "0")
if [ "$DB_EXISTS" -gt 0 ]; then
    echo "[OK] Base de données consommation_elec existe"
else
    echo "[ERREUR] Base de données consommation_elec n'existe pas"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    exit 1
fi
echo ""

# Test 2: Vérifier l'existence des tables
echo "[INFO] Test 2: Vérification de l'existence des tables..."
EXPECTED_TABLES=(
    "consumption_raw"
    "conso_par_jour"
    "pics_journaliers"
    "comparaison_jours"
)

hive -e "USE consommation_elec; SHOW TABLES;" 2>/dev/null > /tmp/hive_tables.txt
MISSING_TABLES=0

for table in "${EXPECTED_TABLES[@]}"; do
    if grep -q "^$table$" /tmp/hive_tables.txt 2>/dev/null; then
        echo "  [OK] Table $table existe"
    else
        echo "  [ERREUR] Table $table n'existe pas"
        MISSING_TABLES=$((MISSING_TABLES + 1))
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

rm -f /tmp/hive_tables.txt

if [ "$MISSING_TABLES" -eq 0 ]; then
    echo "[OK] Toutes les tables attendues existent"
else
    echo "[ERREUR] $MISSING_TABLES table(s) manquante(s)"
fi
echo ""

# Test 3: Vérifier le contenu des tables
echo "[INFO] Test 3: Vérification du contenu des tables..."

# Table consumption_raw
echo "  [INFO] Vérification de consumption_raw..."
RAW_COUNT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM consumption_raw;" 2>/dev/null | tail -1 | tr -d ' ')
if [ -n "$RAW_COUNT" ] && [[ "$RAW_COUNT" =~ ^[0-9]+$ ]] && [ "$RAW_COUNT" -gt 0 ]; then
    echo "    [OK] consumption_raw contient $RAW_COUNT ligne(s)"
else
    echo "    [ERREUR] consumption_raw est vide ou inaccessible"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Table conso_par_jour
echo "  [INFO] Vérification de conso_par_jour..."
CONSO_COUNT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM conso_par_jour;" 2>/dev/null | tail -1 | tr -d ' ')
if [ -n "$CONSO_COUNT" ] && [[ "$CONSO_COUNT" =~ ^[0-9]+$ ]] && [ "$CONSO_COUNT" -gt 0 ]; then
    echo "    [OK] conso_par_jour contient $CONSO_COUNT ligne(s)"
else
    echo "    [WARNING] conso_par_jour est vide ou inaccessible"
fi

# Table pics_journaliers
echo "  [INFO] Vérification de pics_journaliers..."
PICS_COUNT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM pics_journaliers;" 2>/dev/null | tail -1 | tr -d ' ')
if [ -n "$PICS_COUNT" ] && [[ "$PICS_COUNT" =~ ^[0-9]+$ ]] && [ "$PICS_COUNT" -gt 0 ]; then
    echo "    [OK] pics_journaliers contient $PICS_COUNT ligne(s)"
else
    echo "    [WARNING] pics_journaliers est vide ou inaccessible"
fi

# Table comparaison_jours
echo "  [INFO] Vérification de comparaison_jours..."
COMP_COUNT=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM comparaison_jours;" 2>/dev/null | tail -1 | tr -d ' ')
if [ -n "$COMP_COUNT" ] && [[ "$COMP_COUNT" =~ ^[0-9]+$ ]] && [ "$COMP_COUNT" -eq 2 ]; then
    echo "    [OK] comparaison_jours contient $COMP_COUNT ligne(s) (attendu: 2)"
else
    echo "    [WARNING] comparaison_jours contient $COMP_COUNT ligne(s) (attendu: 2)"
fi

echo ""

# Test 4: Vérifier la structure des colonnes
echo "[INFO] Test 4: Vérification de la structure des colonnes..."

# consumption_raw - colonnes principales
EXPECTED_COLS_RAW=("date" "time" "global_active_power" "global_reactive_power" "voltage")
DESCRIBE_RAW=$(hive -e "USE consommation_elec; DESCRIBE consumption_raw;" 2>/dev/null)
MISSING_COLS=0

for col in "${EXPECTED_COLS_RAW[@]}"; do
    if echo "$DESCRIBE_RAW" | grep -qi "$col"; then
        echo "    [OK] Colonne $col trouvée dans consumption_raw"
    else
        echo "    [WARNING] Colonne $col non trouvée dans consumption_raw"
        MISSING_COLS=$((MISSING_COLS + 1))
    fi
done

if [ "$MISSING_COLS" -eq 0 ]; then
    echo "  [OK] Structure de consumption_raw vérifiée"
else
    echo "  [WARNING] $MISSING_COLS colonne(s) manquante(s) dans consumption_raw"
fi
echo ""

# Test 5: Vérifier la cohérence des données
echo "[INFO] Test 5: Vérification de la cohérence des données..."

# Vérifier que conso_par_jour a des valeurs cohérentes
COHERENCE_CHECK=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM conso_par_jour WHERE min_consumption > avg_consumption OR avg_consumption > max_consumption;" 2>&1 | grep -v "^SLF4J" | grep -v "^WARN" | grep -v "^INFO" | grep -E '^[0-9]+$' | tail -1)
COHERENCE_CHECK=${COHERENCE_CHECK:-"N/A"}

if [[ "$COHERENCE_CHECK" =~ ^[0-9]+$ ]]; then
    if [ "$COHERENCE_CHECK" -eq 0 ]; then
        echo "  [OK] Cohérence des données dans conso_par_jour (min <= avg <= max)"
    else
        echo "  [WARNING] $COHERENCE_CHECK incohérence(s) détectée(s) dans conso_par_jour"
    fi
else
    echo "  [WARNING] Impossible de vérifier la cohérence de conso_par_jour (résultat: $COHERENCE_CHECK)"
fi

# Vérifier que comparaison_jours contient weekday et weekend
HAS_WEEKDAY=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM comparaison_jours WHERE day_type = 'weekday';" 2>&1 | grep -E '^[0-9]+$' | tail -1)
HAS_WEEKEND=$(hive -e "USE consommation_elec; SELECT COUNT(*) FROM comparaison_jours WHERE day_type = 'weekend';" 2>&1 | grep -E '^[0-9]+$' | tail -1)
HAS_WEEKDAY=${HAS_WEEKDAY:-0}
HAS_WEEKEND=${HAS_WEEKEND:-0}

if [ "$HAS_WEEKDAY" -ge 1 ] && [ "$HAS_WEEKEND" -ge 1 ]; then
    echo "  [OK] comparaison_jours contient weekday ($HAS_WEEKDAY) et weekend ($HAS_WEEKEND)"
else
    echo "  [WARNING] comparaison_jours incomplet (weekday=$HAS_WEEKDAY, weekend=$HAS_WEEKEND)"
fi
echo ""

# Générer un rapport de validation
REPORT_FILE="$RESULTS_DIR/validation_hive_tables_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Rapport de validation Tables Hive"
    echo "Date: $(date)"
    echo ""
    echo "Base de données: consommation_elec"
    echo "Tables vérifiées: ${#EXPECTED_TABLES[@]}"
    echo "Tables manquantes: $MISSING_TABLES"
    echo ""
    echo "Contenu des tables:"
    echo "  - consumption_raw: $RAW_COUNT ligne(s)"
    echo "  - conso_par_jour: $CONSO_COUNT ligne(s)"
    echo "  - pics_journaliers: $PICS_COUNT ligne(s)"
    echo "  - comparaison_jours: $COMP_COUNT ligne(s)"
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

