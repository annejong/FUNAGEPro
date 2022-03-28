# GSEApro
Functional analysis of Prokaryotes using Gene Set Enrichment Analysis on Transcriptome (RNA-Seq) or Proteome data


# INSTALL GSEA-Pro
1. Clone GSEA-Pro from github
2. Install R 3.4 or newer, if not available
3. goto the gsea_pro folder and run

./gsea_pro_v3.pl  <br>                                                                                                                                          <br>
                                -s sessiondir and output folder [default=current folder]                                                                    <br>
                                -table  Tab delimited text file of locus-tags and experiments: first column = locus_tag, other columns = experiments        <br>
                                -g genome prefix, including full path [e.g. /var/genomes/Bacteria/Lactococcus_lactis_cremoris_MG1363_uid58837/NC_009004 ]   <br>
                                -method analyzing method: experiment | cluster  [ default = experiment ]                                                    <br>
                                -up     cutoff value for positive values [default = 2]                                                                      <br>
                                -down   cutoff value for negative values [default = -2]                                                                     <br>
                                -cluster        Name of the clustercolumn [default = clusterID]                                                             <br>
                                -auto  Auto detect threshold values [default= true]                                                                         <br>
                                -o user prefix for results [default = gsea_pro ]                                                                            <br>



4. <b>Example command line:</b>
./gsea_pro_v3.pl -table gsea_pro_Experiment_Table.txt -g /var/genomes/Bacteria/Bacillus_subtilis_168_uid57675/NC_000964 -o my_results



# INSTALL FACoP locally 

1) goto the FACoP subfolder of GSEA_Pro
2) run the script 00.GSEApro_build_database.sh
3) run the script 01.GSEApro_annotate_genomes.sh
4) Install DIAMOND on your server; Benjamin Buchfink, Chao Xie & Daniel H. Huson, Fast and Sensitive Protein Alignment using DIAMOND, Nature Methods, 12, 59–60 (2015) doi:10.1038/nmeth.3176.)



