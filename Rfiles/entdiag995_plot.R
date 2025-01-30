#entdiag995_plot.R
#Author: nancy.y.kiang@nasa.gov

#Plot time series of diagnostics from Ent_standalone, giss_LSM_standalone, plumber2.
#--------------------

args = commandArgs(trailingOnly=TRUE)
print(args)
numargs = length(args)
if (numargs < 3) {
cat('Usage:  Rscript $R_Ent/entdiag995_plot.R <pathin/> <run name> <site> <sitefilecsv> <NEEname> <skip> < 1 | 2 | 3 > <a> <version 1 | 2>', '\n' )
cat('Generate plots of standalone_LSM diagnostics.', '\n')
cat('pathin/ = path where run output directory is, e.g. $SAVEDISK.', '\n')
cat('run name = run name.', '\n')
cat('site = Fluxnet or PLUMBER2 site name for data file with observations to plot with simulation.',  '\n')
cat('       Currently supported:  MMSF | Vaira \n')
cat('sitefilecsv = path and csv file of site Fluxnet data in directory with site name', '\n')
cat('       Default available site data files: \n')
cat('        /discover/nobackup/nkiang/DATA/Entdata/Sitedata/MMSF/dataMMSF_enteval.csv \n')
cat('        /discover/nobackup/nkiang/DATA/Entdata/Sitedata/Vaira/Vaira2002_version2006_gapfilled_Fluxnet.dat \n')
cat('NEEname = column name for NEE in the sitefilecsv. \n')
cat('skip = number of misc. rows to skip above the header in the sitefilecsv. \n')
cat('optional N = 1-Ent_standalone (default), 2-giss_LSM_standalone, 3-plumber2', '\n')
cat('optional opts = a-plot ACTS albedo, b-a and also plot clump factors', '\n')
cat('optional version = 1-previous plot version without canopyalbedo(:), 2-newer version with canopyalbedo(:)', '\n')
quit()
}

path = paste0(args[1], '/')
#cat(path, '\n')
runname = args[2]
#cat(runname,'\n')
sitename = args[3]
sitefilecsv = args[4]
NEEname = args[5]
skip=args[6]

skip = 0           #Default no rows to skip.
if (numargs > 5) {
 skip = args[6]
}
config = 1           #Default Ent_standalone run
if (numargs > 6) {
 config = args[7]
}

if.acts = FALSE
if.clump = FALSE
if (numargs > 7) {
 if (args[7]=='a') { 
   if.acts = TRUE
 } else if (args[8]=='b') {
   if.acts = TRUE
   if.clump = TRUE
 }
}

if.ver2 = FALSE      #Default, previous for.995 without pp%albedo output.
if (numargs > 8) {
 if (args[9]=='2') {
   if.ver2 = TRUE    #Output pp%albedo(:)
 } 
}

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
cat(Rpath, "\n")
source(paste0(Rpath, "utils_noSDMTools.R"))
source(paste0(Rpath, "entdiag995fn.R"))

runpath = paste0(path, runname, "/")
site = sitename
#sitefilepath = "/discover/nobackup/nkiang/DATA/Entdata/Sitedata/"
datafile = sitefilecsv
#--------------------

#datafile = paste0("/discover/nobackup/nkiang/DATA/Entdata/Sitedata/", site, "/", paste0("data",site,"_enteval.csv"))
cat('data file: ', datafile, "\n")
data = read.table(datafile, sep=",",header = TRUE)
print(names(data))

cat('run directory: ', runpath, "\n")
fort.995=read.table(paste0(runpath,"fort.995"), header=TRUE) #FALSE ) #TRUE)
	#fort.980=read.table(paste0(runpath,"fort.980"), header=FALSE, skip=1)
	fort.980=read.table(paste0(runpath,"fort.980"), header=TRUE)
	#names(fort.980) = names.fort.980[1:ncol(fort.980)]
#	fort.1080=read.table(paste(runpath, "fort.1080", sep=""),	header=FALSE)
#	fort.1082=read.table(paste(runpath, "fort.1082", sep=""),	header=FALSE)
#	fort.1082 = fort.1082[,1:21]


nyr = fort.995[nrow(fort.995),"timecum"]/86400/365

#d = Time vector in days
#d = 1+ (1:nrow(fort.995[,]) - 1)/24  #Fluxnet hourly for MMSF

pdf(file=paste0(runname,"_", Sys.Date(),".pdf"), width=6, height=8)
par(mfrow=c(3,2), omi=c(0,0,0.5,0.5))#, ask=TRUE )

fluxdmat = plot995r(day=NULL,fort.995[,2:ncol(fort.995)], 
   #fluxNEE=rep(data[,c("NEE.umol.m.2.s.1")],nyr), 
   fluxNEE=rep(data[,c(NEEname)],nyr), skip=skip,
   titleouter=paste(runname, Sys.Date()),
   line=0, type="l", #daily=24, 
   if.dailyonly=FALSE, if.ver2=if.ver2)

if (if.acts) {
  cat('Plotting ACTS \n')
  fort.1082 = read.table(paste0(runpath, "fort.1082"), header=FALSE)
  fort.1080 = read.table(paste0(runpath, "fort.1080"), header=FALSE)
  d = 1 + (fort.995[,"timecum"] - fort.995[1,"timecum"])/86400
  temp=plotgort1082(d, fort.1082, lai=fort.995[,"lai"], alim=0.6, titletext=runname)
  plotacts1080(d, fort.1080, alim=0.6, titletext=runname)

  if (if.clump) {
  cat('Plotting clumping factors \n')
  system( paste0("grep clump ", runpath,  "fort.1078  > fort.1078.clump"))
  fort.1078.clump = read.table(paste0(runpath, "fort.1078.clump"), header=FALSE)
  names(fort.1078.clump) = c("names", "clumpd", "clumpi")
  plotclump1078(d, fort.1078.clump)
  }
}

dev.off()

cat('Plotted ', runname, ".\n\n")


