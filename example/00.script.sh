123
gunzip GSM2870806_A_163.txt.gz
gunzip GSM2870807_A_168.txt.gz
gunzip GSM2870808_A_173.txt.gz
gunzip GSM2870809_B_164.txt.gz
gunzip GSM2870810_B_169.txt.gz
gunzip GSM2870811_B_174.txt.gz
gunzip GSM2870812_C_165.txt.gz
gunzip GSM2870813_C_170.txt.gz
gunzip GSM2870814_C_175.txt.gz
gunzip GSM2870815_D_166.txt.gz
gunzip GSM2870816_D_171.txt.gz
gunzip GSM2870817_D_176.txt.gz
gunzip GSM2870818_E_167.txt.gz
gunzip GSM2870819_E_172.txt.gz
gunzip GSM2870820_E_177.txt.gz

/data/molgentools/tables/merge_tables.pl -tables ./ -regex 'txt$' -colomns '0,1' -o 00.merged 


https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE107538

Selected: Vibrio cholerae O1 biovar El Tor str N16961 ASM674v1 genomic
