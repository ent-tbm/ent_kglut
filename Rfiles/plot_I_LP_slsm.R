#plot_I_LP_slsm.R
#Plot lpl_data time series of carbon diagnostics with helpful unit conversions.
#This version is specific to I_LP for SLSM.

#The I_LP files should have the quantities in the array "filepre" below.
#See /discover/nobackup/nkiang/I_LP_files/I_LP_slsm

#library(sf)
#library(ggplot2)
#library(mapview)
#library(lwgeom)
#library(rnaturalearth)
library(glue)

undef = -1.e30

args = commandArgs(trailingOnly=TRUE)
cat('\n', 'args:', args, '\n')
numargs = length(args)
cat('numargs: ', numargs, '\n')

if (numargs < 1 | numargs > 2) {
cat('Usage:  Rscript plot_lpl_data.R <run_name> <optional nsteps>', '\n')
cat(' nsteps:  Number of time steps of output to average in plot info. Default 5 assuming years.','\n')
cat('Assumes run output is in /discover/nobackup/projects/giss/prod_runs/','\n')
cat('WARNING: Assumes I_LP file is /discover/nobackup/nkiang/I_LP_files/I_LP_slsm.\n')
cat('         Assumes that first column has fixed width of 11.  If I_LP file changes, need to updated.\n')
quit()
}

#Get latest standard I_LP_slsm file diagnostic names.  Get first column, WARNING: specifies fixed column width!
#File name prefixes in the lpl_data directory:
I_LP_diags = read.fwf("/discover/nobackup/nkiang/I_LP_files/I_LP_slsm", widths=c(11, NULL), skip=1, header=FALSE)
print(dim(I_LP_diags))
print(I_LP_diags)
filepre = trimws(as.vector(I_LP_diags[1:(dim(I_LP_diags)[1]-2),1])) #Skip save at beginning and end of file

# Time series --------------
#path="/discover/nobackup/projects/giss_ana/users/rruedy/planet_runs/"
path="/discover/nobackup/projects/giss/prod_runs/"

runs=args[1]
if (numargs == 2) {
  nyr=as.integer(args[2])  #nyr is actually nsteps
  cat("Averaging ",nyr," time steps.\n")
} else {
  nyr=5
}

