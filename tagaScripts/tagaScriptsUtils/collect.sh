#####################################################
# Copyright 2016 IBOA Corp
# All Rights Reserved
#####################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

outputDir=$1

for target in $targetList
do

   # determine LOGIN ID for each target
   MYLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $target | tail -n 1`
   # dlm temp , I have no clue why this is needed but it is...
   MYLOGIN_ID=`echo $MYLOGIN_ID` 

   echo
   echo processing, collecting files from $target start:`date | cut -c12-20`

   # if we are in local mode and target == MYIP , do not use ssh or scp
   if cat $TAGA_LOCAL_MODE_FLAG_FILE 2>/dev/null | grep 1 >/dev/null ; then
      if [ $target == $MYIP ]; then
        # collect
        cp /tmp/$TEST_DESCRIPTION* $outputDir
        cp /tmp/tagaRun* $outputDir
        # clean
        rm /tmp/$TEST_DESCRIPTION* 2>/dev/null 
      else
        # collect
        scp $MYLOGIN_ID@$target:/tmp/$TEST_DESCRIPTION* $outputDir
        scp $MYLOGIN_ID@$target:/tmp/tagaRun* $outputDir
        # clean
        ssh -l $MYLOGIN_ID $target rm /tmp/$TEST_DESCRIPTION* 2>/dev/null 
      fi

   # normal mode
   else
      # collect
      scp $MYLOGIN_ID@$target:/tmp/$TEST_DESCRIPTION* $outputDir
      scp $MYLOGIN_ID@$target:/tmp/tagaRun* $outputDir
      # clean
      ssh -l $MYLOGIN_ID $target rm /tmp/$TEST_DESCRIPTION* 2>/dev/null 
   fi

   echo processing, collecting files from $target  stop :`date | cut -c12-20`

done

echo
echo `basename $0` : Total File Count: `ls $outputDir | wc -l` Total Line Count: `cat $outputDir/* | wc -l`
echo

