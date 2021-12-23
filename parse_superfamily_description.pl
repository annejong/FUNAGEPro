#!/usr/bin/perl

#	 Anne de Jong, October 2016
#		- Get SMART descriptions
#		
use strict ;
use lib "/usr/molgentools/lib";
use anne_files ;

my $db_folder = ' /usr/software/interproscan/interproscan-5.11-51.0/data/superfamily/1.75';
my $db_name = 'hmmlib_1.75' ;
my $outputfolder = '/usr/molgentools/gsea_pro/' ;

print "Search descriptions in $db_folder/$db_name\n";
open (FILE,"<$db_folder/$db_name") or die ("Could not read $db_folder/$db_name");
my @lines = <FILE>;	

my @result ;

my $key ;
foreach my $line (@lines) {
	if ($line =~ m/^ACC\s+(.*)/) { $key = $1; }
	if ($line =~ m/^DESC\s+(.*)/) { push @result, "SSF".$key."\t".$1;  }
}

print scalar @result ;
print " Descriptions found\n";
@result = anne_files::unique_array(@result) ;
unshift @result, "key\tdescription" ;
print scalar @result ;
print " Unique Descriptions found\n";
anne_files::write_lines("$outputfolder/superfamily.descriptions", @result);


