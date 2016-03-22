#####################################################
# Copyright 2016 IBOA Corp
# All Rights Reserved
#####################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

# this is our poor-mans interprocess communications mechanism
# it is not elegant but does work
if cat $NET_RESET_IN_PROG_FLAG_FILE 2>/dev/null | grep 1 ; then
   echo Notice: Network Reset is in progress, 
   echo Notice: Network Reset is in progress, 
   echo Notice: This $0 is not permitted to run in this state, exiting with no action!
   echo Notice: This $0 is not permitted to run in this state, exiting with no action!
   exit
fi

###################
# MAIN
###################

# if param is provided, that implies to do reset without checks
if [ $# -eq 1 ]; then

   # more than one bad return, this implies our interface may be bad
   echo Interface is in suspect state - resetting! 
   echo Interface is in suspect state - setting interface down!
   sudo ifconfig $INTERFACE  down < $TAGA_CONFIG_DIR/passwd.txt
   echo Retcode:$?
   sleep 5
   echo Interface is in suspect state - setting interface up!
   sudo ifconfig $INTERFACE  up < $TAGA_CONFIG_DIR/passwd.txt
   echo Retcode:$?

else

   # only do reset if checks indicate it is necessary

   let flag=0
   let retCodeSum=0

   let CHECKVAL=$TARGET_COUNT-1
   # don't proceed with less than 2 checkval
   if [ $CHECKVAL -lt 2 ]; then
      let CHECKVAL=2
   fi

   echo PINGING TARGETS: $targetList >/dev/null

   for target in $targetList
   do
      #echo
      ping -c 1 $target >/dev/null
      let retCode=$?
      #echo retCode: $retCode
      if [ $retCode -eq 2 ] ; then
         echo Unreachable Network Detected, Not much we can do...
         # exit the routine, not much we can do
         exit
      elif [ $retCode -eq 0 ] ; then
         # set the flag that we have at least one successful ping
         let flag=1
      else
         let retCodeSum=$retCodeSum+$retCode
      #   echo retCodeSum: $retCodeSum
      fi
      echo retCode: $retCode retCodeSum: $retCodeSum
      if [ $retCodeSum -ge $CHECKVAL ] ; then
         # we have all the info we need... go ahead and break out
         break
      fi
   done

   echo retCode: $retCode retCodeSum: $retCodeSum CHECKVAL: $CHECKVAL flag:$flag

   # if we have failed to ping anybody...
   if [ $retCodeSum -ge $CHECKVAL ] ; then
      # more than one bad return, this implies our interface may be bad
      echo Interface is in suspect state - resetting! 
      echo Interface is in suspect state - setting interface down!
      sudo ifconfig $INTERFACE  down < $TAGA_CONFIG_DIR/passwd.txt
      echo Retcode:$?
      sleep 5
      echo Interface is in suspect state - setting interface up!
      sudo ifconfig $INTERFACE  up < $TAGA_CONFIG_DIR/passwd.txt
      echo Retcode:$?
   # here is another way to check , this may make the block above unnecessary, 
   # believe that this one is more demanding than the one above
   elif [ $flag -eq 0 ] ; then
      # failure to contact anybody implies our interface may be bad
     
      # before we declare failure, let's check against the gateway
      # get the gateway in case it has changed
      echo; date; echo Determining GATEWAY....
      MYGATEWAY=`route | grep default | cut -c16-30`
      echo GATEWAY: $MYGATEWAY

      echo; echo PINGING GATEWAY: $MYGATEWAY; echo
      ping -c 1 $MYGATEWAY
      let retCode=$?

      if [ $retCode -eq 0 ] ; then
         echo Interface appears healthy, comms with gateway AOK
      else
         echo Interface is in suspect state - resetting! 
         echo Interface is in suspect state - setting interface down!
         sudo ifconfig $INTERFACE  down < $TAGA_CONFIG_DIR/passwd.txt
         echo Retcode:$?
         sleep 5
         echo Interface is in suspect state - setting interface up!
         sudo ifconfig $INTERFACE  up < $TAGA_CONFIG_DIR/passwd.txt
         echo Retcode:$?
      fi
   fi
fi
