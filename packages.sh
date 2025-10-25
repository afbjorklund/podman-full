#!/bin/sh

while read -r package version repository; do
  package=$(echo "$package" | sed -e 's/\.x86_64$//' | sed -e ';s/^podman\-//')
  version=$(echo "$version" | sed -e 's/^.*\://;s/\-.*$//')
  if [ "$package" = "passt" ]; then
	version=$(echo "$version" | sed -e 's/^0\^\(....\)\(..\)\(..\)\.g\(.......\)/\1_\2_\3.\4/')
  fi
  _="$repository"
  printf "%s\t%s\n" "$package" "$version"
done
