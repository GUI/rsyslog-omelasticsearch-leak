# rsyslog omelasticsearch memory leak

This is a test environment to demonstrate some leaks in rsyslog's omelasticsearch module with some specific settings (see [bug report](https://github.com/rsyslog/rsyslog/issues/1668)). This script will send a number of messages to rsyslogd and then print out the memory usage.

To run with Docker:

```sh
$ docker build -t rsyslog_test .
$ docker run rsyslog_test
```

## Summary

- [v8.28.0 `bulkId`: enabled, `errorfile`: enabled](#v8280-bulkid-enabled-errorfile-enabled): Leaks
- [v8.28.0 `bulkId`: enabled, `errorfile`: disabled](#v8280-bulkid-enabled-errorfile-disabled): No leak
- [v8.28.0 `bulkId`: disabled, `errorfile`: enabled](#v8280-bulkid-disabled-errorfile-enabled): No leak
- [v8.27.0 `bulkId`: enabled, `errorfile`: enabled](#v8270-bulkid-enabled-errorfile-enabled): No leak

## v8.28.0 `bulkId`: enabled, `errorfile`: enabled

Leaks memory (note the RSS size going up on each iteration):

```
rsyslogd 8.28.0.master, compiled with:
	PLATFORM:				x86_64-redhat-linux-gnu
	PLATFORM (lsb_release -d):		
	FEATURE_REGEXP:				Yes
	GSSAPI Kerberos 5 support:		No
	FEATURE_DEBUG (debug build, slow code):	No
	32bit Atomic operations supported:	Yes
	64bit Atomic operations supported:	Yes
	memory allocator:			system default
	Runtime Instrumentation (slow code):	No
	uuid support:				Yes
	Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.


rsyslog.conf:

module(load="omelasticsearch")
module(load="imtcp" MaxSessions="500")
input(type="imtcp" address="127.0.0.1" port="9999")

template(name="testTemplate" type="list" option.json="on") {
  constant(value="{")
  constant(value="\"timestamp\":\"")      property(name="timereported" dateFormat="rfc3339")
  constant(value="\",\"message\":\"")     property(name="msg")
  constant(value="\",\"host\":\"")        property(name="hostname")
  constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
  constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
  constant(value="\",\"syslogtag\":\"")   property(name="syslogtag")
  constant(value="\"}")
}
template(name="testIdTemplate" type="string" string="%syslogtag%")

local0.info action(
  name="output-elasticsearch"
  type="omelasticsearch"
  server="127.0.0.1"
  serverport="9200"
  searchIndex="test-index"
  searchType="log"
  template="testTemplate"
  bulkmode="on"
  bulkId="testIdTemplate"
  dynBulkId="on"
  errorfile="/tmp/elasticsearch_error.log"
)


rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  0.0  0.2 187816  5052 ?        Ssl  23:03   0:00 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (1) ==

Elasticsearch count:
epoch      timestamp count 
1500073437 23:03:57  9863  

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105 10.5  1.0 393088 20628 ?        Ssl  23:03   0:01 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (2) ==

Elasticsearch count:
epoch      timestamp count 
1500073451 23:04:11  19776 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  9.9  1.5 393088 31872 ?        Ssl  23:03   0:03 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (3) ==

Elasticsearch count:
epoch      timestamp count 
1500073465 23:04:25  29499 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  9.2  1.9 393088 40584 ?        Ssl  23:03   0:04 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (4) ==

Elasticsearch count:
epoch      timestamp count 
1500073478 23:04:38  39343 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  9.0  2.3 393088 49032 ?        Ssl  23:03   0:05 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (5) ==

Elasticsearch count:
epoch      timestamp count 
1500073491 23:04:51  49466 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  8.8  2.8 393088 58004 ?        Ssl  23:03   0:06 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid
```

## v8.28.0 `bulkId`: enabled, `errorfile`: disabled

Does not leak memory:

```
rsyslogd 8.28.0.master, compiled with:
	PLATFORM:				x86_64-redhat-linux-gnu
	PLATFORM (lsb_release -d):		
	FEATURE_REGEXP:				Yes
	GSSAPI Kerberos 5 support:		No
	FEATURE_DEBUG (debug build, slow code):	No
	32bit Atomic operations supported:	Yes
	64bit Atomic operations supported:	Yes
	memory allocator:			system default
	Runtime Instrumentation (slow code):	No
	uuid support:				Yes
	Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.


rsyslog.conf:

module(load="omelasticsearch")
module(load="imtcp" MaxSessions="500")
input(type="imtcp" address="127.0.0.1" port="9999")

template(name="testTemplate" type="list" option.json="on") {
  constant(value="{")
  constant(value="\"timestamp\":\"")      property(name="timereported" dateFormat="rfc3339")
  constant(value="\",\"message\":\"")     property(name="msg")
  constant(value="\",\"host\":\"")        property(name="hostname")
  constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
  constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
  constant(value="\",\"syslogtag\":\"")   property(name="syslogtag")
  constant(value="\"}")
}
template(name="testIdTemplate" type="string" string="%syslogtag%")

local0.info action(
  name="output-elasticsearch"
  type="omelasticsearch"
  server="127.0.0.1"
  serverport="9200"
  searchIndex="test-index"
  searchType="log"
  template="testTemplate"
  bulkmode="on"
  bulkId="testIdTemplate"
  dynBulkId="on"
  # errorfile="/tmp/elasticsearch_error.log"
)


rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  0.0  0.2 187816  5056 ?        Ssl  23:06   0:00 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (1) ==

Elasticsearch count:
epoch      timestamp count 
1500073598 23:06:38  9579  

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  9.8  0.6 393076 12548 ?        Ssl  23:06   0:01 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (2) ==

Elasticsearch count:
epoch      timestamp count 
1500073613 23:06:53  19847 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  9.2  0.7 393076 15084 ?        Ssl  23:06   0:02 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (3) ==

Elasticsearch count:
epoch      timestamp count 
1500073625 23:07:05  29472 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  8.6  0.7 393076 15084 ?        Ssl  23:06   0:03 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (4) ==

Elasticsearch count:
epoch      timestamp count 
1500073638 23:07:18  39521 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  8.5  0.7 393076 15084 ?        Ssl  23:06   0:04 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (5) ==

Elasticsearch count:
epoch      timestamp count 
1500073650 23:07:30  49259 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       105  8.2  0.7 393076 15344 ?        Ssl  23:06   0:05 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid
```

## v8.28.0 `bulkId`: disabled, `errorfile`: enabled

Does not leak memory:

```
rsyslogd 8.28.0.master, compiled with:
	PLATFORM:				x86_64-redhat-linux-gnu
	PLATFORM (lsb_release -d):		
	FEATURE_REGEXP:				Yes
	GSSAPI Kerberos 5 support:		No
	FEATURE_DEBUG (debug build, slow code):	No
	32bit Atomic operations supported:	Yes
	64bit Atomic operations supported:	Yes
	memory allocator:			system default
	Runtime Instrumentation (slow code):	No
	uuid support:				Yes
	Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.


rsyslog.conf:

module(load="omelasticsearch")
module(load="imtcp" MaxSessions="500")
input(type="imtcp" address="127.0.0.1" port="9999")

template(name="testTemplate" type="list" option.json="on") {
  constant(value="{")
  constant(value="\"timestamp\":\"")      property(name="timereported" dateFormat="rfc3339")
  constant(value="\",\"message\":\"")     property(name="msg")
  constant(value="\",\"host\":\"")        property(name="hostname")
  constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
  constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
  constant(value="\",\"syslogtag\":\"")   property(name="syslogtag")
  constant(value="\"}")
}
template(name="testIdTemplate" type="string" string="%syslogtag%")

local0.info action(
  name="output-elasticsearch"
  type="omelasticsearch"
  server="127.0.0.1"
  serverport="9200"
  searchIndex="test-index"
  searchType="log"
  template="testTemplate"
  bulkmode="on"
  # bulkId="testIdTemplate"
  # dynBulkId="on"
  errorfile="/tmp/elasticsearch_error.log"
)


rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  0.0  0.2 187816  5028 ?        Ssl  23:08   0:00 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (1) ==

Elasticsearch count:
epoch      timestamp count 
1500073704 23:08:24  9457  

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  9.7  0.6 393076 12468 ?        Ssl  23:08   0:01 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (2) ==

Elasticsearch count:
epoch      timestamp count 
1500073717 23:08:37  19533 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  9.2  0.7 393076 14944 ?        Ssl  23:08   0:02 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (3) ==

Elasticsearch count:
epoch      timestamp count 
1500073730 23:08:50  29609 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.6  0.7 393076 14944 ?        Ssl  23:08   0:03 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (4) ==

Elasticsearch count:
epoch      timestamp count 
1500073743 23:09:03  39445 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.4  0.7 393076 14944 ?        Ssl  23:08   0:04 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (5) ==

Elasticsearch count:
epoch      timestamp count 
1500073756 23:09:16  49722 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.2  0.7 393076 15204 ?        Ssl  23:08   0:05 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid
```

## v8.27.0 `bulkId`: enabled, `errorfile`: enabled

Does not leak memory:

```
rsyslogd 8.27.0, compiled with:
	PLATFORM:				x86_64-redhat-linux-gnu
	PLATFORM (lsb_release -d):		
	FEATURE_REGEXP:				Yes
	GSSAPI Kerberos 5 support:		No
	FEATURE_DEBUG (debug build, slow code):	No
	32bit Atomic operations supported:	Yes
	64bit Atomic operations supported:	Yes
	memory allocator:			system default
	Runtime Instrumentation (slow code):	No
	uuid support:				Yes
	Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.


rsyslog.conf:

module(load="omelasticsearch")
module(load="imtcp" MaxSessions="500")
input(type="imtcp" address="127.0.0.1" port="9999")

template(name="testTemplate" type="list" option.json="on") {
  constant(value="{")
  constant(value="\"timestamp\":\"")      property(name="timereported" dateFormat="rfc3339")
  constant(value="\",\"message\":\"")     property(name="msg")
  constant(value="\",\"host\":\"")        property(name="hostname")
  constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
  constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
  constant(value="\",\"syslogtag\":\"")   property(name="syslogtag")
  constant(value="\"}")
}
template(name="testIdTemplate" type="string" string="%syslogtag%")

local0.info action(
  name="output-elasticsearch"
  type="omelasticsearch"
  server="127.0.0.1"
  serverport="9200"
  searchIndex="test-index"
  searchType="log"
  template="testTemplate"
  bulkmode="on"
  bulkId="testIdTemplate"
  dynBulkId="on"
  errorfile="/tmp/elasticsearch_error.log"
)


rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  0.0  0.2 187816  5008 ?        Ssl  23:09   0:00 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (1) ==

Elasticsearch count:
epoch      timestamp count 
1500073808 23:10:08  9781  

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106 10.0  0.6 393076 12712 ?        Ssl  23:09   0:01 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (2) ==

Elasticsearch count:
epoch      timestamp count 
1500073822 23:10:22  19806 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  9.3  0.7 393076 15284 ?        Ssl  23:09   0:02 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (3) ==

Elasticsearch count:
epoch      timestamp count 
1500073836 23:10:36  29293 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.7  0.7 393076 15284 ?        Ssl  23:09   0:03 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (4) ==

Elasticsearch count:
epoch      timestamp count 
1500073849 23:10:49  39778 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.5  0.7 393076 15284 ?        Ssl  23:09   0:04 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid


== Generating log data (5) ==

Elasticsearch count:
epoch      timestamp count 
1500073862 23:11:02  49794 

rsyslogd memory use:
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       106  8.3  0.7 393076 15544 ?        Ssl  23:09   0:05 rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid
```
