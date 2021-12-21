#!/bin/bash

########################################################################################
# script name: daemon_for_gos_kos_via_uniref50.sh
# developed by: Haris Zafeiropoulos
# framework: PREGO - WP2
########################################################################################
# GOAL:
# This script is intented to run every 12 weeks with a cron job 
# to get the latest version of Uniprot  
########################################################################################


cd /data/databases/kegg_orthology

wget https://ftp.uniprot.org/pub/databases/uniprot/knowledgebase/idmapping/idmapping_selected.tab.gz 

gunzip idmapping_selected*

grep "GO:" idmapping_selected.tab | awk -F "\t" '{print $10"\t"$7}' > uniref50_GOs.tsv

sed -i 's/UniRef50_//g' uniref50_GOs.tsv 

./parse_idmap.py

awk -F "\t" '{print $1"\t"$2}' GOs_KOs_via_Uniref50.tsv | sort | uniq | sort > GOs_KOs_via_Uniref50_pairs.tsv 
