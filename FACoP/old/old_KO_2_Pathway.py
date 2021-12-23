# -*- coding: utf-8 -*-
"""
Created on Wed Jun 12 14:33:18 2019

@author: p127804
"""

# download the https://www.genome.jp/kegg-bin/get_htext?ko00001
# expand all
# save as text file
# run this script

import sys
import pandas as pd
import argparse 
import re

#args.KOfile="G:\My Drive\WERK\GSEA_Pro/KEGG_Orthology_KO.txt"
#args.outdir = "G:\My Drive\WERK\GSEA_Pro"


parser = argparse.ArgumentParser(description='GSEApro databases')
parser.add_argument('-i', dest='KOfile',  help='KEGG Orthology (KO) filename')
parser.add_argument('-outdir', dest='outdir', help='result folder', nargs='?', default='.\descriptions.KO')
parser.add_argument('--version', action='version', version='version 1.0')
args = parser.parse_args()



lines = open(args.KOfile, "r")
dict = {}  # use this to improve speed; pandas append is very slow
kegg_pathways = {}
i=0
j=0
current_pathway='Metabolism'
for line in lines:
	# the pathways
	if re.search("\[PATH\:", line):
		items = re.match('\s+(\d+)\s+(.*)\[PATH\:(.*)]', line)
		if items:
			kegg_pathways[j] = {'key': items.group(1),'description': items.group(2) }
			current_pathway = items.group(2)
			j +=1
	# the KO id's
	if re.search("\s+K", line):
		items = re.match("\s+(K\d+)\s+(.*);\s+(.*)", line)
		if items:
			dict[i] = {'key': items.group(1),'Name': items.group(2),'description': items.group(3), 'pathway': current_pathway }
			i +=1



result = pd.DataFrame.from_dict(dict, "index")
result = result.drop_duplicates(subset='key')

result_short = pd.DataFrame()
result_short["key"]=result["key"]
result_short["description"] = result["Name"] + ';' + result["description"]
result_short["pathway"] = result["pathway"]
result_short.sort_values(by='key').to_csv(args.outdir+"/KEGG_Orthology_KO.description", sep='\t', index=False)	
 
kegg_pathway = pd.DataFrame.from_dict(kegg_pathways, "index")
kegg_pathway.sort_values(by='key').to_csv(args.outdir+"/KEGG_pathway.description", sep='\t', index=False)	



