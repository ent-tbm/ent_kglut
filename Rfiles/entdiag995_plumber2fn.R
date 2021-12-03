#entdiag995_plumber2fn.R
#Functions for plotting Ent diagnostics from PLUMBER2 runs

Rpath = paste(Rpath, "../Rfiles/", sep="")

#source(paste(Rpath, "utils.R", sep=""))
source(paste(Rpath, "/utils_noSDMTools.R", sep=""))
source(paste(Rpath, "/entdiag995fn.R", sep=""))

library("RNetCDF")
library("udunits2")


plumber2_ent = function(filedrv, pathdiag, pathout=NULL, info="PLUMBER2 sitename", if.new=TRUE, option=1) {
  #Plot diagnostics from PLUMBER2 Ent run
  #filedrv = PLUMBER2_ent driver file, may include observations for diagnostics
  #pathdiag = path to run outputs
  #info = optional title info for plots
  #if.new = if open a new plot window
  #option = 1-fort.995, 2-fort.1082, 3-TBD
 
  if (is.null(pathout)) {
	pathout = pathdiag
  }
 
  #Get firedrv values for plotting
  nc = open.nc(filedrv, write=FALSE)
  
  #Time
  tsec = var.get.nc(nc, "time")
  tstr = att.get.nc(nc, "time", "units")
  tarr = utcal.nc(tstr, tsec)
  print(tarr[1,])
  print(tarr[length(tsec),])
  dtsecp = tsec[2] - tsec[1] #Assume all the same time step in driver
  print(paste("PLUMBER2 time step (sec):", dtsecp))
  tn = table(tarr[,"year"])
  secperyr = NULL
  for (y in names(tn)) { secperyr = c(secperyr, rep(tn[y], tn[y])) }
  secperyr = secperyr * dtsecp
  tyrp = tarr[1,"year"] + tsec/secperyr
  
  #SWdown
  swdown = var.get.nc(nc, "SWdown")
  
  #LAI
  laip = var.get.nc(nc, "LAI")
  #laiobs = cbind(tyrp, lai=laip)

  close.nc(nc)
  
  #Open plot
  #if (if.new) {  quartz(width=6, height=8)  }
  pdf(file=paste(pathout, "/", info, ".pdf",sep=""), width=6, height=8)
  
  par(mfrow=c(3,2), omi=c(0,0,0.5,0.3), ask=FALSE ) 
  plot(tyrp, swdown, xlab="year", ylab="SWdown (W/m2)", pch=16, cex=0.1); title(paste("observed SWdown"))
  plot(tyrp, laip, xlab="year", ylab="LAI", type="l"); points(tyrp, laip, pch=16, cex=0.3); title(paste("observed LAI"))
  mtext(outer=TRUE, info )
 
  if (option==1) {
  	fort.995 = read.table(paste(pathdiag, "/fort.995", sep=""), header=FALSE)
  	#fort.980 = read.table(paste(pathdiag, "/fort.980", sep=""), header=FALSE)
  	
  	names(fort.995) = names.fort.995.lsm
  	#names(fort.980) = names.fort.980
  	
        d = fort.995[,"timesec"]/(24*3600)
	
	par(mfrow=c(3,2), omi=c(0,0,0.5,0.3), ask=FALSE )

  	#If no observations available to plot:
  	fluxdmat = plot995r(day=d,fort.995[,2:ncol(fort.995)], 
  		fluxNEE=rep(0,length(d)), titleouter=info,line=0, type="l")

  	#If observations are available:
	#plot995a(day=d,fort.995[,2:ncol(fort.995)], 
	#		fluxNEE=rep(NA, , 
	#		drv=fort.980,  #fort.980.hyy16,
	#		fluxET.Wm2=rep(dataMMSF2005V3[,"LE_Wm2"],repn),
	#		line=0, type="l",daily=24,if.dailyonly=FALSE)

  	
  } else if (option==2) {
    print("option 2 fort.982 TBD next")	
  }
  
  dev.off()
}
