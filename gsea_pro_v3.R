# Gene Set Enrichment Analysis for Prokaryotes
# FUNAGE_Pro
#
# Anne de Jong
# University of Groningen
# 
# April 19, 2022 Name changed to FUNAGE-Pro


# using phyper(q, m, n, k, lower.tail = TRUE, log.p = FALSE) from package {stat}


# load parameters from command line or call from the webserver
# R command line:  R --vanilla --slave --args . robyn -r bacillus_cereus_merged_normalized.rpkm Factors.txt Contrasts.txt < /usr/molgentools/rnaseq/RNAseq_multifactor.R
	sessiondir <- commandArgs()[5]
	gene_list <- commandArgs()[6]
	genome  <- commandArgs()[7]
	user_prefix  <- commandArgs()[8]
	cluster_id  <- commandArgs()[9]


# Custom settings / or parameters from webserver

	# for local testing: 
	#  sessiondir  = "E:\\Google Drive\\WERK\\GSEA_Pro\\dataset"
	#  gene_list  = "gsea_pro_locus_list.txt"
	#  user_prefix = "my_results"
	#  genome <- 'ASM904v1_genomic.g2d'
	#  cluster_id <- '1'

# test FACoP
# sudo -u www-data R --vanilla --slave --args /tmp/GSEAPRO/GSEA_PRO/129.125.142.95.4sgv17tddtls9lbcchn2rmh264.883 /tmp/GSEAPRO/GSEA_PRO/129.125.142.95.4sgv17tddtls9lbcchn2rmh264.883/GSEA_Pro.list.single_list.txt /tmp/FACoP/FACoP/129.125.142.95.ncm44vdlmjc3q09s4bk4ee52i1.254/query.FACoP GSEA_Pro single_list < /data/gsea_pro/gsea_pro_v3.R
  
# preset values	
	classes 		<- list('COG','eggNOG_COG','GO','IPR', 'KEGG', 'KEYWORDS', 'Pfam', 'operons','REGULON')
	class_colors	<- list(IPR='#4D4D4D',GO='#5DA5DA',KEGG='#FAA43A', Pfam='#60BD68', SUPERFAMILY='#F17CB0', eggNOG_COG='#B2912F', KEYWORDS='#B276B2', COG='#B276B2', ENOG='#B276B2', operons='#B276B2', REGULON='#B276B2')
	FACoP_classes	<- list('COG','eggNOG_COG','GO','IPR', 'KEGG', 'KEYWORDS', 'Pfam')
	# for FACoP classes the genome names is genome.FACoP and will be applied when needed

#genome = paste(genome,'.FACoP',sep="")	

setwd(sessiondir)

# ------------------------------------------------------- functions ----------------------------------------------------------------------------
	
is.not.null <- function(x) ! is.null(x)
	
	
HypGeomDist_old <- function(k,m,n,N) {	
	# Hypergeometrical distribution -----------------------------------------------------------------
	# It describes the chance when getting a certain amount of IDs (n) without 
	# replacement from the total possible ID's (N), hitting the number of CLASS's 
	# frequency(k) in the TopTopHitsClass when the total CLASS frequency is (m)
	# It uses the summation of the hypergeometrical distribution
	# It calculates for each CLASS, what is the chance to get the number
	# of 'k' TopHitsClass in the TopTopHitsClass or even more extreme when drawing randomly
	# Summation of hypergeometrical distribution
# e.g.,
# k <- as.numeric(list(8, 2, 4, 7, 6, 2, 5, 2, 4, 2, 2, 2, 2, 2, 3, 3))
# m <- as.numeric(list( 9,   5,  56, 166, 249, 217, 107,  26, 160,  30,  13, 206,  99,  33,  18, 168))
# n <- 16
# N <- 1748
	
	
	pvalues <- numeric(length(k))
	ctk <- choose(N,n)

	if ( is.infinite(ctk) ) {
		# print ("Infinite number for ctk")
		for (i in 1:length(k)){
		  pvalues[i]=phyper(k[i], m[i], N-m[i], n)
		}  
	} else {
		# print (ctk)
		for (i in 1:length(k)){
		  pvalues[i]=0
		  for (j in k[i]:m[i]){
			pvalues[i]=pvalues[i]+choose(m[i],j)*choose(N-m[i],n-j)/ctk}
		}
	}
	return(pvalues)
}	
	
	
HypGeomDist <- function(k,m,n,N) {	
	ctk <- choose(N,n)
	pvalues <- numeric(length(k))
	
	if ( is.infinite(ctk) ) {
		i <- list(1:length(k))
		pvalues <- lapply(i, function(x) {  phyper(k[x], m[x], N-m[x], n)  })
	} else {
		for (i in 1:length(k)){
			j <- list( k[i]:m[i] )
			pvalues[i] <- sapply(j, function(x) {  sum(choose(m[i],x)*choose(N-m[i],n-x)/ctk)  }) 
		}
	}
	return(pvalues)
}

	
# -------------------------------------------------------------- main ---------------------------------------------------------------------------------------------------
	
# 1. Read gene list
	GeneList<-read.table(gene_list, sep = "\t", quote = "", blank.lines.skip = TRUE, header=FALSE)
	colnames(GeneList)[1] <- "ID"
	#head(GeneList)

