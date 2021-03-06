#!/usr/bin/env perl
#!/usr/bin/env perl
#
#
#	Anne de Jong
#
#	First release; July 2018
#   Last update; March 2022
#
#	GSEA-Pro v3.0 Gene Set Enrichment Analysis for prokaryotes, multiple experiments and Clusters
#	All html tables are removed and will be js driven on the basis of the .JSON
#	
# 	
#
# GSEA_Pro depends on "gsea_pro.R"

use warnings;
use strict;
use lib "/data/molgentools/lib";
use anne_files ;
use anne_misc ;
use File::Basename;
use JSON;



# ------------------------------------------------------------ parameters ----------------------------------------------------------------------
my $program_dir = dirname($0) ;
my $R_script = "$program_dir/gsea_pro_v3.R";
my $R_autodetect_script = "$program_dir/gsea_pro_benchmark.R";


my $sessiondir ='.' ;
my $method = 'experiment';
my $querytable ;
my $genome ;
my $up = 2 ;
my $down = -2 ;
my %thresholds ;
my $ratioCutoff = 0.1 ;
my $ClusterSize = 3 ;
my $MaxGeneSetUp = 100 ;
my $MaxGeneSetDown = 100 ;
my $user_prefix = 'gsea_pro';
my $clusterColumn = 'clusterID' ;
my $autodetect = 'true';
my $genome2d_url = 'http://genome2d.molgenrug.nl/genome2d_results/GSEA_pro' ;
my $KEGG_organisms = "$program_dir/KEGG_organism.table";
my $usage = "$program_dir/gsea_pro_v3.pl
				-s sessiondir and output folder [default=current folder]
				-table	Tab delimited text file of locus-tags and experiments: first column = locus_tag, other columns = experiments
				-g genome prefix, including full path [e.g. /data/g2d_mirror/Lactococcus_lactis_cremoris_MG1363_uid58837/NC_009004 ]
				-method	analyzing method: experiment | cluster  [ default = $method ]
				-up	cutoff value for positive values [default = $up]
				-down	cutoff value for negative values [default = $down]
				-cluster	Name of the clustercolumn [default = $clusterColumn]
				-auto  Auto detect threshold values [default= $autodetect]
				-o user prefix for results [default = $user_prefix ]

e.g.  ./gsea_pro_v3.pl -table gsea_pro_Experiment_Table.txt -g /var/genomes/Bacteria/Bacillus_subtilis_168_uid57675/NC_000964 -o my_results
";



&parseparam() ;

unlink ("$sessiondir/$user_prefix.OverviewTable.html");  # remove previous run
unlink ("$sessiondir/00.ClassExperiments.json");  # remove previous run
my @analysis_report ; # Contains messages to be reported to the webserver

# Pre-set color schemes
	my @blue = blue_range() ;
	#my @red  = red_range() ;

# The Class names and their web links
# The Class names are defined in the R routine
	my %classes ;
	$classes{GO} = "http://www.ebi.ac.uk/QuickGO/GTerm?id=" ; 
	$classes{IPR} = "http://www.ebi.ac.uk/interpro/entry/" ; 
	$classes{KEGG} = "http://www.genome.jp/kegg-bin/show_pathway?" ; 
	$classes{KEGG_organism} = '';
	$classes{SUPERFAMILY} = "http://supfam.cs.bris.ac.uk/SUPERFAMILY/cgi-bin/scop.cgi?ipid="; 	
	$classes{Pfam} = "http://pfam.xfam.org/family/" ; 
	$classes{KEYWORDS} = "https://en.wikipedia.org/wiki/" ;
	$classes{eggNOG_COG} = "https://www.ncbi.nlm.nih.gov/Structure/cdd/" ; 
	$classes{ENOG} = "https://www.ncbi.nlm.nih.gov/Structure/cdd/" ; 
	$classes{COG} = "http://ecoliwiki.net/colipedia/index.php/Clusters_of_Orthologous_Groups_(COGs)?name=" ; 
	$classes{operons} = g2d_operon_url() ; 
	$classes{REGULON} = "https://www.prodoric.de/matrix/?term=" ; 
	#$classes{MetaCyc} = "http://metacyc.org/META/new-image?type=PATHWAY&object=" ; 
	
# session folders
	my @items = split '/', $sessiondir ;  # get the sessionid without directory: is index [-1]	
	my $session_id = $items[-1] ;
	
