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
parser.add_argument('-i',    dest='KOfile',  help='KEGG Orthology (KO) filename. This is the file downloaded as plain text file from KEGG ortholgy database: https://www.genome.jp/kegg-bin/get_htext?ko00001 ')
parser.add_argument('-KO',   dest='outKO',   help='Output filename of KEGG Orthology KO descriptions', nargs='?', default='.\KEGG_Orthology_KO.description')
parser.add_argument('-PATH', dest='outPATH', help='Output filename of KEGG KO PATHWAY descriptions',   nargs='?', default='.\KEGG_Orthology_PATHWAY.description')
parser.add_argument('-KOPATH', dest='outKOPATH', help='Output filename of KO to PATHWAY descriptions', nargs='?', default='.\KEGG_Orthology_KO2PATH.description')
parser.add_argument('--version', action='version', version='version 1.0')
args = parser.parse_args()



lines = open(args.KOfile, "r")
dict = {}  # use this to improve speed; pandas append is very slow
kegg_pathways = {}
i=0
j=0
current_pathwayID='09100'
current_pathway='Metabolism'
for line in lines:
	# the pathways
	if re.search("\[PATH\:", line):
		items = re.match('[A|B|C|D]\s+(\d+)\s+(.*)\[PATH\:(.*)]', line)
		if items:
			kegg_pathways[j] = {'key': items.group(1),'description': items.group(2) }
			current_pathwayID = items.group(1)
			current_pathway = items.group(2)
			j +=1
	# the Brite Hierarchies
	if re.search("\[BR\:", line):
		items = re.match('[A|B|C|D]\s+(\d+)\s+(.*)\[BR\:(.*)]', line)
		if items:
			kegg_pathways[j] = {'key': items.group(1),'description': items.group(2) }
			current_pathwayID = items.group(1)
			current_pathway = items.group(2)
			j +=1
	# the KO id's
	if re.search("\s+K", line):
		items = re.match("[A|B|C|D]\s+(K\d+)\s+(.*);\s+(.*)", line)
		if items:
			dict[i] = {'key': items.group(1),'Name': items.group(2),'description': items.group(3), 'pathway': current_pathway, 'pathwayID': current_pathwayID }
			i +=1
			



result = pd.DataFrame.from_dict(dict, "index")
result = result.drop_duplicates(subset='key')

KO = pd.DataFrame()
KO["key"]=result["key"]
KO["description"] = result["Name"] + ';' + result["description"]
KO["pathway"] = result["pathway"]
cols=["key","pathway","description"]
KO[cols].sort_values(by='key').to_csv(args.outKO, sep='\t', index=False)	
 
KO2PATH = pd.DataFrame()
KO2PATH["key"]=result["key"]
KO2PATH["pathway"] = result["pathwayID"]
KO2PATH["description"] = result["pathway"]
cols=["key","pathway","description"]
KO2PATH[cols].sort_values(by='key').to_csv(args.outKOPATH, sep='\t', index=False)	
 
kegg_pathway = pd.DataFrame.from_dict(kegg_pathways, "index")
kegg_pathway.sort_values(by='key').to_csv(args.outPATH, sep='\t', index=False)	



