# -*- coding: utf-8 -*-
"""
Created on Wed May 29 15:39:18 2019

@author: Anne
"""

# module load Python/3.5.1-foss-2016a
# python3 /data/p127804/GSEApro/classify_genome.py -genome /data/p127804/GSEApro/genomes/ASM1000v1_genomic.g2d.diamond.tab

import sys
import pandas as pd
import argparse 

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-diamond', dest='diamond', help='Diamond tab results')
parser.add_argument('-db', dest='db', help='Database filename', nargs='?', default='/data/pg-molgen/databases/uniprot_sprot/uniprot_sprot.GO')
parser.add_argument('-class', dest='class_description', help='Class Annotation', nargs='?', default='/data/pg-molgen/databases/uniprot_sprot/go-basic.obo.table')
parser.add_argument('-out', dest='outfile', help='Output filename', nargs='?', default='./')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, June 2019')
args = parser.parse_args()
print('Outfile  ='+args.outfile)

"""
# For local testing



args.diamond = 'G:/My Drive/WERK/Python/FACoP/ASM38552v1_genomic.g2d.diamond.tab'
args.db =      'G:/My Drive/WERK/Python/FACoP/uniprot_sprot.GO'
args.class_description =      'G:/My Drive/WERK/Python/FACoP/go-basic.obo.description'


"""

# ---------------------------------------------------------------- main -------------------------------------------------------------------------------------------

#OLD: # 1. Read the genome file
#OLD: blastColumns=['locus-tag', 'sp','shortName', 'longName','% match','alnLength','mismatches','gaps','QueryStart','QueryEnd','UniprotStart','UniprotEnd','Evalue','Score']
#OLD: genome = pd.read_csv(args.diamond, sep='\t|\|',header=None, index_col=False, engine='python',  names=blastColumns)


# 1. Read Diamond results
blastColumns=['locus-tag', 'UniProt' ,'% match','alnLength','mismatches','gaps','QueryStart','QueryEnd','UniprotStart','UniprotEnd','Evalue','Score']
diamond = pd.read_csv(args.diamond,sep="\t",header=None,  index_col=False, engine='python', names=blastColumns)
# remove sp| from the UniProt if this is still present in the UniProt Name
diamond['UniProt'] = diamond['UniProt'].map(lambda x: x.replace('sp|', ''))
# split UniProt in Long and short Name
diamond[['shortName','longName']] = diamond.UniProt.str.split("|",expand=True,)



	
# 2. Read the uniprot class annotation 
db = pd.read_csv(args.db,sep='\t',header=None, dtype='str', names=["longName","shortName", "description", "classes"])

# 3. Merge the genome with uniprot class annotation
df = pd.merge(diamond, db,  how='inner', on='longName')[['locus-tag','longName','classes','description']]
	
# 4. Read the CLASS annotaton (key=str is used to force KEGG pathway numbers to be handled as string
class_description = pd.read_csv(args.class_description,sep='\t', dtype={'key':str})
class_description.set_index('key', inplace=True)
#class_description.head()


# 5. Convert to GSEApro format
dict = {}  # use this to improve speed; pandas append is very slow
i=0
for index, row in df.iterrows():
	for CLASS in row['classes'].split(';'):
		try:
			dict[i] = {'locus-tag': row['locus-tag'], 'class': CLASS, 'description': class_description.loc[CLASS]['description']}
			i+=1
			pass
		except KeyError:
			pass


result = pd.DataFrame.from_dict(dict, "index")

cols=['locus-tag','class','description']  # select and re-order columns for export
result[cols].sort_values(by='locus-tag').to_csv(args.outfile, sep='\t', index=False)	


