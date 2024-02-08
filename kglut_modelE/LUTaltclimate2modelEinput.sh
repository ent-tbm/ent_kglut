# Generates a lookup input files for modelE and its branches (LAI, LAImax, height, LC) 
# AUTHOR - James Lui
# contact - james.lui@nasa.gov

# !/bin/bash

if [ $# -ne 1 ]; then
  echo "Incorrect number of arguments"
  exit 1
fi

if ! [ -f $1 ]; then
  echo "File does not exist"
  exit 2
fi

# Check if the python module is loaded

pyinstance=$(module list | grep -c "python/")
if [ $pyinstance -eq 0 ]; then
  echo "Python is not loaded, run the command "module load python/GEOSpyD/Min4.8.3_py3.8" (or the latest version) and try again"
  exit 3
fi

Rinstance=$(module list | grep -c "R/")
if [ $Rinstance -eq 0 ]; then
  echo "R is not loaded, run the command "module load R/3.6.3" (or the latest version) and try again"
  exit 3
fi

# Set directory
ppwd=$(pwd)
path=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)
cd "$path"

# Loop over the input file

dohgt=false

while IFS=$'=' read -r -a args; do
  keyword=${args[0]}
  arg=${args[1]}
  if [ "$keyword" = "aij_dir" ]; then
    indir=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "aij_jan" ]; then
    aij_jan=$arg
  elif [ "$keyword" = "lut" ]; then
    lut=$arg
    if ! [ -f "$lut" ]; then
      echo "${lut} not found, searching for newest file beginning with prefix"
      lut=$(ls -t "${lut}*" | head -1)
      echo "Using ${lut}"
    fi
    lut=$(echo ${lut//"/"/"\/"})
  elif [ "$keyword" = "resolution" ]; then
    resolution=$arg
  elif [ "$keyword" = "outdir" ]; then
    outdir=$(echo ${arg//"/"/"\/"})
    outdirn=$arg
  elif [ "$keyword" = "netcdf_format" ]; then
    netcdf_format=$arg
  elif [ "$keyword" = "hgt" ]; then
    arg=$(echo $arg | tr [:lower:] [:upper:])
    if [ "$arg" = "YES" ] || [ "$arg" = "Y" ]; then
      hgt="hgt_"
      dohgt=true
    fi
  elif [ "$keyword" = "metadata_dataversion" ]; then
    metadata_dataversion=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "metadata_datasourcelut" ]; then
    metadata_datasourcelut=$(echo ${arg//"/"/"\/"})
  fi
done < "${ppwd}/${1}"

# resolution
# change to all caps
resolution=$(echo $resolution | tr [:lower:] [:upper:])

if [ "$resolution" = "4X5" ]; then
  dimensions="(46, 72)"
  latdim="np.arange(-88.0, 92.0, 4.0)"
  londim="np.arange(-177.5, 182.5, 5.0)"
  dimname="72x46"
elif [ "$resolution" = "2X2H" ]; then
  dimensions="(90, 144)"
  latdim="np.arange(-89.0, 91.0, 2.0)"
  londim="np.arange(-178.75, 181.25, 2.50)"
  dimname="144x90"
elif [ "$resolution" = "1X1Q" ]; then
  dimensions="(180, 288)"
  latdim="np.arange(-89.5, 90.5, 1.0)"
  londim="np.arange(-178.375, 180.625, 1.25)"
  dimname="288x180"
elif [ "$resolution" = "1X1" ]; then
  dimensions="(180, 360)"
  latdim="np.arange(-89.5, 90.5, 1.0)"
  londim="np.arange(-179.5, 180.5, 1.0)"
  dimname="360x180"
elif [ "$resolution" = "HXH" ]; then
  dimensions="(360, 720)"
  latdim="np.arange(-89.75, 90.25, 0.5)"
  londim="np.arange(-179.75, 180.25, 0.5)"
  dimname="720x360"
elif [ "$resolution" = "QXQ" ]; then
  dimensions="(720, 1440)"
  latdim="np.arange(-89.875, 90.125, 0.25)"
  londim="np.arange(-179.875, 180.125, 0.25)"
  dimname="1440x720"
else
  echo "${resolution} is not recognized as a resolution. Valid resolutions: 4X5, 2X2H, 1X1, HXH, QXQ"
  exit 4
fi

append_rng=$(date | md5sum | cut -c 1-7)
userout="../user/output/"

# aij generate filenames

IFS='.' read -r -a aijname <<< "$aij_jan"
years=${aijname[0]:3}
runname=${aijname[1]:3}

JAN="JAN${years}.aij${runname}.nc"
FEB="FEB${years}.aij${runname}.nc"
MAR="MAR${years}.aij${runname}.nc"
APR="APR${years}.aij${runname}.nc"
MAY="MAY${years}.aij${runname}.nc"
JUN="JUN${years}.aij${runname}.nc"
JUL="JUL${years}.aij${runname}.nc"
AUG="AUG${years}.aij${runname}.nc"
SEP="SEP${years}.aij${runname}.nc"
OCT="OCT${years}.aij${runname}.nc"
NOV="NOV${years}.aij${runname}.nc"
DEC="DEC${years}.aij${runname}.nc"

# output of aij2prectemp.py:
prec="prec_${resolution}_${years}_${runname}_${append_rng}.nc"
temp="temp_${resolution}_${years}_${runname}_${append_rng}.nc"

# output of prectemp2biome2.sh:
biome="V${dimname}_KGbiomes_${years}_${runname}_${append_rng}.nc"

# output of lut2finalout.py:
lai_out="V${dimname}_lai_${years}_${runname}_${append_rng}.nc"
laimax_out="V${dimname}_laimax_${years}_${runname}_${append_rng}.nc"
height_out="V${dimname}_height_${years}_${runname}_${append_rng}.nc"
lc_out="V${dimname}_lc_${years}_${runname}_${append_rng}.nc"

# run aij2prectemp.py
cp "aij2prectemp.py" "${userout}aij2prectemp_${append_rng}.py"

ex "${userout}aij2prectemp_${append_rng}.py" <<EOF
  6s/@@INDIR/${indir}/
  7s/@@OUTDIR/${outdir}/
  19s/@@JAN/${JAN}/
  20s/@@FEB/${FEB}/
  21s/@@MAR/${MAR}/
  22s/@@APR/${APR}/
  23s/@@MAY/${MAY}/
  24s/@@JUN/${JUN}/
  25s/@@JUL/${JUL}/
  26s/@@AUG/${AUG}/
  27s/@@SEP/${SEP}/
  28s/@@OCT/${OCT}/
  29s/@@NOV/${NOV}/
  30s/@@DEC/${DEC}/
  8s/@@PREC/${prec}/
  9s/@@TEMP/${temp}/
  wq
EOF

python "${userout}aij2prectemp_${append_rng}.py"
#rm "aij2prectemp_${append_rng}.py"

# use KG_classify instead ~~run prectemp2biome.sh~~
#echo -e "${prec}\t${temp}\t${outdirn}${biome}" > "ptb_${append_rng}.txt"
#./prectemp2biome.sh "ptb_${append_rng}.txt"
cp "KG_classify_config.txt" "${userout}KG_classify_config_${append_rng}.txt"

ex "${userout}KG_classify_config_${append_rng}.txt" <<EOF
  1s/@@RESOLUTION/${resolution}/
  2s/@@INDIR/${path//"/"/"\/"}/
  3s/@@OUTDIR/${outdir}/
  4s/@@ID/${append_rng}/
  5s/@@TEMP/${outdir}${temp}/
  6s/@@PREC/${outdir}${prec}/
  wq
EOF

Rscript "../Rfiles/KG_classify.R" "${userout}KG_classify_config_${append_rng}.txt"

mv "${outdirn}KG${resolution}_biomes_${append_rng}.nc" "${outdirn}${biome}"
#rm "KG_classify_config_${append_rng}.txt"

# run lut2finalout.py
cp "lut2finalout.py" "${userout}lut2finalout_${append_rng}.py"

ex "${userout}lut2finalout_${append_rng}.py" <<EOF
  9s/@@DIMENSIONS/${dimensions}/
  10s/@@LATDIM/${latdim}/
  11s/@@LONDIM/${londim}/
  14s/@@NETCDF_FORMAT/${netcdf_format}/
  16s/@@BIOME/${outdir}${biome}/
  17s/@@LUT/${lut}/
  19,22s/@@METADATA_DATAVERSION/${metadata_dataversion}/
  26s/@@OUTDIR/${outdir}/
  27s/@@LAI_OUT/${lai_out}/
  28s/@@LAIMAX_OUT/${laimax_out}/
  29s/@@HEIGHT_OUT/${height_out}/
  30s/@@LC_OUT/${lc_out}/
  83,201s/@@METADATA_DATASOURCELUT/${metadata_datasourcelut}/
  wq
EOF

if [ $dohgt ]; then
  ex "${userout}lut2finalout_${append_rng}.py" <<EOF 
    24s/@@HGT/${hgt}/
    wq
EOF
else
  ex "${userout}lut2finalout_${append_rng}.py" <<EOF
    24s/@@HGT//
    ew
EOF
fi

python "${userout}lut2finalout_${append_rng}.py"
#rm "lut2finalout_${append_rng}.py"

# run Ent_map_lc_weighted.R
cp "Ent_map_lcwtd_config.txt" "${userout}Ent_map_lcwtd_config_${append_rng}.txt"

ex "${userout}Ent_map_lcwtd_config_${append_rng}.txt" <<EOF
  1s/@@RESOLUTION/${resolution}/
  2,3s/@@OUTDIR/${outdir}/
  4s/@@LC/${lc_out}/
  5s/@@HEIGHT/${height_out}/
  6s/@@LAIMAX/${laimax_out}/
  7s/@@LAI/${lai_out}/
  wq
EOF

if [ $dohgt ]; then
  ex "${userout}Ent_map_lcwtd_config_${append_rng}.txt" <<EOF
    5s/@@HGT/hgt/
    4,7s/@@NA/NA
    wq
EOF
else
  ex "${userout}Ent_map_lcwtd_config_${append_rng}.txt" <<EOF
    4,7s/ @@NA//
    wq
EOF
fi

Rscript "../Rfiles/Ent_map_lc_weighted.R" "${userout}Ent_map_lcwtd_config_${append_rng}.txt" "TRUE"
#rm "Ent_map_lcwtd_config_${append_rng}.txt"
