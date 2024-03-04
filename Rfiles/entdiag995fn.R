#entdiag995fn.R

names.fort.980 = c("I0", "I1", "J0", "J1", "N_DEPTH", "TairC", "TcanopyC", "Qf", "P_mbar", "Ca", "Ch", "U", "IPARdif", 
"IPARdir", "CosZen", "Smp1", "Smp2", "Smp3", "Smp4", "Smp5", "Smp6", "Sm1", "Sm2", "Sm3", "Sm4", "Sm5", "Sm6", "St1", "St2", "St3", "St4", "St5", "St6", "fice1", "fice2", "fice3", "fice4", "fice5", "fice6", "LAI1", "LAI2", "LAI3", "LAI4", "LAI5", "LAI6", "LAI7", "LAI8", "LAI9", "LAI10", "LAI11", "LAI12", "LAI13", "LAI14", "LAI15", "LAI16", "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9", "h10", "h11", "h12", "h13", "h14", "h15", "h16")


names.fort.995.lsm = c("patchnum", "IPARdir", "IPARdif", "coszen", "pft", "n",
    "lai", "heightm", "leaf", "froot", "wood", 
    "surfmet", "surfstr", "soilmet", "soilstr", "cwd", "surfmic", "soilmic", "slow", "passive",
    "C_fol", "C_w", "C_froot", "C_root", "C_lab", "C_repro",
    "TRANS_SW", "Ci", "GPP", "Rauto", "Soilresp", "NPP", "CO2flux", 
    "GCANOPY", "IPP", "senescefrac", "Sacclim", "c_total", "c_growth", 
    "litter", "betad", "timesec","timecum")
   
names.fort.1082 = c("IPARdir","IPARdif","CosZen",# "cradLAI",
#			"ALBEDO_VIS", "ALBEDO_NIR")
			"ALBEDO_VIS_300-770", "ALBEDO_NIR_770-860","ALBEDO_NIR_860-1250", 
			"ALBEDO_NIR_1250-1500","ALBEDO_NIR_1500-2200","ALBEDO_NIR_2200-4000",
			"ALBEDODIR1", "ALBEDODIR2","ALBEDODIR3","ALBEDODIR4","ALBEDODIR5","ALBEDODIR6",
			"ALBEDODIF1", "ALBEDODIF2","ALBEDODIF3","ALBEDODIF4","ALBEDODIF5","ALBEDODIF6")
			 
