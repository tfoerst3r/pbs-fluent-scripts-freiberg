#!/bin/bash
# SPDX-FileCopyrightText: 2022 Thomas Förster (tfoerst3r@gmail.com)
# SPDX-License-Identifier: MIT

# Description : chain script for Fluent on the old HPC cluster Freiberg
# Required    :    


#----------------#
# Specifications #
#----------------#
Ichunk=1              #.. number of cpus
IinChunk=12           #.. number of cpus 
mem=900               #.. memory of each cpu in MB (max. is system dependent)
calctime=1008         #.. calculation time in hours, max 168 h
Noit=900000           #.. number of iterations of this calculation (ex. Noit=10000)
Dim=2                 #.. domain dimensions
savefr=100            #.. autosave *.dat frequency (ex. savefr=10)
init_file=init        #.. name for inital case/data file
final_file=final      #.. name for this case/data file
restart_file=tmp      #.. name for temp. case/data file
isattol=0.0010        #.. ISAT table tolerance
cfl=50
Ntries=50 
dpm=0.010
species=0.99
temp=0.99
queue=                #.. (empty) -> long and short (48 h); amd_std, sfb920_std
DEPENDENCY=           #.. can add jobs to 
loadm=ansys/19.2      #.. loads the desired ansys version

#######################################
### DO NOT CHANGE BEYOND THIS POINT ###
#######################################

#--------------------------------#
#-- Std Bash Function Routines --#
#--------------------------------#

function die() {
    local scrname=$(basename "$0")
    echo "$scrname: $1" >&2
    exit 1
}

#-----#
function msg() {
    local scrname=$(basename "$0")
    echo "$scrname: $1" >&2
}

trap 'die "Execution aborted."' 1 2 3 9 15

#-----#
function printhelp() {
cat <<-EOM

Usage: runfluent [OPTION] [FILE]
Starts/restarts a looped sbatch routine with 24h intervals.

Requirements:
  - ANSYS fluent

Example of usage:
  hpcdd.sh -n 5 -j c001

Options:
 -j   --jobname             name of job and submissions
 -h   --help                print help message and exit
 -n   --number-of-cycles    number of iteration cycles
 -o   --output              determines output file name 

NOTE: none 

EOM
}

#-- init --#
outfile=
jobname=
NJOBS=

#-- parser options --#
while [ -n "$1" ]; do
    case $1 in
      -h  | --help ) printhelp && exit 0 ;;
      -j  | --jobname ) jobname="$2"; shift 2 ;;
      -n  | --number-of-cycles ) NJOBS="$2"; shift 2 ;;
      -o  | --output ) outfile="$2"; shift 2 ;;
      -- ) shift; break ;;
      -* ) msg "unknown option (ignored): $1"; shift ;;
      * ) break ;;
    esac
done


if [[ -z $outfile ]]; then
    outfile=output.out
fi

if [[ -z $NJOBS ]]; then
    NJOBS=1
fi

if [[ -z $jobname ]]; then
    jobname=fluent001          
fi

echo "Used output $outfile"
echo "Used cycles $NJOBS"


run=run_"$jobname".sh
journal=journal_"$jobname".jou
nodelist=nodelist_"$jobname".txt
cleanup=make_clean_"$jobname".sh
exit_file=exit.chkpt
job_list=job_list_"$jobname".txt

#-- total number of used cpus, not needed
Itot=`echo "$Ichunk * $IinChunk" | bc`  
memtot=`echo "$IinChunk * $mem" | bc`
mempost=MB
memstring=$memtot$mempost
echo $Itot
echo $memstring
#-----------------------#
# Fluent journal script #
#-----------------------#

journal_fluent="
/file/read-case-data $restart_file
/file/auto-save/data-frequency $savefr            
/file/auto-save/root-name $jobname
/file/auto-save/retain-most-recent-files yes
/file/auto-save/max-files 5

/solve/set/discretization-scheme omega
1

