#!/bin/bash
# /*****************************************************************************************************
# Nom : scripts/demo/demo_script.sh
# Rôle : Script de démonstration du projet pour la vidéo
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./demo_script.sh
# ******************************************************************************************************/

echo "=========================================="
echo "DÉMONSTRATION - Projet Hadoop"
echo "Analyse Big Data Consommation Électrique"
echo "Hadoop 3.3.6 / Hive 3.1.3"
echo "=========================================="
echo ""

# Fonction : command_exists
# Rôle     : Vérifie si une commande est disponible dans le PATH
# Param    : $1 - nom de la commande à vérifier
# Retour   : 0 si trouvée, 1 sinon
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "[INFO] Étape 1 : Vérification des services Hadoop"
echo "----------------------------------------"
echo ""

if command_exists jps; then
    echo "Processus Java actifs:"
    jps | grep -E "NameNode|DataNode|ResourceManager|NodeManager|Hive" || echo "  (aucun processus Hadoop/Hive trouvé)"
else
    echo "[WARNING] Commande jps non disponible"
fi
echo ""

echo "[INFO] Étape 2 : Structure HDFS"
echo "----------------------------------------"
echo ""

if command_exists hdfs; then
    hdfs dfs -ls -R /user/projet 2>/dev/null | head -15 || echo "  (structure non disponible)"
else
    echo "[WARNING] Commande hdfs non disponible"
fi
echo ""

echo "[INFO] Étape 3 : Données dans HDFS"
echo "----------------------------------------"
echo ""

if command_exists hdfs; then
    hdfs dfs -ls -h /user/projet/data/raw/ 2>/dev/null || echo "  (aucune donnée)"
    echo ""
    hdfs dfs -du -h /user/projet/data/raw/ 2>/dev/null || true
else
    echo "[WARNING] Commande hdfs non disponible"
fi
echo ""

echo "[INFO] Étape 4 : Résultats MapReduce"
echo "----------------------------------------"
echo ""

if command_exists hdfs; then
    echo "Job 1 - Agrégation par jour (premiers résultats):"
    hdfs dfs -cat /user/projet/output/job1_region_avg/part-r-* 2>/dev/null | head -5 || echo "  (résultats non disponibles)"
    echo ""
    
    echo "Job 3 - Comparaison week-end:"
    hdfs dfs -cat /user/projet/output/job3_weekend/part-r-* 2>/dev/null || echo "  (résultats non disponibles)"
else
    echo "[WARNING] Commande hdfs non disponible"
fi
echo ""

echo "[INFO] Étape 5 : Tables Hive"
echo "----------------------------------------"
echo ""

if command_exists hive; then
    hive -e "USE consommation_elec; SHOW TABLES;" 2>/dev/null || echo "  (connexion Hive non disponible)"
else
    echo "[WARNING] Commande hive non disponible"
fi
echo ""

echo "[INFO] Étape 6 : Requêtes Analytiques"
echo "----------------------------------------"
echo ""

if command_exists hive; then
    echo "Q1 - Top 5 jours par consommation:"
    hive -e "USE consommation_elec; SELECT date, avg_consumption FROM conso_par_jour ORDER BY avg_consumption DESC LIMIT 5;" 2>/dev/null || echo "  (requête non disponible)"
    echo ""
    
    echo "Q3 - Comparaison week-end:"
    hive -e "USE consommation_elec; SELECT * FROM comparaison_jours;" 2>/dev/null || echo "  (requête non disponible)"
else
    echo "[WARNING] Commande hive non disponible"
fi
echo ""

echo "=========================================="
echo "[OK] DÉMONSTRATION TERMINÉE"
echo "=========================================="
echo ""
echo "[INFO] Interfaces disponibles:"
echo "   - HDFS NameNode: http://localhost:9870 (Hadoop 3.x)"
echo "   - YARN ResourceManager: http://localhost:8088"
echo ""
