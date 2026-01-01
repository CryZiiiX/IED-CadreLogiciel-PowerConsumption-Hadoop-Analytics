/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/WeekendComparisonReducer.java
Rôle : Reducer MapReduce pour la comparaison de consommation entre semaine et week-end
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.WeekendComparisonDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Job 3 : Comparaison semaine/week-end
 * 
 * Reducer qui calcule les statistiques de consommation
 * pour les jours de semaine vs week-end.
 * 
 * Format d'entrée :
 * - Clé : "weekday" ou "weekend"
 * - Valeurs : Liste de consommations
 * 
 * Format de sortie :
 * - Clé : "weekday" ou "weekend"
 * - Valeur : avg,min,max,count
 */
public class WeekendComparisonReducer extends Reducer<Text, Text, Text, Text> {

    /**
     * Fonction : reduce
     * Rôle     : Calcule les statistiques de consommation pour les jours de semaine vs week-end
     * Param    : key - type de jour (weekday/weekend), values - liste de consommations, context - contexte MapReduce
     * Retour   : void (écrit dans le contexte)
     */
    @Override
    public void reduce(Text key, Iterable<Text> values, Context context)
            throws IOException, InterruptedException {
        
        List<Double> consumptions = new ArrayList<>();
        
        // Collecter toutes les consommations pour ce type de jour
        for (Text value : values) {
            try {
                double consumption = Double.parseDouble(value.toString());
                consumptions.add(consumption);
            } catch (NumberFormatException e) {
                context.getCounter("REDUCER", "INVALID_VALUES").increment(1);
            }
        }
        
        if (consumptions.isEmpty()) {
            return;
        }
        
        // Calculer les statistiques
        double sum = 0.0;
        double min = Collections.min(consumptions);
        double max = Collections.max(consumptions);
        
        for (double consumption : consumptions) {
            sum += consumption;
        }
        
        double average = sum / consumptions.size();
        int count = consumptions.size();
        
        // Formater la sortie : avg,min,max,count
        String output = String.format("%.4f,%.4f,%.4f,%d", 
                average, min, max, count);
        
        // Émettre le résultat
        context.write(key, new Text(output));
        
        context.getCounter("REDUCER", "PROCESSED_GROUPS").increment(1);
    }
}

