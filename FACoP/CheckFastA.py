# -*- coding: utf-8 -*-
"""
Created on Wed May 29 15:39:18 2019

@author: Anne
"""

import re
from numpy import loadtxt
import argparse 

parser = argparse.ArgumentParser(description='FACoP FastA check')
parser.add_argument('-i',    dest='query',  help='full path Filename ')
parser.add_argument('--version', action='version', version='version 1.0')
args = parser.parse_args()



def read_fasta(filename):
    results = {}
    lines = open(filename, "r").read().split('\n')
    key=''
    for line in lines:
        if re.search("^>", line):
            if key != '': results[key] = seq
            my_list = re.match("^>(.*)", line)
            key = my_list.group(1)
            seq=''
        else:
           seq += line
    if key != '': results[key] = seq  # add the last record
    return results

fasta = read_fasta(args.query)

regex = re.compile('[^a-zA-Z]')  # allow only alphabet in sequences

# write the clean sequences
f = open(args.query, "w")
for key in fasta:
    f.write('>'+key+'\n')
    f.write(regex.sub('', fasta[key])+'\n')
f.close()    


