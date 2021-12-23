# -*- coding: utf-8 -*-
"""
Created Feb 05 2020

@author: Anne
"""

# module load Python/3.5.1-foss-2016a
# python3 /data/p127804/GSEApro/classify_genome.py -genome /data/p127804/GSEApro/genomes/ASM1000v1_genomic.g2d.diamond.tab

import sys
import pandas as pd
import argparse 
import re

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-i', dest='uniprotfile', help='Genome filename')
parser.add_argument('-out', dest='outfile', help='Output filename', nargs='?', default='./')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, June 2019')
args = parser.parse_args()
print('uniprotfile ='+args.uniprotfile)
print('outfile     ='+args.outfile)


# python3 proteinSeq_from_uniprot.py -i /data/gsea_pro/databases/uniprot_sprot.dat -out /data/gsea_pro/databases/uniprot_sprot.test

# ---------------------------------------------------------------- main -------------------------------------------------------------------------------------------
fasta = {}
key=''
checker=False
with open(args.uniprotfile) as lines:
    for line in	lines:
        if re.search("^//", line): checker=False
        if re.search("^ID", line):
            items = re.match("ID   (.*?)\s.*", line)
            if items: key= items.group(1)
        if re.search("^AC", line):
            items = re.match("AC   (.*?);", line)
            if items: key = items.group(1)+'|'+key
            fasta[key] = ''
        if checker: fasta[key] += line.replace(' ','')
        if re.search("^SQ", line): checker=True
        #if re.search("^//", line): print(key+"\t"+fasta[key])




# write as fasta
with open(args.outfile, 'w') as f:
	for key in sorted (fasta): 
		if (key != ''):
			items = key.split("|");  # some keys in UniProt contain multiple pipes, we take the 1st and last item
			newkey = items[0]+'|'+items[-1] ;
			f.write('>'+newkey+'\n'+fasta[key])	
f.close()

print('Numbers of records: '+str(len(fasta)))

  