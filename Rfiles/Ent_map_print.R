#Ent_map_print.R
#Print out maps of Ent vegetation netcdf input files.
#Input file format is ModelE format.

args = commandArgs(trailingOnly=TRUE)
print(paste('args:', args))
numargs = length(args)
if (numargs < 1) {
print ('Usage:  Rscript Ent_map_print.R <config_file> <option: [Ent class]>', quote = FALSE )
print('config_file = text file name', quote = FALSE)
print('option: Ent class = <EntGVSD_PFTs (default)| EntGVSD_COV13 | EntGVSD_COV17 >', quote=FALSE)
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

source("../Rfunctions/utils_noSDMTools.R")
library("RNetCDF")

configfile = args[1]
if (numargs>1) {
        Entclass = args[2]
} else {
        Entclass = 'EntGVSD_PFTs'
}

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

#-------------
if (Entclass=='EntGVSD_PFTs') {
	enttyp=EntGVSD_PFTs
} else if (Entclass=='EntGVSD_COV13') {
	enttyp=EntGVSD_COV13
} else if (Entclass=='EntGVSD_COV17') {
	enttyp=EntGVSD_COV17
} else {
	print('option: Ent class = <EntGVSD_PFTs (default)| EntGVSD_COV13 | EntGVSD_COV17 >', quote=FALSE)
	quit()
}

#lc
filepdf=paste0(pathout, filelc, ".pdf")
pdf(file=filepdf, height=7, width=11)
par(mfrow=c(4,5), omi=c(0,0.0,1.5,0.5), mar=c(1,1,2,2)+0.1)
zlim=c(0,1)
varout=map.EntGVSD(filelc=NULL, file=paste0(pathin,filelc), res=res, varpre="", varlist=enttyp, colors=giss.palette.nowhite(40), type="any", zlim=zlim, xaxt="n", yaxt="n", if.zeroNA=TRUE, titletype=1)
mtext(outer=TRUE, filelc)
dev.off()

#height
fileht = fnames[match("height", fnames[,1]),2]
#varprecheck = fnames[match("height", fnames[,1]),3]
#if (!is.null(varprecheck)) {
#        if (!is.na(varprecheck)) {
#                varpre = paste(fnames[match("height", fnames[,1]),3], "_", sep="")
#        } else {
#                varpre = ""
#        }
#} else {
#        varpre=""
#}
varpre="hgt"
filepdf=paste0(pathout, fileht, ".pdf")
pdf(file=filepdf, height=7, width=11)
par(mfrow=c(4,5), omi=c(0,0.0,1.5,0.5), mar=c(1,1,2,2)+0.1)
zlim=c(0,40)
varout=map.EntGVSD(filelc=paste0(pathin,filelc), file=paste0(pathin,fileht), res=res, varpre=paste0(varpre,"_"), varlist=enttyp, colors=giss.palette.nowhite(40), type="any", zlim=zlim, xaxt="n", yaxt="n", if.zeroNA=TRUE, titletype=1)
mtext(outer=TRUE, fileht)
dev.off()

#laimax
filelaimax = fnames[match("laimax", fnames[,1]),2]
filepdf=paste0(pathout, filelaimax, ".pdf")
pdf(file=filepdf, height=7, width=11)
par(mfrow=c(4,5), omi=c(0,0.0,1.5,0.5), mar=c(1,1,2,2)+0.1)
zlim=c(0,5)
varout=map.EntGVSD(filelc=paste0(pathin,filelc), file=paste0(pathin,filelaimax), res=res, varpre="", varlist=enttyp, colors=giss.palette.nowhite(40), type="any", zlim=zlim, xaxt="n", yaxt="n", if.zeroNA=TRUE, titletype=1)
mtext(outer=TRUE, filelaimax)
dev.off()

#lai
filelai = fnames[match("lai", fnames[,1]),2]
filepdf=paste0(pathout, filelai, ".pdf")
print(paste(filelai, filepdf))
pdf(file=filepdf, height=7, width=11)
mfrow=c(3,4)
par(mfrow=mfrow, omi=c(0,0.0,1.5,0.5), mar=c(1,1,2,2)+0.1)
zlim=c(0,5)
varout=map.EntGVSD.time(file=paste0(pathin,filelaimax), res=res, varpre="", varlist=enttyp, colors=giss.palette.nowhite(40), type="any", zlim=zlim, xaxt="n", yaxt="n", mfrow=mfrow, if.zeroNA=TRUE, titletype=3)
mtext(outer=TRUE, filelaimax)
dev.off()

