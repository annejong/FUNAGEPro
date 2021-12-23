# simple routine to grep the KEGG organism website and make a table of kegg orgIDs and genbankIDs


import os
import sys
import re
sys.path.append('/data/molgentools/lib/')
import anne_files



# 1. Get the KEGG organism list from the KEGG website
os.system('wget http://www.genome.jp/kegg/catalog/org_list.html -O '+ org_list.html')
html = anne_files.read_lines('/org_list.html')

# 2. Parse the html table
lines = []
kegg = ''
name = ''
prokaryotes = False
for line in html:
	if re.search('Prokaryotes', line) : prokaryotes = True
	if prokaryotes:
		match = re.search('show_organism\?org.*>(.*)<\/a>', line) 
		if match: kegg = match.group(1)
		match = re.search('dbget-bin.*>(.*)<\/a>', line) 
		if match: name = match.group(1)
		match = re.search('ftp\:.*all\/(.*)\'>', line) 
		if match: 
			genbank = match.group(1)
			str = genbank[16:] + "\t" + genbank + "\t" + kegg + "\t" + genbank[:15] + "\t" + name
			lines.append(str)
			print str
			kegg = ''  # reset kegg
			name = ''

anne_files.write_lines('/data/gsea_pro/KEGG_organism.table' ,lines)	
