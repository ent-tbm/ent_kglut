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

#savedir = "/discover/nobackup/bvanaart/giss/RUNS_current/"

#datadir ="/discover/nobackup/bvanaart/giss/data/"
#fileforce = paste(datadir, "AU-Tum_2002-2016_OzFlux_Met_ent.nc", sep="")

#----- EDIT THE PATHS AND FILE NAMES ABOVE THIS LINE-------------------

#HOW-TO:  With text input file.
# Load the R module on discover: module load R/3.6.3

args = commandArgs(trailingOnly=TRUE)
numargs = length(args)
if (numargs < 3) {
print ('Usage:  R CMD BATCH entdiag995_plumber2_drv.R <SAVEDISK> <runname> <fileforce> <printoption>', quote = FALSE )
print ('  SAVEDISK <directory where your SAVEDISK is', quote = FALSE )
print ('  runname <run name>', quote = FALSE )
print ('  fileforce <full path and name of met and veg forcings input file to run>', quote = FALSE )
print ('  printoption <1-print only fort.995; 2-print both fort.995 and fort.1082>', quote = FALSE )
quit()
}

savedir = args[1]
RUN = args[2]
fileforce = args[3]
if (numargs > 3) {
 printoption=as.numeric(args[4])
} else {
 #default
 printoption=1
}

info=RUN
cat("savedir: ", savedir, "\n")
cat("RUN: ", RUN, "\n")
cat("fileforce: ", fileforce, "\n")
cat("printoption: ", printoption, "\n")
cat(info, "\n")

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
cat(Rpath, "\n")
source(paste0(Rpath, "/entdiag995_plumber2fn.R"))


if (DEBUG) { 
print(con=stdout(), RUN)
print(info)
print(savedir)
print(fileforce)
}


#Do plots
rundir = paste0(savedir, "/", RUN)
if (DEBUG) { print(con=stdout(), pathdiag) }
cat('filedrv: ', fileforce, "\n")


plumber2_ent(filedrv=fileforce, pathdiag=rundir, pathout='./', info=info, if.new=TRUE, option=printoption)

