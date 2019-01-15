#!/bin/bash

# username and password to use to connect via the reverse proxy and grafana itself
ADMIN_USER=admin
ADMIN_PASSWORD=admin

# change this to true if you want to collect network metrics from the host.
# beware that the containers nodeexporter and cadvisor will be on the same network as the host.
# shutdown before changing from true to false or vice versa (./control.sh down)
COLLECT_HOST_NETWORK=true

# the ip address of the HOST to use to connect to nodeexporter and cadvisor if COLLECT_HOST_NETWORK is true
HOST_IP_ADDRESS=192.168.162.60

# if we collect network data .tmp is our working folder
if [ $COLLECT_HOST_NETWORK ]; then
	DOCKER_FOLDER=./.tmp/
else
	DOCKER_FOLDER=./
fi

# the docker file used
DOCKER_FILE=${DOCKER_FOLDER}docker-compose.yml

case "$1" in
	# special handling for up / restart
	up|restart)
		# if we collect data from host network, we have to copy the docker and prometheus configuration and modify it
		if [ $COLLECT_HOST_NETWORK ]; then
			if [ "$HOST_IP_ADDRESS" = "" ] ; then
				echo "IP address of host not configured"
				exit 1
			fi

			mkdir -p .tmp/prometheus
			# copy used configurations into .tmp
			cp -rf ./prometheus/* .tmp/prometheus/

			# configuring prometheus to scrape from external network
			sed -i "s/nodeexporter:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
			sed -i "s/cadvisor:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml

			# copy docker configuration files
			cp docker-compose.yml .tmp/docker-compose.yml
			cp docker-compose.exporters.yml .tmp/docker-compose.exporters.yml

			# replace mapping paths
			sed -i 's/- \.\/alertmanager\//- \.\.\/alertmanager\//g' .tmp/docker-compose.yml
			sed -i 's/- \.\/caddy\//- \.\.\/caddy\//g' .tmp/docker-compose.yml
			sed -i 's/- \.\/grafana\//- \.\.\/grafana\//g' .tmp/docker-compose.yml

			if [ "$FIRST_ARGUMENT" = "up" ]; then
				docker-compose -f $DOCKER_FILE $@
				docker-compose -f ${DOCKER_FOLDER}docker-compose.exporters.yml $@
			else
				# special handling of restart for nodeexporter and cadvisor
				case "$2" in
					nodeexporter|cadvisor)
						docker-compose -f ${DOCKER_FOLDER}docker-compose.exporters.yml $@
						;;
					*)
						docker-compose -f $DOCKER_FILE $@
				esac
			fi
		else
			docker-compose -f $DOCKER_FILE $@
		fi
		;;
	*)
		docker-compose -f $DOCKER_FILE $@
esac
