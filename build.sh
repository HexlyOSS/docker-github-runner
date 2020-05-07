#!/bin/bash

# APP_NAME=..  (COMES FROM MAKE FILE)
# APP_VERSION=

docker build debian-buster -t $APP_NAME 
# docker build debian-buster -t $APP_NAME:0.0.1

# docker push $APP_NAME