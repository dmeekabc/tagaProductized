#####################################################
# Copyright 2016 IBOA Corp
# All Rights Reserved
#####################################################

TAGA_DIR=~/scripts/taga
TAGA_CONFIG_DIR=$TAGA_DIR/tagaConfig
source $TAGA_CONFIG_DIR/config

# this provides our inter-process comms, 
# it is not bullet proof, but better than nothing...
#clear the reboot in progress flag
rm /tmp/rebootInProgress.dat
rm $NET_RESET_IN_PROG_FLAG_FILE

# basic sanity check, to ensure password updated etc
$tagaScriptsUtilsDir/basicSanityCheck.sh
if [ $? -eq 255 ]; then
  echo Basic Sanith Check Failed - see warning above - $0 Exiting...
  echo
  exit 255
fi

# dlm temp
# Force checks to get the password entry out of the way...
# dlm temp remove this if not necessary!!!
# dlm temp remove this if not necessary!!!
# dlm temp remove this if not necessary!!!
$TAGA_UTILS_DIR/checkInterface.sh "forceChecks"

#exit

START_STATS=`$tagaScriptsStatsDir/adminstats.sh` 
let TX_STATS=`$tagaScriptsStatsDir/adminstats.sh TXonly`
let RX_STATS=`$tagaScriptsStatsDir/adminstats.sh RXonly`
let START_TX_STATS=$TX_STATS
let START_RX_STATS=$RX_STATS
#echo TX_STATS:$TX_STATS
#echo RX_STATS:$RX_STATS


# Do this to get the password entry out of the way
# dlm temp remove this if not necessary!!!
# dlm temp remove this if not necessary!!!
# dlm temp remove this if not necessary!!!
#$TAGA_UTILS_DIR/resetInterface.sh


#########################################
# Update the MASTER entry in the config
#########################################
# strip old MASTER entries and blank lines at end of file
cat $TAGA_CONFIG_DIR/config | sed -e s/^MASTER=.*$//g |     \
      sed -e :a -e '/./,$!d;/^\n*$/{$d;N;;};/\n$/ba' \
           > $TAGA_CONFIG_DIR/tmp.config
# move temp to config
mv $TAGA_CONFIG_DIR/tmp.config $TAGA_CONFIG_DIR/config
# Update the MASTER entry in the config
echo MASTER=$MYIP >> $TAGA_CONFIG_DIR/config
#########################################
# DONE Update the MASTER entry in the config
#########################################

# set the flag in the flag file
echo $ENVIRON_SIMULATION > /tmp/simulationFlag.txt

# source again due to above as well as other boot strap-like dependencies
# note, this may not be necessary and is candidate to investigate 
source $TAGA_CONFIG_DIR/config

echo;echo
if [ $TESTONLY -eq 1 ] ; then
  # use the testing directory for testing
  echo NOTE: Config file is configured for TESTONLY!!
  echo NOTE: Output Dir is NOT being Archived!!
else
  # use the archive directory for archiving
  echo NOTE: Config file is configured for ARCHIVING.
  echo NOTE: Output Dir IS being Archived!!
fi 

sleep 1

echo;echo;echo
echo $0 initializing....  please be patient...
echo;echo

# check time synch if enabled
if [ $TIME_SYNCH_CHECK_ENABLED -eq 1 ]; then
  $tagaScriptsTimerDir/timeSynchCheck.sh
fi


# probe if enabled
if [ $PROBE_ENABLED -eq 1 ]; then
  $tagaScriptsUtilsDir/probe.sh
fi

# get ping times if enabled
if [ $PING_TIME_CHECK_ENABLED -eq 1 ]; then
  $tagaScriptsUtilsDir/pingTimes.sh
fi

# get resource usage if enabled
if [ $RESOURCE_MON_ENABLED -eq 1 ]; then
  $tagaScriptsUtilsDir/wrapResourceUsage.sh
fi
sleep 1


# stop the Simulation Always 
if [ true ] ; then
  $tagaScriptsStopDir/stopXXX.sh
fi

# stop the Simulation and Data Generation in case it is still running somewhere
# use alt list which includes keepAlive process
$tagaScriptsStopDir/runStop.sh "useAltList"

