#!/bin/bash

########################################################################################
# script name: daemon_database_quality.sh
# path on oxygen: /data/databases/scripts/prego_daemons
# developed by: Savvas Paragkamian
# framework: PREGO - WP4
########################################################################################
# GOAL:
# This script is intented to run before the upload of database_pairs.tsv files to postgres.
########################################################################################

## data required from /data/dictionary
database_preferred="/data/dictionary/database_preferred.tsv"

##
usage="Use the parameter -f for the complete path of the file \n\
The parameter -l is for the log file in the current directory \n\
The log will contail the ids that are not in dictionary. \n\
Example: ./daemon_database_quality.sh -f /data/knowledge/database_pairs.tsv -l knowledge.log \n"

time_start=`date +%s`

# handling of arguments
while getopts "f:l:" option
do
   case "$option" in
        f)   datafile="${OPTARG}";;
        l)   logfile="${OPTARG}";;
        ?|:) echo -e "$usage" ; exit 1;;
        *)   echo -e "option ${OPTARG} unknown. \n$usage" ; exit 1 ;;
   esac
done

# Detect if no options were passed
if [ $OPTIND -eq 1 ];
    then echo -e "No options were passed. \n$usage "; exit 1;-
fi

# initiation
echo "the quality control of the file "$datafile" begins"

create_log="$(date +"%Y%m%d")_${logfile}"

if [ -z "$logfile" ]; then
    echo "no logfile is created"
    unset create_log
elif [ -f "$create_log" ]; then
    echo "$create_log exists. Continue without logfile."
    unset create_log
else
    touch "$create_log"
    echo "$create_log created."
fi


# Summary of associations and entities
echo "Step 1/4"
echo "association pairs per source"
cut -f1,3,5 $datafile | sort | uniq -c

# check the number of fields
echo "Step 2/4"
echo "checking the number of fields, 9 are required before upload."

awk -F"\t" '{a[NF]++}END{print "# fields" "\t" "# of lines"; for (i in a){print i FS a[i]}}' $datafile

# find which ids are not in dictionary
echo "Step 3/4"
echo "detecting ids that are missing for dictionary"

missing_from_dictionary=$(awk -F"\t" 'NR==FNR{a[$1][$5][$2]++; next}{b[$2]=$3}\
END{for (i in a){for (s in a[i]){for (j in a[i][s]){if (!(j in b)){\
print i "\t" s "\t" j "\t" a[i][s][j] "\t" "not in dictionary"}}}}}' $datafile $database_preferred)

## check whether the variable missing_from_dictionary has contents
if [ -z "$missing_from_dictionary" ]
then
    echo "there are no missing ids from dictionary"
else
    if [ ! -z "$create_log" ]
    then
        echo "$missing_from_dictionary" > "$create_log"
    fi
    echo "$missing_from_dictionary" | awk -F"\t" '{summary_id[$1][$2]++;summary_as[$1][$2]+=$4}END{\
print "type" "\t" "source" "\t" "# ids" "\t" "# associations";\
for(i in summary_as){for (s in summary_as[i]){print i "\t" s "\t" summary_id[i][s] "\t" summary_as[i][s]}}}'
fi

# Score is in the interval [0,5].

echo "Step 4/4"
echo "count the # of associations that aren't in the interval of [0,5]"


awk -F"\t" '($7>5 || $7<0){a[$0]=1}END{print "# lines NOT in [0,5] = " length(a)}' $datafile

# finish

time_end=`date +%s`
echo "done"
echo "quality control was running for $((time_end-time_start)) seconds."
