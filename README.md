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

After you have successfully created a virtual machine on OpenStack (MetaCentrum Cloud), let's set up ELK Stack.

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

Follows https://www.elastic.co/guide/en/logstash/current/advanced-pipeline.html

### Allow access to Kibana from remote

Enable port 5601 in Openstack: `Network -> Security Groups -> <your-security-group> -> Manage Rules -> Add rule`

* Rule: Custom TCP Rule
* Description: Kibana
* Direction: Ingress
* Open Port: Port
* Port: 5601
* Remote: CIDR
* CIDR: 0.0.0.0/0
* Ether Type: IPv4

### Spin it up

See commented [Makefile](../Makefile) for the workflow. Then you only need to run `make`.

### Using screens

List all screens:
`screen -ls`

Re-attach the screen:
`screen -r <screen-name>`, screen name: `ESnode`, `Lnode`, `Fnode`

Detach screen:
Press "Ctrl-A" and "D" in the attached screen.

Scrolling in the attached screen:
Press "Ctrl-A" and "Esc" in the attached screen.

### Indexing Logs

* Install Filebeat locally on your computer

* In your local `filebeat.yml` set: 
   * `paths` to `/var/log/*.log`
   * `hosts` in output.logstash to `["<instanceIp>:5044"]` (comment out output.elasticsearch)
   * `enabled` in inputs to `true`

* In openstack enable port `5044` for `tcp` connections in `Network->Security Groups -> Manage Rules -> Add rule`

* Run Filebeat on the local machine and elk stack on remote

* To check if logging is running correctly : `curl -XGET 'localhost:9200/<logstash-index-name>/_search?pretty&q=*:*'`

NB: you can `cd` into client dir and use the Makefile, target `make
startup-filebeat`. To include VM public IP at the execution time, you can use
`make PUBLIC-IP=78.128.250.147 startup-filebeat`, with `78.128.250.147` as an
example.

### Cluster

* https://logz.io/blog/elasticsearch-cluster-tutorial/

In openstack enable port `9300` for `tcp` (bouth ingress and egress) connections in `Network->Security Groups -> Manage Rules -> Add rule` 

A cluster consists of `master` and `data` nodes. The only difference between these two types of nodes is in their configuration files `elasticsearch.yml`.
* https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html

Nodes are configurated in  elastic-stack\configs\elasticsearch-master.yml and elastic-stack\configs\elasticsearch-data.yml 
* [elastic-stack/configs/elasticsearch-master.yml](../elastic-stack/configs/elasticsearch-master.yml)
* [elastic-stack/configs/elasticsearch-data.yml](../elastic-stack/configs/elasticsearch-data.yml)

###### Config Explanation

network.host: `[_local_, _site_]`

`_local_` and `_site_` represents the network in which data nodes are finding master nodes.

discovery.seed_hosts: `[master node private addresses]`

### Hints

To check if Elasticsearch is running, run `curl localhost:9200`.

To check if Elasticsearch indexed sample data, run `curl -XGET 'localhost:9200/<logstash-index-name>/_search?pretty&q=geoip.city_name=Buffalo'`, where `<logstash-index-name>` could be found by running `curl 'localhost:9200/_cat/indices?v'`.

Always terminate the instance in OpenStack (policies).

Create a snapshot to persist the state of your VM.
