#!/bin/bash
# /*****************************************************************************************************
# Nom : scripts/export/export_results.sh
# Rôle : Script d'export des résultats Hive vers fichiers locaux
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./export_results.sh
# ******************************************************************************************************/

EXPORT_BASE="/user/projet/export"
LOCAL_EXPORT_DIR="../../data/export"

echo "=========================================="
echo "Export des Résultats Hive"
echo "Hadoop 3.3.6"
echo "=========================================="
echo ""

# Vérifier que la commande hdfs est disponible
if ! command -v hdfs >/dev/null 2>&1; then
    echo "[ERREUR] Commande hdfs non trouvée"
    echo "Assurez-vous que HADOOP_HOME est défini et dans PATH"
    exit 1
fi

# Créer le répertoire local
mkdir -p "$LOCAL_EXPORT_DIR"

# Exporter chaque résultat
EXPORTS=(
    "q1_top_days:Q1_Top10_Jours.csv"
    "q2_monthly_evolution:Q2_Evolution_Mensuelle.csv"
    "q3_weekend_comparison:Q3_Comparaison_Weekend.csv"
    "q4_hourly_distribution:Q4_Distribution_Horaire.csv"
    "q5_annual_peak:Q5_Pic_Annuel.csv"
)

for export_info in "${EXPORTS[@]}"; do
    export_name=$(echo "$export_info" | cut -d: -f1)
    local_file=$(echo "$export_info" | cut -d: -f2)
    
    echo "Export de $export_name..."
    
    HDFS_PATH="$EXPORT_BASE/$export_name"
    LOCAL_PATH="$LOCAL_EXPORT_DIR/$local_file"
    
    # Vérifier que le répertoire HDFS existe
    if hdfs dfs -test -d "$HDFS_PATH" 2>/dev/null; then
        # Copier depuis HDFS vers local
        hdfs dfs -getmerge "$HDFS_PATH/*" "$LOCAL_PATH" 2>/dev/null
        
        if [ -f "$LOCAL_PATH" ]; then
            echo "[OK] Exporté: $LOCAL_PATH"
        else
            echo "[WARNING] Échec de l'export"
        fi
    else
        echo "[WARNING] Répertoire HDFS non trouvé: $HDFS_PATH"
    fi
    
    echo ""
done

echo "=========================================="
echo "[OK] Export Terminé"
echo "=========================================="
echo ""
echo "Fichiers exportés dans: $LOCAL_EXPORT_DIR"
echo ""
