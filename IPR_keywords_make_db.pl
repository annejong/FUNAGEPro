#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#	November , 2016
#
#	GSEA Experiments: Get Keywords From IPR annotation
#	
# 

use warnings;
use strict;
use lib "/usr/molgentools/lib";
use anne_files ;
use anne_misc ;


# IPR db to hash; database can be found in the "InterPro Entry relationships tree" https://www.ebi.ac.uk/interpro/download.html
# Use only the Parent (1st) level
my $IPR_parent_db = 'IPR_parent.db';
my %IPR ;
my @lines = anne_files::read_lines($IPR_parent_db);
foreach my $line (@lines) {
	$line =~ s/,|\(|\)/ /g ;
	my @items = split "\t", $line ;
	if ($items[0] ne '' and defined($items[1])) { $IPR{$items[0]} = lc($items[1]) ;	}	
}

# get all keywords	
my %keywords ;
foreach my $key (keys %IPR) {
	my @words = split " ", $IPR{$key} ;
	foreach my $word (@words) {
		$keywords{$word} = 0 if (!defined($keywords{$word})) ;
		$keywords{$word}++ ;
	}	
}

# filter the keywords 
my @noise = ( 'function','type','system','class','iii','superfamily','n-terminal','c-terminal','and','alpha','beta','delta','gamma','enzyme','factor','fold','bacterial') ;
foreach my $key (sort {$keywords{$b} <=> $keywords{$a}} keys %keywords) {
	if ( $keywords{$key} < 4 or $keywords{$key} > 100 or length($key)<3 ) {
		push @noise, $key ;
		
	}	
}
delete @keywords{@noise};
my $count = scalar (keys %keywords) ;
print "Number of KeyWords = $count\n";



# export the data
my @keywordkeys = keys %keywords ;
my @results;
foreach my $key (sort keys %IPR) {
	my @words = split " ", $IPR{$key} ;
	foreach my $word (@words) {
		if ($word ~~ @keywordkeys) {
			push @results, "$word\t$key\t$IPR{$key}";
		}	
	}
}	

@results = sort(@results); 
foreach my $line (@results) { print "$line\n";}
