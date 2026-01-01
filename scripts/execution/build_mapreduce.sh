#!/bin/bash
# Script pour builder les jobs MapReduce avec Maven
# Usage: ./build_mapreduce.sh

echo "=========================================="
echo "Build des Jobs MapReduce"
echo "=========================================="
echo ""

# Vérifier que Maven est installé
if ! command -v mvn &> /dev/null; then
    echo "[ERREUR] Maven n'est pas installé"
    echo "Installez Maven: sudo apt install maven"
    exit 1
fi

echo "[OK] Maven trouvé: $(mvn -version | head -1)"
echo ""

# Aller dans le répertoire mapreduce
cd "$(dirname "$0")/../../mapreduce" || exit 1

echo "[INFO] Compilation avec Maven..."
echo ""

# Nettoyer et compiler
mvn clean package

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "[OK] Build réussi"
    echo "=========================================="
    echo ""
    
    # Trouver le JAR généré
    JAR=$(find target -name "*.jar" -not -name "*-sources.jar" -not -name "original-*" | head -1)
    
    if [ -n "$JAR" ]; then
        echo "JAR généré: $JAR"
        echo "Taille: $(du -h "$JAR" | cut -f1)"
        echo ""
        echo "Pour exécuter directement:"
        echo "  cd ../../scripts/execution/"
        echo "  ./run_mapreduce_jobs.sh /tmp/$(basename $JAR)"
    fi
else
    echo ""
    echo "[ERREUR] Erreur lors du build"
    exit 1
fi

