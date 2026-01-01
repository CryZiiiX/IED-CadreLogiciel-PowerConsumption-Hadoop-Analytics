/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/PeakDetectionMapper.java
Rôle : Mapper MapReduce pour la détection des pics journaliers de consommation électrique
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.PeakDetectionDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

/**
 * Job 2 : Détection des pics journaliers
 * 
 * Mapper qui extrait la date, l'heure et la consommation active
 * pour identifier les pics de consommation par jour.
 * 
 * Format d'entrée : CSV avec séparateur ';'
 * Colonnes : Date;Time;Global_active_power;...
 * 
 * Format de sortie :
 * - Clé : Date (String) - format DD/MM/YYYY
 * - Valeur : heure,consommation (format: HH:MM:SS,consommation)
 */
public class PeakDetectionMapper extends Mapper<LongWritable, Text, Text, Text> {

    /**
     * Fonction : map
     * Rôle     : Extrait la date, l'heure et la consommation active pour détecter les pics journaliers
     * Param    : key - clé de la ligne, value - contenu de la ligne CSV, context - contexte MapReduce
     * Retour   : void (écrit dans le contexte)
     */
    @Override
    public void map(LongWritable key, Text value, Context context)
            throws IOException, InterruptedException {
        
        // Ignorer l'en-tête
        String line = value.toString();
        if (line.startsWith("Date;Time;")) {
            return;
        }
        
        // Parser la ligne CSV (séparateur ';')
        String[] fields = line.split(";");
        
        // Vérifier qu'on a assez de colonnes (minimum 3)
        if (fields.length < 3) {
            return;
        }
        
        try {
            // Extraire la date (colonne 0)
            String date = fields[0].trim();
            
            // Extraire l'heure (colonne 1)
            String time = fields[1].trim();
            
            // Extraire la consommation active (colonne 2)
            String consumptionStr = fields[2].trim();
            
            // Ignorer les lignes avec valeurs manquantes
            if (consumptionStr.equals("?") || consumptionStr.isEmpty()) {
                return;
            }
            
            double consumption = Double.parseDouble(consumptionStr);
            
            // Vérifier que la consommation est valide
            if (consumption < 0) {
                return;
            }
            
            // Émettre (date, "heure,consommation")
            String outputValue = time + "," + String.valueOf(consumption);
            context.write(new Text(date), new Text(outputValue));
            
        } catch (NumberFormatException e) {
            context.getCounter("MAPPER", "INVALID_LINES").increment(1);
        } catch (Exception e) {
            context.getCounter("MAPPER", "ERRORS").increment(1);
        }
    }
}

