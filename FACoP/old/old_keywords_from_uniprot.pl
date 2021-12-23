#!/usr/bin/env perl

#  parse interpro program 
# 	Anne de Jong
#	University of Groningen
#	the Netherlands
#	anne.de.jong@rug.nl
# 


use strict ;
use warnings ;
use anne_files;

my $query;
my $outfile ;
my $usage = "/data/p127804/GSEApro/keywords_from_uniprot.pl -i /data/pg-molgen/databases/uniprot_sprot/123.dat -o 123.results";
 
parseparam();
print "query=$query\n" ;
my @lines = anne_files::read_lines($query);
my @results = "key	description" ;
foreach my $line (@lines) {
	if ($line =~ m/^KW   (.*)/) {
		
		my @items = split /\; /, $1 ;
		push @results, @items ;
	}	
}

anne_files::write_lines($outfile, unique_array(@results));

sub unique_array {
	# remove duplicates / replicates from array
    return keys %{{ map { $_ => 1 } @_ }};
}

sub parseparam {
    my $var ;
    my @arg = @ARGV ;

    while(@arg) {
        $var = shift(@arg) ;
        $query	= shift(@arg) if($var eq '-i') ;
        $outfile	= shift(@arg) if($var eq '-o') ;
    }
    die "Please add the obo filename as parameter" 	if (!$query) ;

	
}
