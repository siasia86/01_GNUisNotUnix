#!/usr/bin/bash
## 20210730_sjadd

set -xe

DATE=$(date +%Y%m%d);


ES_CONF=/etc/elasticsearch/elasticsearch.yml
LS_CONF=/etc/logstash/logstash.yml
KB_CONF=/etc/kibana/kibana.yml
FB_CONF=/etc/filebeat/filebeat.yml
NX_CONF=/etc/nginx/nginx.conf

BK_DIR=/backup/ORG
BK_DIR2=/backup/masang/log
mkdir -p ${BK_DIR}
mkdir -p ${BK_DIR2}
install="sudo apt-get install -y"
IP_CONF=10.200.90.154

# ----------------------------------------------------------------------

apt update -y
apt upgrade -y

# prerequirements
${install} apt-transport-https curl gnupg2 wget net-tools
#${install} openjdk-11-jre:amd64
${install} openjdk-17-jre:amd64


## elasticsearch
#wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch \
#		| sudo apt-key add -
#echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" \
#| sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

##########################################################################

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
		| sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
		https://artifacts.elastic.co/packages/8.x/apt stable main" \
		| sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt-get update

${install} elasticsearch

#########################################################################
if [ -f "${ES_CONF}" ] ;
then
		sudo cp -a ${ES_CONF} ${ES_CONF}_ORG_${DATE}
else
		echo "${ES_CONF} not exists."
fi
#########################################################################

sudo sed -i "s/^#http.port.*/http.port: 9200/" ${ES_CONF}
sudo sed -i "s/^#network.host.*/network.host: localhost/" ${ES_CONF}

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
sudo systemctl status elasticsearch.service


## logstash
${install} logstash
# starting
sudo systemctl daemon-reload
sudo systemctl enable logstash.service
sudo systemctl restart logstash.service
sudo systemctl status logstash.service

#########################################################################
if [ -f "${LS_CONF}" ] ;
then
		sudo cp -a ${LS_CONF} ${LS_CONF}_ORG_${DATE}
		#sudo cp -a ${LS_CONF} ${BK_DIR}/${LS_CONF}_ORG_${DATE}
else
		echo "${LS_CONF} not exists."
fi
#########################################################################
#
#cat |sudo tee /etc/logstash/conf.d/02-beats-input.conf >/dev/null <<EOF
## input.conf
#input {
#  beats {
#	port => 5044
#  }
#}
#EOF
#
#
#cat |sudo tee /etc/logstash/conf.d/30-elasticsearch-output.conf >/dev/null <<EOF
## output.conf
#output {
#  if [@metadata][pipeline] {
#	elasticsearch {
#	hosts => ["localhost:9200"]
#	manage_template => false
#	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
#	pipeline => "%{[@metadata][pipeline]}"
#	}
#  } else {
#	elasticsearch {
#	hosts => ["localhost:9200"]
#	manage_template => false
#	index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
#	}
#  }
#}
#EOF
#
#########################################################################


cat |sudo tee /etc/logstash/conf.d/01-beats-input-output.conf >/dev/null <<EOF
## input
input {
  beats {
		#path => "/var/log/utm.log"
		port => 5044
  }
}

## output
output {
	elasticsearch {
	hosts => "localhost:9200"
	index => "%{[fields][log_type]}-%{+YYYY.MM.dd}"
	#index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
	}
}
EOF

#########################################################################



## filebeat
${install} filebeat
# starting
sudo systemctl daemon-reload
sudo systemctl enable filebeat.service
sudo systemctl restart filebeat.service
sudo systemctl status filebeat.service

#########################################################################
if [ -f "${FB_CONF}" ] ;
then
		sudo cp -a ${FB_CONF} ${FB_CONF}_ORG_${DATE}
		#sudo cp -a ${KB_CONF} ${BK_DIR}/${KB_CONF}_ORG_${DATE}
else
		echo "${FB_CONF} not exists."
fi
#########################################################################


## kibana
${install} kibana
# starting
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl restart kibana.service
sudo systemctl status kibana.service

#########################################################################
if [ -f "${KB_CONF}" ] ;
then
		sudo cp -a ${KB_CONF} ${KB_CONF}_ORG_${DATE}
		#sudo cp -a ${KB_CONF} ${BK_DIR}/${KB_CONF}_ORG_${DATE}
else
		echo "${KB_CONF} not exists."
fi
#########################################################################

sudo sed -i "s/^#server.port.*/server.port: 5601/" ${KB_CONF}
sudo sed -i "s/^#server.host.*/server.host: \"${IP_CONF}\"/" ${KB_CONF}


## nginx
${install} nginx

cat |sudo tee /etc/nginx/sites-available/ELK.conf >/dev/null <<EOF
# nginx config
server {
  listen	  80 default_server;
  listen	  [::]:80 default_server ipv6only=on;
  server_name ${IP_CONF} logger.example.com;

#  location /api/ {
#	proxy_set_header	Host \$http_host;
#	proxy_set_header	X-Forwarded-Host \$host;
#	proxy_set_header	X-Forwarded-Server \$host;
#	proxy_set_header	X-Forwarded-For \$proxy_add_x_forwarded_for;
#	proxy_pass		  http://${IP_CONF}:12900/;
#  }

  location / {
	proxy_set_header	Host \$http_host;
	proxy_set_header	X-Forwarded-Host \$host;
	proxy_set_header	X-Forwarded-Server \$host;
	proxy_set_header	X-Forwarded-For \$proxy_add_x_forwarded_for;
	proxy_set_header	X-Graylog-Server-URL http://\$server_name;
	#proxy_set_header	X-Graylog-Server-URL http://logger.example.com/api;
	proxy_pass		  http://${IP_CONF}:5601;
  }
}
EOF

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/ELK.conf /etc/nginx/sites-enabled/


sudo systemctl daemon-reload
sudo systemctl enable nginx.service
sudo systemctl restart nginx.service
sudo systemctl status nginx.service


#########################################################################
if [ -f "${NX_CONF}" ] ;
then
		sudo cp -a ${NX_CONF} ${NX_CONF}_ORG_${DATE}
else
		echo "${NX_CONF} not exists."
fi
#########################################################################



echo "install end."
