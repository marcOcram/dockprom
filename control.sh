#!/bin/sh

ADMIN_USER=admin
ADMIN_PASSWORD=admin

COLLECT_HOST_NETWORK=true
IP_ADDRESS=192.168.162.60

if [ $COLLECT_HOST_NETWORK ]; then
	DOCKER_FOLDER=./.tmp/
else
	DOCKER_FOLDER=./
fi
DOCKER_FILE=${DOCKER_FOLDER}docker-compose.yml

case "$1" in
	start)
		if [ $COLLECT_HOST_NETWORK ]; then
			if [ "$IP_ADDRESS" = "" ] ; then
				echo "IP address of host not configured"
				exit 1
			fi

			mkdir -p .tmp/prometheus
			# copy used configurations into .tmp
			cp -r ./prometheus/* .tmp/prometheus/

			# configuring prometheus to scrape from external network
			sed -i "s/nodeexporter:/$IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml
			sed -i "s/cadvisor:/$IP_ADDRESS:/g" .tmp/prometheus/prometheus.yml

			# 
			cp docker-compose.yml .tmp/docker-compose.yml
			cp docker-compose.exporters.yml .tmp/docker-compose.exporters.yml

			# replace mapping paths
			sed -i 's/- \.\/alertmanager\//- \.\.\/alertmanager\//g' .tmp/docker-compose.yml
			sed -i 's/- \.\/caddy\//- \.\.\/caddy\//g' .tmp/docker-compose.yml
			sed -i 's/- \.\/grafana\//- \.\.\/grafana\//g' .tmp/docker-compose.yml

			docker-compose -f docker-compose.yml up -d
			docker-compose -f ${DOCKER_FOLDER}docker-compose.exporters.yml up -d
		else
			docker-compose -f $DOCKER_FILE up -d
		fi
		;;
	stop)
		docker-compose -f $DOCKER_FILE down
		;;
	restart)
		docker-compose -f $DOCKER_FILE restart
		;;
	logs)
		docker-compose -f $DOCKER_FILE logs
		;;
	*)
		echo "Usage: $0 {start|stop|restart|logs}"
		exit 1
esac