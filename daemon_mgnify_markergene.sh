#!/bin/bash

########################################################################################
# script name: daemon_mgnify_markergne.sh
# developed by: Haris Zafeiropoulos
# framework: PREGO - WP2
########################################################################################
# GOAL:
# This script is intented to run every 4 months with a cron job in order to update the
# experiments module to include the total marker gene studies of the MGnify resource
# updating the epxeriments database of the PREGO project
########################################################################################

# Start time of this robot
echo $date

# Get the date of the update 
version=$(date +'%Y_%m_%d')
mgnify_data_directory='/data/databases/mgnify/'
scripts_directory='/data/databases/scripts/gathering_data/mgnify/'

## PART A: The data part

# Build a .tar.gz file with the previous version of the MGnify marker gene data
cd $mgnify_data_directory
tar cvzf mgnify_marker_gene_data_$version.tar.gz marker_gene_data/

# Move the tarball to /data/archives
mv mgnify_marker_gene_data_$version.tar.gz /data/archives/mgnify

# Create a temporar backup with the previously downloads
mv marker_gene_data marker_gene_data_previous

# Create the new marker_gene_data directory along with its corresponding sub-directories and its related files
mkdir marker_gene_data
mkdir marker_gene_data/abundances
mkdir marker_gene_data/processes
mkdir marker_gene_data/samples
mkdir marker_gene_data/runs
touch marker_gene_data/temp_file_with_failed_urls.tsv

# Get the marker gene data from MGnify
cd $scripts_directory
./get_mgnify_markergene_data.py

# Check if everything ran Ok. If an error occurred, then exit the script (keeping the previous version of markergene data)
last_task_return_code=$?
if [ $last_task_return_code -ne 0 ]; then
	echo ERROR $last_task_return_code
	echo $date
	exit $last_task_return_code
fi

# If everything is ok, then remove the temporary backup 
cd $mgnify_data_directory
rm -r marker_gene_data_previous

# -------------------------------------------------------------------------------------------------

## PART B: The associations part

# Chech whether a all.tsv file exists already in the /experiments directory and if yes, remove it
cd $scripts_directory
FILE=/data/experiments/all.tsv
if test -f "$FILE"; then
    rm $FILE
fi

# Build the mgnify_markergene_associations.tsv file 
./extract_mgnify_markergene_associations.py > mgnify_markergene_associations.tsv 2> associations.log

# Build a new all.tsv file with all the .tsv associations files from the different sources, inculding the new MGnify markergene data
cat *.tsv > all.tsv

# Run the create_database perl script
./create_database.R

# Feed the "experiments" database with the new associations
psql -d experiments -f create_database.sql

# End time of this robot
echo $date
