#!/bin/bash -ex

INSTANCE_IP=`tugboat droplets | grep 'monitoring ' | egrep -oh "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" || true`
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -P 2222 root@$INSTANCE_IP:/var/lib/grafana/grafana.db grafana.db
echo .dump | sqlite3 grafana.db > grafana.db.txt
echo -e "select data from dashboard order by id;" | sqlite3 grafana.db | python -c "import json, sys; [sys.stdout.write(json.dumps(json.loads(line), indent=2, sort_keys=True) + '\n') for line in sys.stdin]" >> grafana.db.txt
