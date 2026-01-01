#!/bin/bash
# /*****************************************************************************************************
# Nom : scripts/execution/run_mapreduce_jobs.sh
# Rôle : Script d'exécution des 3 jobs MapReduce pour l'analyse de consommation électrique
# Auteur : Maxime BRONNY
# Version : V1
# Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
# Usage :
#     Pour compiler : N/A (script interprété)
#     Pour executer : ./run_mapreduce_jobs.sh [JAR_PATH] [INPUT_PATH] [OUTPUT_BASE]
# ******************************************************************************************************/

JAR_PATH="${1:-mapreduce-consumption-1.0.jar}"
INPUT_PATH="${2:-/user/projet/data/raw}"
OUTPUT_BASE="${3:-/user/projet/output}"

echo "=========================================="
echo "Exécution des Jobs MapReduce"
echo "Hadoop 3.3.6"
echo "=========================================="
echo ""

# Vérifier que la commande hadoop est disponible
if ! command -v hadoop >/dev/null 2>&1; then
    echo "[ERREUR] Commande hadoop non trouvée"
    echo "Assurez-vous que HADOOP_HOME est défini et dans PATH"
    exit 1
fi

# Convertir le chemin du JAR en chemin absolu si c'est un chemin relatif
if [[ "$JAR_PATH" != /* ]]; then
    # C'est un chemin relatif, convertir en absolu
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    
    # Résoudre le chemin relatif depuis le répertoire courant du script
    if [[ "$JAR_PATH" == ../../* ]]; then
        # Enlever le ../../
        RELATIVE_PATH="${JAR_PATH#../../}"
        JAR_PATH="$PROJECT_ROOT/$RELATIVE_PATH"
    elif [[ "$JAR_PATH" == ../* ]]; then
        # Enlever le ../
        RELATIVE_PATH="${JAR_PATH#../}"
        JAR_PATH="$(cd "$SCRIPT_DIR/.." && pwd)/$RELATIVE_PATH"
    else
        JAR_PATH="$SCRIPT_DIR/$JAR_PATH"
    fi
    
    # Normaliser le chemin (résoudre les .. et .)
    JAR_DIR="$(cd "$(dirname "$JAR_PATH")" && pwd)"
    JAR_NAME="$(basename "$JAR_PATH")"
    JAR_PATH="$JAR_DIR/$JAR_NAME"
fi

# Vérifier que le JAR existe
if [ ! -f "$JAR_PATH" ]; then
    echo "[ERREUR] JAR non trouvé: $JAR_PATH"
    echo "Compilez d'abord avec: cd mapreduce && mvn clean package"
    exit 1
fi

# Configurer le classpath Hadoop
export HADOOP_CLASSPATH=$(hadoop classpath)

# **************************************************
# --- VERIFICATION DES PRE REQUIS --- #
# **************************************************
# Vérifier HDFS
echo "1. Vérification de HDFS..."
if ! hdfs dfsadmin -report &>/dev/null; then
    echo "[ERREUR] HDFS n'est pas accessible"
    echo "Démarrez HDFS avec: start-dfs.sh"
    exit 1
fi
echo "[OK] HDFS accessible"
echo ""

# Vérifier que les données existent
if ! hdfs dfs -test -d "$INPUT_PATH" &>/dev/null; then
    echo "[ERREUR] Répertoire d'entrée non trouvé: $INPUT_PATH"
    echo "Upload les données avec: ../hdfs/upload_to_hdfs.sh"
    exit 1
fi

# **************************************************
# --- EXECUTION JOB 1 --- #
# **************************************************
# Job 1: Agrégation par jour
echo "=========================================="
echo "Job 1: Agrégation de consommation par jour"
echo "=========================================="
echo ""
OUTPUT1="$OUTPUT_BASE/job1_region_avg"

echo "[INFO] Exécution du Job 1..."
java -cp "$JAR_PATH:$HADOOP_CLASSPATH" com.projet.RegionAvgDriver "$INPUT_PATH" "$OUTPUT1"

if [ $? -eq 0 ]; then
    echo "[OK] Job 1 terminé avec succès"
    echo ""
    echo "Résultats (premiers 10 jours):"
    hdfs dfs -cat "$OUTPUT1/part-r-*" | head -10
else
    echo "[ERREUR] Erreur lors de l'exécution du Job 1"
    exit 1
fi

echo ""
echo ""

# **************************************************
# --- EXECUTION JOB 2 --- #
# **************************************************
# Job 2: Détection des pics
echo "=========================================="
echo "Job 2: Détection des pics journaliers"
echo "=========================================="
echo ""
OUTPUT2="$OUTPUT_BASE/job2_peaks"

echo "[INFO] Exécution du Job 2..."
java -cp "$JAR_PATH:$HADOOP_CLASSPATH" com.projet.PeakDetectionDriver "$INPUT_PATH" "$OUTPUT2"

if [ $? -eq 0 ]; then
    echo "[OK] Job 2 terminé avec succès"
    echo ""
    echo "Résultats (premiers 10 jours):"
    hdfs dfs -cat "$OUTPUT2/part-r-*" | head -10
else
    echo "[ERREUR] Erreur lors de l'exécution du Job 2"
    exit 1
fi

echo ""
echo ""

# **************************************************
# --- EXECUTION JOB 3 --- #
# **************************************************
# Job 3: Comparaison week-end
echo "=========================================="
echo "Job 3: Comparaison semaine/week-end"
echo "=========================================="
echo ""
OUTPUT3="$OUTPUT_BASE/job3_weekend"

echo "[INFO] Exécution du Job 3..."
java -cp "$JAR_PATH:$HADOOP_CLASSPATH" com.projet.WeekendComparisonDriver "$INPUT_PATH" "$OUTPUT3"

if [ $? -eq 0 ]; then
    echo "[OK] Job 3 terminé avec succès"
    echo ""
    echo "Résultats:"
    hdfs dfs -cat "$OUTPUT3/part-r-*"
else
    echo "[ERREUR] Erreur lors de l'exécution du Job 3"
    exit 1
fi

echo ""
echo "=========================================="
echo "[OK] Tous les jobs MapReduce terminés"
echo "=========================================="
echo ""
echo "Résultats disponibles dans HDFS:"
echo "  - Job 1: $OUTPUT1"
echo "  - Job 2: $OUTPUT2"
echo "  - Job 3: $OUTPUT3"
echo ""
echo "Pour voir les résultats:"
echo "  hdfs dfs -cat $OUTPUT1/part-r-*"
echo "  hdfs dfs -cat $OUTPUT2/part-r-*"
echo "  hdfs dfs -cat $OUTPUT3/part-r-*"
echo ""
echo "Pour voir l'interface YARN:"
echo "  http://localhost:8088"

