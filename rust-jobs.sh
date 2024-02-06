#!/bin/sh
(
    # number of cpu
    nproc
    # available GiB
    free -g | awk '{ print $7 }' | grep -v ^$
) |
# at least one job
sed -e 's/^0/1/' |
# return the minimum
sort -n | head -1