let iter=0
let k=0
startTime="`date +%T`"
startDTG="`date`"
startEpoch=`date +%s`

# five iterations to converge
let beforeLastLastLastAvgDelta=0
let beforeLastLastAvgDelta=0
let beforeLastAvgDelta=0
let lastAvgDelta=0
let currentAvgDelta=0

let lastEpoch=0

LAST_CONVERGED="Not Yet Converged"

printableDeltaCum=""
printableAverageDeltaCum=""

# flag to indicate if we have reset the net
let resetflag=0

while true
do

   # this provides our inter-process comms, 
   # it is not bullet proof, but better than nothing...
   #clear the reboot in progress flag
   rm /tmp/rebootInProgress.dat
   rm $NET_RESET_IN_PROG_FLAG_FILE

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   let k=$k+1

   # check time synch if enabled
   if [ $TIME_SYNCH_CHECK_ENABLED -eq 1 ]; then
     $tagaScriptsTimerDir/timeSynchCheck.sh
   fi

   # probe if enabled
   if [ $PROBE_ENABLED -eq 1 ]; then
     $tagaScriptsUtilsDir/probe.sh
   fi

   # get ping times if enabled
   if [ $PING_TIME_CHECK_ENABLED -eq 1 ]; then
     $tagaScriptsUtilsDir/pingTimes.sh
   fi

   # get resource usage if enabled
   if [ $RESOURCE_MON_ENABLED -eq 1 ]; then
      let mod=$k%$RESOURCE_DISPLAY_MODULUS
      if [ $mod -eq 0 ] ; then
        echo k:$k
        $tagaScriptsUtilsDir/wrapResourceUsage.sh
      fi
   fi

   # new 15 jan 2016
   # Update the MASTER entry in the config
   # strip old MASTER entries and blank lines at end of file
   cat $TAGA_CONFIG_DIR/config | sed -e s/^MASTER=.*$//g |     \
         sed -e :a -e '/./,$!d;/^\n*$/{$d;N;;};/\n$/ba' \
             > $TAGA_CONFIG_DIR/tmp.config
   mv $TAGA_CONFIG_DIR/tmp.config $TAGA_CONFIG_DIR/config

   # Update the MASTER entry in the config
   echo MASTER=$MYIP >> $TAGA_CONFIG_DIR/config
   echo $ENVIRON_SIMULATION > /tmp/simulationFlag.txt

   # get the config again in case it has changed
   source $TAGA_CONFIG_DIR/config

   while [ $ALL_TESTS_DISABLED -eq 1 ] 
   do
      # refresh the flag to check again
      source $TAGA_CONFIG_DIR/config
      echo
      echo `date` Main Test Loop Disabled ............
      sleep 5
   done

   while [ $iter -ge $MAX_ITERATIONS ] 
   do
      # refresh config in case it has changed
      source $TAGA_CONFIG_DIR/config
      echo
      echo `date` Max Iterations \($iter\) Reached - Disabling ............
      sleep 5
   done

   if [ $STEPWISE_ITERATIONS -eq 1 ]; then
      echo; echo INFO: Step-wise iterations configured...
      echo `date` 
      echo Iterations \($iter\) Reached - Waiting confirmation to proceed
      echo; echo Press \[Enter\] to proceed...
      read input 
   elif [ $STEPWISE_ITERATIONS -ne 0 ]; then
      let modVal=$iter%$STEPWISE_ITERATIONS
      if [ $modVal -eq 0 ]; then 
         echo; echo INFO: Double Iteration Step-wise iterations configured...
         echo `date` 
         echo Iterations \($iter\) Reached - Waiting confirmation to proceed
         echo; echo Press \[Enter\] to proceed...
         read input 
      fi
   fi

   # Increment the iterator
   let iter=$iter+1

   echo
   echo `date` Main Test Loop Enabled ............

   # exit now if simulation only
   if [ $SIMULATION_ONLY -eq 1 ]; then
      echo `date` Simulation Only Flag is True
      echo `date` Background Traffic is Disabled ............
   fi


   echo
   echo `date` Regenerating HostToIpMap File ............

   # build the map each iteration
   $tagaScriptsUtilsDir/createHostToIpMap.sh

   echo `date` Regenerating HostToIpMap File ............ DONE
   echo


   if [ $CONTINUOUS_SYNCH -eq 1 ]; then
     # synch everything 
     $tagaScriptsUtilsDir/synch.sh
   else
     # synch config only
     $tagaScriptsUtilsDir/synchConfig.sh
   fi


   # baseline the aggregate log file
   cp /tmp/runLoop.sh.out /tmp/runLoop.sh.out.before

   # temp/test directory
   mkdir -p $OUTPUT_DIR

   # archive directory
   outputDir=$OUTPUT_DIR/output_`date +%j%H%M%S` 
   mkdir -p $outputDir

   # start the Simulation 
   if [ $START_SIMULATION -eq 1 ] ; then

     # Init the sims (cleanup old files/sockets)
     $tagaScriptsSimDir/simulateInit.sh

     # Init the selected sims (cleanup old files/sockets)
     # XXX RUN SCRIPT
     if [ $XXX_ON -eq 1 ]; then
       $tagaScriptsRunDir/runXXX.sh
     fi
   fi

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   # if first iteration, use special flag to also start keepAlive processes
   if [ $iter -eq 1 ] ; then
     # MAIN RUN SCRIPT (primary sim server and traffic)
     $tagaScriptsRunDir/run.sh "startKeepAlivesFlag"
   else
     # MAIN RUN SCRIPT (primary sim server and traffic)
     $tagaScriptsRunDir/run.sh  
   fi

   # Start of cycle tests
   #sleep $SERVER_INIT_DELAY
   let i=$SERVER_INIT_DELAY/2
   while [ $i -gt 0 ]; 
   do
      let i=$i-1
      echo Servers Initializing.... $i
      sleep 2
   done

   $tagaScriptsTestDir/startOfCycleTests.sh & # run in background/parallel

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   let i=$DURATION1
   while [ $i -gt 0 ]
   do
      let tot=$DURATION2+$i
      echo Total Secs Remain: $tot : Secs Remain Part 1: $i
      sleep 1
      let i=$i-1
   done

   # Mid cycle tests
   $tagaScriptsTestDir/midCycleTests.sh & # run in background/parallel

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   # run the variable test
   echo Executing variable test..... $VARIABLE_TEST
   $tagaScriptsTestDir/$VARIABLE_TEST

   let i=$DURATION2
   while [ $i -gt 0 ]
   do
      let tot=$i
      echo Total Secs Remain: $tot : Secs Remain Part 2: $i
      sleep 1
      let i=$i-1
   done

   #####################################################
   # Client-Side Test Stimulations
   #####################################################

   # End of cycle tests
   $tagaScriptsTestDir/endOfCycleTests.sh
   $tagaScriptsTestDir/endOfCycleTests2.sh
   $tagaScriptsTestDir/endOfCycleTests3.sh

   #####################################################
   # Client-Side Specialized Test Stimulations
   #####################################################

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   if [ $XXX_ON -eq 1 ]; then
     $tagaScriptsTestDir/testXXX.sh
   fi

   sleep 1

   # stop the Simulation each iteration 
   if [ $STOP_SIMULATION -eq 1 ] ; then
      $tagaScriptsStopDir/stopXXX.sh
   fi

   # stop the Remaining Simulation and Data Generation
   $tagaScriptsStopDir/runStop.sh

   # collect and clean
   $tagaScriptsUtilsDir/collect.sh $outputDir
   $tagaScriptsUtilsDir/cleanAll.sh $outputDir

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

   # remove old and put current data in generic output directory
   rm -rf $OUTPUT_DIR/output
   cp -r $outputDir $OUTPUT_DIR/output

   currentEpoch=`date +%s`

   let currentDelta=$currentEpoch-$lastEpoch
   let lastEpoch=$currentEpoch
   let deltaEpoch=$currentEpoch-$startEpoch


