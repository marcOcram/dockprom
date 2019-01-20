#!/bin/bash

# load configuration
source ./configuration.cfg

# delete everything from temporary folder, maybe?
# rm -rf .tmp/*

mkdir -p .tmp

# create a copy of the template file
cp $DOCKER_TEMPLATE_FILE $DOCKER_FILE

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

if $COLLECT_HOST_NETWORK; then
	if [ "$HOST_IP_ADDRESS" = "" ] ; then
		echo "IP address of host not configured"
		exit 1
	fi

	cp $DOCKER_EXPORTERS_TEMPLATE_FILE $DOCKER_EXPORTERS_FILE

	# configuring prometheus to scrape from external network
	sed -i "s/nodeexporter:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
	sed -i "s/cadvisor:/$HOST_IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
fi
