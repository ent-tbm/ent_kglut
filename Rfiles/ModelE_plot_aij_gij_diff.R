#ModelE_plot_aij_gij_diff.R
#Author:  N.Y.Kiang
#Originally developed on NYK Mac as ModelE_check.R

#Difference maps between two runs of full set of either aij or gij diagnostics from ModelE.
#Can do old version of aij that includes gij diagnostics or new version without.

#---------------------

#Example files:
#path = "/discover/nobackup/nkiang/ModelE2.1_lsmdiag/jlui1_E6F40_gij_ent_debug_2/GIJ/"
#path = "/Users/nkiang/NancyResearch/GISS/Models/jlui/E6F40_gij_ent_debug_2/gij/"
#fname = "ANN1954.aijE6F40_gij_ent_debug_2.nc"  #nvars=861
#fname = "JAN1954.gijE6F40_gij_ent_debug_2.nc" #nvars=1031
#fname = "JUL1954.gijE6F40_gij_ent_debug_2.nc"
#path = "/Users/nkiang/NancyResearch/Papers/CMIP6/Ito_C4MIP/c4mip_modele/aij/Egigcc_exp25_hist/"
#fname = "ANN2014.aijEgigcc_exp25.nc" #nvars=1933

args = commandArgs(trailingOnly=TRUE)
print(args)
numargs = length(args)
if (numargs < 4) {
cat('Usage:  Rscript ../Rfiles/ModelE_plot_aij_gij.R <pathin1/> <filename1> <pathin2/> <filename2> <optional N|numra>', '\n' )
cat('Generate difference maps of file2-file1 ModelE aij or gij diagnostics, using diagnostics available in file1.', '\n')
cat('pathin/ = path where diagnostics file is.', '\n')
cat('filename = name of ModelE aij or gij diagnostics netcdf file.', '\n')
cat('pathin2/ = path where diagnostics file2 is.', '\n')
cat('filename2 = name of ModelE aij or gij diagnostics netcdf file2.', '\n')
cat('optional N|numra = N no Ent ra diags | numra number of Ent ra diagnostics. Default 42; prior to 2023 was 27.', '\n')
quit()
}

path = paste0(args[1], '/')
fname = args[2]
path2 = paste0(args[3], '/')
fname2 = args[4]

print(path)
print(fname)
print(path2)
print(fname2)
if (numargs==5) {
  numra = args[5]
}

pathout = '.'  #'output'
if (!dir.exists(pathout)) {
        dir.create(pathout)
}

#---------------------
library(stringr)
library(RNetCDF)
library(ncdf4) # For nc_open, natt_get does not bail if attr does not exit

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
cat(Rpath, "\n")
source(paste0(Rpath, "/utils_noSDMTools.R"))

nc4 = nc_open(paste0(path,fname))
nc42 = nc_open(paste0(path2,fname2))

nc = open.nc(con=paste0(path, fname), write=FALSE)
ndims <- file.inq.nc(nc)$ndims 
dimnames <- character(ndims) 
for(i in seq_len(ndims)) { 
   dimnames[i] <- dim.inq.nc(nc, i-1)$name } 
nvars <- file.inq.nc(nc)$nvars 

nc2 = open.nc(con=paste0(path2, fname2), write=FALSE)
ndims2 <- file.inq.nc(nc2)$ndims 
dimnames2 <- character(ndims2) 
for(i in seq_len(ndims2)) { 
   dimnames2[i] <- dim.inq.nc(nc2, i-1)$name } 
nvars2 <- file.inq.nc(nc2)$nvars 

