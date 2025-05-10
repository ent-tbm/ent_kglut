#KG_classify.R
#Classify maps of temperature and precipitation, and output a map of Koeppen-Geiger classes, both netcdf and plot.
#Temperature and precip files should be netcdf files, each with a variable of dimension (IM, JM, 12) for monthly values.
#To test existing climate files on discover:
# export R_Ent=path to your Rfiles directory
# cd Ent_utils/user
# cd input #If no input directory, then mkdir input
# ln -s /discover/nobackup/nkiang/DATA/CRU_TS3.22/CRU_TS3.22_2HX2/cru_ts3.22_TMN_means_1951-1980_2HX2.nc cru_ts3.22_TMN_means_1951-1980_2HX2.nc 
# ln -s /discover/nobackup/nkiang/DATA/GPCC/GPCC_v6_2HX2/GPCC_v6_PREC_means_1951-1980_2HX2.nc GPCC_v6_PREC_means_1951-1980_2HX2.nc
# cd ..  #cd back into user directory
#If no output directory, then mkdir output
# Rscript $R_Ent/KG_classify.R  $R_Ent/config/config_KG_classify_1951-1980.txt
#Netcdf file will be generate and put in your output directory.

args = commandArgs(trailingOnly=TRUE)
print(args)
numargs = length(args)
if (numargs < 1) {
print ('Usage:  Rscript KG_classify.R <config_file> <ignorepathin>', quote = FALSE )
print('config_file = text file name. See sample config file in Rfiles/config/config_KG_classify_1951-1980.txt', quote = FALSE)
print('config_file must contain the following:', quote=FALSE)
print(' res < spatial resolution 2x2h | 4x5 | hxh | qxq >', quote = FALSE)
print(' pathin < input path/ >', quote = FALSE)
print(' pathout < output path/ >', quote = FALSE)
print(' id <run id >', quote = FALSE)
print(' temp < temperature (Celsius) monhtly maps in netcdf file of dimension (IM,JM,12) >', quote = FALSE)
print(' prec < precipitation (mm/month) monthly maps in netcdf file of dimension (IM, JM 12) >', quote = FALSE)
print(' tname < netcdf variable name for temp file, e.g. tsurf >', quote = FALSE)
print(' pname < netcdf variable name for prec file, e.g. prec >', quote = FALSE)
quit()
}

configfile = args[1]

if (numargs>1) {
	if.ignorepathin=args[2]
} else {
	if.ignorepathin=FALSE
}

Rpath = Sys.getenv("R_Ent")
Rpath

if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
source(paste0(Rpath, "/utils_noSDMTools.R"))
source(paste0(Rpath, "/KoeppenGeiger.R"))
library(rworldmap)

#Parse config file
if (FALSE) {
top=1
res = strsplit(readLines(con=configfile, n=top)[[top]]," ")[[1]][2]
pathin = paste(strsplit(readLines(con=configfile, n=top+1)[[top+1]]," ")[[1]][2], "/", sep="")
pathout = paste(strsplit(readLines(con=configfile, n=top+2)[[top+2]]," ")[[1]][2], "/", sep="")
id = strsplit(readLines(con=configfile, n=top+3)[[top+3]]," ")[[1]][2]
tempfile = strsplit(readLines(con=configfile, n=top+4)[[top+4]]," ")[[1]][2]
precfile = strsplit(readLines(con=configfile, n=top+5)[[top+5]]," ")[[1]][2]
tname = strsplit(readLines(con=configfile, n=top+6)[[top+6]]," ")[[1]][2]
pname = strsplit(readLines(con=configfile, n=top+7)[[top+7]]," ")[[1]][2]
}

textin = read.table(file=configfile, header=FALSE, quote=" ")
#print(textin)
res = as.character(textin[match("res", textin[,1]),2])
pathin=as.character(textin[match("pathin", textin[,1]),2])
pathout=as.character(textin[match("pathout", textin[,1]),2])
id=as.character(textin[match("id", textin[,1]),2])
tempfile=as.character(textin[match("temp", textin[,1]),2])
precfile=as.character(textin[match("prec", textin[,1]),2])
tname=as.character(textin[match("tname", textin[,1]),2])
pname=as.character(textin[match("pname", textin[,1]),2])

if (FALSE) {
print(res, quote = FALSE )
print(pathin, quote = FALSE )
print(pathout, quote = FALSE )
print(tempfile, quote = FALSE )
print(precfile, quote = FALSE )
print(tname, quote = FALSE )
print(pname, quote = FALSE )
}

if (!dir.exists(pathout)) {
	dir.create(pathout)
}

#idn = strsplit(tempfile, ".nc")[[1]][1]
#print(idn)
#idn2 = strsplit(idn, "_")[[1]]
#id = idn2[length(idn2)]
#print(id)

#Generate the classification
IM.JM = IM.JM.from.res(res)
IM = IM.JM[1]
JM = IM.JM[2]
#print(paste("IM, JM = ", IM, JM))

if (if.ignorepathin) {
  Tnc = tempfile
  Pnc = precfile
} else {
  Tnc = paste(pathin, "/", tempfile, sep="")
  Pnc = paste(pathin, "/", precfile, sep="")
}
print(Tnc)
print(Pnc)
#KGnum = run.KG(Tnc="TEMPERATURE_DATA",
#	Pnc="PRECIPITATION_DATA",
#	Tname="tmp",
#	Pname="prec",
#	IM=IM, JM=JM,
#	ttext="TEMPERATURE_DATA", 
#	ptext="PRECIPITATION_DATA",
#	if.new=FALSE)


KGnum = run.KG(Tnc=Tnc,
	Pnc=Pnc,
	Tname=tname,
	Pname=pname,
	IM=IM, JM=JM,
	ttext=tempfile, 
	ptext=precfile,
	if.new=FALSE)

#Plot 
PLOTFILENAME=paste(pathout, "/", "KGbiomes_",res,"_map_", id, ".pdf", sep="")
pdf(PLOTFILENAME, width=9.6, height=6)
par(omi=c(0,0,0,1)) #(bottom, left, top, right)
par(omi=c(0,0,0,0), oma=c(0,0,0,4)) #(bottom, left, top, right) #Use for single

plot.KG(KGnum, if.new=FALSE)
par(xpd=TRUE)
legend(-180, 112, legend=KGcat[1:20,"KGcode"],col=KGrgbhex[1:20], pt.cex=2, pch=15, cex=0.6, horiz=TRUE, bty="n")
legend(-180, 101, legend=KGcat[21:40,"KGcode"],col=KGrgbhex[21:40], pt.cex=2, pch=15, cex=0.6, horiz=TRUE, bty="n")
dev.off()

#Write netcdf file
OUTPUTFILENAME=paste(pathout, "/", "KGbiomes_",res,"_",id, ".nc", sep="")
write.KoeppenGeiger.netcdf(KGnum, fname=OUTPUTFILENAME, varname="KG", undef=-1e30, description=paste("Koeppen-Geiger classification of: ", tempfile, ", ", precfile,".", sep=""))


