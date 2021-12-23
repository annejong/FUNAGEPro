#!/usr/bin/perl

#	 Anne de Jong, October 2016
#		- Get SMART descriptions
#		

use lib "/usr/molgentools/lib";
use anne_files ;

my $db_folder = '/usr/software/interproscan/interproscan-5.11-51.0/data/smart/6.2';
my $db_name = 'smart.HMMs' ;
my $outputfolder = '/usr/molgentools/gsea_pro/';


my @lines = anne_files::read_lines("$db_folder/$db_name");
my @result = "key\tdescription";


my $key ;
foreach my $line (@lines) {
	if ($line =~ m/^ACC\s+(.*)/) { $key = $1; }
	if ($line =~ m/^DESC\s+(.*)/) { push @result, $key."\t".$1;  }
}
print scalar @result ;
print " Description found\n";
anne_files::write_lines("$outputfolder/smart.descriptions", @result);


