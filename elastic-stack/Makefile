# This Makefile downloads Elastic Stack components,
# configures them, spins them up and ships data between them.

# Define variables
ELASTIC-VERSION = 7.4.1
ELASTIC-DOWNLOAD-PREFIX = https://artifacts.elastic.co/downloads

ELASTICSEARCH-EXTRACTED = elasticsearch-${ELASTIC-VERSION}
ELASTICSEARCH = ${ELASTICSEARCH-EXTRACTED}-linux-x86_64
LOGSTASH = logstash-${ELASTIC-VERSION}
KIBANA = kibana-${ELASTIC-VERSION}-linux-x86_64
FILEBEAT = filebeat-${ELASTIC-VERSION}-linux-x86_64

ELASTICSEARCH-URL = ${ELASTIC-DOWNLOAD-PREFIX}/elasticsearch/${ELASTICSEARCH}.tar.gz
LOGSTASH-URL = ${ELASTIC-DOWNLOAD-PREFIX}/logstash/${LOGSTASH}.tar.gz
KIBANA-URL = ${ELASTIC-DOWNLOAD-PREFIX}/kibana/${KIBANA}.tar.gz
FILEBEAT-URL = ${ELASTIC-DOWNLOAD-PREFIX}/beats/filebeat/${FILEBEAT}.tar.gz

# Public IP of the ELK server (Openstack VM)
# Use localhost as a fallback
PUBLIC-IP = localhost
# PUBLIC-IP = 78.128.250.N

SHELL=/bin/bash

# Define fake targets
.PHONY: all config-elasticsearch startup-elasticsearch startup-logstash startup-filebeat startup-kibana startup-all stop-filebeat clean

# Define targets
all: elasticsearch-install logstash-install kibana-install filebeat-install startup-all

elasticsearch-install:
	# Print to the stdout what's going on
	@echo '## Downloading Elasticsearch'
	# Download and unpack Elasticsearch
	curl --location ${ELASTICSEARCH-URL} | tar xzv
	# Create a file with target name as a filename
	# (just to avoid re-making this target)
	touch $@

# Logstash has Elasticsearch as a dependency
logstash-install: elasticsearch-install
	@echo '## Downloading Logstash'
	curl --location ${LOGSTASH-URL} | tar xzv
	touch $@

kibana-install:
	@echo '## Downloading Kibana'
	curl --location ${KIBANA-URL} | tar xzv
	touch $@

filebeat-install:
	@echo '## Downloading Filebeat'
	curl --location ${FILEBEAT-URL} | tar xzv
	touch $@

config-elasticsearch:
	# Based on https://www.elastic.co/guide/en/elasticsearch/reference/current/system-config.html
	# May consult `ulimit -a` for the current limit values
	# Increase file descriptor limits (number of open files)
	# Default 1024 on ubuntu
	ulimit -n 65536
	# Alternatively
	# sudo su -c 'printf "# ELK Setup\n* soft nofile 65536\n* hard nofile 65536\n" >> /etc/security/limits.conf'
	# Disable swapping
	# May consult `less /proc/meminfo | grep -i swap`
	sudo swapoff -a
	# Number of threads should be at least 4096
	# Default 15677 on ubuntu
	# ulimit -n 4096
	# Alternatively
	# sudo su -c 'printf "# ELK Setup\n* soft nproc 4096\n* hard nproc 4096\n" >> /etc/security/limits.conf'
	#
	# Heap size https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html
	# Default 1GB, depends on the current amount of RAM
	# May be changed in config ${ELASTICSEARCH-EXTRACTED}/config/jvm.options
	# Virtual memory https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
	sudo sysctl -w vm.max_map_count=262144

startup-elasticsearch: elasticsearch-install config-elasticsearch
	# Create and detach screen with name 'ESnode' for Elasticsearch
	# and log `screen` stdout to the log file
	screen -S ESnode -L -Logfile screen-logs/esnode.log -d -m ${ELASTICSEARCH-EXTRACTED}/bin/elasticsearch

startup-logstash: logstash-install
	# Initialize Logstash with the given configuration
	cp -f configs/logstash.conf ${LOGSTASH}/logstash.conf
	# Check the Logstash config file for valid syntax and then exit
	${LOGSTASH}/bin/logstash -f ${LOGSTASH}/logstash.conf --config.test_and_exit
	# Start Logstash with automatic config reloading
	screen -S Lnode -L -Logfile screen-logs/lnode.log -d -m ${LOGSTASH}/bin/logstash -f ${LOGSTASH}/logstash.conf # --config.reload.automatic

startup-filebeat: filebeat-install logstash-tutorial.log
	cp -f configs/filebeat.yml ${FILEBEAT}/filebeat.yml
	# Replace localhost with the live ELK server
	sed -i 's/localhost:5044/${PUBLIC-IP}:5044/g' ${FILEBEAT}/filebeat.yml
	screen -S Fnode -L -Logfile screen-logs/fnode.log -d -m ${FILEBEAT}/filebeat -e -c ${FILEBEAT}/filebeat.yml -d "publish"

startup-kibana: kibana-install
	cp -f configs/kibana.yml ${KIBANA}/config/kibana.yml
	screen -S Knode -L -Logfile screen-logs/knode.log -d -m ${KIBANA}/bin/kibana

# Spin it up, use separate screen for every component
startup-all: clean startup-elasticsearch startup-logstash startup-filebeat startup-kibana
	# List available screens
	screen -ls

stop-filebeat:
	@screen -X -S Fnode kill
	# List available screens
	-screen -ls

# Download and unpack sample data provided by Elastic
logstash-tutorial.log:
	curl --location https://download.elastic.co/demos/logstash/gettingstarted/logstash-tutorial.log.gz | gunzip -c > $@

# Clean the workspace to start again
clean:
	# Kill all screens
	-pkill screen
	# Sometimes Logstash is not properly shutted down
	-kill -9 `pgrep -f logstash`
	# Sometimes Filebeat should be forced to read the logs again from scratch by deleting its registry
	-rm -rf ${FILEBEAT}/data/registry
