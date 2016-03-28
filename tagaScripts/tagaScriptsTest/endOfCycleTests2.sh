#####################################################
# Copyright 2016 IBOA Corp
# All Rights Reserved
#####################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

NAME=`basename $0`
IPPART=`$iboaUtilsDir/iboa_padded_echo.sh $MYIP $IP_PAD_LEN`
NAMEPART=`$iboaUtilsDir/iboa_padded_echo.sh $NAME $NAME_PAD_LEN`

if [ $END_OF_CYCLE_TESTS2_ENABLED == 1 ]; then
  if [ $TAGA_DISPLAY_SETTING -ge $TAGA_DISPLAY_ENUM_VAL_4_VERBOSE ]; then
    echo "$IPPART : $NAMEPART : executing at `date`"
  fi
#  echo `basename $0` End of Cycle Tests2 Enabled - proceeding...
else
  if [ $TAGA_DISPLAY_SETTING -ge $TAGA_DISPLAY_ENUM_VAL_4_VERBOSE ]; then
    echo "$IPPART : $NAMEPART : disabled at `date`"
  fi
#  echo `basename $0` End of Cycle Tests2 Disabled - Exiting
  exit
fi

COMMON_PARAMS="--user=$MYLOGIN_ID --password=$MYPASSWD --batch-mode"

for target in $targetList
do
  TEE_FILE=/tmp/endOfCycleTest2_$target.out
  TEE_FILE=/tmp/endOfCycleTest2_$target.out
  echo $COMMAND :`date` : hostname:`hostname` target:$target -------------------------- | tee $TEE_FILE
  $COMMAND --server=$target $COMMON_PARAMS --run-command="list commands" >> $TEE_FILE 
  $COMMAND --server=$target $COMMON_PARAMS --run-command="get-config --source=running" >> $TEE_FILE 
done


