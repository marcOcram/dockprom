#!/bin/sh

ADMIN_USER=admin
ADMIN_PASSWORD=admin

COLLECT_HOST_NETWORK=true
IP_ADDRESS=192.168.162.60

if [ $COLLECT_HOST_NETWORK ]; then
	if [ "$IP_ADDRESS" = "" ] ; then
		echo "IP address of host not configured"
		exit 1
	fi

	mkdir -p .tmp/prometheus/

	# configuring prometheus to scrape from external network
	cp -r prometheus/* .tmp/prometheus/
	sed -i "s/nodeexporter:/$IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
	sed -i "s/cadvisor:/$IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml

	# configure prometheus to use different prometheus configuration
	cp docker-compose.yml .tmp/docker-compose.yml
	sed -i 's/- \.\/prometheus\//- \.\/.tmp\/prometheus\//g' .tmp/docker-compose.yml

	docker-compose -f ./.tmp/docker-compose.yml up -d
	docker-compose -f docker-compose.exporters.yml up -d
else
	docker-compose up -d
fi