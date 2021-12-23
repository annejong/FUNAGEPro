#!/bin/bash
# FACoP pipeline as support for GSEApro
# 2019-06-11

##  #SBATCH --nodes=1			
##  #SBATCH --ntasks-per-node=20
##  ##SBATCH --partition=himem
##  #SBATCH --mem=64GB
##  #SBATCH --time=4:00:00
##  ##SBATCH -p short
##  #SBATCH --job-name=FACoP
##  
##  export PERL5LIB=/data/pg-molgen/software/molgentools_mirror/lib
##  module load BioPerl/1.6.924-intel-2016a-Perl-5.20.3
##  module load BLAST+/2.7.1-foss-2018a
##  module load Python/3.5.1-foss-2016a
 
cpu=2
SCRATCHDIR=/tmp
DATABASEDIR=/data/gsea_pro/databases
PROGRAMDIR=/data/gsea_pro/FACoP

DIAMONDDIR=/data/software/diamond/diamond-master
DIAMOND_DB=$DATABASEDIR/uniprot_sprot.dmnd

genome=$1 # the full path genome filename is the protein fasta name without the .faa extension. The .faa will be added by DIAMOND

function classify_genome {		
	check_seq
	# Add classification data to the all proteins
	if [ ! -f $genome.diamond.tab ]; then
		my_diamond_faa  # DIAMOND is used to find the best hit in Uniprot ==> results is $genome.diamond.tab
	fi	
	python3 $PROGRAMDIR/diamond_format_results.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.description -out $genome.description

	cp $genome.description $genome.FACoP.table
	cp $genome.description $genome.g2d.FACoP.table
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.GO      -class $DATABASEDIR/go-basic.obo.description    -out $genome.g2d.FACoP.GO
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.IPR     -class $DATABASEDIR/IPR.description             -out $genome.g2d.FACoP.IPR
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.eggNOG  -class $DATABASEDIR/eggNOG_COG.description      -out $genome.g2d.FACoP.eggNOG_COG
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.COG     -class $DATABASEDIR/COG.description             -out $genome.g2d.FACoP.COG
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.PFAM    -class $DATABASEDIR/PFAM.description            -out $genome.g2d.FACoP.Pfam
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.Keyword -class $DATABASEDIR/KEYWORD.description         -out $genome.g2d.FACoP.KEYWORDS
	python3 $PROGRAMDIR/classify_genome.py -diamond $genome.diamond.tab -db $DATABASEDIR/uniprot_sprot.KEGGPATHWAY -class $DATABASEDIR/KEGGPATHWAY.description -out $genome.g2d.FACoP.KEGG
	
	$PROGRAMDIR/Annotation2Json.pl -s "$(dirname $genome)" -query "$(basename $genome)".FACoP.table -out 00.GenomeAnnotation.json
	

# test: 	tmpdir=/tmp/FACoP/FACoP/129.125.142.95.2lgm2urjnjng5kaplfoqdoa4d3.196
# test: 	 sudo -u www-data python3 $PROGRAMDIR/classify_genome.py -genome $tmpdir/query.diamond.tab -db $DATABASEDIR/uniprot_sprot.COG -class $DATABASEDIR/COG.description -out $tmpdir/query.COG
# test: 	 sudo -u www-data python3 $PROGRAMDIR/classify_genome.py -genome $tmpdir/query.diamond.tab -db $DATABASEDIR/uniprot_sprot.GO -class /data/gsea_pro/databases/go-basic.obo.description -out $tmpdir/query.COG

}

function check_seq {
	# to prevent errors in DIAMOND etc.. check the input
	python3 $PROGRAMDIR/CheckFastA.py -i $genome.faa 
}

function my_diamond_faa {
	# diamond is used to function map the proteins of the genome on the basis of the Uniprot_sprot database
	$DIAMONDDIR/diamond blastp --unal 1 --threads $cpu --tmpdir $SCRATCHDIR --query $genome.faa --db $DIAMOND_DB --out $genome.diamond.tab --evalue 0.1 --max-target-seqs 1
}



function my_class_assignment {
	declare -a CLASSES=("GO" "KO" "IPR" "PFAM" "Debian" "Keyword" "eggNOG" )
	database=/data/pg-molgen/databases/uniprot_sprot/uniprot_sprot
	
	for class in ${CLASSES[@]}; do
		echo $class
		/data/pg-molgen/software/molgentools_mirror/metagenomics/CLASS_assignment.pl -db $database.$class -diamond $genome.diamond.diamond.tab -o $genome.$class
	done
}	



function my_class_count {
	declare -a CLASSES=("GO" "KO" "IPR" "PFAM" "Debian" "Keyword" "eggNOG" )
	database=/data/pg-molgen/databases/uniprot_sprot/uniprot_sprot
	
	for class in ${CLASSES[@]}; do
		echo $class
		/data/pg-molgen/software/molgentools_mirror/metagenomics/CLASS_count.pl -db $database.$class -diamond $diamondresultdir/$name.diamond.tab -o $classdir/$name.$class.count
	done

}




function my_mkdir {
	if [ ! -d $1 ]; then
		mkdir $1 ;
	fi
}




# =================================================================== samples =============================================================================

## the genome is the protein fasta name without the .faa extension. The .faa will be added by DIAMOND
#testing: genome=/data/p127804/GSEApro/genomes/ASM1000v1_genomic.g2d
#testing: genome=/data/g2d_mirror_genbank/Salmonella_enterica_subsp_enterica_serovar_Typhimurium_R181078.g2d

#classify_genome /data/p127804/GSEApro/genomes/ASM1000v1_genomic.g2d
#classify_genome /data/p127804/GSEApro/genomes/MG1363  

classify_genome
