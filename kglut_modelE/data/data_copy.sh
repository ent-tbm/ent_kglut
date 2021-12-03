#data_copy.sh
#Copy to repository data sets files from the NCCS data portal.

DATAPORTAL=https://portal.nccs.nasa.gov/datashare/GISS/Ent_TBM/Ent_utils/kglut_modelE/data/

wget ${DATAPORTAL}/cru_ts3.22_TS_means_2001-2010_2HX2.nc
wget ${DATAPORTAL}/GPCC_v6_PREC_means_2001-2010_2HX2.nc
wget ${DATAPORTAL}/V144x90_EntMM16_height_trimmed_scaled_ext1.nc
wget ${DATAPORTAL}/V144x90_EntMM16_lai_max_trimmed_scaled_ext1.nc
wget ${DATAPORTAL}/V144x90_EntMM16_lai_trimmed_scaled_ext1.nc
wget ${DATAPORTAL}/V144x90_EntMM16_lc_max_trimmed_scaled.nc

