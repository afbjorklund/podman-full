#!/bin/sh
machine=$(uname -m)
case $machine in
    x86_64 |amd64)	echo "amd64";;
    aarch64|arm64)	echo "arm64";;
    *)			echo "$machine"
esac
