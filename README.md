# PV177 Log Collection and Analysis

Log Collection and Analysis project for the course PV177 Data Science in semester Fall 2019.

## MetaCentrum Account Setup

https://metavo.metacentrum.cz/cs/application/index.html

> Uživatelé MetaCentra mají přístup do MetaCloudu aktivovaný automaticky. [1]

[1] https://wiki.metacentrum.cz/wiki/Registrace_do_cloudu_MetaCentra#Pod.C3.A1n.C3.AD_.C5.BE.C3.A1dosti_o_.C4.8Dlenstv.C3.AD_v_MetaCloudu

## MetaCentrum Cloud Setup

Landing page:
https://cloud.muni.cz/

Dashboard:
https://dashboard.cloud.muni.cz

Documentation:
https://cloud.gitlab-pages.ics.muni.cz/documentation/

### VM @ OpenStack

Provisional setup for the instance:
* source: `ubuntu-bionic-x86_64`
  * Delete Volume on Instance Delete: `Yes`
* flavor: `standard.large`

Associate Floating IP:
* IP address from the pool: `public-cesnet-78-128-251`

Connect via SSH:
* `ssh -i <your-keypair-private-key.pem> ubuntu@78.128.250.<personal-number>`
  * NB: The default username for ubuntu image is `ubuntu`.

## ELK Stack Setup

After you have successfully created a virtual machine on OpenStack (MetaCentrum Cloud), let's setup ELK Stack.

### Clone this repo

`git clone https://gitlab.fi.muni.cz/xluptak4/pv177-log-collection-and-analysis.git`

and then
```
Username for 'https://gitlab.fi.muni.cz': <xlogin>
Password for 'https://<xlogin>@gitlab.fi.muni.cz': <secondary password>
```

### Prerequisities

Update the system and install prerequisities:
* run `./init.sh` (file [init.sh](../init.sh) in this repo)

### Config files

Followes https://www.elastic.co/guide/en/logstash/current/advanced-pipeline.html

### Spin it up

See commented [Makefile](../Makefile) for the workflow. Then you only need to run `make`.

### Using screens

List all screens:
`screen -ls`

Re-attach the screen:
`screen -r <screen-name>`, screen name: `ESnode`, `Lnode`, `Fnode`

Detach screen:
Press "Ctrl-A" and "D" in the attached screen.

### Indexing Logs
Create logs directory in your VM:
* `mkdir ~/pv177-log-collection-and-analysis/logs`

Copy logs via SCP (run this command from your computer, not VM, ensure that your instances are started in openstack):
* `scp -i <your-keypair-private-key.pem> /var/log/*.log  ubuntu@<ip-of-your-instance>:~/pv177-log-collection-and-analysis/logs` 

Add this line to `pv177-log-collection-and-analysis/configs/filebeat.yml` , to paths
* `/home/ubuntu/pv177-log-collection-and-analysis/logs/*.log`

* Rerun ELK stack with `make`

### Hints

To check if Elasticsearch is running, run `curl localhost:9200`.

To check if Elasticsearch indexed sample data, run `curl -XGET 'localhost:9200/<logstash-index-name>/_search?pretty&q=geoip.city_name=Buffalo'`, where `<logstash-index-name>` could be found by running `curl 'localhost:9200/_cat/indices?v'`.

Always terminate the instance in OpenStack (policies).

Create snapshot to persist state of your VM.
