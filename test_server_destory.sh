#! /bin/bash
ftp -v 127.0.0.1 12345 <<SCRIPT
user
cd 123
size readme
modtime readme
get readme
delete readme
cd ..
rmdir 123
SCRIPT

