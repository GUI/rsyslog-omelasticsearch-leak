FROM centos:7

# Install Elasticsearch
RUN yum -y install which java-1.8.0-openjdk-headless
RUN curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && chmod +x /usr/local/bin/wait-for-it
RUN cd /tmp && curl -OL "https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.5/elasticsearch-2.4.5.tar.gz" && tar -xvf elasticsearch-2.4.5.tar.gz

# Install rsyslog
RUN printf '[rsyslog_v8]\nname=Adiscon CentOS-$releasever - local packages for $basearch\nbaseurl=http://rpms.adiscon.com/v8-stable/epel-$releasever/$basearch\nenabled=1\ngpgcheck=0\ngpgkey=http://rpms.adiscon.com/RPM-GPG-KEY-Adiscon\nprotect=1' > /etc/yum.repos.d/rsyslog.repo
RUN yum -y install rsyslog-8.28.0-1.el7 rsyslog-elasticsearch-8.28.0-1.el7
# RUN yum -y install rsyslog-8.27.0-2.el7 rsyslog-elasticsearch-8.27.0-2.el7

COPY rsyslog.conf /tmp/rsyslog.conf
COPY run_test.sh /tmp/run_test.sh
RUN chmod +x /tmp/run_test.sh

CMD /tmp/run_test.sh
