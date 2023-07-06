#plot_lpl_data.R
#Plot lpl_data time series of carbon diagnostics with helpful unit conversions.

#The I_LP file should have had these quantities:
#aij
#Oice oicefr 1 OCEAN/LAKE ICE COVERAGE (%)
#OcnIcGNS oicefr 3 Ocean/Lake Ice Cover as % of total area
#SAT tsurf 1 SURFACE AIR TEMPERATURE (C)
#NetHeat netht_grnd 1 NET HEATING AT GROUND (W/m^2)
#NetRad net_rad_planet 1 NET RAD. OF PLANET (W/m^2)
#MSU_TLT Tmsu-TLT 3 MSU-TLT TEMPERATURE (C)
#MSU_TMT Tmsu_TMT 3 MSU-TMT TEMPERATURE (C)
#MSU_TLS Tmsu_TLS 3 MSU-TLS TEMPERATURE (C)
#SSU_ch1 Tssu_ch1 3 SSU-Ch 1 TEMPERATURE (C)
#SSU_ch2 Tssu_ch2 3 SSU-Ch 2 TEMPERATURE (C)
#SSU_ch3 Tssu_ch3 3 SSU-Ch 3 TEMPERATURE (C)
#soilC soilCpool 3 SOIL CARBON (kgC m-2)
#soilResp soilresp 3 SOIL RESPIRATION (gC m-2 d-1)
#Clabile C_lab 3 PLANT LABILE CARBON (kgC m-2)
#gpp_land gpp 3 GROSS PRIMARY PRODUCTION (gC m-2 d-1)
#autoResp rauto 3 AUTOTROPHIC RESPIRATION (gC m-2 d-1)
#Lakefr lakefr 3 LAKE COVER (%)
#oij
#source("/discover/nobackup/nkiang/Ent_utils/Rfiles/utils_noSDMTools.R")

#library(sf)
#library(ggplot2)
#library(mapview)
#library(lwgeom)
#library(rnaturalearth)

undef = -1.e30

args = commandArgs(trailingOnly=TRUE)
cat('\n', 'args:', args, '\n')
numargs = length(args)
if (numargs < 1) {
cat('Usage:  Rscript plot_lpl_data.R <run_name>', '\n')
cat('Assumes run output is in /discover/nobackup/projects/giss/prod_runs/','\n')
quit()
}


# Time series --------------
#path="/discover/nobackup/projects/giss_ana/users/rruedy/planet_runs/"
path="/discover/nobackup/projects/giss/prod_runs/"

#runs=c( "E21_PI_lcspinnk", "E21_PI_lcspinnkc", "E21_PI_lcspinnkcb", "E21_PI_lcspinnkcbb", "E21_PI_lcspinnkc2")
#runs=c( "E21_PI_lcspinnkcbb",  "E21_PI_lcspinnkcb2")
#runs=c( "E21_PI_lcspinnkcc") #,  "E21_PI_lcspinnkc2")
runs=args[1]

colr=c(2,3,1)
#nyr=100
nyr=30
#nyr=1

if (TRUE) {  #individual runs plots
for (runname in runs) {

#pdf(paste0(runname,"_",Sys.Date(),".pdf"))
pdf(paste0(runname,"_",Sys.Date(),".pdf"))


#files = paste0(diags, ".", runname)
files = list.files(paste0(path, runname, "/lpl_data/"))
cat(files,"\n")

par(mfrow=c(3,3), oma=c(0,0,1,0), ask=FALSE)
for (f in 1:length(files)) {
     if (length(strsplit(files[f],runname)[[1]])==1) {
	file = paste0(path, runname, "/lpl_data/",files[f])
        cat(file, "\n")
	#lpl_dat = read.table(file, header=TRUE, skip=3)
	#plot(lpl_dat[,"Years"], lpl_dat[,"Glob"], xlab="Years", ylab=diags[f], type="l", main=runname)
	textin = strsplit(readLines(con=file, n=1), ";")[[1]][1]
	lpl_dat = read.table(file, header=FALSE, skip=4)

        index = TRUE #All
        #index = lpl_dat[,1]>=1929 & lpl_dat[,1]<=2029 #For E21_PI_lcspinnkcc
	plot(lpl_dat[index,1], lpl_dat[index,2], xlab="Year", ylab=textin, type="l", main=textin, cex.main=.6)
	n = nrow(lpl_dat[index,]); cat("nrow:", n,"\n")
	lm100 = lm(y ~ x, data=data.frame(x=lpl_dat[index,1], y=lpl_dat[index,2])[(n-nyr):n,])
	#mtext(diags[f], cex=0.5, line=.8)
	mtext(paste("last",nyr,"yr mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)
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
if (TRUE) {
  gCm2d_to_PgCyr = (1e-15)*(1.30577E+14)*(365)
  LandNetCO2_PgCyr = gCm2d_to_PgCyr*(respsoil + respauto - gpp)
  SoilC_PgC = (1e-15)*(1.30577E+14)*1e3*soilC #kgC/m2 to PgC global

  index = TRUE #Default
  index = ytime>=1929 & ytime<=2029 #For E21_PI_lcspinnkcc

  plot(ytime[index], SoilC_PgC[index], xlab="Year", ylab="PgC", type="l", main="Global Soil Carbon", cex.main=.6)
  n = length(ytime[index]); cat("nrow:", n,"\n")
        lm100 = lm(y ~ x, data=data.frame(x=ytime[index], y=SoilC_PgC[index])[(n-nyr):n,])
        #mtext(diags[f], cex=0.5, line=.8)
        mtext("PgC", cex=0.5, line=.8)
        mtext(paste("last",nyr,"yr mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)

  plot(ytime[index], LandNetCO2_PgCyr[index], xlab="Year", ylab="net land CO2 flux", type="l", main="NET LAND CO2 UPWARD FLUX (Respsoil + Respauto - GPP)", cex.main=.6)
  n = length(ytime[index]); cat("nrow:", n,"\n")
        lm100 = lm(y ~ x, data=data.frame(x=ytime[index], y=LandNetCO2_PgCyr[index])[(n-nyr):n,])
        #mtext(diags[f], cex=0.5, line=.8)
        mtext("PgC/yr", cex=0.5, line=.8)
        mtext(paste("last",nyr,"yr mean =", signif(mean(lm100$model[,'y'],4))," dy/dyr =", signif(lm100$coef['x'],4)), cex=0.5)
 
}
write.table(file=paste0(runname, ".LandNetCO2_PgCyr.csv"), cbind(Year=ytime, LandNetCO2_PgCyr=LandNetCO2_PgCyr), sep=",", row.names=FALSE) 
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


