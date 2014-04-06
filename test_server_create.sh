#!/bin/bash

rm -fr root
ftp -v 127.0.0.1 12345 <<SCRIPT
user
mkdir 123
pwd
dir
cd 123
put README.md
rename README.md readme
SCRIPT

