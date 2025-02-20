#!/bin/bash
#data_get_2HX2.sh

#Copy to repository data sets files from the NCCS data portal or set up soft links to repository data sets.

DATAPATH=/discover/nobackup/projects/giss_ana/pub/Ent_TBM/Ent_utils/kglut_modelE/data/HXH
DATAPORTAL=https://portal.nccs.nasa.gov/datashare/GISS/Ent_TBM/Ent_utils/kglut_modelE/data/HXH

ts="cru_ts3.22_TS_means_2001-2010_HXH.nc"
prec="GPCC_v6_PREC_means_1901-1950_HXH.nc"
height="V720x360_EntGVSD16_MM_height_trimmed_scaled_nocrops_v1.0b.nc"
laimax="V720x360_EntGVSD16_MM_lai_max_trimmed_scaled_nocrops_v1.0b.nc"
lai="V720x360_EntGVSD16_MM_lai_trimmed_scaled_v1.0b.nc"
lc="V720x360_EntGVSD16_MM_lc_max_trimmed_scaled_nocrops_v1.0b.nc"

if [ -d $DATAPATH ]; then
  ln -s ${DATAPATH}/${ts}
  ln -s ${DATAPATH}/${prec}
  ln -s ${DATAPATH}/${height}
  ln -s ${DATAPATH}/${laimax}
  ln -s ${DATAPATH}/${lai}
  ln -s ${DATAPATH}/${lc}
else
  wget ${DATAPORTAL}/${ts}
  wget ${DATAPORTAL}/${prec}
  wget ${DATAPORTAL}/${height}
  wget ${DATAPORTAL}/${laimax}
  wget ${DATAPORTAL}/${lai}
  wget ${DATAPORTAL}/${lc}
fi