#----------------------------------------------------------------
plot995r = function(day=NULL,dat,fluxNEE=NULL, drv=NULL,fluxET=NULL, laiobs=NULL,
	titleouter="",line=-1.5, type="p" #,daily=48
	, if.dailyonly=FALSE, if.sumpage=FALSE, if.ver2=FALSE) {
	#1/24/2024:  Added options to generate day time vector from timecum if present, and to plot fapar if present.
	#	Got rid of unused and unnecessary daily time steps parameter.
	
	#day - optional time vector in days of year. For earlier versions of Ent_standalone that did not output timecum. 
        #      If input, where daily=#time steps per day:
	#   day = 1+ (1:nrow(dat) - 1)/daily  #Day 1 is midnight beginning of year.
        #dat - fort.995 output files
        #fluxNEE - observed NEE
        #drv - fort.980 forcings file
        #OPTIONAL:  fluxET - observed ET
        #           laiobs - observed lai to compare to when prognostic LAI is run
        #titleouter - Any text info for plot page titles.

        #If no day time vector input, then calculate from timecum if present.
	if (is.null(day)) {
		if (!is.na(match("timecum", names(dat)))) {
			#Make day time vector.  Assume first time point is midnight first day of year to match Fluxnet DTIME.
			day = 1 + (dat[,"timecum"] - dat[1,"timecum"])/86400
		} else {
			cat("Please input the day time vector.\n")
		}
	}
	xlab = "day"

	if (!if.dailyonly) {
		
	for (i in c("IPARdif", "IPARdir")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i)," W/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	#for (i in c("coszen","pft"
	for (i in c("n", "lai")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(i))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	if (!is.null(laiobs)) {
		lines(laiobs[,1], laiobs[,"lai"], col=4)
		points(laiobs[1,], laiobs[,"lai"], col=4, pch=16, cex=0.3)
	}
	for (i in c("heightm")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(i))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}		
			
	#Plot litter
	plot(day,dat[,"litter"],xlab="day",ylab="g-C/m2",type="l")
	title("litter")
		
	#Tpools
	for (i in c("leaf","froot","wood","surfmet","surfstr", "soilmet","soilstr","cwd","surfmic","soilmic","slow","passive")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i), "g-C/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	#Convert C sums (kg/m2) to kg-C/individual.
	for (i in c("C_fol","C_w","C_froot","C_root","C_lab","C_repro")) {
		plot(day, dat[,i]/dat[,"n"],pch=".",type=type, cex=3,xlab=xlab, ylab=paste("kg-C/individ"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}

	
	#Stacked plots
		plot.multi(x=day, ydat = dat[,c("leaf","froot","wood")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool live")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("surfmet","surfstr", "soilmet","soilstr", "cwd","surfmic","soilmic","slow","passive")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool dead")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("C_fol","C_w","C_froot", "C_root","C_lab","C_repro")],
		xlab=xlab,ylab="kg-C/m2-gnd", if.sepleg=TRUE)
		title("individual")
		mtext(outer=TRUE,paste(titleouter),line=line)
	
	plot(day,dat[,"TRANS_SW"],type=type,pch=".",cex=3,xlab=xlab, ylab=paste("transmittance"))
	title("TRANS_SW")
	
	#plot(0,0, type="n", axes=FALSE, xlab="",ylab="")
	
	for (i in c("GPP","Rauto","Soilresp","NPP")) {
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
		i = "CO2flux"
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"),
		ylim=c(min(min(dat[,i]/0.012e-6,na.omit(fluxNEE))),
			max(max(dat[,i]/0.012e-6,na.omit(fluxNEE)))))
		if (!is.null(fluxNEE)) {
			points(day,fluxNEE,col=2,pch=".")
		}
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		
	
	
	#plot(day, dat[,"senescefrac"],pch=".",type=type, cex=3, xlab=xlab, ylab="senescefrac")
	#	title("senescefrac")
	#	mtext(outer=TRUE,paste(titleouter),line=line)

	#GCANOPY
	i = "GCANOPY"	
	plot(day, dat[,i],pch=".",type=type, cex=3, xlab=xlab, ylab=paste(i, " m/s"))
		title(i)
		
	}
	
	#Daily sum plots
	fluxdmat = NULL
	jday = floor(day)
	for (i in c("GPP","Rauto","Soilresp","NPP")) {
		fluxd = tapply(dat[,i]*(60*60*24)/0.012, jday, FUN="na.mean")
		fluxdmat = cbind(fluxdmat, fluxd)
		plot(unique(jday), fluxd, xlab="day",ylab="mol/m2/day", type="l") #type="l")
		#axis(side=4,at=pretty(fluxd),labels=pretty(fluxd)*12)
		#  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
		title(i)
	}
	fluxnames = c("GPP","Rauto","Soilresp","NPP")
	fluxdmat = as.data.frame(fluxdmat)
	names(fluxdmat) = fluxnames
	fluxd = tapply(dat[,"CO2flux"]*(60*60*24)/0.012, jday, FUN="mean")
	fluxdmeas = as.vector(tapply(fluxNEE*60*60*24*1e-6,jday,FUN="na.mean"))
	ylim=c(min(na.omit(c(fluxd,fluxdmeas))), max(na.omit(c(fluxd,fluxdmeas))))
	plot(unique(jday), fluxdmeas, col=2,xlab="day",ylab="mol/m2/day", ylim=ylim, type="l") #"l")
	lines(unique(jday),fluxd,col=1)
	lines(unique(jday),rep(0,length(unique(jday))),lty=3)
	axis(side=4,at=pretty(fluxdmeas),labels=pretty(fluxdmeas)*12);  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
	title("CO2flux")
	mtext(outer=TRUE,paste(titleouter),line=line+2)
	mtext(outer=TRUE,paste(" GCANOPY half-hourly, others daily sums"),line=line)
#	fluxdm = tapply(-dataorig[,"Fc.mg.m2.s"]*(60*30*daily)/12e6, jday, FUN="mean")
#	lines(unique(jday),fluxdm,col=2)
#		legend(200,max(fluxd),legend=c("Ent","Flux meas."),col=1:2,lty=1)

	if (if.sumpage) {
		quartz(width=5,height=7)
		par(mfrow=c(3,2), omi=c(0,0,0.5,0.3))
	}
	fluxd=tapply(dat[,"GCANOPY"], jday, FUN="na.mean")
	plot(unique(jday),fluxd,xlab="day",ylab="GCANOPY (m/s)", type="l")
	title("GCANOPY daily avg ")
	plot(unique(jday),1/fluxd,xlab="day",ylab="s/m", type="l")
	title("CANOPY RESISTANCE daily avg")
	mtext(outer=TRUE,paste("GCANOPY daily averages"),line=line)

	#Plot total soil carbon
	plot(day,apply(dat[,c("surfmet","surfstr", "soilmet","soilstr", "cwd","surfmic","soilmic","slow","passive")],1,FUN="sum"),
		type="l",xlab="day",ylab="g-C/m2")
	title("Total soil carbon")


	for (i in c("senescefrac","betad")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab="day", ylab=paste(i))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line+2)
	}


	plot(unique(jday), fluxdmat[,"GPP"], xlab="day",ylab="mol/m2/day", 
		type="l",ylim=c(min(fluxdmat[,"NPP"]),max(fluxdmat[,"GPP"])))
	flist = c("NPP","Rauto","Soilresp")
	for (i in 1:length(flist)) {
			lines(unique(jday), fluxdmat[,paste(flist[i])], col=i+1)
	}
	legend(200,max(fluxdmat),legend=c("GPP","NPP","Rauto","Soilresp"),lty=1,col=1:4)
	title(paste("NPP/GPP =",sum(fluxdmat[,"NPP"])/sum(fluxdmat[,"GPP"])))

	vname = "fapar"
	if (!is.na(match(vname, names(dat)))) {
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname)
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname, xlim=c(0,10))
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname, xlim=c(100,110))
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname, xlim=c(180,190))
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname, xlim=c(250,260))
		plot(day, dat[,vname], type="l", xlab="day", ylab=vname, main=vname, xlim=c(350,360))
	}

        if (if.ver2) {
                plot(day, dat[,"albVIS"], type="l", xlab="day", ylab="albedo VIS", main="canopy albedo VIS", ylim=c(0,0.6))
                plot(day, dat[,"albNIR1"], type="l", xlab="day", ylab="albedo NIR1", main="canopy albedo NIR1", ylim=c(0,0.6))
                plot(day, dat[,"albNIR2"], type="l", xlab="day", ylab="albedo NIR2", main="canopy albedo NIR2", ylim=c(0,0.6))
                plot(day, dat[,"albNIR3"], type="l", xlab="day", ylab="albedo NIR3", main="canopy albedo NIR3", ylim=c(0,0.6))
                plot(day, dat[,"albNIR4"], type="l", xlab="day", ylab="albedo NIR4", main="canopy albedo NIR4", ylim=c(0,0.6))
                plot(day, dat[,"albNIR5"], type="l", xlab="day", ylab="albedo NIR5", main="canopy albedo NIR5", ylim=c(0,0.6))
        }
	return(fluxdmat)
}


