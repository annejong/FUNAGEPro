# -*- coding: utf-8 -*-
"""
Created on Wed Jun 12 14:33:18 2019
@author:Anne de Jong

Simple script to make KEGG description file
"""
import pandas as pd
import argparse 
import re

parser = argparse.ArgumentParser(description='GSEA-Pro')
parser.add_argument('-sessiondir', dest='sessiondir', help='Session Dir', nargs='?', default='.')
parser.add_argument('-query', dest='query', help='uniprot_sprot KEGG PATHWAY', nargs='?', default='uniprot_sprot.KEGGPATHWAY')
parser.add_argument('-out',dest='outFile', help='Output file name', nargs='?', default='KEGGPATHWAY.description')
parser.add_argument('--version', action='version', version='Anne de Jong, version 2.0, Jan 2021')
args = parser.parse_args()

# args.sessiondir = 'G:/My Drive/WERK/Python/FACoP'

#  load the KEGG pathways
kegg = pd.read_csv(args.sessiondir+'/'+args.query, comment='#',sep='\t')

result= pd.DataFrame()
serie = {}
for index, row in kegg[['KEGGPATHWAY']].copy().drop_duplicates().iterrows():
	match = re.search('PATH:(.*)\]', row.KEGGPATHWAY)
	if match:
		serie['key'] =  row.KEGGPATHWAY
		serie['description'] = match.group(1)	
		result = result.append(pd.Series(serie),ignore_index=True)

result.sort_values(by=['key']).to_csv(args.sessiondir+'/'+args.outFile, index = False, sep ='\t', columns=['key','description'])

				   

