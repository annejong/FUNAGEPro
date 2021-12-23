#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#
#	- Nov 2017: 
#	Proteins can be member of multiple classes. This routine merge the classes to the genes 
#	
# 

# depends on "gsea_pro.R"
use warnings;
use strict;
use lib "/data/molgentools/lib";
use anne_files ;
use anne_misc ;


# ------------------------------------------------------------ parameters ----------------------------------------------------------------------


my $sessiondir ='.' ;
my $query ;
my $outputfilename = 'results_merged_classes.txt';
my $usage = "gsea_pro/gsea_pro_class_merger.pl
	-s sessiondir and output folder [default=current folder]
	-query	Tab delimited text file of locus-tags classes: first column = locus_tag, second columns = class name
	-o ouput filename [default= $outputfilename]

e.g.  /data/molgentools/gsea_pro/gsea_pro_class_merger.pl -query Andrea_classes.txt -o Andrea_classes_merged.txt
e.g.  /data/molgentools/gsea_pro/gsea_pro_class_merger.pl -query ASM161892v1_genomic.txt -o ASM161892v1_genomic_merged.txt
";



&parseparam() ;


my %combined ;
my @lines = anne_files::read_lines($query) ;
foreach my $line (@lines) {
	my @items = split /\t/, $line ;
	if (scalar @items >1) {
		push @{$combined{$items[0]}}, $items[1] ;	
	}
}
my @results ;
foreach my $key (sort {$combined{$a} cmp $combined{$b}} keys %combined) {
	my $classes = join ";", @{$combined{$key}} ;
	#print "$key\t$classes\n";
	push @results, "$key\t$classes" ;
}	

anne_files::write_lines($outputfilename, @results) ;



sub parseparam {
    my $var ;
    my @arg = @ARGV ;

    while(@arg) {
        $var = shift(@arg) ;
		die $usage if ($var eq '-h' or $var eq '--help') ;
		$sessiondir 	= shift(@arg) if($var eq '-s') ;
        $query		 	= shift(@arg) if($var eq '-query') ;
        $outputfilename	= shift(@arg) if($var eq '-o') ;
    }
    die $usage if (!$query) ;
}
