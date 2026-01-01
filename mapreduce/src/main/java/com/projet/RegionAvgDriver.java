/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/RegionAvgDriver.java
Rôle : Driver MapReduce pour l'agrégation de consommation électrique par jour
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.RegionAvgDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * Job 1 : Agrégation de consommation par jour
 * 
 * Driver principal qui configure et lance le job MapReduce
 * pour calculer les statistiques de consommation par jour.
 * 
 * Usage:
 *   hadoop jar mapreduce-consumption-1.0.jar com.projet.RegionAvgDriver \
 *     /user/projet/data/raw \
 *     /user/projet/output/job1_region_avg
 */
public class RegionAvgDriver {

    /**
     * Fonction : main
     * Rôle     : Configure et lance le job MapReduce d'agrégation de consommation par jour
     * Param    : args[0] - chemin d'entrée HDFS, args[1] - chemin de sortie HDFS
     * Retour   : void (termine avec code 0 en succès, 1 en échec)
     */
    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: RegionAvgDriver <input path> <output path>");
            System.exit(-1);
        }
        
        // **************************************************
        // # --- CONFIGURATION DU JOB --- #
        // **************************************************
        Configuration conf = new Configuration();
        
        // Configuration YARN pour le job
        // Allouer les ressources mémoire
        conf.set("mapreduce.map.memory.mb", "1024");
        conf.set("mapreduce.reduce.memory.mb", "1024");
        conf.set("mapreduce.map.java.opts", "-Xmx819m");
        conf.set("mapreduce.reduce.java.opts", "-Xmx819m");
        conf.set("yarn.app.mapreduce.am.resource.mb", "1024");
        
        // Configuration de la compression (optionnel)
        conf.setBoolean("mapreduce.output.fileoutputformat.compress", false);
        
        // **************************************************
        // # --- CREATION ET CONFIGURATION DU JOB --- #
        // **************************************************
        Job job = Job.getInstance(conf, "Consumption Average by Day");
        job.setJarByClass(RegionAvgDriver.class);
        
        // Définir les classes Mapper et Reducer
        job.setMapperClass(RegionAvgMapper.class);
        job.setReducerClass(RegionAvgReducer.class);
        
        // Définir les types de sortie
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        // **************************************************
        // # --- EXECUTION DU JOB --- #
        // **************************************************
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        // Supprimer le répertoire de sortie s'il existe
        Path outputPath = new Path(args[1]);
        outputPath.getFileSystem(conf).delete(outputPath, true);
        
        boolean success = job.waitForCompletion(true);
        
        // Afficher les compteurs
        if (success) {
            System.out.println("\n=== Job 1 terminé avec succès ===");
            System.out.println("Compteurs:");
            System.out.println("  Lignes invalides: " + 
                job.getCounters().findCounter("MAPPER", "INVALID_LINES").getValue());
            System.out.println("  Jours traités: " + 
                job.getCounters().findCounter("REDUCER", "PROCESSED_DAYS").getValue());
        }
        
        System.exit(success ? 0 : 1);
    }
}

