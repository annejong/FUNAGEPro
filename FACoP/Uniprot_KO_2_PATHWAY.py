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
parser.add_argument('-uniprotKO', dest='uniprotKO', help='Uniprot KO file', nargs='?', default=r'.\uniprot_sprot.KO')
parser.add_argument('-KOPATH', dest='KOPATH', help='KEGG_Orthology_KO2PATH.description desription file', nargs='?', default=r'.\KEGG_Orthology_KO2PATH.description')
parser.add_argument('-o', dest='outfile', help='Result file', nargs='?', default=r'.\uniprot_sprot.KEGGPATHWAY')
parser.add_argument('--version', action='version', version='version 1.0')
args = parser.parse_args()

#args.uniprotKO="G:\My Drive\WERK\GSEA_Pro/uniprot_sprot.KO"
#args.KOPATH = "G:\My Drive\WERK\GSEA_Pro/KEGG_Orthology_KO2PATH.description"
#args.outfile = "G:\My Drive\WERK\GSEA_Pro/uniprot_sprot.KEGGPATHWAY"

uniprotKO = pd.read_csv(args.uniprotKO,sep='\t',header=None, names=["long", "short", "descr", "key"])
KOPATH = pd.read_csv(args.KOPATH,sep='\t',header=0, dtype=str)

uniprotKO.head()
KOPATH.head()

result = pd.merge(uniprotKO, KOPATH[['key', 'pathway', 'description']], on='key')
cols=["long", "short","description",'pathway']
result[cols].head()
result[cols].sort_values(by='long').to_csv(args.outfile, sep='\t', index=False)	





