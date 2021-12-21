#!/bin/bash

echo $date

# Get the date of the update and directories with scripts and data
version=$(date +'%Y_%m_%d')
dictionary_update_script_directory='/data/dictionary'

# Build a .tar.gz file with the previous PREGO dictionary and archive it.
cd $dictionary_update_script_directory
cp prego_hidden.tsv prego_hidden_$version.tsv

#ls *.tsv | xargs tar cvzf prego_dictonary_archive_$version.tar.gz
tar cvzf prego_dictonary_archive_$version.tar.gz prego_entities.tsv prego_global.tsv prego_groups.tsv prego_names.tsv prego_preferred.tsv prego_texts.tsv prego_hidden_$version.tsv

mv prego_dictonary_archive_$version.tar.gz /data/archives/dictionary_2019

# update PREGO dictionary. This script downloads the dictionary if the timestamp is differnt and calls the create_database.pl script. duration=2 minutes
./update.csh

echo $date
