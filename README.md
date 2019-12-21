# PV177 Log Collection and Analysis

Synopsis: Log Collection and Analysis project for the course PV177 Data Science
in semester Fall 2019.

The goal of this project is to run Elastic Stack as a server in OpenStack that
collect data from Filebeat or Metricbeat running on the host machines and analyze
this data using Kibana.

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

After you have successfully created a virtual machine on OpenStack (MetaCentrum
Cloud), let's set up ELK Stack.

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

For some default configuration, we followed the official getting started guide
available at https://www.elastic.co/guide/en/logstash/current/advanced-pipeline.html.
The configuration files are in [elastic-stack/configs](../elastic-stack/configs)
directory.

### Allow access to Kibana from remote

Enable port 5601 in Openstack, `Network -> Security Groups -> <your-security-group> -> Manage Rules -> Add rule`:

| Option | Value |
| ------ | ------ |
| Rule: | Custom TCP Rule |
| Description: | Kibana |
| Direction: | Ingress |
| Open Port: | Port |
| Port: | **5601** |
| Remote: | CIDR |
| CIDR: | 0.0.0.0/0 |
| Ether Type: | IPv4 |

Now you will be able to access Kibana in your favorite web browser by pointing to
the allocated floating (public) IP address.

### Spin it up

See commented [Makefile](../elastic-stack/Makefile) for the workflow. Then you
only need to run `make` to spin the server part up (runs all targets), or e.g.
`make startup-filebeat` to spin up only Filebeat on the host side.

#### Using screens

Elastic Stack components (Elasticsearch, Logstash, Kibana, and possibly also
Filebeat and Metricbeat) run in separate consoles (so-called screens) on the server.

List all screens:
`screen -ls`

Re-attach the screen:
`screen -r <screen-name>`, screen name: `ESnode`, `Lnode`, `Fnode`, `Knode` or `Mnode`.

Detach screen:
Press "Ctrl-A" and "D" in the attached screen.

Scrolling in the attached screen:
Press "Ctrl-A" and "Esc" in the attached screen.

#### Monitor network traffic in the cluster

To see if there is some traffic between the Elastic Stack components and/or from
host machines to the server, you can use `tcpdump` to show traffic to a specific
port (e.g. 5601 for Kibana):

```
sudo tcpdump port 5601
```

### Indexing Logs

The following step-by-step guide is provided for the clarity (everything is
already included in the Makefile).

1. Install Filebeat locally on your computer

2. In your local `filebeat.yml`, set the following:
   * `paths` to `/var/log/*.log`
   * `hosts` in output.logstash to `["<instanceIp>:5044"]` (comment out output.elasticsearch)
   * `enabled` in inputs to `true`

3. Enable port `5044` for `tcp` connections in OpenStack in `Network -> Security
  Groups -> <your-security-group> -> Manage Rules -> Add rule` (see [Allow access
  to Kibana from remote section](#allow-access-to-kibana-from-remote)) for more details.

4. Run Filebeat on the local machine and Elastic Stack on remote.

5. To check if logging is running correctly: `curl -XGET 'localhost:9200/<logstash-index-name>/_search?pretty&q=*:*'`

NB: you can `cd` into elastic-stack dir and use the Makefile, target `make
startup-filebeat`. To include VM public IP at the execution time, you can use
`make PUBLIC-IP=78.128.250.147 startup-filebeat`, with `78.128.250.147` as an
example.

### Cluster

We followed this tutorial https://logz.io/blog/elasticsearch-cluster-tutorial/.

Enable port `9300` for `tcp` (both ingress and egress) connections in OpenStack
in `Network -> Security Groups -> <your-security-group> -> Manage Rules -> Add rule`
(see [Allow access to Kibana from remote section](#allow-access-to-kibana-from-remote))
for more details.

A cluster consists of `master` and `data` nodes. The only difference between
these two types of nodes is in their configuration files `elasticsearch.yml`.

Ref.: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html

Node configurations are in `elasticsearch-master.yml` and `elasticsearch-data.yml`
files:
* [elastic-stack/configs/elasticsearch-master.yml](../elastic-stack/configs/elasticsearch-master.yml)
* [elastic-stack/configs/elasticsearch-data.yml](../elastic-stack/configs/elasticsearch-data.yml)

###### Config Explanation

```
network.host: [_local_, _site_]
```

`_local_` and `_site_` represent the network in which data nodes are finding master nodes.

```
discovery.seed_hosts: [<master node private addresses>]
```

### Security [NIY]

Security for Elasticsearch is now free (since May 2019) https://www.elastic.co/blog/security-for-elasticsearch-is-now-free.

Getting started with Elasticsearch security https://www.elastic.co/blog/getting-started-with-elasticsearch-security.

Expanded guide https://www.elastic.co/blog/configuring-ssl-tls-and-https-to-secure-elasticsearch-kibana-beats-and-logstash.

Documentation for Elastic Stack security https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-cluster.html.

### Hints

To check if Elasticsearch is running, run `curl localhost:9200`.

To check if Elasticsearch indexed sample data, run `curl -XGET 'localhost:9200/<logstash-index-name>/_search?pretty&q=geoip.city_name=Buffalo'`, where `<logstash-index-name>` could be found by running `curl 'localhost:9200/_cat/indices?v'`.

Always terminate your instances in OpenStack (service policies) -- actually not strictly.

Create a snapshot to persist the state of your VM.