CHECKAIJGIJDIFF=FALSE #==============================================================
if (CHECKAIJGIJDIFF) {
#Check if the new aij/gij breakdown is missing any of the original aij diagnostics.
vars = data.frame(varname=rep("",nvars), long_name=rep("",nvars), units=rep("",nvars))
hemis = rep(FALSE, nvars)
for(i in seq_len(nvars)) { 
  vars[i,"varname"] = var.inq.nc(nc, i-1)$name
  for (x in c( "long_name", "units")) {
	if (ncatt_get(nc4, vars[i, "varname"], x)$hasatt) { #ncatt_get is library(ncdf4)
			vars[i, x] = att.get.nc(nc, vars[i,"varname"], x)
	} else {
			vars[i, x] = paste0("No ",x)
			print(paste0("No ", x))
	}
  }
  print(paste(i, vars[i,"varname"]))
  hemis[i] = length(str_split(vars[i,"varname"], "_hemis")[[1]])>1
}
#vars.aij.Egigcc_exp25=vars; hemis.Egigcc_exp25=hemis; write.table(file="aij.ANN2014.aijEgigcc_exp25.csv", vars[!hemis,], quote=FALSE, row.names=FALSE, sep=",")
#vars.aij.james=vars; hemis.aij.james=hemis; write.table(file="aij.ANN1954.aijE6F40_gij_ent_debug_2.csv", vars[!hemis,], quote=FALSE, row.names=FALSE, sep=",")
vars.gij = vars;  hemis.gij=hemis; write.table(file="aij.JUL1954.gijE6F40_gij_ent_debug_2.csv", vars[!hemis,], quote=FALSE, row.names=FALSE, sep=",")

gij.in.aij = match(vars.gij[,"varname"], vars.aij.Egigcc_exp25[,"varname"])
vars.aij.Egigcc_exp25[gij.in.aij,"varname"]
vars.aij.Egigcc_exp25[-(gij.in.aij[!is.na(gij.in.aij)]),"varname"]
vars.gij[is.na(gij.in.aij),]
#            varname                                long_name    units
#44         landCtot TOTAL LAND ORGANIC CARBON (incl. excess) kg[C]/m2
#45   landCtot_hemis                             No long_name No units
#82       wbtl_depth                AVERAGE WATER TABLE DEPTH        m
#83 wbtl_depth_hemis                             No long_name No units

vars.aij.Egigcc_exp25.nohemis = vars.aij.Egigcc_exp25[!hemis.Egigcc_exp25,]
vars.gij.nohemis = vars.gij[!hemis.gij,]
gij.in.aij.nohemis = match(vars.gij.nohemis[,"varname"], vars.aij.Egigcc_exp25.nohemis[,"varname"])
vars.aij.Egigcc_exp25.nohemis[gij.in.aij.nohemis,]
vars.aij.Egigcc_exp25.nohemis[-(gij.in.aij.nohemis[!is.na(gij.in.aij.nohemis)]),]
vars.gij.nohemis[is.na(gij.in.aij.nohemis),]
#      varname                                long_name    units
#44   landCtot TOTAL LAND ORGANIC CARBON (incl. excess) kg[C]/m2
#82 wbtl_depth                AVERAGE WATER TABLE DEPTH        m
#write.table(file="aij.Egigcc_exp25.minus.gij.csv", vars.aij.Egigcc_exp25.nohemis[-(gij.in.aij.nohemis[!is.na(gij.in.aij.nohemis)]),], quote=FALSE, row.names=FALSE, sep=",")

vars.aij.james.nohemis = vars.aij.james[!hemis.aij.james & !is.na(hemis.aij.james),]
aij.james.in.aij = match(vars.aij.james.nohemis[,"varname"], vars.aij.Egigcc_exp25.nohemis[,"varname"])
vars.aij.Egigcc_exp25.nohemis[aij.james.in.aij,]
vars.aij.Egigcc_exp25.nohemis[is.na(aij.james.in.aij),]
setdiff(vars.aij.james.nohemis[, "varname"], vars.aij.Egigcc_exp25.nohemis[-(gij.in.aij.nohemis[!is.na(gij.in.aij.nohemis)]),"varname"])
}#======================================================================

#---- Make maps of all diagnostics -----
varnames <- character(nvars) 
for(i in seq_len(nvars)) { 
varnames[i] <- var.inq.nc(nc, i-1)$name
} 

#Find position of Ent ra diagnostics
if (numargs > 4) { #Specify number of ra diagnostics
  if (args[5] == 'N') { #No Ent ra diagnostics, any generic ij file
      ra1 = NA 
      nra=0
  } else {
    ra1 = match("ra001001" ,varnames)
    nra = as.numeric(args[5])
  }
} else { #Default
  ra1 = match("ra001001" ,varnames)
  nra=42  #42-E2.1_branch, 44-E2.1_lakes_slsm
}
if (nra > 0) {
  if (nra<10 ) {
      v3 = paste0("00",nra)
  } else if (nra<100) {
     v3 = paste0("0", nra)
  } else {
    v3 = paste0(nra)
  }
  ralastxt = paste0("ra",v3, "016")
  ralast = match(ralastxt, varnames)
  #ralast = match("ra027016_hemis", varnames)
  #ralast = match("ra042016_hemis", varnames)
  cat('Number of Ent diagnostics, numra, ra1, rlast, ralastxt: ', v3, ": ", nra, ra1, ralast, ralastxt,"\n")
} else {
  ralast = NA
}

axyp = var.get.nc(nc, "axyp")

#val = var.get.nc(nc, varnames[1])

#Map all non-hemis variables of non-Ent-ra diagnostics.
#pdf(file=paste(fname, "_nora.pdf", sep=""), height=7, width=10)
pdf(file=paste0(pathout,"/",fname,"-",fname,".", Sys.Date(), ".pdf"), height=7, width=10)
#quartz(height=6, width=10)
res=res.from.IM.JM(dim(axyp)[1], dim(axyp)[2])
colors = giss.palette(40)
par(mfrow=c(4,4))
par(omi=c(0,0,0,0), oma=c(0,1,4,1), mar=c(2,3,4,4))
if  (is.na(ralast)) {
 irange = 3:nvars
} else if (ralast==nvars) {
	irange = 3:(ra1-1)
} else {
	irange = c(3:(ra1-1), (ralast+1):nvars)
}
 print(paste("nvars", nvars, "irange", toString(irange)))
