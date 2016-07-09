#!/bin/bash
#
# File: deploy_a_replica_set_in_one_machine.sh
# Author: Xuancong Lee[congleetea] <lixuancong@molmc.com>
# Created: Wednesday, June 22 2016
#

name_rs=rs0
dbpath_dir=/srv/mongodb
# kill running mongod
# ps -ef | mongod | awk '{print $2}' | xargs sudo kill -9
# # mkdir dbpath dir
# for i in 1,2,3
# do
#   sudo mkdir -p ${dbpath_dir}_${i}
#   sudo mongod --port 27017+i --dbpath ${dbpath_dir}_${i} --replSet $name_rs --smallfiles --oplogSize 128 &
# done
mongo datapoints --eval "show collections;show dbs;"
