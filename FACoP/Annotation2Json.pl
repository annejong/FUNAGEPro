#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#	July 2019
#	Routine to convert g2d table to JSON. Inherited from gseapro_v3.pl


use warnings;
use strict;
use lib "/data/molgentools/lib";
use anne_files ;
use File::Basename;
use JSON;



# ------------------------------------------------------------ parameters ----------------------------------------------------------------------
my $program_dir = dirname($0) ;
my $sessiondir ;
my $query ;
my $out ;
my $usage = "/data/gsea_pro/FACoP/Annotation2Json.pl -s /tmp/FACoP/FACoP/129.125.142.95.3ajk9u1lmo0tqsafa8oblloih5.749 -query query.FACoP.g2d.table -out 00.GenomeAnnotation.json";

parseparam();


	# convert the genome tabel of genome2d to json format
	my @lines = anne_files::read_lines("$sessiondir/$query");
	$lines[0] = "locus_tag\tshortName\tlongName\tproduct\tgene";
	anne_files::write_lines("$sessiondir/$query", @lines);
	
	my %table = anne_files::read_table_to_hash("$sessiondir/$query") ;
	anne_files::write_lines("$sessiondir/$out",(encode_json \%table)) ;


sub parseparam {
    my $var ;
    my @arg = @ARGV ;
    while(@arg) {
        $var = shift(@arg) ;
		$sessiondir = shift(@arg) if($var eq '-s') ;
		$query 		= shift(@arg) if($var eq '-query') ;
        $out 		= shift(@arg) if($var eq '-out') ;
    }
    die $usage if (!$query) ;
}
