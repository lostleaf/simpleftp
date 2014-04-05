ftp  -v 127.0.0.1 12345 <<SCRIPT
cd /var/log
pwd
dir
get kernel.log
SCRIPT

