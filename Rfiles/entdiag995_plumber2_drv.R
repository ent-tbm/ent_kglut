DEBUG=FALSE
#entdiag995_plumber2_drv.R
#Driver for calling routines in entdiag995fn.R to plot Ent outputs from PLUMBER2 runs.
#This version reads in an input file from the command line in the user directory.
#Rpath = "../Rfiles/"  #Must include the last "/"

#--------------------------------------------------------------------
#HOW-TO OLD: No input file, with edited inputs below.
#0) Load the R module on discover: module load R/3.6.3
#1) Edit the RUN, info, datadir, RUNdir, filedrv for your run.
#2) To run:  R CMD BATCH entdiag995_plumber2_drv.R
#3) Check log file Rout to make sure it ran without errors.
#4) Look at the generated pdf file of plots.

#----- EDIT THE PATHS AND FILE NAMES BELOW --------------------------
#RUN = "rd_lsm_ent_tumba_plumber2"

#info = "PLUMBER2-Tumbarumba-pheno"

#datadir ="/discover/nobackup/bvanaart/giss/data/"

#savedir = "/discover/nobackup/bvanaart/giss/RUNS_current/"

#fileforce = paste(datadir, "AU-Tum_2002-2016_OzFlux_Met_ent.nc", sep="")

#----- EDIT THE PATHS AND FILE NAMES ABOVE THIS LINE-------------------

#HOW-TO:  With text input file.
#0) Load the R module on discover: module load R/3.6.3
#1) Make a text config input file (see USAGE below).
#2) To run:  Rscript entdiag995_plumber2_drv.R <config_file.txt>
#     or to output a log file:
#            R CMD BATCH entdiag995_plumber2_drv.R <config_file.txt>
#3) Check log file Rout to make sure it ran without errors.
#4) Look at the generated pdf file of plots.

args = commandArgs(trailingOnly=TRUE)
numargs = length(args)
if (numargs != 1) {
print ('Usage:  R CMD BATCH entdiag995_plumber2_drv.R <config_file.txt>', quote = FALSE )
print ('<config_file.txt> should be a text file containing:', quote = FALSE )
print (' Rpath <path to Rfiles> (from Ent_utils/user this should be ../Rfiles)', quote = FALSE)
print ('  run <run_name>', quote = FALSE )
print ('  info <title and output file name>', quote = FALSE )
print ('  datadir <directory location of fileforce file (below)>', quote = FALSE)
print ('  rundir <savedisk directory containing run output directory>', quote = FALSE )
print ('  fileforce <name of met and veg forcings input file to run>', quote = FALSE )
print ('  printoption <1-print only fort.995; 2-print both fort.995 and fort.1082>', quote = FALSE )
quit()
}


configfile = args[1]
if (DEBUG) { print(con=stdout(), paste(configfile))}

#Read config file
textin = read.table(configfile, header=FALSE, sep="")

top=1
Rpath = textin[match("Rpath", textin[,1]),2]
RUN = textin[match("run", textin[,1]),2]
info = textin[match("info", textin[,1]),2]
datadir = textin[match("datadir", textin[,1]),2]
savedir = textin[match("savedir", textin[,1]),2]
fileforce = textin[match("fileforce", textin[,1]),2]
printoption = as.numeric(textin[match("printoption", textin[,1]),2])
cat( Rpath )
source(paste0(Rpath, "/entdiag995_plumber2fn.R"))

if (DEBUG) { 
print(con=stdout(), RUN)
print(info)
print(datadir)
print(savedir)
print(fileforce)
}

#Do plots
pathdiag = paste(savedir, RUN, sep="")
if (DEBUG) { print(con=stdout(), pathdiag) }
cat(paste0('filedrv:',datadir, "/", fileforce))
plumber2_ent(filedrv=paste0(datadir, "/", fileforce), pathdiag=pathdiag, pathout=pathdiag, info=info, if.new=TRUE, option=printoption)