#----------------------------------------------------------------
plot995 = function(day,dat,fluxNEE=NULL, fluxET=NULL,titleouter="",line=-1.5, type="p",daily=48,if.dailyonly=FALSE) {
	
	day = (1:nrow(dat))/daily
	xlab = "day"

	if (!if.dailyonly) {
		
	for (i in c("IPARdif", "IPARdir")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i)," W/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	#for (i in c("coszen"
	for (i in c("pft","senescefrac","lai","heightm")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(i))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	
	for (i in c("leaf","froot","wood","surfmet","surfstr", "soilmet","soilstr","cwd","surfmic","soilmic","slow","passive")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i), "g-C/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
		
	for (i in c("C_fol","C_w","C_froot","C_root","C_lab")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste("kg-C/m2-gnd"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	
	plot(day,dat[,"TRANS_SW"],type=type,cex=3,xlab=xlab, ylab=paste("transmittance"))
	title("TRANS_SW")
	
	#plot(0,0, type="n", axes=FALSE, xlab="",ylab="")
	
	for (i in c("GPP","Rauto","Soilresp","NPP")) {
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
		i = "CO2flux"
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"),
		ylim=c(min(min(dat[,i]/0.012e-6,na.omit(fluxNEE))),
			max(max(dat[,i]/0.012e-6,na.omit(fluxNEE)))))
		if (!is.null(fluxNEE)) {
			points(day,fluxNEE,col=2,pch=".")
		}
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		
	
	
	i = "GCANOPY"	
	plot(day, dat[,i],pch=".",type=type, cex=3, xlab=xlab, ylab=paste(i, " m/s"))
		title(i)
		mtext(outer=TRUE,paste(titleouter),line=line)
	
	#plot(day, dat[,"senescefrac"],pch=".",type=type, cex=3, xlab=xlab, ylab="senescefrac")
	#	title("senescefrac")
	#	mtext(outer=TRUE,paste(titleouter),line=line)
	
	#Stacked plots
		plot.multi(x=day, ydat = dat[,c("leaf","froot","wood")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool live")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("surfmet","surfstr", "soilmet","soilstr", "cwd","surfmic","soilmic","slow","passive")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool dead")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("C_fol","C_w","C_froot", "C_root","C_lab")],
		xlab=xlab,ylab="kg-C/m2-gnd", if.sepleg=TRUE)
		title("individual")
		mtext(outer=TRUE,paste(titleouter),line=line)

	}
			
	#Daily sum plots
		jday = floor(day)
		for (i in c("GPP","Rauto","Soilresp","NPP")) {
			fluxd = tapply(dat[,i]*(30*60*48)/0.012, jday, FUN="na.mean")
			plot(unique(jday), fluxd, xlab="day",ylab="mol/m2/day", type="l")
			#axis(side=4,at=pretty(fluxd),labels=pretty(fluxd)*12)
			#  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
			title(i)
		}
		fluxd = tapply(dat[,"CO2flux"]*(30*60*48)/0.012, jday, FUN="mean")
		fluxdmeas = as.vector(tapply(fluxNEE*30*60*48*1e-6,jday,FUN="na.mean"))
		plot(unique(jday), fluxdmeas, col=2,xlab="day",ylab="mol/m2/day", type="l")#, ylim=c(min(na.omit(fluxd,fluxdmeas)), max(na.omit(fluxd,fluxdmeas))))
		lines(unique(jday),fluxd,col=1)
		lines(unique(jday),rep(0,length(unique(jday))),lty=3)
		axis(side=4,at=pretty(fluxdmeas),labels=pretty(fluxdmeas)*12);  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
		title("CO2flux")
		mtext(outer=TRUE,paste(titleouter," daily sums"),line=line)
#		fluxdm = tapply(-dataorig[,"Fc.mg.m2.s"]*(60*30*48)/12e6, jday, FUN="mean")
#		lines(unique(jday),fluxdm,col=2)
#			legend(200,max(fluxd),legend=c("Ent","Flux meas."),col=1:2,lty=1)
}
#---------------------------------------------------------------

plot995a = function(day,dat,fluxNEE=NULL, drv=NULL, 
	fluxET.Wm2=NULL, titleouter="",line=-1.5, type="p",daily=48, 	if.dailyonly=FALSE) {

	fluxdmat = NULL
	jday = floor(day)
	jdayu = unique(jday)
	for (i in c("GPP","Rauto","Soilresp","NPP","CO2flux")) {
		fluxd = tapply(dat[,i]/0.012e-06, jday, FUN="na.mean")
		fluxdmat = cbind(fluxdmat, fluxd)
	}
	fluxdmat = as.data.frame(fluxdmat)
	names(fluxdmat)=c("GPP","Rauto","Soilresp","NPP","CO2flux")
	
	day = (1:nrow(dat))/daily
	xlab = "day"

	if (!if.dailyonly) {
		
	for (i in c("IPARdif", "IPARdir", "coszen")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i)," W/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}

	#for (i in c("coszen","pft"
	for (i in c("n","lai","heightm")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(i))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
			
	#Tpools
	for (i in c("leaf","froot","wood","surfmet","surfstr", "soilmet","soilstr","cwd","surfmic","soilmic","slow","passive")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab=xlab, ylab=paste(paste(i), "g-C/m2"))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}
	#Convert C sums (kg/m2) to kg-C/individual.
	for (i in c("C_fol","C_w","C_froot","C_root", 		"C_lab","C_repro")) {
		plot(day, dat[,i]/dat[,"n"],pch=".",type=type, 			cex=3,xlab=xlab, ylab=paste("kg-C/individ")
			,ylim=c(0,max(dat[,i]/dat[,"n"])))
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		}

	
	#Stacked plots
		plot.multi(x=day, ydat = dat[,c("leaf","froot","wood")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool live")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("surfmet","surfstr", "soilmet","soilstr", "cwd","surfmic","soilmic","slow","passive")],
		xlab=xlab,ylab="g-C/m2", if.sepleg=TRUE)
		title("Tpool dead")
		mtext(outer=TRUE,paste(titleouter),line=line)

		plot.multi(x=day, ydat = dat[,c("C_fol","C_w","C_froot", "C_root","C_lab","C_repro")],
		xlab=xlab,ylab="kg-C/m2-gnd", if.sepleg=TRUE)
		title("individual")
		mtext(outer=TRUE,paste(titleouter),line=line)
	
	plot(day,dat[,"TRANS_SW"],type=type,cex=3,xlab=xlab, ylab=paste("transmittance"))
	title("TRANS_SW")
	
	#plot(0,0, type="n", axes=FALSE, xlab="",ylab="")

	for (i in c("GPP","Rauto","Soilresp","NPP")) {
		#Half-hourly
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"))
		#Daily mean
		lines(jdayu,fluxdmat[,i],col=4)
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
	}
		
		i = "CO2flux"
		#Half-hourly
		plot(day, dat[,i]/0.012e-6,pch=".",type=type, cex=3,xlab=xlab, ylab=paste("umol/m2/s"),
		ylim=c(min(min(dat[,i]/0.012e-6,na.omit(fluxNEE))),
			max(max(dat[,i]/0.012e-6,na.omit(fluxNEE)))))
		if (!is.null(fluxNEE)) {
			points(day,fluxNEE,col=2,pch=".")
		}
		#Daily mean
		lines(jdayu,fluxdmat[,i],col=4)
		fluxd = tapply(fluxNEE, jday, FUN="na.mean")
		lines(jdayu,fluxd,col=3)
		title(paste(i))
		mtext(outer=TRUE,paste(titleouter),line=line)
		
}	
	
	#plot(day, dat[,"senescefrac"],pch=".",type=type, cex=3, xlab=xlab, ylab="senescefrac")
	#	title("senescefrac")
	#	mtext(outer=TRUE,paste(titleouter),line=line)

	#Daily sum plots
	#Stacked fluxes
	plot(unique(jday), fluxdmat[,"GPP"]*60*60*24*1e-6, xlab="day", 
		ylab="mol/m2/day",type="l",ylim=c(min(fluxdmat[,"NPP"]),max(fluxdmat[,"GPP"])))
	flist = c("NPP","Rauto","Soilresp")
	for (i in 1:length(flist)) {
		lines(unique(jday), 	
			fluxdmat[,paste(flist[i])]*60*60*24*1e-6, col=i+1)
	}
	legend(200,max(fluxdmat)*60*60*24*1e-6,
		legend=c("GPP","NPP","Rauto","Soilresp"),lty=1,col=1:4)
	title(paste("NPP/GPP =",
		sum(fluxdmat[,"NPP"])/sum(fluxdmat[,"GPP"])))
	
	#Daily sum individual fluxes
	for (i in c("GPP","Rauto","Soilresp","NPP")) {
		plot(unique(jday), fluxdmat[,i]*60*60*24*1e-6, 			xlab="day",ylab="mol/m2/day", type="l")
		#axis(side=4,at=pretty(fluxd),labels=pretty(fluxd)*12)
		#  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
		title(i)
	}

	#CO2 and measured NEE
	fluxd = fluxdmat[,"CO2flux"]*60*60*24*1e-6
	fluxdmeas = as.vector(tapply(fluxNEE,jday,FUN="na.mean"))*60*60*24*1e-6
	ylim=c(min(na.omit(c(fluxd,fluxdmeas))), max(na.omit(c(fluxd,fluxdmeas))))
	plot(unique(jday), fluxdmeas, col=2,xlab="day",ylab="mol/m2/day", type="l", ylim=ylim)
	lines(jdayu,fluxd,col=1)
	lines(jdayu,rep(0,length(unique(jday))),lty=3)
	axis(side=4,at=pretty(fluxdmeas),labels=pretty(fluxdmeas)*12);  mtext("g-C/m2/day",side=4,line=2.5,cex=.7)
	title("CO2flux")
	mtext(outer=TRUE,paste(titleouter),line=line+2)
	mtext(outer=TRUE,paste(" Fluxes - daily sums"),line=line)

	#GCANOPY
	i = "GCANOPY"	
	plot(day, dat[,i],pch=".",type=type, cex=3, xlab=xlab, 		ylab=paste(i, " m/s"))
	title(i)
	
	fluxd=tapply(dat[,"GCANOPY"], jday, FUN="na.mean")
	plot(unique(jday),fluxd,xlab="day",ylab="GCANOPY (m/s)", type="l")
	title("GCANOPY daily avg ")
	plot(unique(jday),1/fluxd,xlab="day",ylab="s/m", type="l")
	title("CANOPY RESISTANCE daily avg")
	mtext(outer=TRUE,paste("GCANOPY daily means"),line=line)
	mtext(outer=TRUE,paste(titleouter),line=line+2)

	#Transpiration
	if (!is.null(drv)) {
		#VPD = qsat(TK=drv[,"TcanopyC"]+273.15,
		#	Pmb=drv[,"P_mbar"]) - drv[,"Qf"]
		#KE = drv[,"Ch"]*drv[,"U"]*dat[,"GCANOPY"]/
		#	(drv[,"Ch"]*drv[,"U"] + dat[,"GCANOPY"])
		VPD = qsat(TK=drv[,"TcanopyC"]+273.15,
			Pmb=drv[,"P_mbar"]) - drv[,"Qf"]
		KE = drv[,"Ch"]*drv[,"U"]*dat[,"GCANOPY"]/
			(drv[,"Ch"]*drv[,"U"] + dat[,"GCANOPY"])

		Transpir = KE*VPD
		lambdaLE = 2.454e6  #latent heat of vaporization [J kg-1 @ 20 C]  #2260 J/g @ 100 C

		plot(day, fluxET.Wm2,pch=16,cex=0.3,col=2,ylab="W/m2")
		points(day, Transpir*lambdaLE, pch=16,cex=0.3)	
		fluxETd = tapply(fluxET.Wm2, jday, FUN="na.mean")
		print(paste("fluxETd", length(fluxETd), jdayu))
		lines(jdayu,fluxETd,col=2)
		Transpird = tapply(Transpir, jday, FUN="na.mean")
		lines(jdayu,Transpird*lambdaLE,col=4)
		title("LE, red-meas., black&blue-model")
		
		plotdsum(day,Transpir,
			fluxmeas=fluxET.Wm2/lambdaLE,
			ylab1="mm/s", ylab2="mm/d",titletext="ET")
	}

	#Plot litter
	plot(day,dat[,"litter"],xlab="day",ylab="g-C/m2",type="l")
	title("litter")
		
	#Plot total soil carbon
	plot(day,apply(dat[,c("surfmet","surfstr", "soilmet","soilstr", "cwd","surfmic","soilmic","slow","passive")],1,FUN="sum"),
		type="l",xlab="day",ylab="g-C/m2")
	title("Total soil carbon")

	#Plot Sacclim, betad
	for (i in c("senescefrac","Sacclim","betad")) {
		plot(day, dat[,i],pch=".",type=type, cex=3,xlab="day", 
			ylab=paste(i))
		title(paste(i))
	}
	
	mtext(outer=TRUE,paste(titleouter),line=line+2)

	return(fluxdmat)
}

#---------------------------------------------------------------
plot998 = function(d, fort.998) {
	temp = as.data.frame(fort.998)
	names(temp) = c("C_lab","GPP","NPP","Resp_fol","Resp_sw","Resp_lab",
         "Resp_froot","Resp_maint","Resp_growth","Resp_growth_1")
    for (i in 1:ncol(fort.998)) {
    		plot(d, temp[,i],xlab="day",ylab=paste(names(temp)[i]),pch=16,cex=0.3)
    		title(paste(names(temp)[i]))
    }
}

plot998a = function(d, fort.998, xlim=NULL, ylim=NULL) {
		temp = NULL
		for (i in 1:ncol(fort.998)) {
			temp = cbind(temp, as.numeric(as.character(fort.998[,i])))
		}
		temp = as.data.frame(temp)
		names(temp) = c("C_lab","GPP","NPP","Resp_fol","Resp_sw","Resp_lab",
         "Resp_froot","Resp_maint","Resp_growth","Resp_growth_1")

		resplist = c("Resp_fol","Resp_lab","Resp_froot", 
				"Resp_growth","Resp_growth_1")
		if (is.null(xlim)) {
			xlim=c(min(d),max(d))
		}
		ylim = c(min(temp[,resplist]),	max(temp[,resplist]))
		
		par(mfrow=c(1,1))
		plot(d,xlim=xlim,ylim=ylim,xlab="day",ylab="kgC m-2 s-1")
		lines(d, temp[,resplist[4]],col=4)
		for (i in c(1:3,5)) {
			lines(d,temp[,resplist[i]], col=i)
		}
		legend(min(xlim),max(ylim), legend=resplist,col=1:length(resplist), lty=1)
}

#---------------------------------------------------------------
plotacts1080 = function(d, fort.1080, xlim=NULL, ylim=NULL, titletext="Ent ACTS", alim=0.6, type="p") {
	#GORT Ent_standalone diagnostics
		temp = NULL
		for (i in 1:ncol(fort.1080)) {
			temp = cbind(temp, as.numeric(as.character(fort.1080[,i])))
		}
		temp = as.data.frame(temp)
#		names(temp) = c("IPARdir","IPARdif","CosZen","cradLAI","Id","Ii",
#			"ALBEDO_VIS_300-770", "ALBEDO_NIR_770-860","ALBEDO_NIR_860-1250", 
#			"ALBEDO_NIR_1250-1500","ALBEDO_NIR_1500-2200","ALBEDO_NIR_2200-4000",
#			"ALBEDODIR1", "ALBEDODIR2","ALBEDODIR3","ALBEDODIR4","ALBEDODIR5","ALBEDODIR6",
#			"ALBEDODIF1", "ALBEDODIF2","ALBEDODIF3","ALBEDODIF4","ALBEDODIF5","ALBEDODIF6",
#			"TRANS_VIS","TRANS_SW","TRANS_NIR",
#			"TRANS_NIR*expr", "I_sun_1", "I_sun_N2", "I_shade_1", "I_shade_N2")
		names(temp) = c("IPARdir","IPARdif","CosZen","fd", "fi",
			"ALBEDO_VIS_300-770", "ALBEDO_NIR_770-860","ALBEDO_NIR_860-1250", 
			"ALBEDO_NIR_1250-1500","ALBEDO_NIR_1500-2200","ALBEDO_NIR_2200-4000",
			"ALBEDODIR1", "ALBEDODIR2","ALBEDODIR3","ALBEDODIR4","ALBEDODIR5","ALBEDODIR6",
			"ALBEDODIF1", "ALBEDODIF2","ALBEDODIF3","ALBEDODIF4","ALBEDODIF5","ALBEDODIF6",
			"TRANS_SW",
			"I_sun_1", "I_sun_N2", "I_shade_1", "I_shade_N2")
		if (is.null(xlim)) {
			xlim=c(min(d),max(d))
		}

		#Met drivers
		for (i in 1:5) {
			plot(d,temp[,i],xlim=xlim, xlab="day",ylab=names(temp)[i], type="l")
			mtext(outer=TRUE, titletext, line=-1)
		}		
		
		#Albedo dir dif bands
		par(mfrow=c(3,2))
		#s = 0.55
		for (i in 6:23) {
			plot(d,temp[,i],xlim=xlim, ylim=c(0,alim),xlab="day",ylab=names(temp)[i], pch=16, cex=0.2, type=type)
			mtext(outer=TRUE, titletext, line=-1)
		}		
		
		#Rad diagnostics
		for (i in 24:ncol(temp)) {
			plot(d,temp[,i],xlim=xlim,xlab="day",ylab=names(temp)[i], pch=16, cex=0.2, type=type)
			mtext(outer=TRUE, titletext, line=-1)
		}		
				
		#Overlay plots
		par(mfrow=c(3,2))
		alb = temp[,6:ncol(temp)]
		#s = 0.3
		for (b in 1:6) {
				plot(d, alb[,b], xlim=xlim, ylim=c(0, alim), pch=".", type=type, 
				  ylab=names(alb)[b])  #ylab=paste("alb", b, sep=""))
				lines(d, alb[,b+6], pch=".", type=type, col=2)
				lines(d, alb[,b], col=1)
				lines(d, alb[,b+2*6], pch=".", type=type, col=3)
				#lines(d, temp[,"CosZen"]*s, lty=2)
				#lines(d, temp[,"fd"], lty=3)
				#lines(d, temp[,"fi"], lty=4)
				#legend(xlim[1], s, legend=c(paste(c("albedo", "albdir", "albdif"), b, sep=""), "CosZen", "fd", "fi"), 
				#	col=c(1,2,3,1,1,1), lty=c(1,1,1,2,3,4), bty="n")
				legend(xlim[1], alim, legend=c(paste(c("albedo", "albdir", "albdif"), b, sep="")), 
					col=c(1,2,3), lty=c(1,1,1), bty="n")
		}
		mtext(outer=TRUE, titletext, line=-1)
		mtext(outer=TRUE, date(), cex=0.6, adj=1)
		
}

if (FALSE) {
	xlim=c(210,220)
 plot(d, fort.1080[,"ALBEDO_VIS_300-770"], xlim=xlim, type="l")
 lines(d, fort.1080[,"ALBEDODIR1"],xlim=xlim, col=2)
 lines(d, fort.1080[,"ALBEDODIF1"],xlim=xlim, col=3)
}

plotgort1082 = function(d, fort.1082, lai=NULL, xlim=NULL, ylim=NULL, alim=0.5, titletext="") {
	#GORT Ent_standalone diagnostics
		temp = NULL
		for (i in 1:ncol(fort.1082)) {
			temp = cbind(temp, as.numeric(as.character(fort.1082[,i])))
		}
		temp = as.data.frame(temp)
		names(temp) = names.fort.1082
		if (is.null(xlim)) {
			xlim=c(min(d),max(d))
		}

		for (i in 1:3) {
			plot(d, temp[,i],xlim=xlim, xlab="day",ylab=names(temp)[i], type="l")
			mtext(outer=TRUE, titletext)
		}		
		if (!is.null(lai)) 	plot(d, lai, type="l")
		
		#Albedo
		par(mfrow=c(3,2))
		for (i in 4:ncol(temp)) {
			plot(d, temp[,i],xlim=xlim, xlab="day",ylab=names(temp)[i], pch=".",
			ylim=c(0,alim))			
			mtext(outer=TRUE, titletext)
		}
	        par(mfrow=c(3,2))
       		for (i in 4:ncol(temp)) {
			plot(d, temp[,i], xlab="day",ylab=names(temp)[i], pch=".",
				xlim=c(130,135), ylim=c(0,0.55))			
			mtext(outer=TRUE, titletext)
		}

		return(temp)
}
#---------------------------------------------------------------
plot997gort = function(file, fort.997, text="") {
	#file = "../../ModelE_runs/rnk_Edevel2nk_hyy_ENT_FLUXNET_gort/Out_121114wz/fort.997"
	#file = "../../ModelE_runs/rnk_Edevel2nk_hyy_ENT_FLUXNET_gort/Out_origffpclump/fort.997"
	#file = "../../ModelE_runs/rnk_Edevel2nk_hyy_ENT_FLUXNET_gort/Out_wz_dirdiffix/fort.997"
	#file = "../../ModelE_runs/rnk_Edevel2nk_hyy_ENT_FLUXNET_gort/Out_wz_dirdiffix2/fort.997"
	temp = read.table(file)
	temp = temp[,3:6]
	fort.997 = NULL
	for (i in 1:ncol(temp)) {
		fort.997 = cbind(fort.997, as.numeric(as.character(temp[,i])))
	}
	fort.997=as.data.frame(fort.997)
	names(fort.997) = c("L", "Isl", "Ish", "fsl")
	i = 1
	ii = 0
	il = fort.997[i+ii,"L"]
	il2 = fort.997[i+ii+1,"L"]
	while (i<nrow(fort.997) & (i+ii <nrow(fort.997)) & il2>il) {
		ii = ii + 1
		il2 = fort.997[i+ii]
	}
}
#---------------------------------------------------------------
plotdsum = function(dayhalfhr,flux,fluxmeas=NULL
		, xlab="day",ylab1="",ylab2="",xlim=NULL,ylim=NULL,
		titletext="",type="l", if.halfhr=TRUE) {
	if (if.halfhr & !is.null(fluxmeas)) {
		repnum = length(flux)/length(fluxmeas)
		plot(dayhalfhr,rep(fluxmeas,repnum),pch=16,cex=0.3,col=2,ylab=ylab1)
		points(dayhalfhr,flux,pch=16,cex=0.3,col=1)
		}	
	title(titletext)
	jday = floor(dayhalfhr)
	fluxd = tapply(flux*(60*60*24)*1e-6, jday, FUN="na.mean")
	if (!is.null(fluxmeas)) {
		repnum = length(flux)/length(fluxmeas)
		print(repnum)
		fluxmeasd = as.vector(tapply(
			rep(fluxmeas*(60*60*24)*1e-6,repnum), jday, FUN="na.mean"))
		plot(unique(jday),fluxmeasd,col=2,xlim=xlim,ylim=ylim
			,xlab=xlab,ylab=ylab2,type=type)
		lines(unique(jday),fluxd,col=1)
	} else {
			plot(unique(jday),fluxd,xlim=xlim,ylim=ylim
			,xlab=xlab,ylab=ylab,type=type)
	}
	title(titletext)	
	return(cbind(fluxmeasd,fluxd))
	}
	
#---------------------------------------------------------------
plot2 = function(x1,y1,x2,y2,ind1,ind2,xlab,ylab,ttext="",which=1) {
	ylim = c(na.min(c(y1,y2)),na.max(c(y1,y2)))
	if (which==1 | which==2) {
	plot(x1,y1,xlab=xlab,ylab=ylab, pch=16,cex=0.3,ylim=ylim,pty="m")
	points(x2,y2,pch=16,cex=0.3,col=2)
	}
	
	if (which==1 | which==3) {
	plot(x1[ind1],y1[ind1],xlab=xlab,ylab=ylab,type="l",ylim=ylim)
	points(x1[ind1],y1[ind1],pch=16,cex=0.3)
	lines(x2[ind2],y2[ind2],col=2)
	points(x2[ind2],y2[ind2],pch=16,cex=0.3,col=2)
	}
	
	mtext(outer=TRUE,ttext,line=-2)
	}
#---------
showNA = function(x,y,toptitle="") {
	#Plots data point time series, and plots red points where NA.
	#x = time vector
	#y = data matrix
	datasum = rep(0,ncol(y))
	for (i in 1:ncol(y)) {
		index = is.na(y[,i])
		if (sum(!index)>0) {
			plot(x,y[,i],
				xlab="day",ylab=names(y)[i],pch=16,cex=0.4)
			points(x[index],rep(min(y[!index,i]),sum(index)),
				col=2,pch=16, cex=.4)
			title(paste(round(1-sum(index)/nrow(y),digits=3)*100,"%",sep=""),adj=1)
			datasum[i]=sum(!index)/nrow(y)*100
		} 
	mtext(toptitle,outer=TRUE,line=0)
	}
	return(datasum)
}

#--------
interpplot = function(x,y,type="linear"
			,x1=340*24-1,x2=360*24
			,toptext1=""
			,toptext2="With close-up over select days to see some gap-fill") {
		#Interpolate data in matrix y and plot.
			#type="linear": use approx for linear interp all NA
			#type="spline": use spline to interp all NA and ends
			#type="constant": gap fill NA front end not done by approx or spline
yout = NULL
var = names(y)
#par(mfrow=c(2,2))
for (i in var) {
	vec =y[,i]
	plot(x,vec,pch=16,cex=.4,xlab="day",ylab=paste(i))
	#junk = spline(x=d,y=vec,xout=d)
	index = is.na(vec)
	if (sum(index)>0) {
		if (type=="linear") {
			junk = approx(x=x,y=vec,xout=x,method="linear")
		} else if (type=="spline") {
			junk = spline(x=x,y=vec,xout=x)
		} else if (type=="constant") {
			j = 1
			while (is.na(vec[j])) {
				j = j+1
				print(j)
			}
			k = 1
			count=1
			val3 = vec[j]
			while (count<3) {
				if (!is.na(vec[j+k])) { 
					val3=val3+vec[j+k]
					count = count+1
				}
				k = k+1
				print(k)
			}
			vec2 = vec
			vec2[is.na(vec)] = val3/3 #Mean of adjacent 3 values
			junk = list(x=x,y=vec2)
		}
		points(x[index],junk$y[index],pch=16,cex=0.4,col=2)
		nas = (1:length(vec))[index]
		#x1 = 340*24-1 #min(nas)-24 
		#x2 = 360*24  #max(nas)+24 
		xlim = c(x1,x2)
		plot(x[x1:x2],vec[x1:x2],pch=16,cex=0.4
			,ylim=c(na.min(junk$y),na.max(junk$y))
			,xlab="day",ylab=paste(i))
		points(x[x1:x2][is.na(vec[x1:x2])],junk$y[x1:x2][is.na(vec[x1:x2])],pch=16,cex=0.4,col=2)
		yout = cbind(yout,junk$y)
	} else {
		plot(x,vec,pch=16,cex=.4,xlab="day",ylab=paste(i))
		title("No gaps")	
		yout = cbind(yout,vec)
	}
	mtext(outer=TRUE,toptext1,line=0.5)
	mtext(outer=TRUE,toptext2,line=-.75)
}
	yout=as.data.frame(yout)
	names(yout)=names(y)
	return(yout)
}
#------------
insertRow = function(m,r,v=NA) {
	#Insert a row into matrix r after row r, optional values v.
	m1 = m[1:r,]
	m2 = m[(r+1):nrow(m),]
	if (length(v)<ncol(m)) {
		v = rep(NA,ncol(m))
	}
	return(rbind(m1,v,m2))
}

fort.980.names.Matt = c( "I0", "I1", "J0", "J1"
, "N_DEPTH", "TairC", "TcanopyC", "Qf", "P_mbar", "Ca", "Ch", "U"
, "IPARdif", "IPARdir", "CosZen"
, "Smp1", "Smp2", "Smp3", "Smp4", "Smp5", "Smp6"
, "Sm1", "Sm2", "Sm3", "Sm4", "Sm5", "Sm6"
, "St1", "St2", "St3", "St4", "St5", "St6"
, "fice1", "fice2", "fice3", "fice4", "fice5", "fice6"
, "LAI1", "LAI2", "LAI3", "LAI4", "LAI5", "LAI6", "LAI7", "LAI8"
, "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8")
