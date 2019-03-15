#!/bin/sh

rm -r sources

git clone git@github.com:arjuncr/light-os.git

mkdir sources

cp -r light-os/* sources/

rm -r light-os
