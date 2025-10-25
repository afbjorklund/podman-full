#!/bin/sh

while read -r arg package version repository; do
  package=$(echo "$package" | sed -e 's/_VERSION$//' | tr "A-Z_" "a-z-" | sed -e 's/go/golang/')
  version=$(echo "$version" | sed -e 's/^v//')
  if [ "$package" = "debian" ]; then
	  continue
  fi
  _="$arg"
  printf "%s\t%s\n" "$package" "$version"
done
