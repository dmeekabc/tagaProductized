#!/bin/bash
#######################################################################
#
# Copyright (c) IBOA Corp 2016
#
# All Rights Reserved
#                                                                     
# Redistribution and use in source and binary forms, with or without  
# modification, are permitted provided that the following conditions 
# are met:                                                             
# 1. Redistributions of source code must retain the above copyright    
#    notice, this list of conditions and the following disclaimer.     
# 2. Redistributions in binary form must reproduce the above           
#    copyright notice, this list of conditions and the following       
#    disclaimer in the documentation and/or other materials provided   
#    with the distribution.                                            
#                                                                      
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS   
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED    
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE   
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE     
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR  
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT    
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR   
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF           
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT            
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE    
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH     
# DAMAGE.                                                              
#
#######################################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

NAME=`basename $0`
IPPART=`$iboaUtilsDir/iboa_padded_echo.sh $MYIP $IP_PAD_LEN`
NAMEPART=`$iboaUtilsDir/iboa_padded_echo.sh $NAME $NAME_PAD_LEN`
echo "$IPPART : $NAMEPART : executing at `date`"

#echo $MYIP : `basename $0` : executing at `date`
#NAME=`basename $0`
#echo $MYIP : `basename $0` :  executing at `date`
#echo "`$iboaUtilsDir/iboa_padded_echo.sh $MYIP:..$NAME 30` : executing at `date`"
#echo "`$iboaUtilsDir/iboa_padded_echo.sh $MYIP:..$NAME $SCRIPT_HDR_PAD_LEN` : executing at `date`"

# sample simulations require $HOME/python dir
mkdir $HOME/python 2>/dev/null

# if started with flag then use it
if [ $# -eq 1 ]; then
  echo creating /tmp/simulationFlag.txt with 1 flag set to: $1
  # override the value from the config
  let MAX_ENVIRON_SIM_LOOPS=1
  echo $1 > /tmp/simulationFlag.txt
fi


#####################################
# SIMULATE FUNCTION
#####################################

function doSimulate {

  myinterface=$INTERFACE

  let CONFIG_DELAY=10

  #for myiter in 1 2 3 4 5 
  #for myiter in 1 2
  for myiter in 1 
  do

    echo $myinterface going down... 
    sudo /sbin/ifconfig $myinterface down
    sleep $CONFIG_DELAY

    echo $myinterface going up... 
    sudo /sbin/ifconfig $myinterface up <$TAGA_CONFIG_DIR/passwd.txt
    sleep $CONFIG_DELAY

  done
}

################################################3
# MAIN 
################################################3

# One Time / Single Operation Invocations

# cleanup old processes, resources, sockets and such
rm $OLDPROCFILE1 2>/dev/null 
rm $OLDPROCFILE2 2>/dev/null
rm $OLDPROCFILE3 2>/dev/null

# start the server

# starting of servers moved external, note the cleanup above is still vital on each node
if [ $PRIMARY_SIM_SERVER_ON -eq 1 ]; then

   echo $MYIP : `basename $0` : Primary Simulation Server Enabled 

   # start the primary sim server

   PRIMARY_SERVER_STARTCMD="$PRIMARY_SERVER_COMMAND --log-level=debug --log=/tmp/$PRIMARY_SERVER_COMMAND.log"
   $PRIMARY_SERVER_STARTCMD &

else
   #echo $MYIP : `basename $0` : Primary Simulation Server Disabled 
   #echo "`$iboaUtilsDir/iboa_padded_echo.sh $MYIP:..$NAME 30` : primary sim server disabled at `date`"
   CMDPART=`$iboaUtilsDir/iboa_padded_echo.sh PrimarySimServer $CMD_PAD_LEN`
   echo "$IPPART : $NAMEPART : disabled $CMDPART at `date`"
fi

# start the other optional servers
$tagaScriptsSimDir/simulatePubSub.sh <$TAGA_CONFIG_DIR/passwd.txt &
$tagaScriptsSimDir/simulateXXX.sh    <$TAGA_CONFIG_DIR/passwd.txt &
$tagaScriptsSimDir/simulateSIM1.sh   <$TAGA_CONFIG_DIR/passwd.txt &


################################################3
# Main Init
################################################3
let i=$MAX_ENVIRON_SIM_LOOPS
if [ $i -eq 0 ]; then
  #echo $0 exiting since ENVIRON environ simulationFlag is disabled 
  exit
fi

################################################3
# MAIN LOOP
################################################3
while true
do

  # assume no simulation (assume sim flag = 0)
  # touch sim flag in case it is not there 
  touch /tmp/simulationFlag.txt

  # get simulation flag from the master
  scp $MYLOGIN_ID@$MASTER:/tmp/simulationFlag.txt /tmp >/dev/null 2>/dev/null

  MYFLAG=`cat /tmp/simulationFlag.txt`
  if [ $MYFLAG -eq 1 ] ; then

    # open loop
    echo `date` $MYIP ENVIRON simulation in progress
    echo $MYIP ENVIRON Simulation In Progress... > /tmp/simulation.out
    echo $MYIP my master is $MASTER  >> /tmp/simulation.out

    #############################################
    # Do the simulation
    #############################################
    doSimulate

    # close loop
    echo `date` $MYIP ENVIRON simulation in progress
    echo `date` $MYIP ENVIRON simulation in progress >>/tmp/simulation.out
    sleep 5

  else
   echo `basename $0` exiting since ENVIRON environ simulationFlag is disabled
   exit
  fi

  let i=$i-1
  if [ $i -eq 0 ]; then
   echo `basename $0` exiting since max simulation loops achieved
   exit
  fi

done