# Annotation from Genome2D database or FACoP. To make the naming uniform;
	print "===>Genome = $genome\n" ;	

 # ------------------------------------------------------------ main ----------------------------------------------------------------------


# 1. Add the KEGG organism ID, this allows the correct organism link in the KEGG website 
	# use python /data/molgentools/KEGG_organims_mapping.py to generate/update the KEGG organism table
	my $KEGG_organism_id = get_KEGG_organism_id() ;
	print "KEGG organism ID = $KEGG_organism_id\n"; 
	$classes{KEGG_organism} = $KEGG_organism_id ;

 
# 2. Read the experiments, clusters or single table, This will all be stored in the hash: %experiments
	print "\n#2. Read $sessiondir/$querytable\n";
	clean_querytable() ;
	if (chk_query_locustags()<0.10) { # less than 10% matches so give a warning 
		my $str = "<font color=red>ERROR: Bad match between query and organism<br>
					Please check the locus-tags in your query and the selected genome.<br> 
					NOTE: In some annotations the <i>underscore</i> in the locus-tag is missing.<br> </font>" ;
		anne_files::write_string("$sessiondir/sessionprogress",$str);
		anne_files::write_string("$sessiondir/sessionstop", "error: Bad match between query and organism, please check the locus-tags in your query and the selected genome") ;
		print "\nERROR ==> Bad match between query and organism, please check the locus-tags in your query and the selected genome\n\n" ;
		exit();
	}
	my %experiments ;
	anne_files::append_lines("$sessiondir/sessionprogress","Auto detect Threshold Values = ON<br>") if ($autodetect eq 'true') ; 
	anne_files::append_lines("$sessiondir/sessionprogress","Reading data<br>");

#3. Selected method
	print "\n#3. Selected method = $method\n";
	my $InputTableSize = 0 ;
	if ($method eq 'experiment') {
		%experiments = read_experiments($querytable)  ;
	} elsif ($method eq 'cluster') {	
		%experiments = read_clusters($querytable,$clusterColumn ) ;
	} elsif ($method eq 'single') {	
		%experiments = read_single($querytable) ;
	} else {
		print "Error: defined method '-method $method' not found\n" ;
	}	

	
# 4. R script wil be executed for each experiment, cluster or single list
	# test FACoP
	# sudo -u www-data R --vanilla --slave --args /tmp/GSEAPRO/GSEA_PRO/129.125.142.95.4sgv17tddtls9lbcchn2rmh264.883 /tmp/GSEAPRO/GSEA_PRO/129.125.142.95.4sgv17tddtls9lbcchn2rmh264.883/GSEA_Pro.list.single_list.txt /tmp/FACoP/FACoP/129.125.142.95.ncm44vdlmjc3q09s4bk4ee52i1.254/query.FACoP GSEA_Pro single_list < /data/gsea_pro/gsea_pro_v3.R
	print "\n#4. Analyze experiments in R\n";
	anne_files::append_lines("$sessiondir/sessionprogress","Analyze experiments in R<br>");
	my @experimentHits ;
	analyze_experiments_in_R() ;
	my %GenesPerClassID = genes_per_CLASS_ID() ; # Get results from R-output files. And store it in $GenesPerClassID{$experiment}{$class_id}
	
	
# 5. Combine all experiment in one overview table: Class x Experiments
	print "\n#5. Combine all experiment in one overview table: Class x Experiments\n";
	my %class_exp ; # the classID x experiment table
	combine_experiments_classes() ;
	# write a locus-tag list as HTML of all experiment x class_id combination : Data source = %class_exp and  %GenesPerClassID

	
# 6. Results produced by the R routine will be converted to HTML tables and JSON for visualization by the webserver
	print "\n#6. Convert R result tables to HTML and JSON files for all Classes x Experimens\n";
	foreach my $class (keys %classes) {	
		foreach my $experiment (sort keys %experiments) {
			my $file_prefix = "$sessiondir/$user_prefix.GSEA.$class.$experiment" ;
			R_text_table_2_JSON($file_prefix) ;
			
		} 
	}
	
# 7. Write JSON for D3.js TreeMap and GroupedBarPlot
	print "\n#7. Make TreeMap\n";
	make_TreeMap_JSON() ;
	make_GroupedBarPlot_nested_JSON();
	make_GroupedBarPlot_table();
	
	anne_files::write_lines("$sessiondir/00.ClassExperiments_old.json",(encode_json \%class_exp)) ;
	anne_files::write_lines("$sessiondir/00.Class.json",(encode_json \%classes)) ;
	anne_files::write_lines("$sessiondir/00.Experiments.json",(encode_json \%experiments)) ;
	
