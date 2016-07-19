#####################################################
# Copyright 2016 IBOA Corp
# All Rights Reserved
#####################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

# get my login id for this machine and create the path name based on variable user ids
MYLOCALLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $MYIP | tail -n 1`
MYLOCALLOGIN_ID=`echo $MYLOCALLOGIN_ID`
MYDIR=`pwd`
MYDIR=`echo $MYDIR | sed -e s/$MYLOCALLOGIN_ID/MYLOGIN_ID/g`

# provide the info to print into the confirmation request
InfoToPrint=" $MYDIR will be synchronized. "
# issue confirmation prompt and check reponse
$tagaUtilsDir/confirm.sh $0 "$InfoToPrint"
response=$?; if [ $response -ne 1 ]; then exit; fi

echo 
echo $targetList

for target in $targetList
do

   # determine LOGIN ID for each target
   MYLOGIN_ID=`$TAGA_UTILS_DIR/loginIdLookup.sh $target | tail -n 1`
   # dlm temp , I have no clue why this is needed but it is...
   MYLOGIN_ID=`echo $MYLOGIN_ID` 

   MYDIR=`pwd`
   MYDIR=`echo $MYDIR | sed -e s/$MYLOCALLOGIN_ID/MYLOGIN_ID/g`
   MYDIR=`echo $MYDIR | sed -e s/MYLOGIN_ID/$MYLOGIN_ID/g`

   if [ $target == $MYIP ]; then
     echo
     echo skipping self \($target\) ...
     echo
     continue
   else
     echo
     echo processing, synchronizing $target

     # make the directory on remote (target) if it does not exist
     ssh -l $MYLOGIN_ID $target mkdir -p $MYDIR

     # define the source string
     SCP_SOURCE_STR="."          # use this to synch everything here and below

     # send the files to the destination
     scp -r $SCP_SOURCE_STR $MYLOGIN_ID@$target:$MYDIR # <$SCRIPTS_DIR/taga/passwd.txt

   fi
done

