#entdiag_geoalb_plot.R

#Plot map outputs from an Ent/ACTS Ent_standalone global albedo run.
#Run from inside the output diretory. E.g. in $SAVEDISK/<runname>

plotij="Rscript $R_Ent/plot_any_ij.R ."
$plotij Ent_albedo_2HX2.nc 
$plotij Ent_albedodatacheck_2HX2.nc
$plotij Ent_dbhdatacheck_2HX2.nc
$plotij Ent_hdatacheck_2HX2.nc
$plotij Ent_laidatacheck_2HX2.nc
$plotij Ent_popdatacheck_2HX2.nc
$plotij Ent_soilalbedodatacheck_2HX2.nc
$plotij Ent_vegdatacheck_2HX2.nc

