#!/usr/bin/env bash
set -euo pipefail

into=${1:?deliver-deb.sh: name a directory to deliver the packages into}
version=${VERSION:?deliver-deb.sh: name the VERSION}

: "${ROOT_DIR:?deliver-deb.sh: name the ROOT_DIR}"

build=$ROOT_DIR/build/package/deb
rm -rf "$build"
mkdir -p "$build"

cp -a "$ROOT_DIR/src" "$build/source"
cp "$ROOT_DIR/README.md" "$build/source/README.md"
"$ROOT_DIR/scripts/packaging.sh" "$build/source"
sed -i "1s/(.*)/($version)/" "$build/source/debian/changelog"

env -C "$build/source" dpkg-buildpackage -us -uc

lintian --fail-on error,warning,info,pedantic,experimental --display-level '>=pedantic' "$build"/*.changes
echo "ok: lintian passes on the source and on every package, down to pedantic"

mkdir -p "$into"
into=$(realpath "$into")

rm -f -- "$into"/*.deb "$into"/Packages "$into"/Release
cp "$build"/*.deb "$into"
env -C "$into" apt-ftparchive packages . > "$into/Packages"
env -C "$into" apt-ftparchive release . > "$build/Release"
mv "$build/Release" "$into/Release"

echo "$(find "$into" -name '*.deb' | wc -l) packages built and indexed in $into"
