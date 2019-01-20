#!/bin/bash

# load configuration
source ./configuration.cfg

# run build.sh
./build.sh

if $COLLECT_HOST_NETWORK; then
	case "$1" in
		up)
			docker-compose -f $DOCKER_FILE $@
			docker-compose -f $DOCKER_EXPORTERS_FILE $@
		;;
		restart)
			# special handling of restart for nodeexporter and cadvisor
			case "$2" in
				nodeexporter|cadvisor)
					docker-compose -f $DOCKER_EXPORTERS_FILE $@
					;;
				*)
					docker-compose -f $DOCKER_FILE $@
			esac
		;;
		*)
			docker-compose -f $DOCKER_FILE $@
	esac
else
	docker-compose -f $DOCKER_FILE $@
fi
