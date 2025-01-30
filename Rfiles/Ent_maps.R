#Ent_maps.R
#Generate pdf maps of height, lai max, and lai monthly
#Input file format is ModelE format.

args = commandArgs(trailingOnly=TRUE)
print(args)
numargs = length(args)
if (numargs < 1) {
print ('Usage:  Rscript Ent_map_lc_weighted.R <config_file> <option: if.pdf>', quote = FALSE )
print('config_file = text file name', quote = FALSE)
print('option: if.pdf = TRUE logical whether to print to pdf', quote=FALSE)
print('config_file must contain the following:', quote=FALSE)
print(' res < spatial resolution 2HX2 | 4x5 | HxH | QxQ >', quote = FALSE)
print(' pathin < input path/ >', quote = FALSE)
print(' pathout < output path/ >', quote = FALSE)
print(' lc < cover fraction file name >', quote = FALSE)
print(' height < height file name >', quote = FALSE)
print(' laimax < laimax file name >', quote = FALSE)
print(' lai < lai monthly file name >', quote = FALSE)
print('*All files must be in ModelE netcdf format.', quote = FALSE)
print('*An optional 3rd entry for the ModelE file names can be <NA | hgt>, because', quote=FALSE)
print('*the HITEent input file has a prefix "hgt_" for the netcdf array names.', quote=FALSE)
print('*If this prefix is needed, then all the other file name lines must have the 3rd entry as NA.', quote=FALSE)
quit()
} 

configfile = args[1]
if (numargs>1) {
	if.pdf=args[2]
} else {
	if.pdf=FALSE
}

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}

source(paste0(Rpath, "/utils_noSDMTools.R"))
library("RNetCDF")

textin = readLines(con=configfile, n=8)
#pathin = paste(strsplit(textin[3], " ")[[1]][2], "/")

top=1
res = strsplit(readLines(con=configfile, n=top)[[top]]," ")[[1]][2]
pathin = paste(strsplit(readLines(con=configfile, n=top+1)[[top+1]]," ")[[1]][2], "/", sep="")
pathout = paste(strsplit(readLines(con=configfile, n=top+2)[[top+2]]," ")[[1]][2], "/", sep="")
fnames = read.table(configfile, header=FALSE, sep="", skip=top+2)
filelc = fnames[match("lc", fnames[,1]),2]

fileht = fnames[match("height", fnames[,1]),2]
varprecheck = fnames[match("height", fnames[,1]),3]
if (!is.null(varprecheck)) {
	if (!is.na(varprecheck)) {
		varpre = paste(fnames[match("height", fnames[,1]),3], "_", sep="")
	} else {
		varpre = ""
	}
} else {
	varpre=""
}

filelaimax = fnames[match("laimax", fnames[,1]),2]
filelai = fnames[match("lai", fnames[,1]),2]

if (!dir.exists(pathout)) {
	dir.create(pathout)
}

if (if.pdf) {
#land cover
  pdf(file=paste(pathout, filelc, ".pdf", sep=""), width=8, height=5)
    map.EntGVSD(file=paste(pathin, filelc, sep=""), zlim=c(0,1), res=res)
  dev.off()
#height
  pdf(file=paste(pathout, fileht, ".pdf", sep=""), width=8, height=5)
    map.EntGVSD(file=paste(pathin, fileht, sep=""), zlim=c(0,20), varpre=varpre, res=res)
  dev.off()
#laimax
  pdf(file=paste(pathout, filelaimax, ".pdf", sep=""), width=8, height=5)
    map.EntGVSD(file=paste(pathin, filelaimax, sep=""), zlim=c(0,6), res=res)
  dev.off()
#lai
  pdf(file=paste(pathout, filelai, ".pdf", sep=""), width=8, height=5)
    map.EntGVSD.time(file=paste(pathin, filelai, sep=""), zlim=c(0,6), res=res)
  dev.off()
}

