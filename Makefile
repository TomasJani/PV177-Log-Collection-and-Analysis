# This Makefile downloads ELK Stack components
# and spins them up.

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

SHELL=/bin/bash

# Define fake targets
.PHONY: all init-configs startup clean

# Define targets
all: elasticsearch-install logstash-install kibana-install filebeat-install init-configs startup

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

filebeat-install: logstash-install
	@echo '## Downloading Filebeat'
	curl --location ${FILEBEAT-URL} | tar xzv
	touch $@

# Initialize Logstash and Filebeat with the given configurations
init-configs: logstash-install filebeat-install logstash-tutorial.log
	cp -f configs/filebeat.yml ${FILEBEAT}/filebeat.yml
	cp -f configs/logstash.conf ${LOGSTASH}/logstash.conf

# Spin it up, use separate screen for every component
startup: init-configs clean
	# Create and detach screen with name 'ESnode' for Elasticsearch
	screen -S ESnode -d -m ${ELASTICSEARCH-EXTRACTED}/bin/elasticsearch
	# Check the Logstash config file
	${LOGSTASH}/bin/logstash -f ${LOGSTASH}/logstash.conf --config.test_and_exit
	# Start Logstash with automatic config reloading
	screen -S Lnode -d -m ${LOGSTASH}/bin/logstash -f ${LOGSTASH}/logstash.conf # --config.reload.automatic
	screen -S Fnode -d -m ${FILEBEAT}/filebeat -e -c ${FILEBEAT}/filebeat.yml -d "publish"
	# List available screens
	screen -ls

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
	-rm -rf filebeat-7.4.1-linux-x86_64/data/registry
