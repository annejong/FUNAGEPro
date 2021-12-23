# -*- coding: utf-8 -*-
"""
Created on Wed May 29 15:39:18 2019

@author: Anne
"""

import sys
import argparse 

# ---------------------------------------------------------------- parse parameters -------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='GSEApro')
parser.add_argument('-query', dest='table', help='Input table without header')
parser.add_argument('--version', action='version', version='Anne de Jong, version 1.0, June 2019')
args = parser.parse_args()

lines = []
with open(args.table) as f:  lines = f.readlines()
with open(args.table, 'w') as f:
	f.write("key\tdescription\n")
	f.write("".join(lines))
f.close()
