#!/bin/bash

#DOC : get a formated date
function getDate {
	echo $(date +"%d-%m-%Y %H:%M:%S")
}

#DOC : exit the script in 127 if precedent command failed
function assert {
	if [ "$?" -ne "0" ] ; then
		exit 127
	fi
}

#DOC : Check if ENV variable is empty
function isEmpty {
	if [ "$1" == "" ];
	then
		return 0 ; # 0 = true
	else
		return 1; # 1 = false
	fi
}

#DOC: write a log message
function log {
	LOG_MESSAGE=$1
	if ! isEmpty $LOG_MESSAGE;
	then
		echo "[$(getDate)] $LOG_MESSAGE"
	else
		echo ""
	fi
}

#DOC: Add an error prefix to the log
function log_error
{
	LOG_MESSAGE="ERROR : $1"
	log "$LOG_MESSAGE"
}

#DOC: Add a warn prefix to the log
function log_warn
{
	LOG_MESSAGE="WARN : $1"
	log "$LOG_MESSAGE"
}

#DOC: count the number of parameters in the scripts
function countParam {
	NB_PARAM_USED=$1
	NB_PARAM_WANTED=$2
	MAX_PARAM_AUTORISED=$3
	
	if [ -z "$MAX_PARAM_AUTORISED" ]
	then
		if [ $NB_PARAM_WANTED == $NB_PARAM_USED ]
		then
			return 0  # 0 = true
		else
			return 1  # 1 = false
		fi
	else
		if [ $NB_PARAM_USED -le $MAX_PARAM_AUTORISED ] && [ $NB_PARAM_USED -ge $NB_PARAM_WANTED ]
		then
			return 0  # 0 = true
		else
			log "$NB_PARAM_WANTED <= $NB_PARAM_USED <= $MAX_PARAM_AUTORISED"
			return 1  # 1 = false
		fi
	fi
}


#DOC: Patch pattern in a file
function patchFile {
	FILE=$1
	PATTERN_TO_REPLACE=$2
	REPLACE_VALUE=$3
	DELIMITER=$4
	if [ -z "$DELIMITER" ]; then
		DELIMITER="%"
	fi

	log "    -> Replace \"$PATTERN_TO_REPLACE\" by \"$REPLACE_VALUE\" in the file: \"$FILE\""
	sed 's'$DELIMITER"$PATTERN_TO_REPLACE"$DELIMITER"$REPLACE_VALUE"$DELIMITER'g' $FILE >/tmp/$$ && sudo mv /tmp/$$ $FILE
}

#DOC:  Patch pattern in a folder
function patchFilesInFolder {
	FOLDER=$1
	PATTERN_TO_REPLACE=$2
	REPLACE_VALUE=$3
	DELIMITER=$4

	FILES=$(grep -l -R "$PATTERN_TO_REPLACE" "$FOLDER/"*)
	NB_FILES=$(echo $FILES | wc -w)

	if [ $NB_FILES -le 0 ]
	then
		log_warn "No file in folder $FOLDER with the pattern \"$PATTERN_TO_REPLACE\""
	else
		log "Replace \"$PATTERN_TO_REPLACE\" by \"$REPLACE_VALUE\" in folder \"$FOLDER\""
		for CURRENT_FILE in $FILES
		do
			patchFile "$CURRENT_FILE" "$PATTERN_TO_REPLACE" "$REPLACE_VALUE" "$DELIMITER"; assert
		done
	fi
}

#DOC: Check if a file exist
function fileExists {
	FILE=$1
	if [ -f $FILE ];
	then
		log "File \"$FILE\" exist"
		return 0  # 0 = true
	else
		log "File \"$FILE\" doesn't exist"
		return 1  # 1 = false
	fi
}

#DOC: Check if a folder exist
function dirExists {
	DIR=$1
	if [ -d $DIR ];
	then
		log "Folder \"$DIR\" exist"
		return 0  # 0 = true
	else
		log "Folder \"$DIR\" doesn't exist"
		return 1  # 1 = false
	fi
}

#DOC: Check if the symbolic link is correct
function checkSymbolicLink {
	SYM_LINK=$1
	WANTED_VALUE=$2
	CURRENT_LINK=$(readlink $SYM_LINK)
	log "    -> Symlink $SYM_LINK goes to \"$CURRENT_LINK\", wanted value: \"$WANTED_VALUE\""
	if [ "$CURRENT_LINK" == "$WANTED_VALUE" ];
	then
		return 0 # 0 = true
	else
		return 1 # 1 = false
	fi
}

#DOC: Create a symlink
function createSymbolicLink {
	SOURCE=$1
	DESTINATION=$2

	if checkSymbolicLink $DESTINATION $SOURCE;
	then
		log "    -> Symlink \"$DESTINATION\" goes to \"$SOURCE\"already exist"
	else
		log "    -> Create symlink \"$DESTINATION\" goes to \"$SOURCE\""
		sudo ln -s $SOURCE $DESTINATION
	fi
}

#DOC: Create a folder if doesn't exist
function createFolderIfNotExist {
	FOLDER=$1
	if ! dirExists $FOLDER ;
	then
		log "Creation of $FOLDER"
		mkdir -p $FOLDER
	fi
}