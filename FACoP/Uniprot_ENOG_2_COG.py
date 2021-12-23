# -*- coding: utf-8 -*-
"""
Created on Wed May 29 15:39:18 2019

@author: Anne
"""

# ==> uniprot.ENOG + bactCOG.description ==> uniprot.COG

import sys
import pandas as pd
import argparse 

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-ENOG', dest='ENOG', help='uniprot_sprot.ENOG file')
parser.add_argument('-bactCOG', dest='bactCOG', help='bactCOG description file', nargs='?', default='./bactCOG.description')
parser.add_argument('-out', dest='outfile', help='uniprot.COG Output filename', nargs='?', default='./uniprot.COG')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, June 2019')
args = parser.parse_args()
print('uniprot ENOG        ='+args.ENOG)
print('bactCOG description ='+args.bactCOG)
print('Outfile             ='+args.outfile)

# python3 Uniprot_ENOG_2_COG.py -ENOG /data/gsea_pro/databases/uniprot_sprot.ENOG -bactCOG /data/gsea_pro/databases/bactCOG.description -out /data/gsea_pro/databases/niprot_sprot.COG


# ---------------------------------------------------------------- main -------------------------------------------------------------------------------------------

# 1. Read the uniprot ENOG file
ENOG = pd.read_csv(args.ENOG,sep='\t',header=None, names=["longName", "shortName","description","ENOG"])
	
# 2. Read the bactCOG  
COG = pd.read_csv(args.bactCOG,sep='\t',header=None, dtype='str', names=["ENOG","COG"])

# 3. Merge the tables and save it
cols=['longName','shortName','description','COG','ENOG']  # select and re-order columns for export
UniprotCOG = pd.merge(ENOG, COG,  how='inner', on='ENOG')[cols]

cols=['longName','shortName','description','COG']  # select and re-order columns for export

UniprotCOG[cols].sort_values(by='longName').to_csv(args.outfile, sep='\t', index=False)	


