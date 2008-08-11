#!/bin/bash
if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` path_to_zipped_release"
  exit 1
fi  

openssl dgst -sha1 -binary < $1 \
    | openssl dgst -dss1 -sign dsa_priv.pem \
    | openssl enc -base64 