# 8. Make result pages
	print "\n#8. Write the table and html table: Class X Experiment \n";
	print "\t Table 1 json\n";
	make_Table_1_JSON();
	print "\t GeneAnnotation json\n";
	make_GenomeAnnotation_JSON() ;
	
# 9. print Analysis Report
	print "\n#9. Analysis Report\n";
	print join "\n", @analysis_report	;
	print "\n";

# 10. FINAL. let the web server know that the run is finished
	anne_files::write_string("$sessiondir/sessionstop", "done") ;

	
	
	
	
	
	
	
# ------------------------------------------------------------ functions ----------------------------------------------------------------------


sub g2d_operon_url {
  # http://genome2d.molgenrug.nl/g2d_show_feature_from_table.html?genome=g2d_mirror%2FBacillus_subtilis_subsp_subtilis_str_168%2FASM904v1_genomic&annotation=operons&feature=operon_0006
	my $url = 'http://genome2d.molgenrug.nl/g2d_show_feature_from_table.html' ;
	my $url_genome = $genome;
	$url_genome =~ s/\/data\/// ;  # remove /data
	$url_genome =~ s/\//%2F/g ; # replace / by %2F for the url
	$url = $url.'?genome='.$url_genome.'&annotation=operons&feature=' ;
	print "============> $url \n";
	return $url ;
	
}

sub make_GenomeAnnotation_JSON {
	# convert the genome table of genome2d to json format
	my %table = anne_files::read_table_to_hash("$genome.g2d.FACoP.table") ;
	print "Annotation is loaded from $genome.g2d.FACoP.table\n================================================================\n" ;
	anne_files::write_lines("$sessiondir/00.GenomeAnnotation.json",(encode_json \%table)) ;
}	



sub make_Table_1_JSON {
	my %json ;
	
	# for (my $i=1; $i<=5; $i++) { push @stars, "<img src=images/star$i.png style=width:15px;height:15px;>" ; }
	foreach my $class_id (sort {$class_exp{$a}{Class} cmp $class_exp{$b}{Class} || $a cmp $b} keys %class_exp) {
		foreach my $expKey (sort keys %experiments ) {
			$json{$class_id}{Class} = $class_exp{$class_id}{Class} ;
			$json{$class_id}{ClassSize} = $class_exp{$class_id}{ClassSize} ;
			$json{$class_id}{Description} = $class_exp{$class_id}{Description} ;
			if (defined($class_exp{$class_id}{$expKey}{ExpectationValue})) {
				$json{$class_id}{experiments}{$expKey}{adj_pvalue}	= $class_exp{$class_id}{$expKey}{adj_pvalues} ;
				$json{$class_id}{experiments}{$expKey}{color} 		= $class_exp{$class_id}{$expKey}{ColorIdx} ;
				$json{$class_id}{experiments}{$expKey}{ExpValue} 	= $class_exp{$class_id}{$expKey}{ExpectationValue} ;
				$json{$class_id}{experiments}{$expKey}{geneset} 	= $class_exp{$class_id}{$expKey}{geneset} ;
				$json{$class_id}{experiments}{$expKey}{hits} 		= $class_exp{$class_id}{$expKey}{Hits} ;
				$json{$class_id}{experiments}{$expKey}{rank} 		= anne_misc::roundup(-1+$class_exp{$class_id}{$expKey}{ColorIdx}/2) ;
			} else {
				$json{$class_id}{experiments}{$expKey}{adj_pvalue}	= '';
				$json{$class_id}{experiments}{$expKey}{color} 		= '';
				$json{$class_id}{experiments}{$expKey}{ExpValue} 	= '';
				$json{$class_id}{experiments}{$expKey}{geneset} 	= '';
				$json{$class_id}{experiments}{$expKey}{hits} 		= '';
				$json{$class_id}{experiments}{$expKey}{rank} 		= '-1';
			}
		}	
	}
	anne_files::write_lines("$sessiondir/00.ClassExperiments.json",(encode_json \%json)) ;
}	


