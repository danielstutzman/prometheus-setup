#!/bin/bash -ex
fwknop -s -n monitoring.danstutzman.com
ssh root@monitoring.danstutzman.com -L 9090:localhost:9090 -L 9100:localhost:9100 -L 9093:localhost:9093
