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
parser.add_argument('-query', dest='query', help='eggNOG_COG.annotations.tsv file', nargs='?', default='eggNOG_COG.annotations.tsv')
parser.add_argument('-release',dest='release', help='The release ID of ENOG. e.g. ENOG50', nargs='?', default='ENOG50')
parser.add_argument('--version', action='version', version='Anne de Jong, version 2.0, Jan 2021')
args = parser.parse_args()

# args.sessiondir = 'G:/My Drive/WERK/Python/FACoP'
# args.release = 'ENOG50'

#  load the eggNOG COG annotation
colnames=['nr','key','COG','description']
eggnog = pd.read_csv(args.sessiondir+'/'+args.query, comment='#',sep='\t',header=None, names=colnames)
eggnog = eggnog.fillna('unkown')

cog = eggnog.loc[lambda x: x['key'].str.contains(r'COG*', regex = True)]
cog.sort_values(by=['key']).to_csv(args.sessiondir+'/eggNOG_COG.description', index = False, sep ='\t', columns=['key','description', 'COG'])

# remove the COG records by inverting the selection
enog = eggnog.loc[lambda x: x['key'].str.contains(r'COG*', regex = True)==False]
enog['key'] = enog['key'].apply(lambda x: args.release+x)
enog.sort_values(by=['key']).to_csv(args.sessiondir+'/ENOG.description', index = False, sep ='\t', columns=['key','description','COG'])

