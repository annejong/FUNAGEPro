# Gene Set Enrichment Analysis for Prokaryotes
# GSEA_Pro
#
# Anne de Jong
# University of Groningen
# 
# Januari 2017, Benchmark GSEA


# --------------------------------------------------------------------- parameters ---------------------------------------------------------------

# load parameters from command line or call from the webserver
	sessiondir <- commandArgs()[5]
	gene_list <- commandArgs()[6]
	genome  <- commandArgs()[7]
	experiment <- commandArgs()[8]



# for local use: 
#
#	sessiondir  = "E:\\Google Drive\\WERK\\GSEA_Pro"
#	sessiondir  = "C:\\Users\\Anne\\Google Drive\\WERK\\GSEA_Pro"
#	gene_list  = "genelist.txt"
#	genome <- 'ASM904v1_genomic.g2d'
#	experiment <- 'A_F71Y-WT'
#	maxTopHits <- 200	
	
maxTopHits <- 200
noiseValue <- 1.1	
	
# this can be change to e.g. IPR, GO, KEGG 	
benchmark_class <- 'IPR'

setwd(sessiondir)

# ------------------------------------------------------- functions ----------------------------------------------------------------------------
	
is.not.null <- function(x) ! is.null(x)
	
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


load_class_data <- function(Class) {
	# Read the classes Class data from files
	# for testing:  Class<- 'GO'
	filename = paste(genome,Class,sep='.')
	if (file.exists(filename)) {
		CLASS_table<-read.table(filename, sep = "\t", quote = "", blank.lines.skip = TRUE, header=FALSE)
		colnames(CLASS_table) <- c("ID","CLASS_ID","Description")
	} 		
	return(CLASS_table)
}


Test_Class <- function(GeneSubList, CLASS_table) {
	# for testing:  GeneSubList<- my_gene_subset
	TopHitsClass<-merge(CLASS_table, GeneSubList, by="ID")
	
	# b. Get frequencies	
	# Frequencies of CLASS members in GeneSubList ==> k
		ClassFrequency_TopHits<-as.data.frame(with(TopHitsClass[!duplicated(TopHitsClass), ], table(CLASS_ID)))
	# Frequencies of CLASS members ==> m
		ClassFrequency<-as.data.frame(with(CLASS_table[!duplicated(CLASS_table), ], table(CLASS_ID)))
	# Combine the Frequency tables
		CombinedClassCount<-cbind(ClassFrequency_TopHits,ClassFrequency$Freq)
		colnames(CombinedClassCount)=c("CLASS_ID","Hits","ClassSize")
	# remove Class members that are not present or only 1x in GeneSubList
		CombinedClassCount<-CombinedClassCount[CombinedClassCount$Hits>1,]
	# remove Class members that only occur 1x in the total class
		CombinedClassCount<-CombinedClassCount[CombinedClassCount$ClassSize>1,]
	#Checking how many ID's are left after merging them with CLASS's ==> N
		foundg<-as.data.frame(with(TopHitsClass[!duplicated(TopHitsClass), ],table(ID)))									
	
	
	# c. Preparing variables for the formula to calculate pvalues

	k <- CombinedClassCount$Hits
	m <- CombinedClassCount$ClassSize
	n <- nrow(CombinedClassCount)
	N <- nrow(foundg)
	sum_of_pvalues <- 1
	adj_pvalues = 1 ;
	if ( (k!=0) && (m!=0) && (n!=0) ) {
		pvalues <- HypGeomDist(k,m,n,N)
		adj_pvalues <- p.adjust(pvalues,method="BH",length(k))
	}	
	return(sum(adj_pvalues < 0.01))
}



	
# -------------------------------------------------------------- main --------------------------------------------------------------------------------
	
# 1. Read gene list
	GeneList<-read.table(gene_list, sep = "\t", quote = "", blank.lines.skip = TRUE, header=TRUE)
	colnames(GeneList) <- c("ID", "Value")
	
	GenesUp <- GeneList[order(GeneList$Value, decreasing = TRUE),]
	GenesUp <- GenesUp[ which(GenesUp$Value > noiseValue),]
	if (nrow(GenesUp) > maxTopHits) { GenesUp <- GenesUp[1:maxTopHits,] }

	GenesDown <- GeneList[order(GeneList$Value, decreasing = FALSE),]
	GenesDown <- GenesDown[ which(GenesDown$Value < -noiseValue),]
	if (nrow(GenesDown) > maxTopHits) { GenesDown <- GenesDown[1:maxTopHits,] }

	#head(GenesUp)
	#head(GenesDown)

