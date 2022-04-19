# FUNAGE-Pro
Functional analysis of Prokaryotes using Gene Set Enrichment Analysis on Transcriptome (RNA-Seq) or Proteome data

update 2022-Apr-19, Name change from GSEA-Pro to FUNAGE-Pro

# INSTALL FUNAGE-Pro
1. Clone FUNAGE-Pro from github
2. Install R 3.4 or newer, if not available
2. Install Perl 5.26 or newer, if not available
2. Install Python 3.6 or newer, if not available
3. goto the gsea_pro folder and run

./gsea_pro_v3.pl  <br> 
<ul style="list-style-type:none;">                                                                                                                                 </li>
    <li> <b>-s       </b>sessiondir and output folder [default=current folder]                                                                    </li>
    <li> <b>-table   </b>Tab delimited text file of locus-tags and experiments: first column = locus_tag, other columns = experiments        </li>
    <li> <b>-g       </b>genome prefix, including full path [e.g. /var/genomes/Bacteria/Lactococcus_lactis_cremoris_MG1363_uid58837/NC_009004 ]   </li>
    <li> <b>-method  </b>analyzing method: experiment | cluster  [ default = experiment ]                                                    </li>
    <li> <b>-up      </b>cutoff value for positive values [default = 2]                                                                      </li>
    <li> <b>-down    </b>cutoff value for negative values [default = -2]                                                                     </li>
    <li> <b>-cluster </b> Name of the clustercolumn [default = clusterID]                                                             </li>
    <li> <b>-auto    </b>Auto detect threshold values [default= true]                                                                         </li>
    <li> <b>-o user  </b>prefix for results [default = gsea_pro ]                                                                            </li>
</ul>


4. <b>Example command line:</b>
./gsea_pro_v3.pl -table gsea_pro_Experiment_Table.txt -g /var/genomes/Bacteria/Bacillus_subtilis_168_uid57675/NC_000964 -o my_results



# INSTALL FACoP locally 

1) goto the FACoP subfolder of FUNAGE_Pro
2) run the script 00.FUNAGEpro_build_database.sh
3) run the script 01.GSEApro_annotate_genomes.sh
4) Install DIAMOND on your server; Benjamin Buchfink, Chao Xie & Daniel H. Huson, Fast and Sensitive Protein Alignment using DIAMOND, Nature Methods, 12, 59–60 (2015) doi:10.1038/nmeth.3176.)



