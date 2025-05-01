# Generates a lookup table based on config file 
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

# Check if the python module is loaded

pyinstance=$(module list | grep -c "python/")
if [ $pyinstance -eq 0 ]; then
  echo "Python is not loaded. See kglut_modelE/README for module load requirements, and try again"
  exit 3
fi

Rinstance=$(module list | grep -c "R/")
if [ $Rinstance -eq 0 ]; then
  echo "R is not loaded. See kglut_modelE/README for module load requirements, and try again"
  exit 3
fi

# Set directory
ppwd=$(pwd)
path=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)
cd "$path"

append_rng=$(date | md5sum | cut -c 1-7)-$(date '+%Y-%m-%d')

# Loop over the input file

if [[ ${1:0:1} = '.' || ${1:0:1} != '/' ]]; then
  configfile="${ppwd}/${1}"
else
  configfile=$1
fi

regression="kde"
while IFS=$'=' read -r -a args; do
  keyword=${args[0]}
  arg=${args[1]}
  if [ "$keyword" = "temp" ]; then
    temp=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "prec" ]; then
    prec=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "lai" ]; then
    lai=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "laimax" ]; then
    laimax=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "height" ]; then
    height=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "lc" ]; then 
    lc=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "resolution" ]; then
    resolution=$arg
  elif [ "$keyword" = "metadata_dataversion" ]; then
    metadata_dataversion=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "hgt" ]; then
    arg=$(echo $arg | tr [:lower:] [:upper:])
    if [ "$arg" = "YES" ] || [ "$arg" = "Y" ] || [ "$arg" = "TRUE" ] || [ "$arg" = "T" ]; then
      hgt="hgt_"
    else
      hgt=""
    fi
  elif [ "$keyword" = "outdir" ]; then
  # relative dir check
    if [[ ${arg:0:1} = '.' || ${arg:0:1} != '/' ]]; then
      arg="${path}/${arg}"
    fi
    arg="${arg}/"
    outdir=$(echo ${arg//"/"/"\/"})
    outdirn=$arg
  elif [ "$keyword" = "netcdf_format" ]; then
    netcdf_format=$arg
  elif [ "$keyword" = "lctrimfrac" ]; then
    lctrimfrac=$arg
  elif [ "$keyword" = "lai_threshold_replace" ]; then
    lai_threshold_replace=$arg
  elif [ "$keyword" = "metadata_description" ]; then
    metadata_description=$(echo ${arg//"/"/"\/"})
  elif [ "$keyword" = "overwrite_laimax" ]; then
    arg=$(echo $arg | tr [:lower:] [:upper:])
    if [ "$arg" = "YES" ] || [ "$arg" = "Y" ] || [ "$arg" = "TRUE" ] || [ "$arg" = "T" ]; then
      overwrite_laimax="True"
    else
      overwrite_laimax="False"
    fi
  elif [ "$keyword" = "suffix" ]; then
    if [ ${#arg} -eq 0 ]; then
      append_rng=$(date '+%Y-%m-%d')
    else
      append_rng="${arg}_$(date '+%Y-%m-%d')"
    fi
  elif [ "$keyword" = "regression" ]; then
    arg=$(echo $arg | tr [:upper:] [:lower:])
    if [ "$arg" = "kde" ] || [ "$arg" = "kde_scott" ] || [ "$arg" = "kdescott" ] || [ "$arg" = "scott" ] || [ "$arg" = "pdf" ]; then
      regression="kde"
    elif [ "$arg" = "kde_silverman" ] || [ "$arg" = "kdesilverman" ] || [ "$arg" = "silverman" ]; then
      regression="kde_silverman"
    elif [ "$arg" = "average" ] || [ "$arg" = "weighted_average" ] || [ "$arg" = "weightedaverage" ] || [ "$arg" = "wtd_avg" ] || [ "$arg" = "wtdavg" ] || [ "$arg" = "avg" ]; then
      regression="weighted_average"
    fi
  fi

done < $configfile

mkdir -p $outdirn

# resolution
# change to all caps
resolution=$(echo $resolution | tr [:lower:] [:upper:])

if [ "$resolution" = "4X5" ]; then
  dimensions="(46, 72)"
  latdim="np.arange(-90.0, 94.0, 4.0)"
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

userout="../user/output/"
userout=$outdirn

# generate filenames 

# data sources
metadata_filenames="${prec} ${temp} ${lai} ${laimax} ${lc} ${height} at resolution ${dimname}"

# output of prectemp2biome.sh
biome="V${dimname}_KGbiomes_${append_rng}.nc"

# output of regress_biome2laihite.py
lai_csv_file_raw="EntKG_regressionLAI_monthly_raw_${append_rng}.csv"
laimax_csv_file_raw="EntKG_regressionLAI_max_raw_${append_rng}.csv"
height_csv_file_raw="EntKG_regressionheight_raw_${append_rng}.csv"
lc_csv_file_raw="EntKG_regressionLC_raw_${append_rng}.csv"
samples_csv_file="EntKG_regressionsamples_${append_rng}.csv"

# output of csv tools
lai_csv_file="EntKG_regressionLAI_monthly_${append_rng}.csv"
laimax_csv_file="EntKG_regressionLAI_max_${append_rng}.csv"
height_csv_file="EntKG_regressionheight_${append_rng}.csv"
lc_csv_file="EntKG_regressionLC_trim_natveg_${append_rng}.csv"

# output of csv2lut.py
lut_out="Ent_v${resolution}_KoeppenGeigerLUT_${append_rng}.nc"

# use KG_classify instead ~~run prectemp2biome.sh~~
#echo -e "${prec}\t${temp}\t${outdirn}${biome}" > "ptb_${append_rng}.txt"
#./prectemp2biome.sh "ptb_${append_rng}.txt"
cp "KG_classify_config.txt" "${userout}KG_classify_config_${append_rng}.txt"

ex "${userout}KG_classify_config_${append_rng}.txt" <<EOF
  1s/@@RESOLUTION/${resolution}/
  2s/@@INDIR/\//
  3s/@@OUTDIR/${outdir}/
  4s/@@ID/${append_rng}/
  5s/@@TEMP/${temp}/
  6s/@@PREC/${prec}/
  wq
EOF

Rscript "../Rfiles/KG_classify.R" "${userout}KG_classify_config_${append_rng}.txt" "TRUE"

if [ $? -ne 0 ]; then
  echo "Error raised in step, halting."
  exit 10
fi

mv "${outdirn}KG${resolution}_biomes_${append_rng}.nc" "${outdirn}${biome}"
#rm "KG_classify_config_${append_rng}.txt"

# run regress_biome2laihite.py
cp "regress_biome2laihite.py" "${userout}regress_biome2laihite_${append_rng}.py"

ex "${userout}regress_biome2laihite_${append_rng}.py" <<EOF
  20s/@@BIOME/${outdir}${biome}/
  21s/@@LAI/$lai/
  22s/@@LAIMAX/$laimax/
  23s/@@HEIGHT/$height/
  24s/@@HGT/$hgt/
  25s/@@LC/$lc/
  31s/@@REGRESSION/$regression/
  40s/@@DIMENSIONS/$dimensions/
  41s/@@LATDIM/$latdim/
  42s/@@LONDIM/$londim/
  44s/@@OUTDIR/$outdir/
  34s/@@LAI_CSV_FILE_RAW/$lai_csv_file_raw/
  35s/@@LAIMAX_CSV_FILE_RAW/$laimax_csv_file_raw/
  36s/@@HEIGHT_CSV_FILE_RAW/$height_csv_file_raw/
  37s/@@LC_CSV_FILE_RAW/$lc_csv_file_raw/
  38s/@@SAMPLES_CSV_FILE/$samples_csv_file/
  wq
EOF

python "${userout}regress_biome2laihite_${append_rng}.py"
#rm "regress_biome2laihite_${append_rng}.py"

if [ $? -ne 0 ]; then
  echo "Error raised in step, halting."
  exit 10
fi

# run csvLAIdominanthemi.py
cp "csvLAIdominanthemi.py" "${userout}csvLAIdominanthemi_${append_rng}.py"

ex "${userout}csvLAIdominanthemi_${append_rng}.py" <<EOF
  8s/@@LAI_CSV_FILE_RAW/${outdir}${lai_csv_file_raw}/
  9s/@@SAMPLES_CSV_FILE/${outdir}${samples_csv_file}/
  14s/@@LAI_THRESHOLD_REPLACE/$lai_threshold_replace/
  11s/@@OUTDIR/$outdir/
  12s/@@LAI_CSV_FILE/$lai_csv_file/
  wq
EOF

python "${userout}csvLAIdominanthemi_${append_rng}.py"
#rm "csvLAIdominanthemi_${append_rng}.py"

if [ $? -ne 0 ]; then
  echo "Error raised in step, halting."
  exit 10
fi

# run csvremoveSTD.py
cp "csvremoveSTD.py" "${userout}csvremoveSTD_${append_rng}.py"

ex "${userout}csvremoveSTD_${append_rng}.py" <<EOF
  3s/@@LAIMAX_CSV_FILE_RAW/${outdir}${laimax_csv_file_raw}/
  4s/@@HEIGHT_CSV_FILE_RAW/${outdir}${height_csv_file_raw}/
  6s/@@OUTDIR/$outdir/
  7s/@@LAIMAX_CSV_FILE/$laimax_csv_file/
  8s/@@HEIGHT_CSV_FILE/$height_csv_file/
  wq
EOF

python "${userout}csvremoveSTD_${append_rng}.py"
#rm "csvremoveSTD_${append_rng}.py"

# run trim_Ent_KG_LUT.R
cp "../Rfiles/trim_Ent_KG_LUT.R" "${userout}trim_Ent_KG_LUT_${append_rng}.R"

ex "${userout}trim_Ent_KG_LUT_${append_rng}.R" <<EOF
  28s/@@LC_CSV_FILE_RAW/${outdir}${lc_csv_file_raw}/
  38s/@@LCTRIMFRAC/$lctrimfrac/
  29s/@@OUTDIR/$outdir/
  32s/@@LC_CSV_FILE/$lc_csv_file/
  wq
EOF

Rscript "${userout}trim_Ent_KG_LUT_${append_rng}.R"
#rm "trim_Ent_KG_LUT_${append_rng}.R"

if [ $? -ne 0 ]; then
  echo "Error raised in step, halting."
  exit 10
fi

# run csv2lut.py
cp "csv2lut.py" "${userout}csv2lut_${append_rng}.py"

ex "${userout}csv2lut_${append_rng}.py" <<EOF
  19s/@@OVERWRITE_LAIMAX/$overwrite_laimax/
  21s/@@DIMENSIONS/$dimensions/
  22s/@@LATDIM/$latdim/
  23s/@@LONDIM/$londim/
  28s/@@LAI_CSV_FILE/${outdir}${lai_csv_file}/
  29s/@@LAIMAX_CSV_FILE/${outdir}${laimax_csv_file}/
  30s/@@HEIGHT_CSV_FILE/${outdir}${height_csv_file}/
  31s/@@LC_CSV_FILE/${outdir}${lc_csv_file}/
  140s/@@METADATA_FILENAMES/$metadata_filenames/
  142s/@@METADATA_DATAVERSION/$metadata_dataversion/
  145s/@@METADATA_DESCRIPTION/$metadata_description/
  26s/@@NETCDF_FORMAT/$netcdf_format/
  33s/@@OUTDIR/$outdir/
  34s/@@LUT_OUT/$lut_out/
  wq
EOF

python "${userout}csv2lut_${append_rng}.py"
echo "Output file: ${outdir}${lut_out}"
#rm "csv2lut_${append_rng}.py"

if [ $? -ne 0 ]; then
  echo "Error raised in step, halting."
  exit 10
fi

echo "Intermediate scripts used to generate outputs can be found here: ${userout}"
echo "All output files:"
ls ${outdir}*${append_rng}*