#   #############################################
#   # Recover Net if Necessary
#   #############################################
#   #if [ $currentDelta -ge 200 ]; then
#   if [ $currentDelta -ge 150 ]; then
#      echo Network is in a bad state... 
#      echo Attempting to Recover Network....
#
#      $TAGA_UTILS_DIR/recoverNet.sh &
#
#      echo Suspending while the network recovers...  
#      $IBOA_UTILS_DIR/iboaDelay.sh 150 5
#      echo Continuing....
#   fi
#   #############################################
#   # End Recover Net if Necessary
#   #############################################
   

   # special handling for iteration 1
   if [ $iter -eq 1 ]; then
      # use the delta epoch instead of current delta
      printableDeltaCum="$printableDeltaCum D: "
      printableAverageDeltaCum="$printableAverageDeltaCum A: "
   else 
      printableDeltaCum="$printableDeltaCum $currentDelta"
      printableAverageDeltaCum="$printableAverageDeltaCum $currentAvgDelta"
   fi

   #############################################################
   # create the log dir
   #############################################################
   mkdir -p $LOG_DIR

   #############################################################
   # Print to the Delta Cumlative Log File
   #############################################################

   echo; echo Convergence:
   echo $printableDeltaCum
   echo $printableDeltaCum > /tmp/deltaCum.out
   # make the log dir
   mkdir -p $LOG_DIR
   echo $printableDeltaCum > $LOG_DIR/deltaCum.out
   echo $printableDeltaCum > $LOG_DIR/_deltaCum.out
   echo $printableDeltaCum > $LOG_DIR/d_deltaCum.out

   #############################################################
   # Print to the Average Delta Cumlative Log File
   #############################################################

   echo $printableAverageDeltaCum
   echo
   echo $printableAverageDeltaCum > /tmp/averageDeltaCum.out
   echo $printableAverageDeltaCum > $LOG_DIR/averageDeltaCum.out
   echo $printableAverageDeltaCum > $LOG_DIR/_averageDeltaCum.out
   echo $printableAverageDeltaCum > $LOG_DIR/d_averageDeltaCum.out

   #these are really avgs not deltas
   let beforeLastLastLastAvgDelta=$beforeLastLastAvgDelta
   let beforeLastLastAvgDelta=$beforeLastAvgDelta
   let beforeLastAvgDelta=$lastAvgDelta
   let lastAvgDelta=$currentAvgDelta
   let currentAvgDelta=$deltaEpoch/$iter

   # add if converged check here

   if [ $beforeLastLastLastAvgDelta -eq $beforeLastLastAvgDelta ] ; then
   if [ $beforeLastLastAvgDelta -eq $beforeLastAvgDelta ] ; then
   if [ $beforeLastAvgDelta -eq $lastAvgDelta ] ; then
      if [ $beforeLastAvgDelta -eq $currentAvgDelta ] ; then
          echo Converged: $currentAvgDelta has converged 
          echo Converged: $currentAvgDelta has converged 
          echo Converged: $currentAvgDelta has converged >> $TAGA_RUN_DIR/counts.txt
          echo Converged: $currentAvgDelta has converged >> $TAGA_RUN_DIR/counts.txt
          # store it
          LAST_CONVERGED=$currentAvgDelta
      else
         echo Not Converged marker 1 >/dev/null
      fi
    else
      echo Not Converged marker 2 >/dev/null
   fi
   fi
   fi

   echo LastConverged: $LAST_CONVERGED >> $TAGA_RUN_DIR/counts.txt
   echo LastConverged: $LAST_CONVERGED >> $TAGA_RUN_DIR/counts.txt

   # new header
   echo `date` LastConverged: $LAST_CONVERGED >> $TAGA_RUN_DIR/counts.txt

   # count and sort and display results matrix
   # note, startDTG must be last param since includes spaces
   $tagaScriptsStatsDir/countSends.sh $outputDir $iter $startTime $currentDelta $deltaEpoch $startDTG
   $tagaScriptsStatsDir/countReceives.sh $outputDir $iter $startTime $startDTG 

   for i in 1 2 #3 4 5 6 # 7 8 9 10 11
   do
      let ticker=6-$i
      echo Configuration Change Window: Change Configuration Now... $ticker
      sleep 2
   done

   CURRENT_STATS=`$tagaScriptsStatsDir/adminstats.sh`

   echo
   echo "TAGA:Iter:$iter START STATS:   $START_STATS"
   echo "TAGA:Iter:$iter CURRENT STATS: $CURRENT_STATS"

   let TX_STATS=`$tagaScriptsStatsDir/adminstats.sh TXonly`
   let RX_STATS=`$tagaScriptsStatsDir/adminstats.sh RXonly`
   let CURRENT_TX_STATS=$TX_STATS
   let CURRENT_RX_STATS=$RX_STATS
   let DELTA_TX_STATS=$CURRENT_TX_STATS-$START_TX_STATS
   let DELTA_RX_STATS=$CURRENT_RX_STATS-$START_RX_STATS

