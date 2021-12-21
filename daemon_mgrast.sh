#!/bin/bash

########################################################################################
# script name: daemon_mgrast.sh
# path on oxygen: /data/databases/scripts/prego_daemons
# developed by: Haris Zafeiropoulos
# framework: PREGO - WP2
########################################################################################
# GOAL:
# This script is intented to run few months with a cron job in order to update the
# "Experiments" module of the PREGO knowledgebase by including the recently added
# entries of the MG-RAST platform
########################################################################################


# Start time of this robot
echo $date

# Get the date of the update 
version=$(date +'%Y_%m_%d')
mg_rast_data_directory='/data/databases/mg_rast/'
scripts_directory='/data/databases/scripts/gathering_data/mg_rast/'

# Archive previous version
cd $mg_rast_data_directory
tar cvzf mgrast_$version.tar.gz .
mv mgrast_$version.tar.gz /data/archives/mgrast


# Remove files from previous version, so not to append to those the same information
# We chose an implementation like this as we do not know whether MG-RAST will decide to get any other types of data
# Our implementation will not be affected by such an alteration

mkdir previous_version

# Move all to the previous_version directory; not itself
EXCLUDE="previous_version"
TARGET="previous_version"
ls -1 | grep -v ^$EXCLUDE | xargs -I{} mv {} $TARGET

# Go to the scripts directory and remove the projects related files 
cd $scripts_directory
rm projects_included_in_mgrast.tsv projects_retrieved_from_mgrast.tsv

# Now, run the get_mgrast_data.py script 
./get_mgrast.data



# Check if everything ran Ok. If an error occurred, then exit the script (keeping the previous version of markergene data)
last_task_return_code=$?
if [ $last_task_return_code -ne 0 ]; then
	echo ERROR $last_task_return_code
	echo $date
	exit $last_task_return_code
fi

# If everything is fine we can remove the previous version
cd $mg_rast_data_directory
rm -r previous_version

# And then run the associations script
cd $scripts_directory
./extract_mgrast_associations.py

