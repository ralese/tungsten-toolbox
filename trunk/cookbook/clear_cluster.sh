#!/bin/bash
# (C) Copyright 2012,2013 Continuent, Inc - Released under the New BSD License
# Version 1.0.4 - 2013-03-07

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

. ./cookbook/BOOTSTRAP.sh $NODES

WANTED_TOPOLOGY=$2
if [ -z "$WANTED_TOPOLOGY" ]
then
    echo unable to determine which topology is required
    exit 1
fi

check_current_topology $WANTED_TOPOLOGY

are_you_sure_you_want_to_clear

MYSQL="mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -P $DATABASE_PORT"
for NODE in ${ALL_NODES[*]} 
do 
    if [ "$STOP_REPLICATORS" == "1" ]
    then
        ssh $NODE "if [ -x $REPLICATOR ] ; then $REPLICATOR stop;  fi" 
    fi
    if [ "$REMOVE_TUNGSTEN_BASE" == "1" ]
    then
        ssh $NODE rm -rf $TUNGSTEN_BASE/*
    fi  
    if [ "$REMOVE_SERVICE_SCHEMA" == "1" ]
    then
        for D in $($MYSQL -h $NODE -BN -e 'show schemas like "tungsten%"' )
        do
            $MYSQL -h $NODE -e "drop schema $D"
        done
    fi
    if [ "$REMOVE_TEST_SCHEMAS" == "1" ]
    then
        $MYSQL -h $NODE -e 'drop schema if exists test'
        $MYSQL -h $NODE -e 'drop schema if exists evaluator'
    fi
    if [ "$REMOVE_DATABASE_CONTENTS" == "1" ]
    then
        for D in $($MYSQL -h $NODE -BN -e 'show schemas ' | grep -v -w 'mysql\|information_schema\|performance_schema'  )
        do
            $MYSQL -h $NODE -e "drop schema $D"
        done
    fi
    if [ "$CLEAN_NODE_DATABASE_SERVER" == "1" ]
    then
        $MYSQL -h $NODE -e 'create schema if not exists test'
        $MYSQL -h $NODE -e 'set global read_only=0'
        $MYSQL -h $NODE -e 'set global binlog_format=mixed'
        $MYSQL -h $NODE -e 'reset master'
    fi
    ssh $NODE "if [ -f $TUNGSTEN_BASE/tungsten/CURRENT_TOPOLOGY ] ; then rm -f $TUNGSTEN_BASE/tungsten/CURRENT_TOPOLOGY ; fi"
done

[ -f $INSTALL_LOG ] && rm -f $INSTALL_LOG
[ -f $CURRENT_TOPOLOGY ] && rm -f $CURRENT_TOPOLOGY