# 2. Load the Class data from genome classification file	
	CLASS_table <- load_class_data(benchmark_class)
	#head(CLASS_table)
	

# 3. Test the class for max score
	results <- NULL
	# UP
		my_list <- seq(3, nrow(GenesUp),2)  # Start with minimum of 3 genes until all genes, with step 2
		my_scores <- lapply(my_list, function(y) {
			#y <- 149
			my_gene_subset  <- lapply(as.data.frame(GenesUp$ID), function(x) {x[seq(1,y,1)]})
			names(my_gene_subset) = "ID"
			x <- Test_Class(my_gene_subset, CLASS_table ) / (7+y)
		})
		my_scores_table <- as.data.frame(unlist(my_list))
		my_scores_table$scores = unlist(my_scores)
		colnames(my_scores_table) <- c("cutoff", "scores")
		GenesUp$cutoff <- seq_len(nrow(GenesUp))  # add the rownumber as cutoff column to be able to merge the results
		my_scores_table <- merge(my_scores_table, GenesUp, by = "cutoff", , incomparables = NA)
		filename = paste('00.Scores_up',experiment,'txt',sep='.')
		write.table(my_scores_table, file=filename, sep="\t", row.names=F, col.names=TRUE, quote=FALSE)	
		
		my_max <- my_scores_table[my_scores_table$score==max(my_scores_table$score),]  # get the row with max score
		my_max <- my_max[my_max$Value==max(my_max$Value),]  # get the row with highest Value
		results$UP.max <- my_max$score
		results$UP.max_index <- my_max$cutoff 
		results$UP.cutoff <- round(my_max$Value, digits=2)
		
		my_scores_table_up_down <- my_scores_table
	# DOWN
		my_list <- seq(3, nrow(GenesDown),2)  # Start with minimum of 3 genes until all genes, with step 2
		my_scores <- lapply(my_list, function(y) {
			#y <- 149
			my_gene_subset  <- lapply(as.data.frame(GenesDown$ID), function(x) {x[seq(1,y,1)]})
			names(my_gene_subset) = "ID"
			x <- Test_Class(my_gene_subset, CLASS_table )  / (7+y)
		})
		my_scores_table <- as.data.frame(unlist(my_list))
		my_scores_table$scores = unlist(my_scores)
		colnames(my_scores_table) <- c("cutoff", "scores")
		GenesDown$cutoff <- as.numeric(seq(nrow(GenesDown),1,-1))  # add the rownumber as cutoff column to be able to merge the results
		GenesDown$cutoff <- 1+ abs(GenesDown$cutoff - max(GenesDown$cutoff))  # reverse order of numbers
		my_scores_table <- merge(my_scores_table, GenesDown, by = "cutoff", , incomparables = NA)
		filename = paste('00.Scores_down',experiment,'txt',sep='.')
		write.table(my_scores_table, file=filename, sep="\t", row.names=F, col.names=TRUE, quote=FALSE)	

		my_max <- my_scores_table[my_scores_table$score==max(my_scores_table$score),]  # get the row with max score
		my_max <- my_max[my_max$Value==min(my_max$Value),]  # get the row with highest Value
		
		results$DOWN.max <- my_max$score
		results$DOWN.max_index <- my_max$cutoff 
		results$DOWN.cutoff <- round(my_max$Value, digits=2)
	
		# Merge and sort UP and DOWN and write table
		my_scores_table_up_down <- rbind(my_scores_table_up_down, my_scores_table) 
		my_scores_table_up_down <- my_scores_table_up_down[order(my_scores_table_up_down$Value, decreasing = TRUE),]
		#my_scores_table_up_down$row <- 1:nrow(my_scores_table_up_down)
		my_scores_table_up_down$cutoff <- 1:nrow(my_scores_table_up_down)
		# head(my_scores_table_up_down)
		filename = paste('00.Scores_up_down',experiment,'txt',sep='.')
		write.table(my_scores_table_up_down, file=filename, sep="\t", row.names=F, col.names=TRUE, quote=FALSE)	
	
# 4. Write the results
	results

	filename = paste('00.GSEA_benchmark',experiment,'txt',sep='.')
	write.table(t(as.data.frame(results)), file=filename, sep="\t", row.names=T, col.names=FALSE, quote=FALSE)
	write.table(t(as.data.frame(results)), file='00.GSEA_benchmark.txt', sep="\t", row.names=T, col.names=FALSE, quote=FALSE)
	