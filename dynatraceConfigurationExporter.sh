#!/bin/bash

# Simple shell script to dump configuration from Dynatrace environment
# - Stores JSON configuration in directories (per environment) (config/<ENVIRONMENT>/<ENTITY>)
# - Provides pre-formatted curl commands to push configurations to different environments (copy&paste curl command)

# Dependencies: curl jq

CONFIG_PATHS=(
"alertingProfiles"
"anomalyDetection/diskEvents"
"anomalyDetection/metricEvents"
"anomalyDetection/processGroups"
"applicationDetectionRules"
"applications/web"
"autoTags"
"aws/credentials"
"azure/credentials"
"cloudFoundry/credentials"
"conditionalNaming/{type}"
"dashboards"
"kubernetes/credentials"
"maintenanceWindows"
"managementZones"
"notifications"
"remoteEnvironments"
"reports"
"service/customServices/java"
"service/customServices/php"
"service/customServices/dotNet"
"service/customServices/go"
"service/customServices/nodeJS"
"service/detectionRules/FULL_WEB_REQUEST"
"service/detectionRules/FULL_WEB_SERVICE"
"service/detectionRules/OPAQUE_AND_EXTERNAL_WEB_REQUEST"
"service/ibmMQTracing/imsEntryQueue"
"service/requestAttributes"
"service/requestNaming")

prepare_confdir() {
	[ -z "${ENVIRONMENT}" ] && echo "Environment not specified" && exit 1
	[ -z "${1}" ] && echo "Configuration type specified" && exit 2
	CONFDIR="config/${ENVIRONMENT}/$1"
	echo "Creating configuration directory $CONFDIR"
	mkdir -p "$CONFDIR"
	export CONFDIR
}

dumpEntity() {
	if [[ ! " ${CONFIG_PATHS[@]} " =~ " ${1} " ]]; then
		>&2 echo -e "API Entity \e[31m${1}\e[0m unknown"
		exit 1
	fi
	CONFIG_ENTITY="${1}"
	CONFIG_ENTITY_API="/api/config/v1/$CONFIG_ENTITY"
	prepare_confdir "${CONFIG_ENTITY}"
	CONFIG_LIST_JSON="${CONFDIR}/_.json"
	echo $CONFIG_LIST_JSON
	curl -XGET ${CURLARGS} -H "Authorization: api-token ${APITOKEN}" "${TENANT}${CONFIG_ENTITY_API}">"${CONFIG_LIST_JSON}" 

	if [ "${CONFIG_ENTITY}" == "dashboards" ]; then
	    ITERATOR='.dashboards[]| .id, (.owner+"_"+.name)'
	else 
        ITERATOR='.values[]|.id,.name'
	fi

	jq -r "${ITERATOR}" "${CONFIG_LIST_JSON}" |while read ID; do
		read NAME
		ENTITY_FILE="$CONFDIR/$NAME.json"
		echo -e "\e[2mDumping ${CONFIG_ENTITY}\e[2m with ID:\e[1m${ID}\e[0m \e[2m(\e[0m\e[1m${NAME}\e[0m\e[2m) to \e[1m${ENTITY_FILE}\e[0m"
		curl -XGET ${CURLARGS} -H "Authorization: api-token ${APITOKEN}" "${TENANT}${CONFIG_ENTITY_API}/${ID}" |jq '.' >"${ENTITY_FILE}"
		echo -e "curl \$CURLARGS -XPUT -H \"Content-Type: application/json\" -H \"Authorization: api-token \$APITOKEN\" \"\$TENANT${CONFIG_ENTITY_API}/${ID}\" --data @\"${ENTITY_FILE}\""
	done
}

help() {
	echo "Usage:"
	echo -e "\e[1m$0 <configEntity>\e[0m\n\n"
	echo "Available config entities:"
	for entity in ${CONFIG_PATHS[@]}; do
		echo -e "\t$entity"
	done
	echo -e ""
	echo -e "Variables must be set:"
	echo -e "\t\e[1mTENANT\e[0m - URL to environment"
	echo -e "\t\e[1mAPITOKEN\e[0m - API token for accessing the configuration API"
	echo -e "\t\e[1mENVIRONMENT\e[0m - Name of the environment"
	echo -e "\t\e[1mCURLARGS\e[0m - Optional arguments to curl"
}

preCheck() {
	FAIL=0
	for v in ENVIRONMENT TENANT APITOKEN; do	
		[ -z "${!v}" ] && echo -e "Variable \e[31m$v\e[0m is not set" && FAIL=1
	done

	for c in curl jq; do
		if ! command -v ${c} &>/dev/null; then echo -e "Command \e[31m${c}\e[0m not found" && FAIL=2 
		fi
	done
	[ ! "${FAIL}" -eq 0 ] && exit 1
}


case "${1}" in 
    '-h'|'-help'|'help')
	help
    ;;
	*)
    preCheck
	dumpEntity "${1}"
esac
