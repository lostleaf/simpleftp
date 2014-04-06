ftp -a -v 127.0.0.1 12345 <<SCRIPT
cd 123
pwd
dir
get readme
get 456.pdf
SCRIPT

