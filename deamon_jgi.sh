#!/bin/bash

########################################################################################
# script name: daemon_mgnify_markergne.sh
# path on oxygen: /data/databases/scripts/prego_daemons
# developed by: Haris Zafeiropoulos
# framework: PREGO - WP2
########################################################################################
# GOAL:
# This script is intented to run few months with a cron job in order to update the
# knowledge module of the PREGO knowledgebase to include the new genome and metagenome 
# entries of the JGI/IMG platform
########################################################################################

# Start time of this robot
echo $date

# Get the date of the update 
version=$(date +'%Y_%m_%d')
jgi_data_directory='/data/databases/jgi/'
scripts_directory='/data/databases/scripts/gathering_data/jgi/'
experiments_path='/data/experiments/'
knowledge_path='/data/knowledge/'

# Archive previous version
cd $jgi_data_directory
tar cvzf jgi_$version.tar.gz .
mv jgi_$version.tar.gz /data/archives/jgi


# Run script to export associations 
cd $scripts_directory 
./extract_jgi_isolates_associations.py

# Keep unique entries
cd $experiments_path
sort -u jgi_associations.tsv > tmp
mv tmp jgi_associations.tsv

cd $knowledge_path
sort -u jgi_associations.tsv > tmp
mv tmp jgi_associations.tsv



# Check if everything in downloading the new entries of JGI/IMG ran Ok.
# If an error occurred, then exit the script (keeping the previous version of markergene data)
last_task_return_code=$?
if [ $last_task_return_code -ne 0 ]; then
	echo ERROR $last_task_return_code
	echo $date
	exit $last_task_return_code
fi
