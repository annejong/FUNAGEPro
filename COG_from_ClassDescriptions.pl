#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#	November , 2016
#
#	GSEA-pro; Make COG functional categories
# 	Use description of several classes to get the COG functional categories
#	
# 

use warnings;
use strict;
use lib "/usr/molgentools/lib";
use anne_files ;
use anne_misc ;


my $sessiondir = '.';
my $genome = "/var/genomes/g2d_mirror/Lactococcus_lactis_subsp_cremoris_MG1363/ASM942v1_genomic" ;

my $usage = "/usr/molgentools/gsea_pro/COG_from_ClassDescriptions.pl -i genome_base_name
	GSEA-pro; Derive COG functional classes from IPR and GO description match
		More info at https://www.ncbi.nlm.nih.gov/COG/
		download cognames2003-2014.tab and fun2003-2014.tab from ftp://ftp.ncbi.nih.gov/pub/COG/COG2014/data/
		
	parameters: 
	-i genome base name [e.g. $genome]

	e.g. /usr/molgentools/gsea_pro/COG_from_ClassDescriptions.pl -i /var/genomes/g2d_mirror/Lactococcus_lactis_subsp_cremoris_MG1363/ASM942v1_genomic
	
";
# -------------------------------------------- main -----------------------------------------------------------------------------------------------
parseparam();


my %cognames = get_cognames('/usr/molgentools/gsea_pro/cognames2003-2014.tab');
my %cogfun = get_cogfun('/usr/molgentools/gsea_pro/fun2003-2014.tab');



my @lines = screen_class_4_matches("$genome.g2d.IPR") ;  # find matches in the IPR class
push @lines, screen_class_4_matches("$genome.g2d.GO") ;  # add matches from the GO class
push @lines, screen_class_4_matches("$genome.g2d.KEGG") ;  # add matches from the KEGG class
push @lines, screen_class_4_matches("$genome.g2d.Pfam") ;  # add matches from the PFAM class


@lines = anne_files::unique_array(@lines) ;				# remove replicates
print "\tTotal locus tags with COG functional category: ".(scalar @lines)."\n" ;

anne_files::write_lines("$genome.g2d.COG", sort @lines) ;



# -------------------------------------------- functions -----------------------------------------------------------------------------------------------

sub screen_class_4_matches {
	my $classfile = shift ;
	if (!-e $classfile) { print "\tFile not found $classfile\n"; exit(); }
	my %class = get_interpro($classfile) ; 
	my @results ;
	foreach my $key (sort keys %class) {
		my $cogKey = find_match($class{$key}{description}) ;
		if ($cogKey ne '' and defined($cogfun{$cognames{$cogKey}{func_cat}})) { 
			push @results, "$class{$key}{locus}\t$cognames{$cogKey}{func_cat}\t$cogfun{$cognames{$cogKey}{func_cat}}" ; }
	}	
	print "\tCOGs from $classfile: ".(scalar @results)."\n" ;
	return @results ;
}

sub find_match {
	# does the description match the cognames description
	my $result = '';
	my $description = lc(shift) ;
	$description =~ s/\+|\s+|\-|\)|\(|\\|\///g ;
	foreach my $key (keys %cognames) {
		if ($cognames{$key}{description} =~ m/$description/) {
			$result = $key ;
			last();
		}
	}	
	return $result ;
}

sub get_cognames {
	my $filename = shift ;
	my @lines = anne_files::read_lines($filename) ;
	my %results ;
	foreach my $line (@lines) {
		if ($line !~ m/^#/) {  # doen not start with remark char #
			my @items = split "\t", $line ;
			if (defined($items[2])) {
				my $key = $items[0] ;
				$results{$key}{func_cat} 	= $items[1] ;  
				$results{$key}{description}	= lc($items[2]) ;
				$results{$key}{description}	=~ s/\s+|\-|\)|\(|\\|\///g ;
			}
		}	
	}
	return %results ;
}	

sub get_cogfun {
	my $filename = shift ;
	my @lines = anne_files::read_lines($filename) ;
	my %results ;
	foreach my $line (@lines) {
		if ($line !~ m/^#/) {  # doen not start with remark char #
			my @items = split "\t", $line ;
			if (defined($items[1])) {
				$results{$items[0]} = $items[1] ;  
			}
		}	
	}
	return %results ;
}	



sub get_interpro {
	my $filename = shift ;
	my @lines = anne_files::read_lines($filename) ;
	my %results ;
	my $count = 0 ;
	foreach my $line (@lines) {
		my @items = split "\t", $line ;
		if (defined($items[2])) {
			$count++;
			$results{$count}{locus} 	  = $items[0] ;
			$results{$count}{IPR} 		  = $items[1] ;
			$results{$count}{description} = $items[2] ;
		}
	}
	return %results ;
}	


sub parseparam {
    my $var ;
    my @arg = @ARGV ;

    while(@arg) {
        $var = shift(@arg) ;
        $sessiondir 	= shift(@arg) if($var eq '-s') ;
        $genome		 	= shift(@arg) if($var eq '-i') ;
    }
    die $usage if (!$genome) ;
}
	