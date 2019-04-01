#!/bin/sh

rm -r sources

git clone https://github.com/arjuncr/light-os-buildtools.git

mkdir sources

cp -r light-os/* sources/

rm -r light-os
