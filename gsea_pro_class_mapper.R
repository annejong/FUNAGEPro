

# ------------------------------------------------------- parameters ----------------------------------------------------------------------------

sessiondir  = "E:\\Google Drive\\WERK\\GSEA_Pro\\dataset"
sessiondir  = "E:\\Google Drive\\WERK\\PROJECTS\\Andrea\\2017-07_Functional_Alignment"
filename_class_mapper_table = "gsea_pro_class_mapper.table.txt"
classes <- list('IPR','GO', 'Pfam', 'KEGG','SUPERFAMILY')
# all possible classes: classes <- list('IPR','GO', 'KEGG', 'Pfam', 'SUPERFAMILY', 'SMART', 'KEYWORDS', 'COG', 'operons')

# ------------------------------------------------------- functions ----------------------------------------------------------------------------



# ------------------------------------------------------- main ---------------------------------------------------------------------------------
	
setwd(sessiondir)


# 1. Read data files

	# Read the table of content
	# this is a tab delimited tabel with the header: ID	genome	name	datafile
	# ID = just an unique identifier
	# genome = the prefix for the annotation file: e.g. genome.GO
	# name = Name used for the result file
	# datafile = tab delimited file starting with the locus-tag and column(s) with values
	class_mapper_table <- read.table(filename_class_mapper_table, sep = "\t", quote = "", blank.lines.skip = TRUE, header=TRUE)
	head(class_mapper_table)

	filenames <- NULL
	# process all the expression files	
	for (tablerow in 1:nrow(class_mapper_table)) {
		print(class_mapper_table$genome[tablerow])
		print(as.character(class_mapper_table$datafile[tablerow]))
	
		DATA_table <- read.table(as.character(class_mapper_table$datafile[tablerow]), sep = "\t", quote = "", blank.lines.skip = TRUE, header=TRUE)
		colnames(DATA_table)[1] <- c("locus_tag")  # unify the header of the first column
		head(DATA_table)
			
		# Merge each class to the data set
		class_tables <- lapply(classes, function(classgroup) {
								# classgroup <- classes[2]  # example for testing
								filename = paste(class_mapper_table$genome[tablerow],classgroup,sep='.')
								CLASS_table<-read.table(filename, sep = "\t", quote = "", blank.lines.skip = TRUE, header=FALSE)
								colnames(CLASS_table) <- c("locus_tag","ID","Description")
								#head(CLASS_table)

							# 2. merge the data	
								MERGED_table <- merge(CLASS_table[, c("locus_tag", "ID", "Description")], DATA_table, by="locus_tag")
								MERGED_table <- MERGED_table[order(MERGED_table$ID),]
								CLASS_values <- MERGED_table[, !(colnames(MERGED_table) %in% c("locus_tag","Description"))] 
								aggregate( . ~ ID, CLASS_values, median)

							})	
			
		# 3. Save the class group tables
		i<-1
		list_of_files <- list()
		for (classgroup in classes){
			print(classgroup)
			#prt <- head(as.data.frame(class_tables[i]))
			#print(prt)
			filename = paste(class_mapper_table$name[tablerow],'-CLASS_',classgroup, '-MEAN.txt',sep='')
			list_of_files <- c(list_of_files, filename)
			write.table(as.data.frame(class_tables[i]),    file=filename, sep="\t", row.names=F, quote=FALSE)
			i<- i+1
		}
		filenames <- rbind(filenames, list_of_files)
				

	}
	
	# all generated files
	colnames(filenames) <- classes
	filenames 
	
	# Merge tables with off same class
	lapply(classes, function(classgroup) {
						MERGED_table <- NULL
						for (my_table in filenames[,classgroup]){
							one_table<-read.table(my_table, sep = "\t", quote = "", blank.lines.skip = TRUE, header=TRUE)
							colnames(one_table)[1] <- c("ID")
							head(one_table)
							if (is.null(MERGED_table)) {
								MERGED_table <- one_table 
							} else {
								MERGED_table <- merge(MERGED_table,one_table, by="ID", all=F)
							}	
						}	
						filename = paste('MERGED_',classgroup, '-MEAN.txt',sep='')
						write.table(as.data.frame(MERGED_table), file=filename, sep="\t", row.names=F, quote=FALSE)
	})					
		

