#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#	November , 2016
#
#	GSEA Experiments: Make Keyword Class
#	
# 

use warnings;
use strict;
use lib "/usr/molgentools/lib";
use anne_files ;
use anne_misc ;


my $genome = "/var/genomes/g2d_mirror/Lactococcus_lactis_subsp_cremoris_MG1363/ASM942v1_genomic" ;


my %keywords = get_keyword_table();
my @IPR_list = get_IPR_list() ; # the IPRs in the keyword table


my @results ;
foreach my $line (anne_files::read_lines("$genome.g2d.IPR") ) {
	my @items = split "\t", $line ;
	if (defined($items[1])) {
		if ($items[1] ~~ @IPR_list) {
			#push @results, get_keywords_keys($items[1]) ;
			foreach my $key (get_keywords_keys($items[1])) {
				my $newline = "$items[0]\t$keywords{$key}{keyword}\t$items[1] - $items[2]" ; 
				print $newline."\n";
				push @results, $newline ;
			}	
		}
	}
}
anne_files::write_lines("$genome.g2d.KEYWORDS", @results) ;



# -------------------------------------------- functions -----------------------------------------------------------------------------------------------

sub get_keywords_keys {
	# return the %keywords keys of the matches
	my $IPR = shift ;
	my @all_matches = grep { $keywords{$_}{IPR} eq $IPR } keys %keywords;
	#print join(";", @all_matches)."<=====\n"; 
	return @all_matches ;
}


sub get_keyword_table {
	# add the keywords to a hash
	my @lines = anne_files::read_lines('/usr/molgentools/gsea_pro/IPR_keywords.db') ;
	my %results ;
	my $count = 0 ;
	foreach my $line (@lines) {
		my @items = split "\t", $line ;
		if (defined($items[1])) {
			$count++;
			$results{$count}{keyword} 	= $items[0] ;
			$results{$count}{IPR} 		= $items[1] ;
			$results{$count}{description} = $items[2] ;
		}
	}
	return %results ;
}	

sub get_IPR_list {
	my @results ;
	foreach my $key (keys %keywords) {push @results, $keywords{$key}{IPR} ; }
	
	return @results ;
}	