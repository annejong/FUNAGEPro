#!/usr/bin/env perl

##############################################################
##    Genome2D program 
## 	Anne de Jong
##	University of Groningen
##	the Netherlands
##	anne.de.jong@rug.nl
##
##############################################################
##
##   
##  Convert UniProt 2 Classes
##



## Get latest database: wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz

# export PERL5LIB=/data/molgentools/lib

use strict ;
use warnings ;
use anne_files ;


if( $#ARGV == -1 ){ print "USAGE:\n\t/data/pg-molgen/databases/uniprot_sprot/Uniprot_2_KO.pl databasedir\n"; exit(); }
my $databasedir   = $ARGV[0];
my @lines = anne_files::read_lines("$databasedir/uniprot_sprot.dat") ;


my $key ;
my $AC ;
my $DE ;
my $GeneName ;
my @Description ;
my @ID;
my @KO ;
my @KOdb ;
my @GO ;
my @GOdb ;
my @IPR ;
my @IPRdb ;
my @KEGG ;
my @KEGGdb ;
my @PFAM ;
my @PFAMdb ;
my @eggNOG ;
my @eggNOGdb ;
my @ENOG ;
my @ENOGdb ;
my @KW ;
my @KWdb ;



foreach my $line (@lines) {
	$line =~ s/\.$// ;  # remove the dot
	if ($line =~ /^\/\//)   { # END OF RECORD
		if (@KO)    { push @KOdb,     "$key\t$AC\t$DE\t".join ";", @KO ;     @KO = () ;      }
		if (@GO)    { push @GOdb,     "$key\t$AC\t$DE\t".join ";", @GO ;     @GO = () ;      }
		if (@eggNOG){ push @eggNOGdb, "$key\t$AC\t$DE\t".join ";", @eggNOG ; @eggNOG = () ;  }
		if (@ENOG)  { push @ENOGdb,   "$key\t$AC\t$DE\t".join ";", @ENOG ;   @ENOG = () ;  }
		if (@IPR)   { push @IPRdb,    "$key\t$AC\t$DE\t".join ";", @IPR ;    @IPR = () ;     }
		if (@KEGG)  { push @KEGGdb,   "$key\t$AC\t$DE\t".join ";", @KEGG ;   @KEGG = () ;    }
		if (@PFAM)  { push @PFAMdb,   "$key\t$AC\t$DE\t".join ";", @PFAM ;   @PFAM = () ;    }
		if (@KW)    { push @KWdb,     "$key\t$AC\t$DE\t".join " ", @KW ;     @KW = () ;      }
		push @Description, "$key\t$AC\t$DE\t$GeneName" ;
	}	
	if ($line =~ /^ID   (.*?)\s+/)                       { push @ID, $1; $key = $1 ; }	
	if ($line =~ /^AC   (.*?);/)                         { $AC = $1 ; }	
	if ($line =~ /^DE   RecName: Full=(.*?)(\ \{|;)/)    { $DE = $1 ; }	
	if ($line =~ /^GN   Name=(.*?)(\ \{|;)/)             { $GeneName = $1 ; }	
	if ($line =~ /^DR   KO; (.*?);/)                     { push @KO, $1 ; }
	if ($line =~ /^DR   GO; (.*?);/)                     { push @GO, $1 ; }
	if ($line =~ /^DR   eggNOG; (COG.*?);/)              { push @eggNOG, $1 ; }
	if ($line =~ /^DR   eggNOG; (ENOG.*?); Bacteria/)    { push @ENOG, $1 ; }
	if ($line =~ /^DR   InterPro; (.*?);/)               { push @IPR, $1 ; }
	if ($line =~ /^DR   KEGG; (.*?);/)                   { push @KEGG, $1 ; }
	if ($line =~ /^DR   Pfam; (.*?);/)                   { push @PFAM, $1 ; }
	if ($line =~ /^KW   (.*)/)                           { push @KW, $1 ; }
		
}

anne_files::write_lines("$databasedir/uniprot_sprot.ID", @ID) ;
anne_files::write_lines("$databasedir/uniprot_sprot.KO", @KOdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.GO", @GOdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.eggNOG", @eggNOGdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.ENOG", @ENOGdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.IPR", @IPRdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.KEGG", @KEGGdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.PFAM", @PFAMdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.Keyword", @KWdb) ;
anne_files::write_lines("$databasedir/uniprot_sprot.description", @Description) ;


