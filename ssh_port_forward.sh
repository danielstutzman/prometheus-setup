#!/bin/bash -ex
tugboat ssh monitoring -o "-L 9090:localhost:9090 -L 9100:localhost:9100"
