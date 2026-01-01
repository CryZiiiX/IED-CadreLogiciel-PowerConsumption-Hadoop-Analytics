#!/bin/bash
# /*****************************************************************************************************
# Nom : scripts/hdfs/create_structure.sh
# Rôle : Script de création de la structure de répertoires HDFS du projet
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./create_structure.sh
# ******************************************************************************************************/

echo "=========================================="
echo "Création de la Structure HDFS"
echo "Hadoop 3.3.6"
echo "=========================================="
echo ""

# Vérifier que la commande hdfs est disponible
if ! command -v hdfs >/dev/null 2>&1; then
    echo "[ERREUR] Commande hdfs non trouvée"
    echo "Assurez-vous que HADOOP_HOME est défini et dans PATH"
    exit 1
fi

# Vérifier que HDFS est accessible
echo "1. Vérification de HDFS..."
if ! hdfs dfsadmin -report &>/dev/null; then
    echo "[ERREUR] HDFS n'est pas accessible"
    echo "Démarrez HDFS avec: start-dfs.sh"
    exit 1
fi
echo "[OK] HDFS est accessible"
echo ""

# 2. Créer les répertoires
echo "2. Création des répertoires HDFS..."

DIRECTORIES=(
    "/user/projet"
    "/user/projet/data"
    "/user/projet/data/raw"
    "/user/projet/data/processed"
    "/user/projet/output"
    "/user/projet/output/job1_region_avg"
    "/user/projet/output/job2_peaks"
    "/user/projet/output/job3_weekend"
)

for dir in "${DIRECTORIES[@]}"; do
    if hdfs dfs -test -d "$dir" 2>/dev/null; then
        echo "   [OK] $dir existe déjà"
    else
        if hdfs dfs -mkdir -p "$dir"; then
            echo "   [OK] Créé: $dir"
        else
            echo "   [ERREUR] Erreur lors de la création: $dir"
        fi
    fi
done

echo ""

# 3. Définir les permissions (optionnel)
echo "3. Configuration des permissions..."
hdfs dfs -chmod -R 755 /user/projet 2>/dev/null || true
echo "[OK] Permissions configurées"
echo ""

# 4. Afficher la structure
echo "4. Structure HDFS créée:"
echo ""
hdfs dfs -ls -R /user/projet | head -20
echo ""

echo "=========================================="
echo "[OK] Structure HDFS créée avec succès"
echo "=========================================="
echo ""
echo "Répertoires créés:"
echo "  /user/projet/data/raw           → Données brutes"
echo "  /user/projet/data/processed     → Données traitées"
echo "  /user/projet/output/job1_...    → Outputs MapReduce"
echo ""
