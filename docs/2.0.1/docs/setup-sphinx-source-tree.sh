#!/usr/bin/env bash

set -eou pipefail

DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

RELEASE_TAG=$1
CANTON_RELEASE_TAG=$2
DOWNLOAD_DIR=$3
SPHINX_DIR=$4

mkdir -p $SPHINX_DIR/source/canton
tar xf $DOWNLOAD_DIR/sphinx-source-tree-$RELEASE_TAG.tar.gz -C $SPHINX_DIR --strip-components=1
tar xf $DOWNLOAD_DIR/canton-docs-$CANTON_RELEASE_TAG.tar.gz -C $SPHINX_DIR/source/canton

cp $SPHINX_DIR/source/canton/exts/canton_enterprise_only.py $SPHINX_DIR/configs/static/

# Rewrite absolute references.
find $SPHINX_DIR/source/canton -type f -print0 | while IFS= read -r -d '' file
do
    sed -i 's|include:: /substitution.hrst|include:: /canton/substitution.hrst|g ; s|image:: /images|image:: /canton/images|g' $file
    sed -i "s|__VERSION__|$RELEASE_TAG|g" $file
done
sed -i '/^  concepts$/d' $SPHINX_DIR/source/canton/tutorials/tutorials.rst

# Drop Canton’s index in favor of our own.
rm $SPHINX_DIR/source/canton/index.rst

declare -A sphinx_targets=( [html]=html [pdf]=latex )

sed -i "s/'sphinx.ext.extlinks',$/'sphinx.ext.extlinks','canton_enterprise_only','sphinx.ext.todo',/g" $SPHINX_DIR/configs/html/conf.py
sed -i "s/'sphinx.ext.extlinks'$/'sphinx.ext.extlinks','canton_enterprise_only','sphinx.ext.todo'/g" $SPHINX_DIR/configs/pdf/conf.py

(
cd $DIR/overwrite
for f in $(find . -type f); do
    target=$SPHINX_DIR/source/$f
    mkdir -p $(dirname $target)
    cp $f $target
done
)
