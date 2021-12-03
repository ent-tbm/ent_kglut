#data_link.sh
#Set up soft links to repository data sets.

DATAPATH=/discover/nobackup/projects/giss_ana/pub/Ent_TBM/Ent_utils/kglut_modelE/data/

ln -s ${DATAPATH}/cru_ts3.22_TS_means_2001-2010_2HX2.nc
ln -s ${DATAPATH}/GPCC_v6_PREC_means_2001-2010_2HX2.nc
ln -s ${DATAPATH}/V144x90_EntMM16_height_trimmed_scaled_ext1.nc
ln -s ${DATAPATH}/V144x90_EntMM16_lai_max_trimmed_scaled_ext1.nc
ln -s ${DATAPATH}/V144x90_EntMM16_lai_trimmed_scaled_ext1.nc
ln -s ${DATAPATH}/V144x90_EntMM16_lc_max_trimmed_scaled.nc

