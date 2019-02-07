#!/bin/bash
# Abe Tishelman-Charny
# 16 January 2019
# 
# The purpose of this script is to run the CRAB steps to create gen miniAOD's of WWgg for different decay channels. This is so variables can be plotted to see the differences in the processes. 

# Want to change to CMSSW directory which python config file was created in. 

# Location of my pythia fragments 
#/afs/cern.ch/work/a/atishelm/private/HH_WWgg/CMSSW_7_1_25/src/Configuration/GenProduction/python/ggF_X1000_WWgg_enuenugg.py
#/afs/cern.ch/work/a/atishelm/private/HH_WWgg/CMSSW_7_1_25/src/Configuration/GenProduction/python/ggF_X1000_WWgg_jjenugg.py

## Location of my CRAB configuration files (maybe not)
##/afs/cern.ch/work/a/atishelm/private/CRAB/CrabConfig.py

submit_crab_postGEN(){

    #!/bin/bash

    cmssw_v=$2
    chosen_threads=$4 
    echo "chosen threads: $chosen_threads "
    cd /afs/cern.ch/work/a/atishelm/private/HH_WWgg/$cmssw_v/src/ # Directory where config file was conceived. Need to be in same CMSSW for crab config 
    cmsenv

    # Check if there is a VOMS proxy for using CRAB 
    check_proxy 

    # Source CRAB 
    source /cvmfs/cms.cern.ch/crab3/crab.sh

    # Create CRAB Config file 
    IDName=$1 # Decay identifying name. Anything unique about the process should be contained in the pythia fragment file name 
    #IDName=${IDName#"cmssw_configs/"} # Remove cmssw folder part from eventual crab config path
    IDName=${IDName#"$cmssw_v/src/cmssw_configs/"} # Remove '/CMSSW_X_X_X/src/cmssw_configs' from ID 
    
    IDName=${IDName%???} # Remove .py 

    ccname=$IDName
    ccname+="_CrabConfig.py" # Crab Configuration file name 

    totfiles=1 # (I think) this is the number of files to spread the crab output across. It may also be the number of files to use as input 

    echo "from CRABClient.UserUtilities import config, getUsernameFromSiteDB" >> TmpCrabConfig.py
    echo "config = config()" >> TmpCrabConfig.py
    echo " " >> TmpCrabConfig.py




    # if crab working area already exists, increment to unique name 
    working_area=/afs/cern.ch/work/a/atishelm/private/HH_WWgg/$cmssw_v/src/crab_projects/crab_$IDName

    # Do until unused working area name is found 
    # Make into some unique name function? Don't need to yet I guess 
    i=$((0))
    while : ; do

        if [ $i == 0 ]; then

            # If default working area doesn't exist, use this name 
            if [ ! -d $working_area ]; then 

                echo "Creating crab working area: '$working_area' for this crab request"
                # No need to increment IDName 
                break 
        
            fi

        else 
        
            tmp_IDName=$IDName
            tmp_IDName+=_$i 
            working_area=/afs/cern.ch/work/a/atishelm/private/HH_WWgg/$cmssw_v/src/crab_projects/crab_$tmp_IDName 
            if [ ! -d $working_area ]; then

                echo "Creating crab working area: '$working_area' for this crab request"
                IDName=$tmp_IDName 
                # Use incremented IDName 
                break 

            fi 
    
        fi

    i=$((i+1))

    #echo "i = $i"
    #if [ $i == 2 ]; then
    #    break 
    #fi

    done






    echo "config.General.requestName = '$IDName'" >> TmpCrabConfig.py

    echo "config.General.workArea = 'crab_projects'" >> TmpCrabConfig.py
    echo "config.General.transferOutputs = True" >> TmpCrabConfig.py
    echo "config.General.transferLogs = False" >> TmpCrabConfig.py
    echo " " >> TmpCrabConfig.py
    echo "config.JobType.pluginName = 'Analysis'" >> TmpCrabConfig.py
    #echo "arg = $1"
    echo "config.JobType.psetName = '/afs/cern.ch/work/a/atishelm/private/HH_WWgg/$1'" >> TmpCrabConfig.py # Depends on cmssw config memory location  

    if [ $chosen_threads != noval ]
    then
        echo "config.JobType.numCores = $chosen_threads" >> TmpCrabConfig.py  
        echo "config.JobType.maxMemoryMB = 8000" >> TmpCrabConfig.py
    else
        echo "no thread customization chosen. Not including numCores or maxMemory options in crab config file."
    fi 

    echo " " >> TmpCrabConfig.py
    echo "config.Data.outputPrimaryDataset = 'postGEN_Outputs'" >> TmpCrabConfig.py
    echo "config.Data.splitting = 'FileBased'" >> TmpCrabConfig.py
    echo "config.Data.unitsPerJob = 1" >> TmpCrabConfig.py # Number of output files    
    #echo "#config.Data.outLFNDirBase = '/store/user/%s/' % (getUsernameFromSiteDB()) " >> TmpCrabConfig.py
    #echo "config.Data.outLFNDirBase = '/store/group/phys_higgs/resonant_HH/RunII/MicroAOD/HHWWggSignal/'" >> TmpCrabConfig.py
    echo "config.Data.outLFNDirBase = '/store/user/atishelm/'" >> TmpCrabConfig.py
    echo "config.Data.publication = True" >> TmpCrabConfig.py
    echo "config.Data.outputDatasetTag = '$IDName'" >> TmpCrabConfig.py

    

    echo "config.Data.userInputFiles = ['$3'] # If DR1 step, this should be GEN file(s) " >> TmpCrabConfig.py # Could make this a list 
    echo " " >> TmpCrabConfig.py
    echo "config.Site.whitelist = ['T2_CH_CERN']" >> TmpCrabConfig.py  
    echo "config.Site.storageSite = 'T2_CH_CERN'" >> TmpCrabConfig.py

    # Now using multiple cmssw version, so will have a crab_configs and cmssw_configs folder for each CMSSW 
    
    #echo "pwd = $PWD" 
    #echo "ccname = $ccname"

    cp TmpCrabConfig.py $ccname
    #mv $ccname ../../crab_configs/$ccname  
    mv $ccname crab_configs/$ccname  
    rm TmpCrabConfig.py 

    #crab submit -c ../../crab_configs/$ccname 
    crab submit -c crab_configs/$ccname 
    crab status 

    }