colr=c(2,3,1)
if (TRUE) {  #individual runs plots
for (runname in runs) {

pdf(paste0(runname,"_lpl_",Sys.Date(),".pdf"))

lpldir = "/lpl_data/"

  

files = paste0(trimws(filepre), ".", runname)
#files = list.files(paste0(path, runname, lpldir))
cat(files,"\n")

par(mfrow=c(3,3), oma=c(0,0,1,0), ask=FALSE)
gpp=NULL;rauto=NULL;respsoil=NULL;soilC=NULL;ytime=NULL #Need these here so that they are saved outside the loop.
for (f in 1:length(files)) {
     if (length(strsplit(files[f],runname)[[1]])==1) {
	file = paste0(path, runname, lpldir, files[f])
        cat(file, "\n")
	textin = strsplit(readLines(con=file, n=1), ";")[[1]][1]
	#tryCatch(lpl_dat = read.table(file, header=FALSE, skip=4), finally=print(paste("Not found in lpl_data:", textin)) )
	lpl_dat = read.table(file, header=FALSE, skip=4)

        index = TRUE #All
	plot(lpl_dat[index,1], lpl_dat[index,2], xlab="Year", ylab=textin, type="l", main=textin, cex.main=.6)
	n = nrow(lpl_dat[index,]); cat("nrow:", n,"\n")
        #cat('n:',n,'  nyr:', nyr,'n-nyr: ',n-nyr,'\n')
	lm100 = lm(y ~ x, data=data.frame(x=lpl_dat[index,1], y=lpl_dat[index,2])[(n-nyr):n,])
	mtext(paste("last",nyr,"timesteps mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)
	mtext(outer=TRUE, runname, line=-1)

        #Collect carbon fluxes
        f=strsplit(files[f],"/")[[1]]
        len=length(f)
        diag=strsplit(f[len], paste0(".",runname))[[1]]
        cat(diag, "\n")
        #if (diag=="gpp_land") { gpp=lpl_dat[,2]; ytime=lpl_dat[,1]  }
        #if (diag=="autoResp") { respauto=lpl_dat[,2]; ytime=lpl_dat[,1] }
        #if (diag=="soilresp") { cat("soilResp\n"); respsoil=lpl_dat[,2]; ytime=lpl_dat[,1] }
        #if (diag=="soilC")    { soilC=lpl_dat[,2]; ytime=lpl_dat[,1] }
        if (diag=="gpp") { gpp=lpl_dat[,2]; ytime=lpl_dat[,1]  }
        if (diag=="rauto") { respauto=lpl_dat[,2]; ytime=lpl_dat[,1] }
        if (diag=="soilresp") { cat("soilResp\n"); respsoil=lpl_dat[,2]; ytime=lpl_dat[,1] }
        if (diag=="soilCpool")    { soilC=lpl_dat[,2]; ytime=lpl_dat[,1] }
     }
}
# Plot global soil and net carbon fluxes
  gCm2d_to_PgCyr = (1e-15)*(1.30577E+14)*(365)

SoilC_PgCyr=NULL
if (!is.null(soilC)) {
  SoilC_PgC = (1e-15)*(1.30577E+14)*1e3*soilC #kgC/m2 to PgC global
  cat("SoilC_PgC \n")
  index = TRUE #Default
  plot(ytime[index], SoilC_PgC[index], xlab="Year", ylab="PgC", type="l", main="Global Soil Carbon", cex.main=.6)
  n = length(ytime[index]); cat("nrow:", n,"\n")
        lm100 = lm(y ~ x, data=data.frame(x=ytime[index], y=SoilC_PgC[index])[(n-nyr):n,])
        #mtext(diags[f], cex=0.5, line=.8)
        mtext("PgC", cex=0.5, line=.8)
        mtext(paste("last",nyr,"yr mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)
} else {
  cat("soilCpool missing from I_LP file and lpl_data, \n")
}

LandNetCO2_PgCyr=NULL
if (!is.null(gpp) && !is.null(rauto) && !is.null(respsoil) ) {
  LandNetCO2_PgCyr = gCm2d_to_PgCyr*(respsoil + respauto - gpp)
  cat("LandNetCO2_PgCyr \n")
  index = TRUE #Default
  plot(ytime[index], LandNetCO2_PgCyr[index], xlab="Year", ylab="net land CO2 flux", type="l", main="NET LAND CO2 UPWARD FLUX (Respsoil + Respauto - GPP)", cex.main=.6)
  n = length(ytime[index]); cat("nrow:", n,"\n")
        lm100 = lm(y ~ x, data=data.frame(x=ytime[index], y=LandNetCO2_PgCyr[index])[(n-nyr):n,])
        #mtext(diags[f], cex=0.5, line=.8)
        mtext("PgC/yr", cex=0.5, line=.8)
        mtext(paste("last",nyr,"yr mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)
 
}
write.table(file=paste0(runname, "_lpl_LandNetCO2_PgCyr.csv"), cbind(Year=ytime, LandNetCO2_PgCyr=LandNetCO2_PgCyr), sep=",", row.names=FALSE) 
dev.off()
} #runname
}

if (FALSE) {
# Superimposed plots, combine runs per diagnostic.
pdf(paste0("ELP_combo_", Sys.Date(),".pdf"))
par(mfrow=c(3,3), oma=c(0,0,1,0), ask=FALSE)

plot.blank()
legend(-1,1, legend=runs, lty=1, col=colr)
for (di in 1:length(diags)) {
   lpl = NULL
   mint=-undef; maxt=undef; miny=-undef; maxy=undef
   for (r in 1:length(runs)) {
     runname = runs[r]
     file = paste0(path,runname, "/lpl_data/",diags[di],".",runname)
     textin = strsplit(readLines(con=file, n=1), ";")[[1]][1]
     lp = read.table(file, header=FALSE, skip=4)
     mint=min(mint,lp[,1]); maxt=max(maxt, lp[,1]); miny=min(miny,lp[,2]); maxy=max(maxy,lp[,2])
     lpl = append(lpl, list(lp))
   }
   plot(0,0, xlim=c(mint,maxt), ylim=c(miny,maxy), xlab="Years", ylab=diags[di], type="l", main=textin, cex.main=.6)
   mtext(diags[di], cex=0.5, line=.8)
   for (r in 1:length(lpl)) {
	lines(lpl[[r]][,1], lpl[[r]][,2], col=colr[r])
   }
   mtext(outer=TRUE, "ELP Lakes", line=-1)
}
dev.off()
}

cat('Done.\n')

