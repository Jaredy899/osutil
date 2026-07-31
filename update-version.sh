#!/usr/bin/env bash
# Usage: ./update-version.sh 2.2.2
set -euo pipefail
cd "$(dirname "$0")"
v="${1#v}"

sed -i '' "s/^version = \".*\"/version = \"$v\"/" Cargo.toml
sed -i '' "/name = \"osutil_/,/version = / s/version = \".*\"/version = \"$v\"/" Cargo.lock

git add Cargo.toml Cargo.lock
git commit -m "$v"
git tag "v$v"
git push origin HEAD "v$v"
./build-and-release.sh
