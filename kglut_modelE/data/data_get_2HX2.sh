#!/bin/bash
#data_get_2HX2.sh

#Copy to repository data sets files from the NCCS data portal or set up soft links to repository data sets.

DATAPATH=/discover/nobackup/projects/giss_ana/pub/Ent_TBM/Ent_utils/kglut_modelE/data/2HX2
DATAPORTAL=https://portal.nccs.nasa.gov/datashare/GISS/Ent_TBM/Ent_utils/kglut_modelE/data/2HX2

ts="cru_ts3.22_TS_means_2001-2010_2HX2.nc"
prec="GPCC_v6_PREC_means_2001-2010_2HX2.nc"
height="V144x90_EntGVSD_v1.0_MM16_height_trimmed_scaled.nc"
laimax="V144x90_EntGVSD_v1.0_MM16_lai_max_trimmed_scaled.nc"
lai="V144x90_EntGVSD_v1.0_MM16_lai_trimmed_scaled.nc"
lc="V144x90_EntGVSD_v1.0_MM16_lc_max_trimmed_scaled.nc"
height_ext="V144x90_EntMM16_height_trimmed_scaled_ext.nc"
laimax_ext="V144x90_EntMM16_lai_max_trimmed_scaled_ext.nc"
lai_ext="V144x90_EntMM16_lai_trimmed_scaled_ext.nc"

if [ -d $DATAPATH ]; then
  ln -s ${DATAPATH}/${ts}
  ln -s ${DATAPATH}/${prec}
  ln -s ${DATAPATH}/${height}
  ln -s ${DATAPATH}/${laimax}
  ln -s ${DATAPATH}/${lai}
  ln -s ${DATAPATH}/${lc}
  ln -s ${DATAPATH}/${height_ext}
  ln -s ${DATAPATH}/${laimax_ext}
  ln -s ${DATAPATH}/${lai_ext}
else
  wget ${DATAPORTAL}/${ts}
  wget ${DATAPORTAL}/${prec}
  wget ${DATAPORTAL}/${height}
  wget ${DATAPORTAL}/${laimax}
  wget ${DATAPORTAL}/${lai}
  wget ${DATAPORTAL}/${lc}
  wget ${DATAPORTAL}/${height_ext}
  wget ${DATAPORTAL}/${laimax_ext}
  wget ${DATAPORTAL}/${lai_ext}
fi
