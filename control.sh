#!/bin/bash

# username and password to use to connect via the reverse proxy and grafana itself
ADMIN_USER=admin
ADMIN_PASSWORD=admin

# change this to true if you want to collect network metrics from the host.
# beware that the containers nodeexporter and cadvisor will be on the same network as the host.
# shutdown containers before changing from true to false or vice versa (./control.sh down)
COLLECT_HOST_NETWORK=false

# the ip address of the HOST to use to connect to nodeexporter and cadvisor if COLLECT_HOST_NETWORK is true
HOST_IP_ADDRESS=192.168.162.60

DOCKER_FOLDER=.tmp/

# the docker file used
DOCKER_FILE=${DOCKER_FOLDER}docker-compose.yml
DOCKER_EXPORTERS_FILE=${DOCKER_FOLDER}docker-compose.exporters.yml

# delete everything from temporary folder, maybe?
# rm -rf .tmp/*

mkdir -p .tmp

# create a copy of the template file
cp docker-compose.template.yml .tmp/docker-compose.yml

# replace mapping paths
sed -i 's/- \.\/alertmanager\//- \.\.\/alertmanager\//g' .tmp/docker-compose.yml
sed -i 's/- \.\/caddy\//- \.\.\/caddy\//g' .tmp/docker-compose.yml
sed -i 's/- \.\/grafana\//- \.\.\/grafana\//g' .tmp/docker-compose.yml

mkdir -p .tmp/prometheus

# create a copy of prometheus configuration which will be used for the start
cp -rf ./prometheus/* .tmp/prometheus/

HOSTNAME=$(hostname)

# replace variables (only ${hostname} supported at the moment)
sed -i "s/\${hostname}/$HOSTNAME/g" .tmp/prometheus/prometheus.yml
sed -i "s/\${hostname}/$HOSTNAME/g" .tmp/prometheus/alert.rules

if [ $COLLECT_HOST_NETWORK ]; then
	if [ "$HOST_IP_ADDRESS" = "" ] ; then
		echo "IP address of host not configured"
		exit 1
	fi

	cp docker-compose.exporters.template.yml .tmp/docker-compose.exporters.yml

	# configuring prometheus to scrape from external network
	sed -i "s/nodeexporter:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
	sed -i "s/cadvisor:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
fi

if [ $COLLECT_HOST_NETWORK ]; then
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
