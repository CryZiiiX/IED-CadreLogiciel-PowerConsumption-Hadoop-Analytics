/*****************************************************************************************************
Nom : mapreduce/src/main/java/com/projet/WeekendComparisonDriver.java
Rôle : Driver MapReduce pour la comparaison de consommation entre semaine et week-end
Auteur : Maxime BRONNY
Version : V1
Licence : Réalisé dans le cadre du cours Technique d'intelligence artificiel M1 INFORMATIQUE BIG-DATA
Usage :
    Pour compiler : mvn clean package (depuis le répertoire mapreduce/)
    Pour executer : hadoop jar target/mapreduce-consumption-1.0.jar com.projet.WeekendComparisonDriver <input> <output>
******************************************************************************************************/

package com.projet;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * Job 3 : Comparaison semaine/week-end
 * 
 * Driver principal qui configure et lance le job MapReduce
 * pour comparer la consommation entre jours de semaine et week-end.
 * 
 * Usage:
 *   hadoop jar mapreduce-consumption-1.0.jar com.projet.WeekendComparisonDriver \
 *     /user/projet/data/raw \
 *     /user/projet/output/job3_weekend
 */
public class WeekendComparisonDriver {

    /**
     * Fonction : main
     * Rôle     : Configure et lance le job MapReduce de comparaison semaine/week-end
     * Param    : args[0] - chemin d'entrée HDFS, args[1] - chemin de sortie HDFS
     * Retour   : void (termine avec code 0 en succès, 1 en échec)
     */
    public static void main(String[] args) throws Exception {
        
        if (args.length != 2) {
            System.err.println("Usage: WeekendComparisonDriver <input path> <output path>");
            System.exit(-1);
        }
        
        Configuration conf = new Configuration();
        
        // Configuration YARN
        conf.set("mapreduce.map.memory.mb", "1024");
        conf.set("mapreduce.reduce.memory.mb", "1024");
        conf.set("mapreduce.map.java.opts", "-Xmx819m");
        conf.set("mapreduce.reduce.java.opts", "-Xmx819m");
        conf.set("yarn.app.mapreduce.am.resource.mb", "1024");
        
        Job job = Job.getInstance(conf, "Weekend vs Weekday Comparison");
        job.setJarByClass(WeekendComparisonDriver.class);
        
        job.setMapperClass(WeekendComparisonMapper.class);
        job.setReducerClass(WeekendComparisonReducer.class);
        
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        Path outputPath = new Path(args[1]);
        outputPath.getFileSystem(conf).delete(outputPath, true);
        
        boolean success = job.waitForCompletion(true);
        
        if (success) {
            System.out.println("\n=== Job 3 terminé avec succès ===");
            System.out.println("Compteurs:");
            System.out.println("  Groupes traités: " + 
                job.getCounters().findCounter("REDUCER", "PROCESSED_GROUPS").getValue());
        }
        
        System.exit(success ? 0 : 1);
    }
}

