# Generates a KG biome files from monthly modelE outputs (aij). Sub-script of LUTaltclimate2modelEinput.sh
# AUTHOR - James Lui
# contact - james.lui@nasa.gov

# !/bin/bash

if [ $# -ne 1 ]; then
  echo "Incorrect number of arguments"
  exit 1
fi

if ! [ -f $1 ]; then
  echo "File $1 does not exist"
  exit 2
fi

path=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)

${path}/LUTaltclimate2modelEinput.sh $1 "true"
