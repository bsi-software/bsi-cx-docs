#!/bin/bash

#############################################################################################
#
# Script copies built output zip from documents build into this git repo.
#  - Folder 'images' is always synchronized (checksum based)
#  - html files with their corresponding pdf and zip files:
#    - only copied there are changes in html except the "Last updated" date
#
#############################################################################################

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' ERR

if (( $# != 3 )); then
    echo "Expecting arguments: zip file, target repository directory and major.minor version"
    echo "example: cx-docs.zip workspace/bsi-cx-docs 22.0"
    exit 2
fi

# --- VARIABLES ---

sourceZip=$1
targetRepoDir=$2
version=$3
sourceBaseDir="copyworkdir"

# --- SCRIPT ---

# make working directory and ensure there is no such dir yet (will be removed at the end of script again)
mkdir $sourceBaseDir

echo "Unzip $sourceZip to $sourceBaseDir"

unzip -q $sourceZip -d $sourceBaseDir

files=($sourceBaseDir/*)
mainZipDir="${files[0]##*/}"

sourceDir="${sourceBaseDir}/${mainZipDir}"
targetDir="${targetRepoDir}/docs/${version}"

echo "Copy files from $sourceDir to $targetDir ..."

# copy images and track changes (rsync using only checksums)
rsync -uac --info=name ${sourceDir}/images/* ${targetDir}/images/

for htmlFile in ${sourceDir}/*.html
do
  htmlFilename=${htmlFile##*/}
  filename=${htmlFilename%.*}

  # for each html, check if there are changes except for timestamps
  if [[ -n "$(diff -q --ignore-matching-lines='Last update [0-9\-]\+ [0-9:]\+' --ignore-matching-lines='Version Date [0-9\-]\+' ${sourceDir}/${htmlFilename} ${targetDir}/${htmlFilename})" ]]; then
    echo "File ${htmlFilename} changed: copy ${filename}.html, ${filename}.pdf"

    cp "${sourceDir}/${filename}.html" "${targetDir}/${filename}.html"
    cp "${sourceDir}/${filename}.pdf" "${targetDir}/${filename}.pdf"

  fi

done


rm -rf $sourceBaseDir

echo "Copy successfully completed"
