#!/bin/bash
# (C) Copyright 2012 Continuent, Inc - Released under the New BSD License
# Version 1.0.3 - 2012-11-19

NODES=$1
if [ -z "$NODES" ]
then
    echo "We need a NODES file to work with"
    exit 1
fi

if [ ! -f ./cookbook/BOOTSTRAP.sh ]
then
    echo "./cookbook/BOOTSTRAP.sh not found"
    exit 1
fi

if [ ! -f ./cookbook/utilities.sh ]
then
    echo "./cookbook/utilities.sh not found"
    exit 1
fi

. ./cookbook/BOOTSTRAP.sh $NODES
. ./cookbook/utilities.sh 

fill_roles

for NODE in ${MASTERS[*]}
do
    SERVICE=$($TREPCTL -host $NODE services |$SIMPLE_SERVICES -r master -a list)
    $TREPCTL -host $NODE -service $SERVICE heartbeat
done

for NODE in ${ALL_NODES[*]}
do
    echo "# node $NODE"
    $TREPCTL -host $NODE services | $SIMPLE_SERVICES
done