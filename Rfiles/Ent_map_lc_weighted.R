#Ent_map_lc_weighted.R
#Generate netcdf maps of dominant Ent cover or cover-weighted averages  of height, lai max, or lai monthly
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
pathin = strsplit(readLines(con=configfile, n=top+1)[[top+1]]," ")[[1]][2]
if (pathin[length(pathin)]!="/") { pathin = paste(pathin,  "/", sep="") }
pathout = strsplit(readLines(con=configfile, n=top+2)[[top+2]]," ")[[1]][2]
if (pathout[length(pathout)]!="/") { pathout = paste(pathout,  "/", sep="") }
fnames = read.table(configfile, header=FALSE, sep="", skip=top+2)
filelc = fnames[match("lc", fnames[,1]),2]

if (!dir.exists(pathout)) {
	dir.create(pathout)
}

#Dominant land cover
domlc = Ent_calc_domlc_GISS(file=paste(pathin, filelc, sep=""), lctypes=EntGVSD_PFTs)
fnameout = paste(filelc, "_domlc.nc", sep="")
if (if.pdf) {
	pdf(file=paste(pathout,  fnameout, ".pdf", sep=""), width=8, height=5)
	Ent_domlc_plot(lctype=domlc, numpft=16, res=res, legend.cex=0.6,  
		Entcolors=Entcolors16, if.new=FALSE)
		 mtext(fnameout, cex=0.8)
	dev.off()
}
fileoutnc = paste(pathout, filelc, "_domlc.nc", sep="")
create.map.template.nc(res=res.from.IM.JM(dim(domlc)[1],dim(domlc)[2]), varname="domlc", longname="dominant Ent land cover", units="category", vardescr="dominant Ent land cover catergory", description=paste("source file:", filelc), undef=-1e30,  fileout=fileoutnc, contact="Nancy.Y.Kiang@nasa.gov", vartype='NC_FLOAT') 
nc = open.nc(con=fileoutnc, write=TRUE)
var.put.nc(nc, "domlc", domlc)
close.nc(nc)
 
#Height cover-weighted map
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
heightwtdlc = Ent_calc_lc_weighted_map_GISS(
	filelc=paste(pathin, filelc, sep=""),
	filevar= paste(pathin, fileht, sep=""),
	pathout=pathout,
	varname="height", longname="canopy height", vardescr="cover-weighted canopy height",varpre=varpre,
	units="m", lctypes=EntGVSD_COV13, if.pdf=if.pdf,
	info=fileht)

#LAImax cover-weighted map
filelaimax = fnames[match("laimax", fnames[,1]),2]
laimaxwtdlc = Ent_calc_lc_weighted_map_GISS(
	filelc=paste(pathin, filelc, sep=""),
	filevar= paste(pathin, filelaimax, sep=""),
	pathout=pathout,
	varname="laimax",  longname="leaf area index (LAI) annual maximum", vardescr="cover-weighted maximum annual LAI", varpre="",
	units="m^2/m^2", lctypes=EntGVSD_COV13, 
	if.pdf=if.pdf, zlim=c(0,6),
	info=filelaimax)

#LAI monthly cover-weighted map
filelai = fnames[match("lai", fnames[,1]),2]
laiwtdlc = Ent_calc_lc_weighted_map_GISS(
	filelc=paste(pathin, filelc, sep=""),
	filevar= paste(pathin, filelai, sep=""),
	pathout=pathout,
	varname="lai",  longname="leaf area index (LAI) monthly", vardescr="cover-weighted monthly LAI", varpre="", 
	units="m^2/m^2", lctypes=EntGVSD_COV13, 
	if.time=TRUE, if.pdf=if.pdf, zlim=c(0,6),
	info=filelai)