; -- changes turb value for the particles
(rpsetvar 'dpm/mu-turb-to-mu-lam 0.01)

; -- trigger file for exit ------------------------- ;
(SET! checkpoint/exit-filename \"./$exit_file\")

; -- declares written checkpoint cas and dat file -- ;
(rpsetvar 'checkpoint/filename \"$restart_file\")


;--------------------------;
; -- set courant number -- ;
;--------------------------;
/solve/set/p-v-controls
;Flow Courant Number [10]
$cfl
;Explicit momentum under-relaxation [0.4]
0.35
;Explicit pressure under-relaxation [0.4]
0.35
;; -- END flow courant number -- ;;


;----------------------------;
; -- define URF tolerance -- ;
;----------------------------;
/solve/set/under-relaxation/ species-0 $species
/solve/set/under-relaxation/ temperature $temp
/solve/set/under-relaxation/ dpm $dpm


;-----------------------------;
; -- define ISAT tolerance -- ;
;-----------------------------;
/define/models/species/integration-parameters
;Enable Chemistry Acceleration expert? [no] 

;Enable isat? [yes] 

;ODE Absolute error tolerance [1e-08] 

;ODE Relative error tolerance [1e-09] 

;ISAT error tolerance [0.002] 
$isattol
;Max. Storage [Mb] [500] 
1000
;Verbosity [0] 

;Enable Dynamic Mechanism Reduction? [no] 

;Enable Agglomerate Chemistry? [no] 

;Dimension Reduction [1=on, 0=off]? [0]

;; -- Done to set EDC basics -- ;;


;-------------------------------------------------;
; -- set number of tries for random walk model -- ;
;-------------------------------------------------;
define injections set-injection-properties
coal_inj01

;# Particle type [wet-combusting]: Change current value? [no] 

;# Injection type [surface]: Change current value? [no] 

;# Injection Material [coal]: Change current value? [no] 

;# Available surfaces: Surface(1) [()]

;# Surface(2) [()] 

;# Scale Flow Rate by Face Area [no] 
yes
;# Use Face Normal for Velocity Components [yes] 

;# Stochastic Tracking? [yes] 

;# Random Eddy Lifetime? [no] 

;# Number of Tries [90] 
$Ntries
;# Time Scale Constant [0.15] 

;# Modify Laws? [no]

;# Set user defined initialization function? [no]

;# Cloud Tracking? [no] 

;# Devolatilizing Species [vol]: Change current value? [no] 

;# Rosin Rammler diameter distribution? [no] 

;# Liquid Material [water-liquid]: Change current value? [no] 

;# Liquid Fraction [0.044585] 

;# Evaporating Species [h2o]: Change current value? [no]

;# Mass Fraction of fc1<s> [0.0]

;# Mass Fraction of ash1 [0.0]

;# Mass Fraction of fc2<s> [0.0]

;# Mass Fraction of ash2 [0.0]

;# Mass Fraction of fc3<s> [0.0]

;# Mass Fraction of ash3 [0.0]

;# Mass Fraction of fc4<s> [0.0]

;# Mass Fraction of ash4 [0.0]

;# Mass Fraction of fc5<s> [0.7624]

;# Mass Fraction of ash5 [0.2376]

;# Diameter (m) [6.176e-5]

;# Temperature (k) [343.15]

;# Velocity Magnitude (m/s) [6]

;# Total Flow Rate (kg/s) [0.7]

;-- Inj. mod. done --;   


;---------------------------;
; -- calculation routine -- ;
;---------------------------;
solve iter $Noit
file write-case-data $write_final ok
parallel timer usage
exit ok
"


#---------------------------------------#
# Accompanying shell script to `sbatch` #
#---------------------------------------#

if [ -z $queue ]; then
bash_fluent_pre="#!/bin/bash

#PBS -N $jobname
#PBS -l select=$Ichunk:ncpus=$IinChunk:mem=$memstring:mpiprocs=$IinChunk
#PBS -l walltime=$calctime:00:00
#PBS -j oe
#PBS -V
#PBS -m ae

"
else
bash_fluent_pre="#!/bin/bash

#PBS -N $jobname
#PBS -l select=$Ichunk:ncpus=$IinChunk:mem=$memstring:mpiprocs=$IinChunk
#PBS -l walltime=$calctime:00:00
#PBS -j oe
#PBS -V
#PBS -m ae
#PBS -q $queue

"
fi



bash_fluent_main="
## -- loading fluent at the node
. /etc/profile.d/modules.sh
module load $loadm              
module load intel/impi
module load openmpi

## -- generating nodefile
cd \$PBS_O_WORKDIR              
cp \$PBS_NODEFILE $nodelist

#---------------------------#
#-- Remove exit indicator --#
#---------------------------#
#-- fluent will remove exit file
#-- automatically

if [ -e $exit_file ]; then
  rm $exit_file  
  find . -iname '*.out' ! -iname $outfile ! -iname 'slurm*' | xargs rm
fi

#-----------------------------------------------------------------#


if [ -f \\#restart.inp ]; then
    iter_restart=\$(awk '{print \$2}' \\#restart.inp | head -n1)
    rename \"\$iter_restart.cas#f\" '$restart_file.cas' *
    rename '$restart_file.cas.dat' '$restart_file.dat' *
fi

if [ $calctime -eq 1008 ]; then
    sleep 1007h 35m && touch $exit_file &
elif [ $calctime -eq 48 ]; then
    sleep 47h 35m && touch $exit_file &
elif [ $calctime -eq 24 ]; then
    sleep 23h 35m && touch $exit_file &
elif [ $calctime -eq 168 ]; then
    sleep 167h 35m && touch $exit_file &
else
    sleep 23h 35m && touch $exit_file &
fi


export MPI_REMSH=/opt/pbs/bin/pbs_tmrsh
export FLUENT_SSH=\$MPI_REMSH
export FLUENT_NO_REMOTE_SSH=1
export I_MPI_HYDRA_BOOTSTRAP=rsh
export I_MPI_HYDRA_BOOTSTRAP_EXEC=\$MPI_REMSH



fluent $Dim"ddp" -t $Itot -g -mpi=intel -cnf=$nodelist -i $journal > $outfile
" 

#fluent $Dim\"ddp\" -t $Itot -gpgpu=0 -mpi=intel -g -pinfiniband -cnf=\$PBS_NODEFILE -i $journal > $outfile

#---------------------#
# generate calc files #
#---------------------#

echo "$bash_fluent_pre"   > $run
echo "$bash_fluent_main"  >> $run
echo "$journal_fluent" > $journal


#--------------#
# loop routine #
#--------------#

### -- inital procedures -- ###
JOB_FILE="$run"

cp -f $init_file.cas $restart_file.cas
cp -f $init_file.dat $restart_file.dat

### -- chain routine -- ###
    
### -- Loop of $NJOBS instances -- ###
for i in `seq 1 $NJOBS`
do
    JOB_CMD="qsub"
    if [[ -z "$DEPENDENCY" ]];then
        JOB_CMD="$JOB_CMD $JOB_FILE"
    else
        JOB_CMD="$JOB_CMD -W depend=afterok:$DEPENDENCY $JOB_FILE"
    fi

    echo "Running job command: $JOB_CMD"
    
    #-- executing and assigning $JOB_CMD, identical to $($JOB_CMD)
    OUT=`$JOB_CMD`
    echo "Result: $OUT"
    
    #-- assigning $DEPENDENCY, previous process only --#
    DEPENDENCY=`echo $OUT | awk -F. '{print $1}'`


    if [[ -z "$DEPENDENCY" ]];then
        echo $DEPENDENCY > $job_list
    else
        echo $DEPENDENCY >> $job_list
    fi
done


#----------------#
# cleanup script #
#----------------#

bash_cleanup="#!/bin/bash

IFS=$'\n' tmp=\$(cat $job_list)

for jobid in \${tmp[@]}; do
    qdel \"\$jobid\"
    echo \"qdel \$jobid\"
done

rm $nodelist
rm $run
rm $journal
rm $cleanup
rm $job_list
rm $restart_file.cas $restart_file.dat
rm *.inp
rm cleanup-fluent-*
"

echo "$bash_cleanup"   > $cleanup

