#!/bin/sh

SOURCE="sources"

if [ -d ${SOURCE} ];
then
rm -r $SOURCE
fi

mkdir $SOURCE

git clone https://github.com/arjuncr/light-os.git
 
mv  light-os/* $SOURCE/

rm -r light-os
