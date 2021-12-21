#!/bin/bash

########################################################################################
# script name: daemon_textmining.sh
# path on oxygen: /data/databases/scripts/prego_daemons
# developed by: Savvas Paragkamian
# framework: PREGO - WP1
########################################################################################
# GOAL:
# This script is intented to run every month with a cron job in order to update the
# textmining module to include the updated PubMed MEDLINE
########################################################################################

echo "The textmining daemon has started"
echo `date`

time_start=`date +%s`

# Get the date of the update and directories with scripts and data
version=$(date +'%Y_%m_%d')
pubmed_update_script_directory='/data/databases/scripts/gathering_data/pubmed'
textmining_data_directory='/data/textmining/'


echo "update PubMed"
# Update Pubmed articles (weekly). duration=5 minutes
cd $pubmed_update_script_directory
./pubmed.csh &> pubmed.log

echo `date`
# Textmining update after the Pubmed update. duration=510 minutes (8.5 hours)

# Build a .tar.gz file with the previous textmining data and archive it. disk space=~200 gb
echo "create tarball"
cd $textmining_data_directory

tar cvzf textmining_data_$version.tar.gz database_pairs.tsv database_documents.tsv database_mentions.tsv database_segments.tsv database_matches.tsv database_counts.tsv

# Move the archive to /data/archives. Archive these as well even though these are relations and not raw data? 
# todo - The best solution would be to archive the postgres database textmining. 

mv textmining_data_$version.tar.gz /data/archives
echo `date`

# Run tagger for the updated Pubmed. Configuration is 8 threads which uses 6gb ram and it takes 150 minutes to run. 
echo "run tagger"
./update.csh

echo `date`
echo "run perl scripts"
# todo - Maybe add the following lines inside the update.csh script.
# Run perl scripts to find relations and counts in the specific order presented below. duration=211 minutes (3 hours and 31 minutes)
./create_segments.pl # duration=6 minutes, ram=4gb
./create_pairs.pl # duration=5 minutes, ram=4gb
./create_documents.pl # duration=9 minutes, ram=6gb
./create_matches.pl # duration=76 minutes, ram=6gb
./create_counts.pl # duration=50 minutes, ram=6gb
./create_mentions.pl # duration=65 minutes, ram=6gb

# Update postgres with the create_database.sql script
# as of 2020/07/03 only user pafilis is allowed to run the script in order for the mamba platform to be updated. Duration is 160 minutes (2 hours and 40 minutes)
#
#psql -d textmining -f create_database.sql # run as pafilis

time_end=`date +%s`
echo "finished"
echo `date`
echo "textmining daemon was running for $((time_end-time_start)) seconds."
