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


use strict ;
use warnings ;
use File::Copy ;
use anne_files;

my $query = 'Pfam-A.hmm.dat' ;
my $outfile ;
my $usage = "/data/molgentools/functional_analysis/parse_PFAM_names.pl
	Download latest version: wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam32.0/Pfam-A.hmm.dat.gz	Unpack it
" ;

parseparam();

my @lines = anne_files::read_lines($query) ;
my @result = "key\tdescription\tID\tTP" ;
my %row ;
foreach my $line (@lines) {
	if ($line =~ m/\/\//) { # end of record
		my @items = split /\./, $row{'AC'} ;
		#print "$items[0]\n" ;
		push @result, $items[0]."\t".$row{'DE'}."\t".$row{'ID'}."\t".$row{'TP'} ;
	}
	if ($line =~ m/#=GF (..)   (.*)/) { $row{$1} = $2 ; }

}

anne_files::write_lines($outfile, @result);


sub parseparam {
    my $var ;
    my @arg = @ARGV ;
    while(@arg) {
        $var = shift(@arg) ;
        $query	 = shift(@arg) if($var eq '-i') ;
        $outfile = shift(@arg) if($var eq '-o') ;
    }
    die $usage 	if (!$query) ;
}