sub get_KEGG_organism_id {
	my @lines = anne_files::read_lines($KEGG_organisms) ;
	my $genomeid = '' ;
	if ($genome =~ m/.*\/(.*)_genomic/) { $genomeid = $1 ; }
	my $result = '';
	foreach my $line (@lines) {
		my @items = split "\t", $line ;
		if (scalar @items >2) {
			if ($items[0] =~ m/$genomeid/) {
				$result = $items[2];
				last ;
			}	
		}
	}
	return $result ;
	
}

sub clean_querytable {
	# remove space
	my @result ;
	my @lines = anne_files::read_lines("$sessiondir/$querytable") ;
	foreach my $line (@lines) {
		$line =~ s/(\n|\r|\x0d)//g;		 # remove line breaks etc
		$line =~ s/(\ |\!|\\|\/|\||\:|\*|\"|\?|\<|\>)//g ;   # remove illegal chars 
		push @result, $line ;
	}
	$querytable = 'query_cleaned.txt' ;
	anne_files::write_lines("$sessiondir/$querytable", @result) ;
}

	
sub analyze_experiments_in_R {	
	# analyze each experiments one by one in R
	foreach my $experiment (sort keys %experiments) {
		push @experimentHits, scalar  @{ $experiments{$experiment} } ;
		if (scalar  @{ $experiments{$experiment} } >= $ClusterSize) {
			print "Analyzing experiment $experiment\n";
			anne_files::write_lines("$sessiondir/$user_prefix.list.$experiment.txt", @{ $experiments{$experiment} } ); 
			# run the R script
			print "R parameters\n
			sessiondir = $sessiondir \n
			experiment = $sessiondir/$user_prefix.list.$experiment.txt \n
			genome = $genome \n
			user_prefix = $user_prefix \n
			experiment = $experiment \n" ;
			my $tmp = "R --vanilla --slave --args $sessiondir $sessiondir/$user_prefix.list.$experiment.txt $genome $user_prefix $experiment < $R_script 2>>$sessiondir/00.GSEA_Pro.log" ;
			anne_files::write_log("$sessiondir/log.txt", $tmp, 'true') ;
			system($tmp) ;
		}
	}
}


sub chk_query_locustags {
	# check if the correct organism is selected on the basis of locus tags
	print "Check if the correct organism is selected based on $sessiondir/$querytable\n";
	my @lines = anne_files::read_lines("$sessiondir/$querytable");
	my @query_locustags ;
	foreach my $line (@lines) {
		my @items = split ";|,|\t", $line ; # split on the most common separators
		push @query_locustags, $items[0] ;  # string with all locus tags
	}
	my $locustags = join ' ', anne_files::unique_array(@query_locustags) ; # long concatenated 'query locus_tag string'
	my $queryCount = scalar anne_files::unique_array(@query_locustags) ; ;
	@lines = anne_files::read_lines("$genome.g2d.FACoP.table") ;
	print "Checking $genome     .g2d.FACoP.table\n" ;
	print "$lines[0]\n$lines[1]\n$lines[2]\n" ;
	print "$lines[0]\n$lines[1]\n$lines[2]\n" ;
	my $count = 0;
	foreach my $line (@lines) {
		my @items = split ";|,|\t", $line ; # split on the most common separators
		if ($items[0] ne '') { 
			$count++ if ($locustags =~ m/$items[0]/) ;  # compare the locus_tag to the long concatenated 'query locus_tag string'
		}	
	}	
	print "Locus-tags check:$count /  $queryCount = ".$count /  $queryCount."\n";
	return $count /  $queryCount ;  # return ratio: correct query / total in query 
}


sub autodetect_threshold {
	# R script to detect threshold values
	# expected: locustag value as tab delimited and no header
	# R script will write the benchmark data to 00.my_scores_up.$experiment.txt and 00.my_scores_down.$experiment.txt
	my ($experiment, @lines) = @_ ;
	anne_files::append_lines("$sessiondir/sessionprogress","Detecting Threshold values for $experiment<br>");
	anne_files::write_lines("$sessiondir/autodetect.tmp",@lines) ;
	my $commandline = "R --vanilla --slave --args $sessiondir $sessiondir/autodetect.tmp $genome $experiment < $R_autodetect_script 2>>$sessiondir/00.GSEA_Pro.log" ;
	anne_files::write_log("$sessiondir/log.txt", $commandline, 'true') ;
	system($commandline) ;
	# read the R results summary 
	my $up = 2 ;
	my $down = -2 ;
	@lines = anne_files::read_lines("$sessiondir/00.GSEA_benchmark.txt");
	foreach my $line (@lines) {
		my @items = split /\t/, $line ;
		$up   = $items[1] if $items[0] eq 'UP.cutoff' ;
		$down = $items[1] if $items[0] eq 'DOWN.cutoff' ;
	}	
	return ($up, $down) ;
}


sub read_single {
	# read a single list, use only the first column if second columns is missing
	print "Read single list\n";
	my $filename = shift ;
	my @lines = anne_files::read_lines("$sessiondir/$filename");
	$InputTableSize = scalar @lines;
	my %results ;
	my @autodetect_lines ;
	my %single_list ; ;
	foreach my $line (@lines) {
		my @items = split ";|,|\t", $line ; # split on the most common separators
		if (defined($items[1])) { 						# check if second column contains values
			if (anne_misc::is_numeric($items[1])) {	 	# check if second column is numeric
				if ($items[1]<-1 or $items[1]>1) {  	# check if values is between thresholds
					#push @{ $results{single_list} }, $items[0] ;
					push @autodetect_lines, "$items[0]\t$items[1]";	
					$single_list{$items[0]} = $items[1] ;	
				}
			}
		} else { # no second column		
			push @{ $results{single_list} }, $items[0] ;	
		}	
	}
	if (scalar @autodetect_lines > 2) { # Apply the Threshold values if the input does contain > 2 values
		($up, $down) = autodetect_threshold('single_list',@lines) if ($autodetect eq 'true') ;
		@{ $results{single_list} }  = grep { $single_list{$_} < $down or  $single_list{$_} > $up } keys %single_list; # take only locus tags in range
	}
	# make report
	$thresholds{single_list}{down} = $down ;
	$thresholds{single_list}{up} = $up ;		# store the results for the report
	return %results ;
}


sub read_experiments {
	# push all locus-tags passing the cutoffs to results with the key=experimentname
	print "Reading Experiments\n";
	my $filename = shift ;
	my %table = anne_files::read_table_to_hash("$sessiondir/$filename") ;
	$InputTableSize = scalar keys %table ;
	my %results ;
	# 1. load the data
	my %tmp ;
	foreach my $locus (sort keys %table) {
		foreach my $experiment (sort keys %{$table{$locus}}) {
			if ( anne_misc::is_realnumber($table{$locus}{$experiment}) ) {
				if ( $table{$locus}{$experiment} <= -1.1 or $table{$locus}{$experiment} >= 1.1 ) {  # remove noise at this stage, thresholds will be applied in step 2 below 
					$tmp{$experiment}{$locus} = $table{$locus}{$experiment} ; }
			}
		}
	}
	# 2. filter values using threshold values and if needed auto detect threshold values
	foreach my $experiment (keys %tmp) {
		my $count = 0 ;
		my @locus_list ;
		foreach my $locus (sort {$table{$b}{$experiment} <=> $table{$a}{$experiment}} keys %table) { 
			if ($count<$MaxGeneSetUp and $table{$locus}{$experiment}>0) {
				#print $table{$locus}{$experiment}."\n" ;
				push @locus_list, $locus ; 
				$count++ ;
			}
		}	
		# autodetect threshold
		my @lines ;
		foreach my $locus (keys %{$tmp{$experiment}}) { push @lines, $locus."\t".$tmp{$experiment}{$locus}; }
		($up, $down) = autodetect_threshold($experiment, @lines) if ($autodetect eq 'true') ;
		$thresholds{$experiment}{up} = $up ;		# store the results for the report
		$thresholds{$experiment}{down} = $down ;
		foreach my $locus (keys %{$tmp{$experiment}}) { 
			if ($tmp{$experiment}{$locus}<= $down or $tmp{$experiment}{$locus} >= $up ) {
				push @{ $results{$experiment} }, $locus ;
			}
		}
	}
	# make report
	my $keycount = scalar keys %results ;
	push @analysis_report, "Number of Experiments: $keycount" ;
	return %results ;
}

sub leading_zeros {
	my $number = shift ;
	if ($number =~ (/^\d+$/)) {  return sprintf("%02d", $number); } # is a number 
	else { return $number ; }
}

sub read_clusters {
	# Here we do not use Thresholds because the clusters are already based on statistics
	# only use clusters >= $ClusterSize
	print "Reading Clusters\n";
	my $filename = shift ;
	my $clusterColumn = shift ;
	my %table = anne_files::read_table_to_hash("$sessiondir/$filename") ;
	$InputTableSize = scalar keys %table ;
	my %results ;
	foreach my $locus (sort keys %table) {
		#my $test = leading_zeros($table{$locus}{$clusterColumn}) ;
		my $cluster = "Cluster".leading_zeros($table{$locus}{$clusterColumn}) ;
		#my $cluster = "Cluster_".$table{$locus}{$clusterColumn};
		push @{ $results{$cluster} }, $locus ;
	}
	# locus tags can/will occur multiple times, so make the array unique
	# remove clusters < $ClusterSize
	foreach my $cluster (keys %results) {
		@{ $results{$cluster} } = anne_files::unique_array(@{ $results{$cluster} }) ; 
		delete $results{$cluster} if (scalar  @{ $results{$cluster} } < $ClusterSize ) ;
	} 
	# make report
	my $keycount = scalar keys %results ;
	push @analysis_report, "Number of Clusters: $keycount" ;
	return %results ;
}




sub combine_experiments_classes {	
	# The result of each experiment/clustering or single list are here combined with all the Classes analyzed into one table document: ClassID x Experiment
	foreach my $experiment (sort keys %experiments) {
		my $filename = "$sessiondir/$user_prefix.GSEA_merged.$experiment.txt" ;
		if (-e($filename)) {
			my %exp_table = anne_files::read_table_to_hash("$sessiondir/$user_prefix.GSEA_merged.$experiment.txt") ; 
			foreach my $class_id (keys %exp_table) {
				# rule: Hits must be more than 10% of the class size, except if Hits =2 then 20% will be the cutoff
				my $ratioCutoff = 0.01 ;
				$ratioCutoff = 0.2 if ($exp_table{$class_id}{Hits} == 2) ;
				if ( $exp_table{$class_id}{Ratio} >= $ratioCutoff ) {
					my $geneset = '';
					if (defined($GenesPerClassID{$experiment}{$class_id})) { $geneset = join ',', @{$GenesPerClassID{$experiment}{$class_id}}; }  # add the genelset
					$class_exp{$class_id}{$experiment}{geneset}				= $geneset ;
					$class_exp{$class_id}{$experiment}{pvalues}				= $exp_table{$class_id}{pvalues} ;
					$class_exp{$class_id}{$experiment}{adj_pvalues}			= $exp_table{$class_id}{adj_pvalues} ;
					$class_exp{$class_id}{$experiment}{minFDR} 				= $exp_table{$class_id}{minFDR} ;
					$class_exp{$class_id}{$experiment}{Hits} 				= $exp_table{$class_id}{Hits} ;
					$class_exp{$class_id}{$experiment}{ExpectationValue} 	= anne_misc::roundup($exp_table{$class_id}{Ratio}*$exp_table{$class_id}{minFDR}) ; # ratio x -log2(pvalue) 
					$class_exp{$class_id}{$experiment}{ColorIdx} 			= value2colorIdx($class_exp{$class_id}{$experiment}{ExpectationValue} ) ;
					$class_exp{$class_id}{Class} 							= $exp_table{$class_id}{class} ;		# independent of experiment
					$class_exp{$class_id}{ClassSize} 						= $exp_table{$class_id}{ClassSize} ;	# independent of experiment
					$class_exp{$class_id}{Description} 						= $exp_table{$class_id}{Description} ;  # independent of experiment
					$class_exp{$class_id}{Description} 	=~ s/\"//g ; # remove unwanted chars
				}
			}	
		}
	}	
}	


sub get_genome_size {
	my @lines = anne_files::read_lines("$genome.table") ;
	shift @lines ;
	return scalar @lines ;
}



sub genes_per_CLASS_ID {
	# Get results from R output files
	my %results ;
	foreach my $class (sort keys %classes) {
		foreach my $experiment (sort keys %experiments ) {
			my @lines = anne_files::read_lines("$sessiondir/$user_prefix.TopHitsClass.$class.$experiment.txt") ;  # file containing the genelist
			shift @lines ; # remove header
			foreach my $line (@lines) {
				my @items = split "\t", $line ;
				my $class_id = $items[1] ;
				push @{$results{$experiment}{$class_id}}, $items[0] ;
			}
		}	
	}
	return %results ;
}

sub make_TreeMap_JSON {
	my @json = '[' ;
	foreach my $class_id (keys %class_exp) {
		foreach my $experiment (sort keys %experiments) {
			my $geneset = '';
			if (defined($GenesPerClassID{$experiment}{$class_id})) { $geneset = join ';', @{$GenesPerClassID{$experiment}{$class_id}}; }
			if (defined($class_exp{$class_id}{$experiment}{Hits})) {
				my $url = $classes{$class_exp{$class_id}{Class}} ;
				push @json, '  {';
				push @json, "    \"key\": \"$class_id:$class_exp{$class_id}{Description}\",";
				push @json, '    "experiment": "'.$experiment.'",' ;
				push @json, '    "class": "'.$class_exp{$class_id}{Class}.'",';
				push @json, '    "class_id": "'.$class_id.'",';
				push @json, '    "description": "'.$class_exp{$class_id}{Description}.'",';
				push @json, '    "genes": "'.$geneset.'",';
				push @json, '    "url": "'.$url.$class_id.'",';
				push @json, '    "value":'.$class_exp{$class_id}{$experiment}{Hits} ;
				push @json, '  },' ;
			}
		}   
	} 
	pop @json ;
	push @json , '  }' ; # last bracket without comma
	push @json, ']';
	anne_files::write_lines(" $sessiondir/gsea_pro.json",@json) ;
}

sub R_text_table_2_JSON {
	my $file_prefix = shift ;
	if (!-e "$file_prefix.txt") { 
		anne_files::write_log("$sessiondir/log.txt", "WARNING: $file_prefix.txt not found", 'false') ;
	} else {
		my %table = anne_files::read_table_to_hash("$file_prefix.txt") ;
		my @json = '[' ;
		foreach my $class_id (sort keys %table) {
			push @json, '  {';
			my @record ="    \"key\": \"$class_id\"";
			foreach my $header (sort keys %{$table{$class_id}}) {
				if (anne_misc::is_realnumber($table{$class_id}{$header}) and !( $table{$class_id}{class} eq "KEGG" and $header eq "CLASS_ID") ) {   # NOTE KEGG classIDs are numbers but should be treated as text by javascript
					push @record, '    "'.$header.'":  '.$table{$class_id}{$header} ;
				} else {
					push @record, '    "'.$header.'": "'.$table{$class_id}{$header}.'"' ;
				}	
			}	
			push @json, join ",\n", @record ;
			push @json, '  },' ;			
		}
		pop @json ;
		push @json , '  }' ; # last bracket without comma
		push @json, ']';
		anne_files::write_lines("$file_prefix.json", @json) ;	
	}
}		



sub value2colorIdx {
	# use Hits * minFDR in the range from 1..100
	my $value = shift ;
	my $index = anne_misc::roundup($value) ;
	$index = 10 if ($index>10) ;
	return $index ;
}



	
#sub make_GroupedBarPlot_JSON {
#	my @json ;
#	for my $class_id (sort keys %class_exp) {
#		if ($class_exp{$class_id}{Class} eq 'COG') {  # We only do COG here
#			my @records ;
#			foreach my $experiment (sort keys %experiments) {
#				my @record 	;
#				if (defined($class_exp{$class_id}{$experiment}{geneset})) {
#					push @record, '"geneset":"'. 		$class_exp{$class_id}{$experiment}{geneset}.	 '"';
#					push @record, '"pvalues":'. 		$class_exp{$class_id}{$experiment}{pvalues}			 ;
#					push @record, '"adj_pvalues":'. 	$class_exp{$class_id}{$experiment}{adj_pvalues}	     ;
#					push @record, '"minFDR":'. 			$class_exp{$class_id}{$experiment}{minFDR} 	         ;
#					push @record, '"Hits":'. 			$class_exp{$class_id}{$experiment}{Hits} 	         ;
#					push @record, '"ExpectationValue":'.$class_exp{$class_id}{$experiment}{ExpectationValue};
#				} else {
#					push @record, '"geneset":"-"';
#					push @record, '"pvalues":1';
#					push @record, '"adj_pvalues":1';
#					push @record, '"minFDR":0';
#					push @record, '"Hits":0';
#					push @record, '"ExpectationValue":0';
#				}
#				push @records, '"experiment": "'.$experiment.'",'."\n\t".(join ",\n\t\t", @record)  ;
#			}
#			push @json, '"class_id": "'.$class_id.'",'."\n   \"values\": [\n\t{".(join "\n\t},\n\t{", @records)."}\n\t]";
#		}
#	}
#	my $result = "[\n{".(join "\n},{", @json)."}\n]\n\n" ; 	
#	anne_files::write_string("$sessiondir/00.GroupedBarPlot.json", $result) ;	
#}

sub make_GroupedBarPlot_nested_JSON {
	my @json ;
	for my $class_id (sort keys %class_exp) {
		if ($class_exp{$class_id}{Class} eq 'COG') {  # We only do COG here
			my @records ;
			foreach my $experiment (sort keys %experiments) {
				#print "$class_id\t$experiment\n";
				my @record 	;
				if (defined($class_exp{$class_id}{$experiment}{geneset})) {
					push @record, '"geneset":"'. 		$class_exp{$class_id}{$experiment}{geneset}.	 '"';
					push @record, '"pvalues":'. 		$class_exp{$class_id}{$experiment}{pvalues}			 ;
					push @record, '"adj_pvalues":'. 	$class_exp{$class_id}{$experiment}{adj_pvalues}	     ;
					push @record, '"minFDR":'. 			$class_exp{$class_id}{$experiment}{minFDR} 	         ;
					push @record, '"Hits":'. 			$class_exp{$class_id}{$experiment}{Hits} 	         ;
					push @record, '"ExpectationValue":'.$class_exp{$class_id}{$experiment}{ExpectationValue};
				} else {
					push @record, '"geneset":"-"';
					push @record, '"pvalues":1';
					push @record, '"adj_pvalues":1';
					push @record, '"minFDR":0';
					push @record, '"Hits":0';
					push @record, '"ExpectationValue":0';
				}
				push @records, '"experiment": "'.$experiment.'",'."\n\t".'"values":[{'.(join ",\n\t\t", @record).'}]'  ;
			}
			push @json, '"class_id": "'.$class_id.'",'."\n   \"values\": [\n\t{".(join "\n\t},\n\t{", @records)."}\n\t]";
		}
	}
	my $result = "[\n{".(join "\n},{", @json)."}\n]\n\n" ; 	
	anne_files::write_string("$sessiondir/00.GroupedBarPlot.json", $result) ;	
}

sub make_GroupedBarPlot_table {
	my @table = "Exp,".(join ",", sort keys %experiments) ;
	for my $class_id (sort keys %class_exp) {
		if ($class_exp{$class_id}{Class} eq 'COG') {  # We only do COG here
			my @record = $class_id	;
			foreach my $experiment (sort keys %experiments) {
				#print "$class_id\t$experiment\n";
				if (defined($class_exp{$class_id}{$experiment}{geneset})) {
					push @record, $class_exp{$class_id}{$experiment}{minFDR} 	         ;
				} else {
					push @record, '0';
				}
			}
			push @table, join ",", @record ;
		}
	}
	anne_files::write_lines("$sessiondir/00.GroupedBarPlot.table", @table) ;	
}



sub blue_range {
	# blue color range white to black: derived from http://www.w3schools.com/colors/colors_picker.asp
	my @blues = ( "#ffffff","#ecf2f9","#d9e6f2","#c6d9ec","#b3cce5","#9fbfdf","#8cb2d9","#79a6d2","#6699cc","#538cc6","#407fbf","#3973ac","#336699","#2d5986","#264c73","#204060","#1a334c","#132639","#0d1926","#060d13","#000000" ) ;
	my @result = ( "#ecf2f9","#c6d9ec","#b3cce5","#8cb2d9","#79a6d2","#6699cc","#407fbf","#3973ac","#336699","#264c73","#204060","#132639") ;
	return @result ;
}	



sub parseparam {
    my $var ;
    my @arg = @ARGV ;
    while(@arg) {
        $var = shift(@arg) ;
        $sessiondir 	= shift(@arg) if($var eq '-s') ;
        $method		 	= shift(@arg) if($var eq '-method') ;
        $querytable		= shift(@arg) if($var eq '-table') ;
        $genome			= shift(@arg) if($var eq '-g') ;
        $up				= shift(@arg) if($var eq '-up') ;
        $down			= shift(@arg) if($var eq '-down') ;
        $clusterColumn	= shift(@arg) if($var eq '-cluster') ;
        $ClusterSize	= shift(@arg) if($var eq '-clustersize') ;
        $autodetect		= shift(@arg) if($var eq '-auto') ;
        $user_prefix	= shift(@arg) if($var eq '-o') ;
    }
    die $usage if (!$querytable or !$genome) ;
}