# GitHub Note: Consider refactoring the below four big blocks into a single script file
# .. several input params will be required

   wordlen=`echo $DELTA_RX_STATS | awk '{print length($0)}'`

   if [ $wordlen -eq 8 ]; then
      let MBytes=$DELTA_RX_STATS*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1-2`.`echo $MBytes | cut -c3`
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS ($megabytePrint MB RX)"
   elif [ $wordlen -eq 7 ]; then
      let MBytes=$DELTA_RX_STATS*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1`.`echo $MBytes | cut -c2`
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS ($megabytePrint MB RX)"
   elif [ $wordlen -eq 6 ]; then
      let KBytes=$DELTA_RX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-3`.`echo $KBytes | cut -c4`
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS ($kilobytePrint KB RX)"
   elif [ $wordlen -eq 5 ]; then
      let KBytes=$DELTA_RX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-2`.`echo $KBytes | cut -c3-4`
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS ($kilobytePrint KB RX)"
   elif [ $wordlen -eq 4 ]; then
      let KBytes=$DELTA_RX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1`.`echo $KBytes | cut -c2-4`
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS ($kilobytePrint KB RX)"
   else
      echo "TAGA:Iter:$iter DELTA_RX_STATS:      $DELTA_RX_STATS" 
   fi

   wordlen=`echo $DELTA_TX_STATS | awk '{print length($0)}'`

   if [ $wordlen -eq 8 ]; then
      let MBytes=$DELTA_TX_STATS*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1-2`.`echo $MBytes | cut -c3`
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS ($megabytePrint MB TX)"
   elif [ $wordlen -eq 7 ]; then
      let MBytes=$DELTA_TX_STATS*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1`.`echo $MBytes | cut -c2`
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS ($megabytePrint MB TX)"
   elif [ $wordlen -eq 6 ]; then
      let KBytes=$DELTA_TX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-3`.`echo $KBytes | cut -c4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS ($kilobytePrint KB TX)"
   elif [ $wordlen -eq 5 ]; then
      let KBytes=$DELTA_TX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-2`.`echo $KBytes | cut -c3-4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS ($kilobytePrint KB TX)"
   elif [ $wordlen -eq 4 ]; then
      let KBytes=$DELTA_TX_STATS*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1`.`echo $KBytes | cut -c2-4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS ($kilobytePrint KB TX)"
   else
      echo "TAGA:Iter:$iter DELTA_TX_STATS:      $DELTA_TX_STATS" 
   fi


   let DELTA_RX_STATS_ITER=$DELTA_RX_STATS/$iter

   wordlen=`echo $DELTA_RX_STATS_ITER | awk '{print length($0)}'`
   if [ $wordlen -eq 8 ]; then
      let MBytes=$DELTA_RX_STATS_ITER*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1-2`.`echo $MBytes | cut -c3`
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER \($megabytePrint MB RX per Iter\)
   elif [ $wordlen -eq 7 ]; then
      let MBytes=$DELTA_RX_STATS_ITER*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1`.`echo $MBytes | cut -c2`
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER \($megabytePrint MB RX per Iter\)
   elif [ $wordlen -eq 6 ]; then
      let KBytes=$DELTA_RX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-3`.`echo $KBytes | cut -c4`
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER \($kilobytePrint KB RX per Iter\)
   elif [ $wordlen -eq 5 ]; then
      let KBytes=$DELTA_RX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-2`.`echo $KBytes | cut -c3-4`
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER \($kilobytePrint KB RX per Iter\)
   elif [ $wordlen -eq 4 ]; then
      let KBytes=$DELTA_RX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1`.`echo $KBytes | cut -c2-4`
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER \($kilobytePrint KB RX per Iter\)
   else
      echo TAGA:Iter:$iter DELTA_RX_STATS_ITER: $DELTA_RX_STATS_ITER
   fi

   let DELTA_TX_STATS_ITER=$DELTA_TX_STATS/$iter

   wordlen=`echo $DELTA_TX_STATS_ITER | awk '{print length($0)}'`
   if [ $wordlen -eq 8 ]; then
      let MBytes=$DELTA_TX_STATS_ITER*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1-2`.`echo $MBytes | cut -c3`
      echo "TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER ($megabytePrint MB TX per Iter)"
   elif [ $wordlen -eq 7 ]; then
      let MBytes=$DELTA_TX_STATS_ITER*10 # multiply by 10 to get fraction
      let MBytes=$MBytes/1000000
      megabytePrint=`echo $MBytes | cut -c1`.`echo $MBytes | cut -c2`
      echo "TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER ($megabytePrint MB TX per Iter)"
   elif [ $wordlen -eq 6 ]; then
      let KBytes=$DELTA_TX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-3`.`echo $KBytes | cut -c4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER ($kilobytePrint KB TX per Iter)"
   elif [ $wordlen -eq 5 ]; then
      let KBytes=$DELTA_TX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1-2`.`echo $KBytes | cut -c3-4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER ($kilobytePrint KB TX per Iter)"
   elif [ $wordlen -eq 4 ]; then
      let KBytes=$DELTA_TX_STATS_ITER*10 # multiply by 10 to get fraction
      let KBytes=$KBytes/1000
      kilobytePrint=`echo $KBytes | cut -c1`.`echo $KBytes | cut -c2-4`
      echo "TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER ($kilobytePrint KB TX per Iter)"
   else
      echo TAGA:Iter:$iter DELTA_TX_STATS_ITER: $DELTA_TX_STATS_ITER
   fi

   sleep 2

   # move output to the archive
   mv $TAGA_RUN_DIR/output/output_* $TAGA_DIR/archive 2>/dev/null

   # re-baseline the aggregate log file
   cp /tmp/runLoop.sh.out /tmp/runLoop.sh.out.after

   # create output specific to this iteration from the two baseline files
   diff /tmp/runLoop.sh.out.before /tmp/runLoop.sh.out.after | cut -c3- > /tmp/runLoop.sh.out.iter

   # sleep end of iteration delay time
   $iboaUtilsDir/iboaDelay.sh $END_OF_ITER_DELAY $END_OF_ITER_DELAY_PRINT_MODULUS

   #############################################
   # Recover Net if Necessary
   #############################################
   if [ $currentDelta -ge $MAX_ITER_DUR_BEFORE_REBOOT ]; then
      # don't do it on first iter
      if [ $iter -ge 2 ] ; then
      # if we recovered net already, don't do it twice in a row
      if [ $resetflag -eq 1 ]; then
         # reset the flag
         let resetflag=0
      else

         echo Network is in a bad state... 
         echo Attempting to Recover Network....

         # this provides our inter-process comms, 
         # it is not bullet proof, but better than nothing...
         echo 1 > /tmp/rebootInProgress.dat

         $TAGA_UTILS_DIR/recoverNet.sh "doNotResetInterface" &

         echo Suspending while the network recovers...  
         $IBOA_UTILS_DIR/iboaDelay.sh 150 5

         # this provides our inter-process comms, 
         # it is not bullet proof, but better than nothing...
         #clear the reboot in progress flag
         rm /tmp/rebootInProgress.dat

         # set the flag so we don't reboot next iteration
         let resetflag=1

         echo Continuing....

      fi
      fi
   else
      # reset the flag
      let resetflag=0
   fi
   #############################################
   # End Recover Net if Necessary
   #############################################

   # check/repair the interface
   $TAGA_UTILS_DIR/checkInterface.sh

done

