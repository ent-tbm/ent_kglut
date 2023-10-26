#plot_any_ij.R
#Author:  N.Y.Kiang
#Originally from ModelE_plot_aij_gij.R

#Map full set of any ij.

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
if (numargs < 2) {
cat('Usage:  Rscript ../Rfiles/ModelE_plot_aij_gij.R <pathin/> <filename>', '\n' )
cat('Generate maps of any ij diagnostics.', '\n')
cat('pathin/ = path where diagnostics file is.', '\n')
cat('filename = name of ModelE aij or gij diagnostics netcdf file.', '\n')
quit()
}

path = paste0(args[1], '/')
fname = args[2]

print(path)
print(fname)

#---------------------
library(stringr)
library(RNetCDF)
library(ncdf4) # For nc_open, natt_get does not bail if attr does not exit

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
cat("R_Ent: ", Rpath, "\n\n")
source(paste0(Rpath, "/utils_noSDMTools.R"))

nc4 = nc_open(paste0(path,fname))

nc = open.nc(con=paste0(path, "/",fname), write=FALSE)
ndims <- file.inq.nc(nc)$ndims 
dimnames <- character(ndims) 
for(i in seq_len(ndims)) { dimnames[i] <- dim.inq.nc(nc, i-1)$name } 
nvars <- file.inq.nc(nc)$nvars 

print('got here')

#---- Make maps of all diagnostics -----
varnames <- character(nvars) 
for(i in seq_len(nvars)) { 
  varnames[i] <- var.inq.nc(nc, i-1)$name
} 
cat(varnames, '\n')

#axyp = var.get.nc(nc, "axyp")
var3 = var.get.nc(nc, varnames[3])  #skip arrays for lon, lat

#Map all non-hemis variables of non-Ent-ra diagnostics.
#pdf(file=paste(fname, "_nora.pdf", sep=""), height=7, width=10)
pdf(file=paste0(fname,".", Sys.Date(), ".pdf"), height=7, width=10)
#quartz(height=6, width=10)

res=res.from.IM.JM(dim(var3)[1], dim(var3)[2])
print(res)

colors = giss.palette(40)
par(mfrow=c(4,4))
par(omi=c(0,0,0,0), oma=c(0,1,4,1), mar=c(2,3,4,4))
irange = 3:nvars
print(paste("nvars", nvars, "irange", toString(irange)))
for (i in irange) { 
	print(paste(i, varnames[i]))
	#hemis = length(str_split(varnames[i], "hemis" )[[1]])>1
	#print(paste(i, varnames[i], hemis))
	#if (!hemis) {
		mapz = var.get.nc(nc, varnames[i])
		if (ncatt_get(nc4, varnames[i], "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
			datmis = att.get.nc(nc, varnames[i], "missing_value")
			mapz[mapz==datmis] = NA
		}
 		#att.inq.nc(nc, varnames[i], "units") #This bails if attr does not exist, cannot error handle
 		if (ncatt_get(nc4, varnames[i], "units")$hasatt) { #ncatt_get is library(ncdf4)
			units = paste("(", att.get.nc(nc, varnames[i], "units"), ")", sep="")
		} else {
			units = "(No units)"
			print("No units")
		}
		titletext = paste(varnames[i], units)
		plot.grid.continuous(mapz=mapz, res=res, colors=colors, xlab="",ylab="", zlim=NULL, 
			titletext=titletext, if.fill=TRUE, cex.main=0.85, cex.axis=0.8, cex.legend=0.8)
		#mtext(mapstat(mapz, axyp, if.global=FALSE, dig=3, short=TRUE), cex=0.5)
		plot(coastsCoarse, add=TRUE, col=gray(0.3), lwd=0.3)
	#}
	mtext(outer=TRUE, paste(fname, Sys.Date()))
}
dev.off()

close.nc(nc)
nc_close(nc4)

print("Done.")

