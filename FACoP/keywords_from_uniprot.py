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
import re

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-i', dest='uniprotfile', help='Genome filename')
parser.add_argument('-out', dest='outfile', help='Output filename', nargs='?', default='./')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, June 2019')
args = parser.parse_args()
print('uniprotfile ='+args.uniprotfile)
print('outfile     ='+args.outfile)



# ---------------------------------------------------------------- main -------------------------------------------------------------------------------------------
keydict = {}
with open(args.uniprotfile) as lines:
	for line in	lines:
		if re.search("^KW", line):
			items = line[5:].replace('.',';').split(';')
			for item in map(str.lstrip, items):  # remove leading spaces of all items
				keydict[item] = 'keyword'  



# write file in the GSEApro format
with open(args.outfile, 'w') as f:
	f.write('key\tdescription\n')
	for key in sorted (keydict): 
		if key != "": f.write(key+'\tkeyword\n')	
f.close()
