# -*- coding: utf-8 -*-
"""
Created on Wed May 29 15:39:18 2019

@author: Anne
"""


import sys
import pandas as pd
import argparse 

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-diamond', dest='diamond', help='Diamond tab results')
parser.add_argument('-db', dest='db', help='Uniprot description file', nargs='?', default='./uniprot_sprot.description')
parser.add_argument('-out', dest='outfile', help='Annotated genome', nargs='?', default='./query.description')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, July 2019')
args = parser.parse_args()
print('Diamond result file ='+args.diamond)
print('Uniprot description ='+args.db)
print('Outfile             ='+args.outfile)

# python3 $PROGAMDIR/diamond_format_results.py -diamond query.diamond.tab -db /data/gsea_pro/databases/uniprot_sprot.description 

'''
For local testing

args.diamond = 'G:/My Drive/WERK/Python/FACoP/ASM904v1_genomic.g2d.diamond.tab.sp'
args.db =      'G:/My Drive/WERK/Python/FACoP/uniprot_sprot.description'

'''
# ---------------------------------------------------------------- main -------------------------------------------------------------------------------------------


blastColumns=['locus_tag', 'UniProt' ,'% match','alnLength','mismatches','gaps','QueryStart','QueryEnd','UniprotStart','UniprotEnd','Evalue','Score']

# 1. Read Diamond results
diamond = pd.read_csv(args.diamond,sep="\t",header=None,  index_col=False, engine='python', names=blastColumns)
# remove sp| from the UniProt if this is still present in the UniProt Name
diamond['UniProt'] = diamond['UniProt'].map(lambda x: x.replace('sp|', ''))
# split UniProt in Long and short Name
diamond[['shortName','longName']] = diamond.UniProt.str.split("|",expand=True,)

	
# 2. Read Uniprot description  
description = pd.read_csv(args.db,sep='\t',header=None, dtype='str', index_col=0, names=["longName","shortName",'product','gene'])

# 3. Merge the tables and save it
MergedTable = pd.merge(diamond, description, on='shortName', how='left')

# 4. select and re-order columns for export
cols=['locus_tag','shortName','longName','product','gene']  
MergedTable[cols].sort_values(by='locus_tag').to_csv(args.outfile, sep='\t', index=False)	


