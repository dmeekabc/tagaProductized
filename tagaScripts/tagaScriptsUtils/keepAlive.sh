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

#
# Github notes:  We are getting return codes of 0, 1, and 141 when we
# do an /sbin/ifconfig up when the interface is already up
# ... we are not sure what to make of those return codes at this point
#
#... we are putting this keepAlive effort on hold until further point in time
#


IP_TO_KEEP_ALIVE=$MYIP
ITFC_TO_KEEP_ALIVE=$INTERFACE

MY_KA_LOG_FILE=/tmp/tagaKeepAlive.log

let CURRENT_RX_BYTES=`/sbin/ifconfig $INTERFACE | grep "RX bytes" | cut -d: -f 2 | cut -d\( -f 1`
let PREVIOUS_RX_BYTES=$CURRENT_RX_BYTES

function checkInterface {

   echo checking interface $INTERFACE >> $MY_KA_LOG_FILE

   # default to success (good status)
   let status=1

   # loop back is always good
   if [ $INTERFACE = "lo" ]; then

      echo loopback interface $INTERFACE is always good! >> $MY_KA_LOG_FILE

      # status is already set to 1
      #let status=1

   else

      let CURRENT_RX_BYTES=`/sbin/ifconfig $INTERFACE | grep "RX bytes" | cut -d: -f 2 | cut -d\( -f 1`

      if [  $CURRENT_RX_BYTES -eq $PREVIOUS_RX_BYTES ] ; then
         echo Warning: Potential Problem with Interface $ITFC_TO_KEEP_ALIVE Identified!! >> $MY_KA_LOG_FILE
         echo Warning: Potential Problem with Interface $ITFC_TO_KEEP_ALIVE Identified!! >> $MY_KA_LOG_FILE
         echo Warning: $ITFC_TO_KEEP_ALIVE does not appear to be receiving traffic!! >> $MY_KA_LOG_FILE
         echo Warning: $ITFC_TO_KEEP_ALIVE does not appear to be receiving traffic!! >> $MY_KA_LOG_FILE
         echo CURRENT_RX_BYTES:$CURRENT_RX_BYTES PREVIOUS_RX_BYTES:$PREVIOUS_RX_BYTES >> $MY_KA_LOG_FILE
         echo CURRENT_RX_BYTES:$CURRENT_RX_BYTES PREVIOUS_RX_BYTES:$PREVIOUS_RX_BYTES >> $MY_KA_LOG_FILE
 
         # set status to failed (not success, bad status)
         let status=2
   
         echo Warning: Potential Problem with Interface $ITFC_TO_KEEP_ALIVE Identified!! >> $MY_KA_LOG_FILE
         echo Warning: Potential Problem with Interface $ITFC_TO_KEEP_ALIVE Identified!! >> $MY_KA_LOG_FILE
      else
         echo Info: Interface $ITFC_TO_KEEP_ALIVE appears to be in a good state. >> $MY_KA_LOG_FILE
         echo Info: Interface $ITFC_TO_KEEP_ALIVE is receiving traffic. >> $MY_KA_LOG_FILE
         echo CURRENT_RX_BYTES:$CURRENT_RX_BYTES PREVIOUS_RX_BYTES:$PREVIOUS_RX_BYTES >> $MY_KA_LOG_FILE
   
         # status is already set to 1
         #let status=1
   
         echo Info: Interface $ITFC_TO_KEEP_ALIVE appears to be in a good state. >> $MY_KA_LOG_FILE

      fi # end if current bytes does or does not equal previous bytes
 
      let PREVIOUS_RX_BYTES=$CURRENT_RX_BYTES

   fi # end if loopback or otherwise 

   # return good(1) or bad(2) status-
   return $status

}

############################
# MAIN
############################

echo
echo `date` : $0 : executing on $MYIP
echo  Notice: This process may make changes to $INTERFACE configuration. !!
echo  Notice: This process may make changes to $INTERFACE configuration. !!
echo  Notice: Output from this $0 command can be found in $MY_KA_LOG_FILE
echo  Notice: Output from this $0 command can be found in $MY_KA_LOG_FILE
echo  Notice: Monitor $MY_KA_LOG_FILE for activity related to this $0 command.
echo  Notice: Monitor $MY_KA_LOG_FILE for activity related to this $0 command.
echo

# do this once initially to get the password out of the way
# note, we may be able to pass "< confirm.txt" ('y') as other option

echo sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up >> $MY_KA_LOG_FILE
sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up
echo RetCode: $? >> $MY_KA_LOG_FILE

# do the delay here to ensure we have chance for rx byte count to change
$iboaUtilsDir/iboaDelay.sh 60 5 >> $MY_KA_LOG_FILE

while true
do

   echo Keep Alive >> $MY_KA_LOG_FILE
   echo IP_TO_KEEP_ALIVE: $IP_TO_KEEP_ALIVE ITFC_TO_KEEP_ALIVE: $ITFC_TO_KEEP_ALIVE >> $MY_KA_LOG_FILE
   checkInterface
   let status=$?

   echo returned status: $status >> $MY_KA_LOG_FILE
   echo returned status: $status >> $MY_KA_LOG_FILE

   if [ $status -eq 1 ] ; then
      echo "sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up" >> $MY_KA_LOG_FILE
      sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up
      echo RetCode: $? >> $MY_KA_LOG_FILE
   else
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, resetting interface! >> $MY_KA_LOG_FILE
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, resetting interface! >> $MY_KA_LOG_FILE
      sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE down
      echo RetCode: $? >> $MY_KA_LOG_FILE
      sleep 1
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, resetting interface! >> $MY_KA_LOG_FILE
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, resetting interface! >> $MY_KA_LOG_FILE
      sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE down
      echo RetCode: $? >> $MY_KA_LOG_FILE
      sleep 5
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, restoring interface! >> $MY_KA_LOG_FILE
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, restoring interface! >> $MY_KA_LOG_FILE
      sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up
      echo RetCode: $? >> $MY_KA_LOG_FILE
      sleep 1
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, restoring interface! >> $MY_KA_LOG_FILE
      echo Possible Issue with $ITFC_TO_KEEP_ALIVE identified, restoring interface! >> $MY_KA_LOG_FILE
      sudo /sbin/ifconfig $ITFC_TO_KEEP_ALIVE $IP_TO_KEEP_ALIVE up
      echo RetCode: $? >> $MY_KA_LOG_FILE
   fi

   $iboaUtilsDir/iboaDelay.sh 60 5 >> $MY_KA_LOG_FILE

done
