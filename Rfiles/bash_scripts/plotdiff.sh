# Generates diff file and diff plots with R files

#! /bin/sh

if [ $# -ne 2 ]; then
  echo "Incorrect number of arguments, requires two .nc files to make diff"
  exit 1
fi

if ! [ -f $1 ] || ! [ -f $2 ]; then
  echo "File(s) not found"
  exit 2
fi

if [ $1 = $2 ]; then
  echo "Files are the same"
  exit 4
fi

Rinstance=$(module list | grep -c "R/")
if [ $Rinstance -eq 0 ]; then
  echo "R is not loaded, run the command "module load R/3.6.3" (or the latest version) and try again"
  exit 3
fi

ncinstance=$(module list | grep -c "nco/")
if [  $ncinstance -eq 0 ]; then
  echo "nco tools not found, run the command "module load nco/5.0.1" (or the latest version) and try again"
  exit 3
fi

# Set directory
path=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)

file1=$(basename $1)
file2=$(basename $2)

IFS='.' read -r -a arg1 <<< $file1
IFS='.' read -r -a arg2 <<< $file2

date1=${arg1[0]}
date2=${arg2[0]}

xij1=${arg1[1]:0:3}
xij2=${arg2[1]:0:3}

runname1=${arg1[1]:3}
runname2=${arg2[1]:3}

if [ $xij1 = $xij2 ]; then
  diffpre="diff${xij1}_"
else
  diffpre="diff${xij1}-${xij2}_"
fi

if [ $runname1 = $runname2 ]; then
  diffname="${diffpre}${date1}-${date2}_${runname1}.nc"
elif [ $date1 = $date2 ]; then
  diffname="${diffpre}${date1}_${runname1}-${runname2}.nc"
fi

echo "File 1: $file1"
echo "File 2: $file2"

ncks -O -v lon,lat $1 "${diffname}" # HACK, lon,lat need to be first two vars
ncdiff -A $1 $2 "${diffname}" # does not preserve order of variables
ncks -A -v axyp $1 "${diffname}" # ncdiff also diffs axyp, so need it back
echo "Diff written to $diffname"

Rscript $path/../ModelE_plot_aij_gij.R $(pwd)/ $diffname 
