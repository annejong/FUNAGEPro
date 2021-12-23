# -*- coding: utf-8 -*-
"""
Created on Wed Jun 12 14:33:18 2019

@author: p127804
"""


import sys
import pandas as pd
import argparse 
import re


parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-id', dest='id', help='ID to retrieve', nargs='?', default=r'.\uniprot_sprot.ID')
parser.add_argument('-uniprot', dest='uniprot', help='uniprot FastA file', nargs='?', default=r'.\uniprot_sprot.fasta')
parser.add_argument('-o', dest='outfile', help='Result file', nargs='?', default=r'uniprot_sprot_bact.fasta')
parser.add_argument('--version', action='version', version='version 1.0')
args = parser.parse_args()

#args.uniprotKO="G:\My Drive\WERK\GSEA_Pro/uniprot_sprot.KO"
#args.KOPATH = "G:\My Drive\WERK\GSEA_Pro/KEGG_Orthology_KO2PATH.description"
#args.outfile = "G:\My Drive\WERK\GSEA_Pro/uniprot_sprot.KEGGPATHWAY"

# python3 /data/gsea_pro/program/filter_fasta_for_prokaryotes.py -id /data/gsea_pro/databases/uniprot_sprot.ID -uniprot /data/gsea_pro/databases/uniprot_sprot.fasta > /data/gsea_pro/databases/uniprot_sprot_bact.fasta



def read_fasta(fasta):
	checker=False
	fasta = {}
	key= ''
	with open(args.uniprot) as f:
		for line in f:
			if re.search("^>", line):
				checker=False
				items = re.match(">sp\|.*\|(.*?)\s", line)
				if items:
					checker=True
					key=items.group(1)
					fasta[key] = line
			else:
				if checker: 
					fasta[key] = fasta[key]+line
	return fasta	



fasta = read_fasta(args.uniprot)

with open(args.id) as f:
	IDs = f.read().splitlines()
	for ID in IDs:
		print(fasta[ID])




def read_fasta(fasta):
	checker=False
	fasta = {}
	key= ''
	with open(args.uniprot) as f:
		for line in f:
			if checker: fasta[key] += line
			if re.search("^>", line):
				checker=False
				items = re.match(">sp\|.*\|(.*?)\s", line)
				if items:
					checker=True
					key=items.group(1)
	return fasta	

	