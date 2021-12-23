#!/usr/bin/perl
#	 Anne de Jong, October 2016
#		- Get PANTHER descriptions
#		

use lib "/usr/molgentools/lib";
use anne_files ;

my $db_folder = '/usr/software/interproscan/interproscan-5.11-51.0/data/panther/9.0/model/globals';
my $db_name = 'names.tab' ;
my $outputfolder = '/usr/molgentools/gsea_pro/' ;

my @lines = anne_files::read_lines("$db_folder/$db_name");
my @result = "key\tdescription";

foreach my $line (@lines) {
	if ($line =~ m/^(PTHR\d+)\.mag.*\t(.*)/) { push @result, $1."\t".$2; }
}
print scalar @result ;
print " Descriptions found\n";
anne_files::write_lines("$outputfolder/panther.descriptions", @result);


