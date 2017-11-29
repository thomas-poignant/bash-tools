#!/bin/bash

#DOC : Cette fonction retourne la date formatée
function getDate {
	echo $(date +"%d-%m-%Y %H:%M:%S")
}

#DOC : Cette fonction va nous faire sortir du script en erreur 127 dans le
#      cas ou la fonction précédente ne s'est pas correctement déroulée
function assert {
	if [ "$?" -ne "0" ] ; then
		exit 127
	fi
}

#DOC : Cette fonction regarde si la variable est vide ou non
function isEmpty {
	if [ "$1" == "" ];
	then
		return 0 ; # 0 = true
	else
		return 1; # 1 = false
	fi
}

#DOC: fonction qui permet de logger
function log {
	LOG_MESSAGE=$1
	if ! isEmpty $LOG_MESSAGE;
	then
		echo "[$(getDate)] $LOG_MESSAGE"
	else
		echo ""
	fi
}

#DOC: fonction qui permet de logger une erreur
function log_error
{
	LOG_MESSAGE="ERROR : $1"
	log "$LOG_MESSAGE"
}

#DOC: fonction qui permet de logger un warn
function log_warn
{
	LOG_MESSAGE="WARN : $1"
	log "$LOG_MESSAGE"
}

#DOC: fonction qui vérifie que le nombre de paramètre en entrée est bien le nombre attendu
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


#DOC: Fonction qui patch un fichier
function patchFile {
	FILE=$1
	PATTERN_TO_REPLACE=$2
	REPLACE_VALUE=$3
	DELIMITER=$4
	if [ -z "$DELIMITER" ]; then
		DELIMITER="%"
	fi

	log "    -> Remplacement de la chaine \"$PATTERN_TO_REPLACE\" par \"$REPLACE_VALUE\" dans le fichier \"$FILE\""
	sed 's'$DELIMITER"$PATTERN_TO_REPLACE"$DELIMITER"$REPLACE_VALUE"$DELIMITER'g' $FILE >/tmp/$$ && sudo mv /tmp/$$ $FILE
}

#DOC: Fonction qui recherche tous les fichiers a patcher dans un répertoire et les patchs
function patchFilesInFolder {
	FOLDER=$1
	PATTERN_TO_REPLACE=$2
	REPLACE_VALUE=$3
	DELIMITER=$4

	FILES=$(grep -l -R "$PATTERN_TO_REPLACE" "$FOLDER/"*)
	NB_FILES=$(echo $FILES | wc -w)

	if [ $NB_FILES -le 0 ]
	then
		log_warn "Il n'y a aucun fichier dans le repertoire $FOLDER qui contient le pattern \"$PATTERN_TO_REPLACE\""
	else
		log "Remplacement de la chaine \"$PATTERN_TO_REPLACE\" par \"$REPLACE_VALUE\" dans les fichiers presents dans le repertoire \"$FOLDER\""
		for CURRENT_FILE in $FILES
		do
			patchFile "$CURRENT_FILE" "$PATTERN_TO_REPLACE" "$REPLACE_VALUE" "$DELIMITER"; assert
		done
	fi
}

#DOC: Fonction qui test si un fichier existe
function fileExists {
	FILE=$1
	if [ -f $FILE ];
	then
		log "Le fichier \"$FILE\" existe"
		return 0  # 0 = true
	else
		log "Le fichier \"$FILE\" n'existe pas"
		return 1  # 1 = false
	fi
}

#DOC: Fonction qui test si un repertoire existe
function dirExists {
	DIR=$1
	if [ -d $DIR ];
	then
		log "Le repertoire \"$DIR\" existe"
		return 0  # 0 = true
	else
		log "Le repertoire \"$DIR\" n'existe pas"
		return 1  # 1 = false
	fi
}

#DOC: fonction qui vérifie un lien symbolique pour voir s'il correspond à l'URL attendu
function checkSymbolicLink {
	SYM_LINK=$1
	WANTED_VALUE=$2
	CURRENT_LINK=$(readlink $SYM_LINK)
	log "    -> Nous regardons si le lien symbolique $SYM_LINK qui pointe vers \"$CURRENT_LINK\" a la valeur souhaitee \"$WANTED_VALUE\""
	if [ "$CURRENT_LINK" == "$WANTED_VALUE" ];
	then
		return 0 # 0 = true
	else
		return 1 # 1 = false
	fi
}

#DOC: Fonction qui créer un lien symbolique
function createSymbolicLink {
	SOURCE=$1
	DESTINATION=$2

	if checkSymbolicLink $DESTINATION $SOURCE;
	then
		log "    -> Le lien symbolique \"$DESTINATION\" qui pointe sur le fichier \"$SOURCE\" existe deja"
	else
		log "    -> Creation du lien symbolique \"$DESTINATION\" qui pointe sur le fichier \"$SOURCE\""
		sudo ln -s $SOURCE $DESTINATION
	fi
}

#DOC: fonction qui créer un répertoire s'il n'existe pas
function createFolderIfNotExist {
	FOLDER=$1
	if ! dirExists $FOLDER ;
	then
		log "Creation du repertoire $FOLDER"
		mkdir -p $FOLDER
	fi
}

#DOC: fonction qui patch partiellement une ligne qui contient un pattern dans un dossier
function patchLinesInFolder {
	if ! countParam $# 3 5
	then
		log_error " -> [patchLinesInFolder] Nombre d'arguments invalide:"
		log_error "       1) FOLDER: \"$1\""
		log_error "       2) SEARCH_PATTERN \"$2\""
		log_error "       3) REPLACEMENT \"$3\""
		log_error "       4) [AFTER \"$4\"]"
		log_error "       5) [BEFORE \"$5\"]"
	else
		FOLDER=$1
		SEARCH_PATTERN=$2
		REPLACEMENT=$3
		AFTER=$4
		BEFORE=$5
	
		FILES=$(grep -l -R "$SEARCH_PATTERN" "$FOLDER/"*)
		NB_FILES=$(echo $FILES | wc -w)
		
		if [ $NB_FILES -le 0 ]
		then
			log_warn "Il n'y a aucun fichier dans le repertoire $FOLDER qui contient le pattern \"$SEARCH_PATTERN\""
		else
			for CURRENT_FILE in $FILES
			do
				patchLines "$CURRENT_FILE" "$SEARCH_PATTERN" "$REPLACEMENT" "$AFTER" "$BEFORE"
			done
		fi
	fi
}

#DOC: fonction qui patch partiellement une ligne qui contient un pattern dans un fichier
function patchLines
{
	if ! countParam $# 3 5
	then
		log_error " -> [patchLines] Nombre d'arguments invalide:"
		log_error "       1) FILE: \"$1\""
		log_error "       2) SEARCH_PATTERN \"$2\""
		log_error "       3) REPLACEMENT \"$3\""
		log_error "       4) [AFTER \"$4\"]"
		log_error "       5) [BEFORE \"$5\"]"
	else
		FILE=$1
		SEARCH_PATTERN=$2
		REPLACEMENT=$3
		AFTER=$4
		BEFORE=$5
		
		if [ ! -z "$AFTER" ]; then
			REPLACEMENT="$AFTER $REPLACEMENT"
		fi
		if [ ! -z "$BEFORE" ]; then
			REPLACEMENT="$REPLACEMENT $BEFORE"
		fi
		
		patchFile "$FILE" "$AFTER.*$BEFORE.*$SEARCH_PATTERN.*" "$REPLACEMENT" "/"; assert
	fi
}

