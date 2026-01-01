/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/PeakDetectionReducer.java
Rôle : Reducer MapReduce pour la détection des pics journaliers de consommation électrique
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.PeakDetectionDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.*;

/**
 * Job 2 : Détection des pics journaliers
 * 
 * Reducer qui identifie les 3 plus hauts pics de consommation par jour.
 * 
 * Format d'entrée :
 * - Clé : Date (String)
 * - Valeurs : Liste de "heure,consommation"
 * 
 * Format de sortie :
 * - Clé : Date
 * - Valeur : peak1_time,peak1_value,peak2_time,peak2_value,peak3_time,peak3_value
 */
public class PeakDetectionReducer extends Reducer<Text, Text, Text, Text> {

    /**
     * Fonction : ConsumptionMeasure (classe interne)
     * Rôle     : Stocke une mesure de consommation avec son heure pour le tri
     * Param    : time - heure de la mesure, consumption - valeur de consommation
     * Retour   : objet ConsumptionMeasure
     */
    static class ConsumptionMeasure implements Comparable<ConsumptionMeasure> {
        String time;
        double consumption;
        
        ConsumptionMeasure(String time, double consumption) {
            this.time = time;
            this.consumption = consumption;
        }
        
        /**
         * Fonction : compareTo
         * Rôle     : Compare deux mesures par consommation décroissante
         * Param    : other - mesure à comparer
         * Retour   : int - valeur de comparaison
         */
        @Override
        public int compareTo(ConsumptionMeasure other) {
            // Trier par consommation décroissante
            return Double.compare(other.consumption, this.consumption);
        }
    }
    
    /**
     * Fonction : reduce
     * Rôle     : Identifie les 3 plus hauts pics de consommation par jour
     * Param    : key - date, values - liste de mesures "heure,consommation", context - contexte MapReduce
     * Retour   : void (écrit dans le contexte)
     */
    @Override
    public void reduce(Text key, Iterable<Text> values, Context context)
            throws IOException, InterruptedException {
        
        List<ConsumptionMeasure> measures = new ArrayList<>();
        
        // Collecter toutes les mesures pour cette date
        for (Text value : values) {
            try {
                String[] parts = value.toString().split(",");
                if (parts.length == 2) {
                    String time = parts[0];
                    double consumption = Double.parseDouble(parts[1]);
                    measures.add(new ConsumptionMeasure(time, consumption));
                }
            } catch (NumberFormatException e) {
                context.getCounter("REDUCER", "INVALID_VALUES").increment(1);
            }
        }
        
        // Si aucune mesure valide, ignorer
        if (measures.isEmpty()) {
            return;
        }
        
        // Trier par consommation décroissante
        Collections.sort(measures);
        
        // Prendre les 3 plus hauts pics
        StringBuilder output = new StringBuilder();
        int peaksToFind = Math.min(3, measures.size());
        
        for (int i = 0; i < peaksToFind; i++) {
            ConsumptionMeasure peak = measures.get(i);
            if (i > 0) {
                output.append(",");
            }
            output.append(peak.time)
                  .append(",")
                  .append(String.format("%.4f", peak.consumption));
        }
        
        // Si moins de 3 pics, compléter avec des valeurs vides
        for (int i = peaksToFind; i < 3; i++) {
            output.append(",,");
        }
        
        // Émettre le résultat
        context.write(key, new Text(output.toString()));
        context.getCounter("REDUCER", "PROCESSED_DAYS").increment(1);
    }
}

