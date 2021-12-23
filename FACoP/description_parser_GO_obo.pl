#!/usr/bin/env perl

#  parse interpro program 
# 	Anne de Jong
#	University of Groningen
#	the Netherlands
#	anne.de.jong@rug.nl
#
#  2014-October
#
#  Parse the GO obo http://geneontology.org/ontology/go-basic.obo file
# 


use strict ;
use warnings ;
use File::Copy ;
use anne_files;

my $obo_file; 
parseparam();

my @lines = anne_files::read_lines($obo_file);
my @results = "key	description" ;
my $id="";
my $name="";
foreach my $line (@lines) {
	if ($line =~ m/^\[Term/ and $id ne "") {
		push @results, "$id\t$name" ;
	} elsif ($line =~ m/^id: (.*)/) { 
		$id=$1 ;
	} elsif ($line =~ m/^name: (.*)/) { 
		$name=$1 ;
	}	
}

anne_files::write_lines("$obo_file.description", @results);

sub parseparam {
    my $var ;
    my @arg = @ARGV ;

    while(@arg) {
        $var = shift(@arg) ;
        $obo_file	= shift(@arg) if($var eq '-i') ;
    }
    die "Please add the obo filename as parameter" 	if (!$obo_file) ;

	
}