# 2. Analyses of all classes
	print(paste('GENOME in R ==> ',genome))
	results <- lapply(classes, function(x) {
								# for testing:  x<- 'GO' or x<- 'KEGG'
								if (x %in% FACoP_classes) {
									filename = paste(genome,'g2d.FACoP',x,sep='.')
								} else {
									filename = paste(genome,'g2d',x,sep='.') 
								}	
								filenameout = paste(user_prefix,"TopHitsClass",x,cluster_id,'txt',sep='.')
								if (file.exists(filename)) {
									# a. Read the classes Class data from files
										CLASS_table<-read.table(filename, sep = "\t", quote = "", blank.lines.skip = TRUE, header=FALSE)
										colnames(CLASS_table) <- c("ID","CLASS_ID","Description")
										# head(CLASS_table)
									# b. Add class data to the genes and write annotation to files
										Annotation <- CLASS_table
										Annotation$ID <- NULL
										Annotation <- Annotation[order(Annotation$CLASS_ID),]
										Annotation <- Annotation[!duplicated(Annotation[,1]),]
										# head(Annotation)
										
										
										TopHitsClass<-merge(CLASS_table, GeneList, by="ID")
										write.table(TopHitsClass, file=filenameout, sep="\t", row.names=F, quote=FALSE)
									
									# c. Get frequencies	
										# Frequencies of CLASS members in GeneList ==> k
											ClassFrequency_TopHits<-as.data.frame(with(TopHitsClass[!duplicated(TopHitsClass), ], table(CLASS_ID)))
										# Frequencies of CLASS members ==> m
											ClassFrequency<-as.data.frame(with(CLASS_table[!duplicated(CLASS_table), ], table(CLASS_ID)))
										# Combine the Frequency tables
											CombinedClassCount<-cbind(ClassFrequency_TopHits,ClassFrequency$Freq)
											colnames(CombinedClassCount)=c("CLASS_ID","Hits","ClassSize")
										# remove Class members that are not present or only 1x in GeneList
											CombinedClassCount<-CombinedClassCount[CombinedClassCount$Hits>1,]
										# remove Class members that only occur 1x in the total class
											CombinedClassCount<-CombinedClassCount[CombinedClassCount$ClassSize>1,]
										#Checking how many ID's are left after merging them with CLASS's ==> N
											foundg<-as.data.frame(with(TopHitsClass[!duplicated(TopHitsClass), ],table(ID)))									
									
									
									# d. Preparing variables for HypGeomDist

										k <- CombinedClassCount$Hits
										m <- CombinedClassCount$ClassSize
										n <- nrow(CombinedClassCount)
										N <- nrow(foundg)

										if ( (k!=0) && (m!=0) && (n!=0) ) {
											pvalues <- HypGeomDist(k,m,n,N)
										
											adj_pvalues<-p.adjust(pvalues,method="BH",length(k))
											result_table<-cbind(CombinedClassCount,pvalues,adj_pvalues)
											result_table<-merge(result_table, Annotation, by="CLASS_ID")
											result_table<-result_table[order(result_table$pvalues),]
											result_table<-result_table[result_table$adj_pvalues<=0.05,]
											result_table<-format(result_table, digits=2, nsmall=2)
											x <- result_table
										}	
										
								}	
				})
	names(results) <- classes
	names(results)

# 3. Add colors and export table for each class
	result_tables <- NULL
	result_tables <- lapply(names(results), function(x) {
										if (is.not.null(results[[x]])) {
											result_table <- unique(as.data.frame(results[x]))
											colnames(result_table) <- colnames(results[[1]])
											result_table$class <- x
											result_table$color <- as.character(class_colors[x])
											result_table$Ratio <- format( round(as.numeric(result_table$Hits) / as.numeric(result_table$ClassSize),2), nsmall=2 )
											result_table$minFDR <- -log(as.numeric(result_table$adj_pvalues)+1e-12, 10)
											result_table$log2ClassSize <- log(as.numeric(result_table$ClassSize), 2)
											if (nrow(result_table)>0) {
												filename = paste(user_prefix,'GSEA',x, cluster_id,'txt',sep='.')
												write.table(result_table, file=filename, sep="\t", row.names=F, quote=FALSE)
											}
										   result_table
										}

									})	
	
	names(result_tables) <- names(results)
	head(result_tables)

	# Only take the tophits after sorting on ratio
	my_tophits <- 3
	result_tables_tophits <- NULL
	result_tables_tophits <- lapply(names(result_tables), function(x) {
									# testing: x <- 'IPR'
									result <- as.data.frame(result_tables[[x]])
									head(result[order(as.numeric(result$Ratio),  decreasing = TRUE), ], my_tophits)
								})	
	names(result_tables_tophits) <- names(result_tables)
	#head(result_tables_tophits)



# 4. Combine and save results
	merged_table <- do.call("rbind", result_tables)
	merged_table$cluster_id <- cluster_id
	merged_table_tophits <- do.call("rbind", result_tables_tophits)

	#merged_table_tophits$cluster_id <- cluster_id
	# lower p-values then 1e-12 is always significant and for plotting purposes we add a plateau here 
	#merged_table$minFDR <- -log(as.numeric(merged_table$adj_pvalues)+1e-12, 10)
	#merged_table$log2ClassSize <- log(as.numeric(merged_table$ClassSize), 2)

	filename = paste(user_prefix,'GSEA_merged', cluster_id,'txt',sep='.')
	write.table(merged_table, file=filename, sep="\t", row.names=F, quote=FALSE)
	filename = paste(user_prefix,'GSEA_merged_tophits', cluster_id, 'txt',sep='.')
	write.table(merged_table_tophits, file=filename, sep="\t", row.names=F, quote=FALSE)



	


