# Purpose 

The script starts depended chain jobs on the designated clusters.

# Usage

~~~ bash
$> hpc_fgnew.sh -n 5 -j c001
~~~

Beforehand specifications for Fluent cluster jobs need to be set.

Excerpt from the script:

~~~
#----------------#
# Specifications #
#----------------#
Ichunk=5              #.. number of cpus
IinChunk=40           #.. number of cpus 
gpu=0                 #.. 0/1 usable gpu, no..0, yes..1 (gpu queue)
mem=800               #.. memory of each cpu in MB (max. is system dependent)
calctime=168          #.. calculation time in hours, max 168 h
Noit=900000           #.. number of iterations of this calculation (ex. Noit=10000)
Dim=3                 #.. domain dimensions
savefr=50             #.. autosave *.dat frequency (ex. savefr=10)
init_file=init        #.. name for inital case/data file
final_file=final      #.. name for this case/data file
restart_file=tmp      #.. name for temp. case/data file
isattol=0.00005       #.. ISAT table tolerance
cfl=50
Ntries=15             #.. tries of the random walk model
dpm=0.005             #.. dpm under-relax
species=0.95
temp=0.90
DEPENDENCY=           #.. can add jobs to 
loadm=ansys/19.2      #.. loads the desired ansys version
~~~

