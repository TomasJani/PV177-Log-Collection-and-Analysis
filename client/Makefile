# This Makefile downloads and spins Filebeat up
# on the client side to ship data to ELK server.

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
.PHONY: all clean startup-filebeat stop-filebeat

# Define targets
all: filebeat-install startup-filebeat

filebeat-install:
	@echo '## Downloading Filebeat'
	curl --location ${FILEBEAT-URL} | tar xzv
	touch $@

startup-filebeat: filebeat-install
	cp -f configs/filebeat.yml ${FILEBEAT}/filebeat.yml
	screen -S Fnode -L -Logfile screen-logs/fnode.log -d -m ${FILEBEAT}/filebeat -e -c ${FILEBEAT}/filebeat.yml -d "publish"
	# List available screens
	screen -ls

stop-filebeat:
	@screen -X -S Fnode kill
	# List available screens
	-screen -ls

# Clean the workspace to start again
clean: stop-filebeat
	# Sometimes Filebeat should be forced to read the logs again from scratch by deleting its registry
	-rm -rf filebeat-7.4.1-linux-x86_64/data/registry
