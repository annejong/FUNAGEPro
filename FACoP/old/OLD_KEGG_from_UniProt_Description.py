# -*- coding: utf-8 -*-
"""
Created on Thu Mar 11 14:14:04 2021

@author: Anne
"""
import sys
import re
import argparse
import pandas as pd


# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='Promoter Prediction')
parser.add_argument('-sessiondir', dest='sessiondir', help='Session Dir', nargs='?', default='.')
parser.add_argument('-keggTable', dest='kegg', help='ko00001.keg file', nargs='?', default='ko00001.keg.table' )
parser.add_argument('-UniProtDescription', dest='uniprot', help='ko00001.keg file', nargs='?', default='uniprot_sprot.description' )
parser.add_argument('-out',dest='outFile', help='Output file name', nargs='?', default='uniprot.KEGGPATHWAY')
parser.add_argument('--version', action='version', version='Anne de Jong, version 2.0, Jan 2021')
args = parser.parse_args()


#args.sessiondir = 'G:/My Drive/WERK/Python/FACoP'


uniprot_header = ["long","short", "product", "gene"]
uniprot = pd.read_csv(args.sessiondir+'/'+args.uniprot, comment='#',header=None, sep='\t', names=uniprot_header)
kegg = pd.read_csv(args.sessiondir+'/'+args.kegg, comment='#', sep='\t')
kegg=kegg.dropna()

pathways=pd.DataFrame()
row = {}

for index, UniProtRow in uniprot.dropna().iterrows():
	keggRows = kegg.loc[kegg['gene'].str.contains(UniProtRow['gene'], case=True)]
	if not keggRows.empty: 
		row['long'] = UniProtRow.long
		row['short'] = UniProtRow.short
		row['product'] = UniProtRow['product']
		row['KEGGPATH'] = keggRows.iloc[0].C
		#print(UniProtRow['long'] + ' ' + keggRow.iloc[0].C)
		pathways.append(pd.Series(row),ignore_index=True)
	
	
pathways.to_csv(args.sessiondir+'/'+args.outFile, index = False, sep ='\t')