e <- simpleError("test error")
for (i in irange) { #non-ra diagnostics
#for (i in 3:nvars) {	
#for (i in 3:20) {	
	print(paste(i, varnames[i]))
	hemis = length(str_split(varnames[i], "hemis" )[[1]])>1
	print(paste(i, varnames[i], hemis))
	if (!hemis) {
		mapz = var.get.nc(nc, varnames[i])
                mapz2 = tryCatch(var.get.nc(nc2, varnames[i]), error = function(e) e)
                if (is.null(dim(mapz2))) { next }
		if (ncatt_get(nc4, varnames[i], "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
			datmis = att.get.nc(nc, varnames[i], "missing_value")
			mapz[mapz==datmis] = NA
		}
		if (ncatt_get(nc42, varnames[i], "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
			datmis = att.get.nc(nc2, varnames[i], "missing_value")
			mapz2[mapz2==datmis] = NA
		}
 		#att.inq.nc(nc, varnames[i], "units") #This bails if attr does not exist, cannot error handle
 		if (ncatt_get(nc4, varnames[i], "units")$hasatt) { #ncatt_get is library(ncdf4)
			units = paste("(", att.get.nc(nc, varnames[i], "units"), ")", sep="")
		} else {
			units = "(No units)"
			print("No units")
		}
		titletext = paste(varnames[i], units)
		plot.grid.continuous(mapz=mapz2-mapz, res=res, colors=colors, xlab="",ylab="", zlim=NULL, 
			titletext=titletext, if.fill=TRUE, cex.main=0.85, cex.axis=0.8, cex.legend=0.8)
		mtext(mapstat(mapz2-mapz, axyp, if.global=FALSE, dig=3, short=TRUE), cex=0.5)
		plot(coastsCoarse, add=TRUE, col=gray(0.3), lwd=0.3)
	}
	mtext(outer=TRUE, paste(fname2, " - ", fname, Sys.Date()))
}
dev.off()

lastvar = 1
zlim=NULL
#Plot ra diagnostics

#if (!is.na(ralast)) {
if (!is.na(ra1)) {
pdf(paste0(pathout,"/", fname2,"-", fname, "_Entradiags.",Sys.Date(),".pdf"), height=7, width=10)
par(mfrow=c(4,4))
par(omi=c(0,0,0,0), oma=c(0,1,4,1), mar=c(2,3,4,4))
for (i in ra1:ralast) {
	mapz = var.get.nc(nc, varnames[i])
        mapz2 = tryCatch(var.get.nc(nc2, varnames[i]), error = function(e) e)
        if (is.null(dim(mapz2))) { next }
	hemis = length(str_split(varnames[i], "hemis" )[[1]])>1
	print(paste(i, varnames[i], hemis))
	if (!hemis) {
		if (ncatt_get(nc4, varnames[i], "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
			datmis = att.get.nc(nc, varnames[i], "missing_value")
			mapz[mapz==datmis] = NA
		}
		if (ncatt_get(nc42, varnames[i], "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
			datmis = att.get.nc(nc2, varnames[i], "missing_value")
			mapz2[mapz2==datmis] = NA
		}
		vi = as.numeric(substr(varnames[i], 3,5))
		entdiag = Ent_diags_LUT[vi, "entdiagname"]
		entunits = paste("(", Ent_diags_LUT[as.numeric(substr(varnames[i], 3,5)), "units"], ")", sep="")
		entcov = EntGVSD_PFTs[as.numeric(substr(varnames[i], 6, 8))]
		print(paste(entdiag, entunits, entcov))
		titletext = paste(varnames[i], entdiag, entunits)
		
		#if (vi>lastvar) {
		#	par(mfrow=c(4,4), ask=FALSE)
		#}
		plot.grid.continuous(mapz=mapz2-mapz, res=res, colors=colors, xlab="",ylab="", zlim=NULL, titletext=titletext, if.fill=TRUE, cex.main=0.85, cex.axis=0.8, cex.legend=0.8)
		plot(coastsCoarse, add=TRUE, col=gray(0.3), lwd=0.3)
		
		#title(titletext, cex=0.7)
		mtext(entcov, cex=0.5, line=0.75)
		mtext(mapstat(mapz2-mapz, axyp, dig=3, if.global=TRUE, short=TRUE), cex=0.5)
	}
	mtext(outer=TRUE, paste(fname, Sys.Date()))
	
	lastvar = vi	
}
dev.off()
}

# Map single variable
#		map.GCM.Ent.ncid(ncid=nc, res="2x2.5", varname=entdiag, pftlist=EntGVSD_PFT13, colors=colors, type="any", zlim=NULL, unitstype=1, if.zeroNA=TRUE, titletype=3, if.coasts=FALSE)
#		title(titletext)
#		mtext(mapstat(mapz, axyp, dig=3, short=TRUE), cex=0.5)


close.nc(nc)
nc_close(nc4)

print("Done.")

#This didn't work:
#tryCatch( { <any set of expressions> }, error=print("No units")) 
	
