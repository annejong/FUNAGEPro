# -*- coding: utf-8 -*-
"""
Created on Thu Mar 11 11:25:46 2021

@author: Anne
"""
import sys
import re
import argparse
import pandas as pd


# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='Promoter Prediction')
parser.add_argument('-sessiondir', dest='sessiondir', help='Session Dir', nargs='?', default='.')
parser.add_argument('-kegg', dest='kegg', help='ko00001.keg file', nargs='?', default='ko00001.keg' )
parser.add_argument('-out',dest='outFile', help='Output file name', nargs='?', default='ko00001.keg.table')
parser.add_argument('--version', action='version', version='Anne de Jong, version 2.0, Jan 2021')
args = parser.parse_args()


#args.sessiondir = 'G:/My Drive/WERK/Python/FACoP'

df_kegg=pd.DataFrame()
with open(args.sessiondir+'/'+args.kegg) as f:
	row = {}
	for line in f:
		line = line.rstrip()
		if re.search(r'^A', line): row['A'] = line[1:]
		if re.search(r'^B', line): row['B'] = line[3:]
		if re.search(r'^C', line): row['C'] = line[5:]
		if re.search(r'^D', line):
			match = re.search(r'(^D)\s+(.{6})\s+(.*); (.*)',line)
			if match:
				row['KO'] = match.group(2)			
				row['gene'] = match.group(3)			
				row['enzyme'] =match. group(4)			
				df_kegg = df_kegg.append(pd.Series(row),ignore_index=True)
			
df_kegg.to_csv(args.sessiondir+'/'+args.outFile, index = False, sep ='\t')

