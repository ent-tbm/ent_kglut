# Driver script for generating statistics for APAR/FAPAR by global and per PFT diagnostics
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

while IFS=$'=' read -r -a args; do
  keyword=${args[0]}
  arg=${args[1]}
  if [ "$keyword" = "aij_dir" ]; then
    indir=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "aij_jan" ]; then
    aij_jan=$arg
  elif [ "$keyword" = "resolution" ]; then
    resolution=$arg
  elif [ "$keyword" = "outdir" ]; then
    outdir=$(echo ${arg//"/"/"\/"})
    outdirn=$arg
  elif [ "$keyword" = "metadata" ]; then
    metadata=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "canopy_model" ]; then
    canopy_model=$(echo ${arg//"/"/"\/"})
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
ANN="ANN${years}.aij${runname}.nc"

# output of aij2prectemp.py:
prec="prec_${resolution}_${years}_${runname}_${append_rng}.nc"
temp="temp_${resolution}_${years}_${runname}_${append_rng}.nc"

# output of prectemp2biome.sh
biome="V${dimname}_EntKG_biomes_${append_rng}.nc"

# output of regress_APAR_stat.py
out_nc="Ent_PAR_${runname}_regression_${append_rng}.nc"
out_apar="Ent_APAR_${runname}_plots_${append_rng}.pdf"
out_fapar="Ent_FAPAR_${runname}_plots_${append_rng}.pdf"

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
  36s/@@DIMENSIONS/${dimensions}/
  37s/@@LATDIM/${latdim}/
  38s/@@LONDIM/${londim}/
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

# run regress_APAR_stat.py
cp "regress_APAR_stat.py" "${userout}regress_APAR_stat_${append_rng}.py"

ex "${userout}regress_APAR_stat_${append_rng}.py" <<EOF
  13s/@@INDIR/${indir}/
  14s/@@BIOME/${outdir}${biome}/
  16s/@@OUTDIR/${outdir}/
  17s/@@OUT_NC/${out_nc}/
  18s/@@OUT_APAR_PDF/${out_apar}/
  19s/@@OUT_FAPAR_PDF/${out_fapar}/
  20s/@@RUNNAME/${runname}/
  21s/@@CANOPYMODEL/${canopy_model}/
  22s/@@METADATA/${metadata}/
  27s/@@JAN/${JAN}/
  28s/@@FEB/${FEB}/
  29s/@@MAR/${MAR}/
  30s/@@APR/${APR}/
  31s/@@MAY/${MAY}/
  32s/@@JUN/${JUN}/
  33s/@@JUL/${JUL}/
  34s/@@AUG/${AUG}/
  35s/@@SEP/${SEP}/
  36s/@@OCT/${OCT}/
  37s/@@NOV/${NOV}/
  38s/@@DEC/${DEC}/
  39s/@@ANN/${ANN}/
  45s/@@DIMENSIONS/${dimensions}/
  46s/@@LATDIM/${latdim}/
  47s/@@LONDIM/${londim}/
  wq
EOF

python "${userout}regress_APAR_stat_${append_rng}.py"
#rm "${userout}regress_APAR_stat_${append_rng}.py"

echo "Intermediate scripts used to generate outputs can be found here: ${userout}"
echo "All output files:"
ls ${outdir}*${append_rng}*
