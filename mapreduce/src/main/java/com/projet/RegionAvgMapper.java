/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/RegionAvgMapper.java
Rôle : Mapper MapReduce pour l'agrégation de consommation électrique par jour
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.RegionAvgDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

/**
 * Job 1 : Agrégation par jour
 * 
 * Mapper qui extrait la date et la consommation active globale
 * pour chaque ligne du dataset de consommation électrique.
 * 
 * Format d'entrée : CSV avec séparateur ';'
 * Colonnes : Date;Time;Global_active_power;Global_reactive_power;Voltage;...
 * 
 * Format de sortie :
 * - Clé : Date (String) - format DD/MM/YYYY
 * - Valeur : Consommation active (Double en kilowatts)
 */
public class RegionAvgMapper extends Mapper<LongWritable, Text, Text, Text> {

    /**
     * Fonction : map
     * Rôle     : Extrait la date et la consommation active de chaque ligne d'entrée CSV
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
            
            // Extraire la consommation active globale (colonne 2)
            // Gérer les valeurs manquantes représentées par '?'
            String consumptionStr = fields[2].trim();
            
            // Ignorer les lignes avec valeurs manquantes
            if (consumptionStr.equals("?") || consumptionStr.isEmpty()) {
                return;
            }
            
            double consumption = Double.parseDouble(consumptionStr);
            
            // Vérifier que la consommation est valide (positive)
            if (consumption < 0) {
                return;
            }
            
            // Émettre (date, consommation)
            // On utilise Text pour la valeur car on veut garder la précision
            context.write(new Text(date), new Text(String.valueOf(consumption)));
            
        } catch (NumberFormatException e) {
            // Ignorer les lignes avec des valeurs invalides
            context.getCounter("MAPPER", "INVALID_LINES").increment(1);
        } catch (Exception e) {
            // Gérer les autres erreurs
            context.getCounter("MAPPER", "ERRORS").increment(1);
        }
    }
}

