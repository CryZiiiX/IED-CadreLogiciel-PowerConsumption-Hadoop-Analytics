/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/PeakDetectionDriver.java
Rôle : Driver MapReduce pour la détection des pics journaliers de consommation électrique
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.PeakDetectionDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * Job 2 : Détection des pics journaliers
 * 
 * Driver principal qui configure et lance le job MapReduce
 * pour identifier les 3 plus hauts pics de consommation par jour.
 * 
 * Usage:
 *   hadoop jar mapreduce-consumption-1.0.jar com.projet.PeakDetectionDriver \
 *     /user/projet/data/raw \
 *     /user/projet/output/job2_peaks
 */
public class PeakDetectionDriver {

    /**
     * Fonction : main
     * Rôle     : Configure et lance le job MapReduce de détection des pics journaliers
     * Param    : args[0] - chemin d'entrée HDFS, args[1] - chemin de sortie HDFS
     * Retour   : void (termine avec code 0 en succès, 1 en échec)
     */
    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: PeakDetectionDriver <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // Configuration YARN
        conf.set("mapreduce.map.memory.mb", "1024");
        conf.set("mapreduce.reduce.memory.mb", "1024");
        conf.set("mapreduce.map.java.opts", "-Xmx819m");
        conf.set("mapreduce.reduce.java.opts", "-Xmx819m");
        conf.set("yarn.app.mapreduce.am.resource.mb", "1024");
        
        Job job = Job.getInstance(conf, "Peak Detection by Day");
        job.setJarByClass(PeakDetectionDriver.class);
        
        job.setMapperClass(PeakDetectionMapper.class);
        job.setReducerClass(PeakDetectionReducer.class);
        
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        Path outputPath = new Path(args[1]);
        outputPath.getFileSystem(conf).delete(outputPath, true);
        
        boolean success = job.waitForCompletion(true);
        
        if (success) {
            System.out.println("\n=== Job 2 terminé avec succès ===");
            System.out.println("Compteurs:");
            System.out.println("  Jours traités: " + 
                job.getCounters().findCounter("REDUCER", "PROCESSED_DAYS").getValue());
        }
        
        System.exit(success ? 0 : 1);
    }
}

