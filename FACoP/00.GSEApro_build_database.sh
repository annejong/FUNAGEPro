#!/bin/bash
# GSEApro Database builder
# 2019-06-11

#SBATCH --nodes=1			
#SBATCH --ntasks-per-node=1
##SBATCH --partition=himem
#SBATCH --mem=8GB
##SBATCH --time=24:00:00
#SBATCH -p short
#SBATCH --job-name=GSEApro_Database_Build

export PERL5LIB=/data/pg-molgen/software/molgentools_mirror/lib
module load BioPerl/1.6.924-intel-2016a-Perl-5.20.3
module load BLAST+/2.7.1-foss-2018a
module load Python/3.6.4-intel-2018a
 

SCRATCHDIR=/tmp
DIAMONDDIR=/data/software/diamond/diamond-master
DATABASEDIR=/data/gsea_pro/databases
PROGRAMDIR=/data/gsea_pro/FACoP


function my_uniprot_download {
	# Download latest UniProt-Swisprot manual curated bacterial database
	wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_sprot_bacteria.dat.gz -O $DATABASEDIR/uniprot_sprot.dat.gz
	gunzip -f $DATABASEDIR/uniprot_sprot.dat.gz

	# Optionally a the large EMBL Uniprot can be used but is very sow in annotation and proteins are not reviewed and curated
#	wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_trembl_bacteria.dat.gz  -O $DATABASEDIR/uniprot_trembl_bacteria.dat.gz 
#	gunzip -f $DATABASEDIR/uniprot_trembl_bacteria.dat.gz

	# Get proteins from the database and store to fasta
	python3 $PROGRAMDIR/proteinSeq_from_uniprot.py -i $DATABASEDIR/uniprot_sprot.dat -out $DATABASEDIR/uniprot_sprot.fasta
	# test command : python3 /data/gsea_pro/FACoP/proteinSeq_from_uniprot.py -i uniprot_sprot.dat -out uniprot_sprot.fasta.test 
 



	
}	

function my_GO_download {
	# Latest GO OBO database and parse it for GSEApro
	wget http://purl.obolibrary.org/obo/go/go-basic.obo -O $DATABASEDIR/go-basic.obo
	$PROGRAMDIR/description_parser_GO_obo.pl -i $DATABASEDIR/go-basic.obo  # make description table
}	


function my_PFAM_download {
	# Latest PFAM
	wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam32.0/Pfam-A.hmm.dat.gz -O $DATABASEDIR/Pfam-A.hmm.dat.gz
	gunzip -f $DATABASEDIR/Pfam-A.hmm.dat.gz
	$PROGRAMDIR/parse_PFAM_names.pl -i $DATABASEDIR/Pfam-A.hmm.dat -o $DATABASEDIR/PFAM.description 
	#python3 $PROGRAMDIR/add_header.py -query $DATABASEDIR/PFAM.description
}

function my_IPR_download {
	# Latest Interpro
	wget ftp://ftp.ebi.ac.uk/pub/databases/interpro/74.0/names.dat -O $DATABASEDIR/IPR.description
	python3 $PROGRAMDIR/add_header.py -query $DATABASEDIR/IPR.description
}

function my_eggNOG_COG_download {
	# 1. Download Latest eggNOG @EMBL
	wget http://eggnog5.embl.de/download/eggnog_5.0/per_tax_level/2/2_annotations.tsv.gz -O $DATABASEDIR/eggNOG_COG.annotations.tsv.gz
	gunzip -f $DATABASEDIR/eggNOG_COG.annotations.tsv.gz
	# 2. Use only the COG#### annotation
	python3 $PROGRAMDIR/make_EggNOG_COG_description.py -sessiondir $DATABASEDIR
}

function OLD_my_bactNOG_download {	
	# Latest Bacterial eggNOG
	wget http://eggnogdb.embl.de/download/eggnog_4.5/data/bactNOG/bactNOG.annotations.tsv.gz -O $DATABASEDIR/bactNOG.annotations.tsv.gz
	gunzip -f $DATABASEDIR/bactNOG.annotations.tsv.gz
	# get column 2 and 6 for NOG
	cut -d$'\t' -f2,6 $DATABASEDIR/bactNOG.annotations.tsv > $DATABASEDIR/bactNOG.description
	python3 $PROGRAMDIR/add_header.py -query $DATABASEDIR/bactNOG.description
	# get column 2 and 5 for COG
	cut -d$'\t' -f2,5 $DATABASEDIR/bactNOG.annotations.tsv > $DATABASEDIR/bactCOG.description
	python3 $PROGRAMDIR/add_header.py -query $DATABASEDIR/bactCOG.description
}

