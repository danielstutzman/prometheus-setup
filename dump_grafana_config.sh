#!/bin/bash -ex
fwknop -s -n monitoring.danstutzman.com
scp root@monitoring.danstutzman.com:/var/lib/grafana/grafana.db grafana.db
echo .dump | sqlite3 grafana.db > grafana.db.txt
echo -e "select data from dashboard order by id;" | sqlite3 grafana.db | python -c "import json, sys; [sys.stdout.write(json.dumps(json.loads(line), indent=2, sort_keys=True) + '\n') for line in sys.stdin]" >> grafana.db.txt
