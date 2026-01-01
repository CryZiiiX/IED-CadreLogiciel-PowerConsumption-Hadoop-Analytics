/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/WeekendComparisonMapper.java
Rôle : Mapper MapReduce pour la comparaison de consommation entre semaine et week-end
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.WeekendComparisonDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

/**
 * Job 3 : Comparaison semaine/week-end
 * 
 * Mapper qui classe chaque jour comme "weekday" ou "weekend"
 * et extrait la consommation.
 * 
 * Format d'entrée : CSV avec séparateur ';'
 * Colonnes : Date;Time;Global_active_power;...
 * 
 * Format de sortie :
 * - Clé : "weekday" ou "weekend"
 * - Valeur : consommation
 */
public class WeekendComparisonMapper extends Mapper<LongWritable, Text, Text, Text> {

    private SimpleDateFormat dateFormat;
    
    /**
     * Fonction : setup
     * Rôle     : Initialise le format de date pour le parsing
     * Param    : context - contexte MapReduce
     * Retour   : void
     */
    @Override
    protected void setup(Context context) {
        // Format de date : DD/MM/YYYY
        dateFormat = new SimpleDateFormat("dd/MM/yyyy", Locale.ENGLISH);
        dateFormat.setLenient(false);
    }
    
    /**
     * Fonction : map
     * Rôle     : Classe chaque jour comme "weekday" ou "weekend" et extrait la consommation
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
        
        // Parser la ligne CSV
        String[] fields = line.split(";");
        
        if (fields.length < 3) {
            return;
        }
        
        try {
            // Extraire la date
            String dateStr = fields[0].trim();
            Date date = dateFormat.parse(dateStr);
            
            // Déterminer si c'est un week-end
            Calendar cal = Calendar.getInstance();
            cal.setTime(date);
            int dayOfWeek = cal.get(Calendar.DAY_OF_WEEK);
            
            // Calendar.SUNDAY = 1, Calendar.SATURDAY = 7
            String dayType = (dayOfWeek == Calendar.SATURDAY || dayOfWeek == Calendar.SUNDAY) 
                    ? "weekend" : "weekday";
            
            // Extraire la consommation
            String consumptionStr = fields[2].trim();
            
            if (consumptionStr.equals("?") || consumptionStr.isEmpty()) {
                return;
            }
            
            double consumption = Double.parseDouble(consumptionStr);
            
            if (consumption < 0) {
                return;
            }
            
            // Émettre (type_de_jour, consommation)
            context.write(new Text(dayType), new Text(String.valueOf(consumption)));
            
        } catch (ParseException e) {
            context.getCounter("MAPPER", "INVALID_DATES").increment(1);
        } catch (NumberFormatException e) {
            context.getCounter("MAPPER", "INVALID_CONSUMPTION").increment(1);
        } catch (Exception e) {
            context.getCounter("MAPPER", "ERRORS").increment(1);
        }
    }
}

