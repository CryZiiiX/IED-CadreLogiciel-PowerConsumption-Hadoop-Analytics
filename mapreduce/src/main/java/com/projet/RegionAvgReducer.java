/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/RegionAvgReducer.java
Rôle : Reducer MapReduce pour l'agrégation de consommation électrique par jour
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.RegionAvgDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Job 1 : Agrégation par jour
 * 
 * Reducer qui calcule les statistiques de consommation par jour :
 * - Moyenne
 * - Minimum
 * - Maximum
 * 
 * Format d'entrée :
 * - Clé : Date (String)
 * - Valeurs : Liste de consommations (Text)
 * 
 * Format de sortie :
 * - Clé : Date
 * - Valeur : moyenne,min,max,count (format CSV)
 */
public class RegionAvgReducer extends Reducer<Text, Text, Text, Text> {

    /**
     * Fonction : reduce
     * Rôle     : Calcule les statistiques de consommation (moyenne, min, max, count) par jour
     * Param    : key - date, values - liste de consommations pour cette date, context - contexte MapReduce
     * Retour   : void (écrit dans le contexte)
     */
    @Override
    public void reduce(Text key, Iterable<Text> values, Context context)
            throws IOException, InterruptedException {
        
        List<Double> consumptions = new ArrayList<>();
        
        // Collecter toutes les valeurs de consommation pour cette date
        for (Text value : values) {
            try {
                double consumption = Double.parseDouble(value.toString());
                consumptions.add(consumption);
            } catch (NumberFormatException e) {
                context.getCounter("REDUCER", "INVALID_VALUES").increment(1);
            }
        }
        
        // Si aucune valeur valide, ignorer
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
        
        // Formater la sortie : moyenne,min,max,count
        String output = String.format("%.4f,%.4f,%.4f,%d", 
                average, min, max, count);
        
        // Émettre le résultat
        context.write(key, new Text(output));
        
        // Incrémenter le compteur de lignes traitées
        context.getCounter("REDUCER", "PROCESSED_DAYS").increment(1);
    }
}