function my_KEYWORD_parser {
	# get all the keywords from uniprot
	python3 $PROGRAMDIR/keywords_from_uniprot.py -i $DATABASEDIR/uniprot_sprot.dat -o $DATABASEDIR/KEYWORD.description
	#$PROGRAMDIR/keywords_from_uniprot.pl -i $DATABASEDIR/uniprot_sprot.dat -o $DATABASEDIR/KEYWORD.description_perl
}



function my_KEGG_parser {
	# 1.  <== IMPORANT, the description KO file can only be downloaded from https://www.genome.jp/kegg-bin/get_htext?ko00001
			# goto the KEGG website and expand all
			# save as plain text file { Download htext } and upload the ko00001.keg to $DATABASEDIR
	# 2. convert the ko00001.keg to ko00001.keg.table
	python3 $PROGRAMDIR/ko00001.keg_2_table.py -sessiondir $DATABASEDIR -kegg ko00001.keg -out ko00001.keg.table
	# 3. Add the KEGG pathways to UniProt IDs	
	python3 $PROGRAMDIR/Add_KEGG_2_UniProt_IDs.py -sessiondir $DATABASEDIR -keggTable ko00001.keg.table -UniProtDescription uniprot_sprot.description -out uniprot_sprot.KEGGPATHWAY
	python3 $PROGRAMDIR/make_KEGGPATHWAY_description.py -sessiondir $DATABASEDIR
	# 4. make KEGG KO descriptions
	python3 $PROGRAMDIR/description_parser_KEGG_Orthology_KO.py -i $DATABASEDIR/ko00001.keg -KO $DATABASEDIR/KEGG_Orthology_KO.description -PATH $DATABASEDIR/KEGG_Orthology_PATHWAY.description -KOPATH $DATABASEDIR/KEGG_Orthology_KO2PATH.description
	# 5. Convert Uniprot.KO to Uniprot.KEGG_pathway using the KO2PATH file
	python3 $PROGRAMDIR/Uniprot_KO_2_PATHWAY.py -uniprotKO $DATABASEDIR/uniprot_sprot.KO -KOPATH $DATABASEDIR/KEGG_Orthology_KO2PATH.description -o $DATABASEDIR/uniprot_sprot.KEGGPATHWAY
}



function my_mkdir {
	if [ ! -d $1 ]; then
		mkdir $1 ;
	fi
}




# =================================================================== MAIN =============================================================================

function database_setup {
	# Setting up the database: Download databases and reformat for GSEApro
	my_uniprot_download
	$PROGRAMDIR/Uniprot_2_Classes.pl $DATABASEDIR # extract CLASS information form the uniprot database
	# clean the .fasta to prevent makeblastdb error, if there is any
	# command line:    awk -v RS=">" -v FS="\n" -v ORS="" ' { if ($2) print ">"$0 } ' uniprot_sprot.fasta > uniprot_sprot.fasta

	$DIAMONDDIR/diamond makedb --in $DATABASEDIR/uniprot_sprot.fasta --db $DATABASEDIR/uniprot_sprot	# format the uniprot_sprot for DIAMOND
	my_GO_download
	my_PFAM_download
	my_IPR_download
	my_eggNOG_COG_download
	my_KEYWORD_parser 
	my_KEGG_parser  #  <== IMPORANT, the description KO file can only be downloaded manually from https://www.genome.jp/kegg-bin/get_htext?ko00001
	python3 $PROGRAMDIR/Uniprot_ENOG_2_COG.py -ENOG $DATABASEDIR/uniprot_sprot.ENOG -bactCOG $DATABASEDIR/bactCOG.description -out $DATABASEDIR/uniprot_sprot.COG

}

# for local server instead of cluster:
export PERL5LIB=/data/molgentools/lib

## The database setup for GSEApro 
database_setup

