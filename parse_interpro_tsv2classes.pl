#!/usr/bin/env perl

#  parse interpro tsv file 
# 	Anne de Jong
#	University of Groningen
#	the Netherlands
#	anne.de.jong@rug.nl
#
#  2014-October
#
#  Parse the TSV output of InterProScan and generate class files for functional analsyis
#  This will replace the 2 step procedure:  parse_interpro.pl  and parse_iprgo_2_class.pl
#		- Oct 2015, MetaCyc description added

use strict ;
use warnings ;
use File::Copy ;
use lib "/data/molgentools/lib";
use anne_files;

my $sessiondir = "./" ;
my $interpro_tsv_file ;
my $usage = "/data/molgentools/gsea_pro/parse_interpro_tsv2classes.pl -s /data/genomes/Bacteria/Lactococcus_lactis_cremoris_MG1363_uid58837 -i NC_009004.g2d.tsv
				-s Sessiondir [default=current folder]
				-i queryfile is the result file of interproscan, usually the .tsv file
				
e.g. /data/molgentools/gsea_pro/parse_interpro_tsv2classes.pl -s /data/genomes/g2d_mirror/Acinetobacter_baumannii_KAB05 -i ASM180642v1_genomic.g2d.tsv				
" ;

&parseparam();

# load descriptions of the class_IDs 
my %IPR_description 	= anne_files::read_table_to_hash("/data/databases/interpro/interpro_term_description.txt");
my %GO_description 		= anne_files::read_table_to_hash("/data/databases/go/go-basic.obo.table");
my %KEGG_description 	= anne_files::read_table_to_hash("/data/databases/KEGG/KEGG_pathway_description.txt");
my %Pfam_description 	= anne_files::read_table_to_hash("/data/databases/PFAM/Pfam_description.txt");
my %Gene3D_description 	= anne_files::read_table_to_hash("/data/molgentools/gsea_pro/Gene3D_CATH_description.txt");
my %MetaCyc_description = anne_files::read_table_to_hash("/data/databases/MetaCyc/MetaCyc_description.txt");
my %SMART_description 	= anne_files::read_table_to_hash("/data/molgentools/gsea_pro/smart.descriptions");
my %PANTHER_description = anne_files::read_table_to_hash("/data/molgentools/gsea_pro/panther.descriptions");
my %SUPERFAMILY_description = anne_files::read_table_to_hash("/data/molgentools/gsea_pro/superfamily.descriptions");


my %classes ;
parse_tsv();
write_classfiles() ;

sub parse_tsv {
	my @lines = anne_files::read_lines($sessiondir.'/'.$interpro_tsv_file) ;
	foreach my $line (@lines) {
		my @items = split "\t", $line ;
		my @ID = split /\|/, $items[0] ;											# llmg_2398|zitP|YP_001033640.1|GeneID:4799038
		my $locus = $ID[0] ;
		$locus = $items[0] if ($items[0] =~ m/^fig\|/) ;							# If RAST IDs are used  fig|....  
		my $method = $items[3] ;													# e.g. PANTHER
		my $IPR = $items[11] ;
		my @GOs = () ; 
		@GOs = split /\|/, $items[13] if (defined($items[13]));						# GO:0000166|GO:0004832|GO:0005524|GO:0006438
		my @PATHways ;
		@PATHways = split /\|/, $items[14] if (defined($items[14]))	 ;				# KEGG: 00010+1.1.1.27|KEGG: 00270+1.1.1.27|KEGG: 00620+1.1.1.27|KEGG: 00640+1.1.1.27|MetaCyc: PWY-5481|MetaCyc: PWY-6901|UniPathway: UPA00554
		$classes{$method}{$locus}{$items[4]} = $items[0] ;
		$classes{IPR}{$locus}{$IPR} = $items[0] if (defined($IPR));		
		foreach my $GO (@GOs) { $classes{GO}{$locus}{$GO} = $items[0] ; }
		foreach my $PATHway (@PATHways) { 
			if ($PATHway =~ m/(.*)\: (.*?)\+.*/) {						# KEGG: 00010+1.1.1.27
				$classes{$1}{$locus}{$2} = $items[0] ; 
			} elsif ($PATHway =~ m/(.*)\: (.*)/) {						# other pathways, e.g. MetaCyc
				$classes{$1}{$locus}{$2} = $items[0] ; 
			}	
		}
	}
}


sub write_classfiles {
	my $outputfile = $interpro_tsv_file ;
	$outputfile =~ s/\.tsv$// ;
	foreach my $method (sort keys %classes) {
		my @file = () ;
		foreach my $locus (sort keys %{$classes{$method}}) {
			foreach my $class_id (sort keys %{$classes{$method}{$locus}}) {  # test KEGG
				my $description = $classes{$method}{$locus}{$class_id};
				$description =  $IPR_description{$class_id}{description} 	if ($method eq 'IPR'  and defined($IPR_description{$class_id}{description})) ; 
				$description =  $GO_description{$class_id}{description} 		if ($method eq 'GO'   and defined($GO_description{$class_id}{description})) ; 
				$description =  $KEGG_description{$class_id}{description}	if ($method eq 'KEGG' and defined($KEGG_description{$class_id}{description})) ; 
				$description =  $MetaCyc_description{$class_id}{description}	if ($method eq 'MetaCyc' and defined($MetaCyc_description{$class_id}{description})) ; 
				$description =  $Gene3D_description{$class_id}{description}	if ($method eq 'Gene3D' and defined($Gene3D_description{$class_id}{description})) ; 
				$description =  $Pfam_description{$class_id}{description}	if ($method eq 'Pfam' and defined($Pfam_description{$class_id}{description})) ; 
				$description =  $SMART_description{$class_id}{description}	if ($method eq 'SMART' and defined($SMART_description{$class_id}{description})) ; 
				$description =  $PANTHER_description{$class_id}{description}	if ($method eq 'PANTHER' and defined($PANTHER_description{$class_id}{description})) ; 
				$description =  $SUPERFAMILY_description{$class_id}{description}	if ($method eq 'SUPERFAMILY' and defined($SUPERFAMILY_description{$class_id}{description})) ; 
				my $add = 1;
				$add = 0 if ($class_id =~ /PTHR.*\:/g) ;  # avoid PANTHER sub classes
				if ($method eq 'KEGG') { # Add text to prevent numbering
					push @file, "$locus\tKEGG:$class_id\t$description" ;
				} else {
					push @file, "$locus\t$class_id\t$description" if ($add) ;
				}	
			}	
		}
		print "\t\tSave class file: $outputfile.$method\n";
		anne_files::write_lines("$sessiondir/$outputfile.$method", @file) ;
	}

}


sub parseparam {
    my $var ;
    my @arg = @ARGV ;
    while(@arg) {
        $var = shift(@arg) ;
        $sessiondir = shift(@arg) if($var eq '-s') ;
		$interpro_tsv_file	= shift(@arg) if($var eq '-i') ;
    }
    die $usage if (!$interpro_tsv_file ) ;
	$sessiondir =~ s/\/$// ; # remove the last / from sessiondir to make it universal
}