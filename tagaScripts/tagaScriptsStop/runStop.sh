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

MYLOCALLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $MYIP | tail -n 1`
MYLOCALLOGIN_ID=`echo $MYLOCALLOGIN_ID`

# stop the simulations
for target in $targetList
do

   # resource
   TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
   source $TAGA_CONFIG_DIR/config

   # determine LOGIN ID for each target
   MYLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $target | tail -n 1`
   # dlm temp , I have no clue why this is needed but it is...
   MYLOGIN_ID=`echo $MYLOGIN_ID` 

   COMMAND_TO_RUN=$tagaScriptsStopDir/simulateStop.sh     
   COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/$MYLOCALLOGIN_ID/MYLOGIN_ID/g`
   COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/MYLOGIN_ID/$MYLOGIN_ID/g`

   if echo $BLACKLIST | grep $target >/dev/null ; then
      echo The $target is in the black list, skipping...
      continue
   else
      echo `basename $0` processing $target
     if [ $STOP_SIMULATION -eq 1 ] ; then
       #echo STOP simulation processing on $target
       #ssh -l $MYLOGIN_ID $target $tagaScriptsStopDir/simulateStop.sh     & 
       ssh -l $MYLOGIN_ID $target $COMMAND_TO_RUN  & 
     else
       echo NOT STOPING simulation processing on $target
     fi
   fi
done

# stop everything else
# note, this used to be the stopAll.sh script which is now OBE

for target in $targetList
do

   # resource
   TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
   source $TAGA_CONFIG_DIR/config

   # determine LOGIN ID for each target
   MYLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $target | tail -n 1`
   # dlm temp , I have no clue why this is needed but it is...
   MYLOGIN_ID=`echo $MYLOGIN_ID` 

   COMMAND_TO_RUN=$tagaScriptsStopDir/stop.sh     
   COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/$MYLOCALLOGIN_ID/MYLOGIN_ID/g`
   COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/MYLOGIN_ID/$MYLOGIN_ID/g`

   if echo $BLACKLIST | grep $target >/dev/null ; then
      echo The $target is in the black list, skipping...
      continue
   elif [ $target == $MYIP ]; then
      echo skipping self for now...
      continue
   fi

   echo processing, cleaning $target
   #ssh -l $MYLOGIN_ID $target $tagaScriptsStopDir/stop.sh $1 <$TAGA_CONFIG_DIR/passwd.txt
   ssh -l $MYLOGIN_ID $target $COMMAND_TO_RUN $1 <$TAGA_CONFIG_DIR/passwd.txt
done

# do myself last

# resource
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

# determine LOGIN ID for myself
MYLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $MYIP | tail -n 1`
# dlm temp , I have no clue why this is needed but it is...
MYLOGIN_ID=`echo $MYLOGIN_ID` 

COMMAND_TO_RUN=$tagaScriptsStopDir/stop.sh     
COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/$MYLOCALLOGIN_ID/MYLOGIN_ID/g`
COMMAND_TO_RUN=`echo $COMMAND_TO_RUN | sed -e s/MYLOGIN_ID/$MYLOGIN_ID/g`

# do not use scp if target == MYIP and local mode flag set
if cat $TAGA_LOCAL_MODE_FLAG_FILE 2>/dev/null | grep 1 >/dev/null ; then
   if [ $target == $MYIP ]; then
      echo processing, cleaning $MYIP
      $tagaScriptsStopDir/stop.sh $1 <$TAGA_CONFIG_DIR/passwd.txt
   else
      echo processing, cleaning $MYIP
      ssh -l $MYLOGIN_ID $MYIP $tagaScriptsStopDir/stop.sh $1 <$TAGA_CONFIG_DIR/passwd.txt
   fi
else
   echo processing, cleaning $MYIP
   ssh -l $MYLOGIN_ID $MYIP $tagaScriptsStopDir/stop.sh $1 <$TAGA_CONFIG_DIR/passwd.txt
fi


