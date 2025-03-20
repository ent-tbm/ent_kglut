#KoeppenGeiger.R
#Author:  Nancy.Y.Kiang@nasa.gov
#Cite:   "Based on, with slight modifications to:
#         Rubel, F. and Kottek, M., 2010. Observed and projected climate shifts 1901-2100 depicted by world maps of the Koppen-Geiger climate classification. Meteorologische Zeitschrift, 19(2): 135-141.  doi:10.1127/0941-2948/2010/0430
#         Kottek, M., Grieser, J., Beck, C., Rudolf, B. and Rubel, F., 2006. World map of the Koppen-Geiger climate classification updated. Meteorologische Zeitschrift, 15(3): 259-263. doi:10.1127/0941-2948/2006/0130"
#Modification to Kottek et al. (2006): Instead of a half-year summer, we used 4-month seasons for tropical climates As and Aw (northern hemisphere, summer = June-September, winter = November-February).  This also identifies the rain shadow areas in East Africa, Sri Lanka, and maybe a little too much of northeastern Brazil. Locations in the code where this modification is done are documented in-line where they occur.
#Acknowledge: Classification R code by Nancy Y. Kiang.

Rpath = paste0(Sys.getenv("R_Ent"), "/")
if (Rpath=="") {
  cat("Please set environment variable R_Ent to the path to your Rfiles directory")
  quit()
}
source(paste0(Rpath,"/utils_noSDMTools.R"))

#Packages to install:  sp, fields, spam, maps, maptools, rworldmap, SDMTools(legend.gradient, only does vertical), plotrix(color.legend, can do horizontal and vertical)
library(sp)
library(fields) 
library(spam) 
library(maps) 
library(maptools) 
library(rworldmap) 
#library(SDMTools) 
library(plotrix)
library(RNetCDF)

#To run:
#1.  Source this file.
#2.  Copy and paste commands inside scripts in file KGrun.R.  Change the paths for your files.

#From Table 1 and Table 2 keys in Kottek et al. (2006) Meteorologische Zeitschrift, Vol. 15, No. 3, 259-263 (June 2006)
#"Table 1: Key to calculate the climate formula of Koeppen and Geiger for the main climates and subsequent precipitation conditions, the first two letters of the classification. Note that for the polar climates (E) no precipitation differentiations are given, only temperature conditions are defined. This key implies that the polar climates (E) have to be determined first, followed by the arid climates (B) and subsequent differentiations into the equatorial climates (A) and the warm temperate and snow climates (C) and (D), respectively. The criteria are explained in the text."
#This yields these 34 classes:
KGclasses = c("Af","Am","As","Aw","BSh","BSk","BWh","BWk"
     ,"Csa","Csb","Csc","Csd","Cwa","Cwb","Cwc","Cwd","Cfa","Cfb","Cfc","Cfd"
     ,"Dsa","Dsb","Dsc","Dsd","Dwa","Dwb","Dwc","Dwd","Dfa","Dfb","Dfc","Dfd"
     ,"ET","EF" )

ONTHcap = c("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC")
ONTH = c("January","February","March","April","May","June","July","August","September","October", "November","December")

#Lookup table for KG categories and map colors.
KGcat = as.data.frame(t(array(dim=c(6,40),
c("Af", 0.5, 0, 0,  "dark red", "Equatorial rainforest, fully humid",
"Am",  1,  0,   0, "bright red", "Equatorial monsoon",
"As",  1,  0.5, 0.5, "dark pink", "Equatorial savannah with dry summer",
"Aw",  1,  0.8, 0.8, "pale pink", "Equatorial savannah with dry winter",
"BWk", 1.0, 1.0, 0.5, "pale yellow", "Arid desert cold",
"BWh", 1.0, 0.8, 0.0, "medium yellow", "Arid desert hot",
"BSk", 0.8, 0.7, 0.6, "cool brown","Arid steppe cold steppe",
"BSh", 0.8, 0.6, 0.1, "warm yellow-brown", "Arid steppe hot",
"Csa", 0.0, 0.95, 0.0, "bright green", "Warm temperate with dry hot summer",
"Csb", 0.5, 1.0, 0.0, "yellow green", "Warm temperate with dry warm summer",
"Csc", 0.8, 1.0, 0.0, "yellower green","Warm temperate with dry cool summer and cold winter",
"Csd", 0.5, 0.5, 0.5, "NA-grey", "Warm temperate with dry summer extremely continental",
"Cwa", 0.7, 0.5, 0.2, "warm brown","Warm temperate with dry winter and hot summer",
"Cwb", 0.65, 0.4, 0.2, "medium cool brown","Warm temperate with dry winter and warm summer",
"Cwc", 0.45, 0.3, 0.1, "dark brown", "Warm temperate with dry cold winter and cool summer",
"Cwd", 0.6, 0.6, 0.6, "NA-pale grey", "Warm temperate with dry winter extremely continental",
"Cfa", 0.0, 0.25, 0.0, "dark green","Warm temperate fully humid with hot summer",
"Cfb", 0.0, 0.5, 0.0, "medium green","Warm temperate fully humid with warm summer",
"Cfc", 0.0, 0.8, 0.0, "medium vivid green","Warm temperate fully humid with cool summer and cold winter",
"Cfd", 0.4, 0.4, 0.4, "NA-deep grey","Warm temperate fully humid extremely continental",
"Dsa", 1.0, 0.1, 1.0, "magenta","Snow with dry hot summer",
"Dsb", 1.0, 0.5, 1.0, "pale magenta","Snow with dry warm summer",
"Dsc", 1.0, 0.7, 1.0, "paler magenta", "Snow with dry cool summer and cold winter",
#"Dsd", 1.0, 1.0, 1.0, "NA-white     ", "Snow with dry summer extremely continental",
#"Dsd", 0.9, 0.9, 0.9, "NA-paler grey", "Snow with dry summer extremely continental",
"Dsd", 1.0, 0.95, 0.95, "pale pink-grey", "Snow with dry summer extremely continental",
"Dwa", 0.8, 0.7, 0.9, "pale grey purple", "Snow with dry winter and hot summer",
"Dwb", 0.7, 0.6, 0.8, "medium grey purple","Snow with dry winter and warm summer",
"Dwc", 0.5, 0.4, 0.7, "grey purple", "Snow with dry cold winter and cool summer",
"Dwd", 0.4, 0.2, 0.6, "deep grey purple","Snow with dry winter extremely continental",
"Dfa", 0.3, 0.1, 0.3, "black purple","Snow fully humid with hot summer",
"Dfb", 0.5, 0.0, 0.4, "red purple", "Snow fully humid with warm summer",
"Dfc", 0.8, 0.0, 0.9, "bright purple", "Snow fully humid with cool summer and cold winter",
"Dfd", 0.8, 0.25, .6, "red fuchsia", "Snow fully humid extremely continental",
"EF",  0.5, 0.6, 1.0, "grey blue", "Polar frost",
"ET",  0.5, 1.0, 1.0, "turquoise", "Polar tundra",
"UA",  0.93, 0.93, 0.93, "tba","Unknown equatorial",
"UAu", 0.94, 0.94, 0.94, "tba","Unknown equatorial 3",
"UB",  0.95, 0.95, 0.95, "tba", "Unknown arid",
"UE",  0.96, 0.96, 0.96, "tba", "Unknown polar",
"Ufu", 0.97, 0.97, 0.97, "tba", "Unknown warmtemp.snow",
"Uuu", 0.98, 0.98, 0.98, "undef", "No data"
))))

KGcat.BeckNK  = as.data.frame(t(array(dim=c(6,40),
c("Af", 0,0,1, "color descr" ,"Equatorial rainforest, fully humid",
"Am", 0,0.47,1, "color descr" ,"Equatorial monsoon", 
"As", 0.6,0.80,1, "color descr" ,"Equatorial savannah with dry summer",
"Aw", 0.27,0.67,0.98, "color descr" ,"Equatorial savannah with dry winter", 
"BWk", 1,0.59,0.59, "color descr" ,"Arid desert cold",
"BWh", 1,0,0, "color descr" ,"Arid desert hot",
"BSk", 1,0.86,0.39, "color descr" ,"Arid steppe cold steppe",
"BSh", 0.96,0.65,0, "color descr" ,"Arid steppe hot",
"Csa", 1,1,0, "color descr" ,"Warm temperate with dry hot summer",
"Csb", 0.78,0.78,0, "color descr" ,"Warm temperate with dry warm summer",
"Csc", 0.59,0.59,0, "color descr" ,"Warm temperate with dry cool summer and cold winter",
"Csd", 0.45,0.3,0.1, "color descr" ,"Warm temperate with dry summer extremely continental",
"Cwa", 0.59,1,0.59, "color descr" ,"Warm temperate with dry winter and hot summer",
"Cwb", 0.39,0.78,0.39, "color descr" ,"Warm temperate with dry winter and warm summer",
"Cwc", 0.2,0.59,0.2, "color descr" ,"Warm temperate with dry cold winter and cool summer",
"Cwd", 0.6,0.6,0.6, "color descr" ,"Warm temperate with dry winter extremely continental",
"Cfa", 0.78,1,0.31, "color descr" ,"Warm temperate fully humid with hot summer",
"Cfb", 0.39,1,0.31, "color descr" ,"Warm temperate fully humid with warm summer",
"Cfc", 0.2,0.78,0, "color descr" ,"Warm temperate fully humid with cool summer and cold winter",
"Cfd", .4,0.4,0.4, "color descr" ,"Warm temperate fully humid extremely continental",
"Dsa", 1,0,1, "color descr" ,"Snow with dry hot summer",
"Dsb", 0.78,0,0.78, "color descr" ,"Snow with dry warm summer",
"Dsc", 0.59,0.2,0.59, "color descr" ,"Snow with dry cool summer and cold winter",
"Dsd", 0.59,0.39,0.59, "color descr" ,"Snow with dry summer extremely continental",
"Dwa", 0.67,0.69,1, "color descr" ,"Snow with dry winter and hot summer",
"Dwb", 0.35,0.47,0.86, "color descr" ,"Snow with dry winter and warm summer",
"Dwc", 0.29,0.31,0.71, "color descr" ,"Snow with dry cold winter and cool summer",
"Dwd", 0.2,0,0.53, "color descr" ,"Snow with dry winter extremely continental",
"Dfa", 0,1,1, "color descr" ,"Snow fully humid with hot summer",
"Dfb", 0.22,0.78,1, "color descr" ,"Snow fully humid with warm summer",
"Dfc", 0,0.49,0.49, "color descr" ,"Snow fully humid with cool summer and cold winter",
"Dfd", 0,0.27,0.37, "color descr" ,"Snow fully humid extremely continental",
"EF", 0.4,0.4,0.4, "color descr" ,"Polar frost",
"ET", 0.7,0.7,0.7, "color descr" ,"Polar tundra",
"UA", 0.93,0.93,0.93, "color descr" ,"Unknown equatorial",
"UAu", 0.94,0.94,0.94, "color descr" ,"Unknown equatorial 3",
"UB", 0.95,0.95,0.95, "color descr" ,"Unknown arid",
"UE", 0.96,0.96,0.96, "color descr" ,"Unknown polar",
"Ufu", 0.97,0.97,0.97, "color descr" ,"Unknown warmtemp.snow",
"Uuu", 0.98,0.98,0.98, "color descr" ,"No data"
))))

#Alternative palest grey for unknowns
#"UA",  0.97, 0.97, 0.97, "tba","Unknown equatorial",
#"UAu", 0.97, 0.97, 0.97, "tba","Unknown equatorial 3",
#"UB",  0.97, 0.97, 0.97, "tba", "Unknown arid",
#"UE",  0.97, 0.97, 0.97, "tba", "Unknown polar",
#"Ufu", 0.97, 0.97, 0.97, "tba", "Unknown warmtemp.snow",
#"Uuu", 0.97, 0.97, 0.97, "undef", "No data"

#Alternative palest grey gradient for unknowns
#"UA",  0.93, 0.93, 0.93, "tba","Unknown equatorial",
#"UAu", 0.94, 0.94, 0.94, "tba","Unknown equatorial 3",
#"UB",  0.95, 0.95, 0.95, "tba", "Unknown arid",
#"UE",  0.96, 0.96, 0.96, "tba", "Unknown polar",
#"Ufu", 0.97, 0.97, 0.97, "tba", "Unknown warmtemp.snow",
#"Uuu", 0.98, 0.98, 0.98, "undef", "No data"


#Alternative grey for unknowns
#"UA",  0.2, 0.2, 0.2, "tba","Unknown equatorial",
#"UAu", 0.3, 0.3, 0.3, "tba","Unknown equatorial 3",
#"UB",  0.4, 0.4, 0.4, "tba", "Unknown arid",
#"UE",  0.9, 0.9, 0.9, "tba", "Unknown polar",
#"Ufu", 0.85, 0.85, 0.85, "tba", "Unknown warmtemp.snow",
#"Uuu", 0.5, 0.5, 0.5, "undef", "No data"

names(KGcat)=c("KGcode","r","g","b","color","descr")
KGcat = as.data.frame(cbind(num=1:nrow(KGcat), KGcat))
KGcat[,"r"]= as.numeric(as.character(KGcat[,"r"]))
KGcat[,"g"]= as.numeric(as.character(KGcat[,"g"]))
KGcat[,"b"]= as.numeric(as.character(KGcat[,"b"]))

names(KGcat.BeckNK)=c("KGcode","r","g","b","color","descr")
KGcat.BeckNK = as.data.frame(cbind(num=1:nrow(KGcat.BeckNK), KGcat.BeckNK))
KGcat.BeckNK[,"r"]= as.numeric(as.character(KGcat.BeckNK[,"r"]))
KGcat.BeckNK[,"g"]= as.numeric(as.character(KGcat.BeckNK[,"g"]))
KGcat.BeckNK[,"b"]= as.numeric(as.character(KGcat.BeckNK[,"b"]))

KGrgb = function(rgbtab=KGcat) {
	KGrgbhex = NULL
	for (i in 1:nrow(rgbtab)) {
		#print(paste(i, rgbtab[i,"r"], rgbtab[i,"g"], rgbtab[i,"b"]))
		KGrgbhex = c(KGrgbhex, rgb(rgbtab[i,"r"], rgbtab[i,"g"], rgbtab[i,"b"]))
	}
	return(KGrgbhex)
}

KGrgbhex= KGrgb()
KGrgbhex.BeckNK = KGrgb(rgbtab=KGcat.BeckNK)

KGlegend = function(colors=KGrgbhex, KGcattab=KGcat, newwindow=FALSE) {
	#Quick check of map colors
	if (newwindow) {
		quartz(width=6,height=4)
	}
	cex = 0.65
	plot(0,0, xlim=c(-180,180),ylim=c(-90,90), type="n", bty="n", xaxt="n", yaxt="n",xlab="",ylab="")
	par(xpd=TRUE)
	#colors=KGrgbhex	
	legend(-180, 150, legend=KGcattab[1:20,"num"], col=colors[1:20], pch=15, cex=cex)
	legend(-150, 150, legend=KGcattab[1:20,"KGcode"], col=colors[1:20], pch=15, cex=cex)
	legend(-110,150, legend=KGcattab[1:20,"color"], col=colors[1:20], pch=15, cex=cex)

	legend(0,150, legend=KGcattab[21:39, "num"], col=colors[21:39], pch=15, cex=cex)
	legend(30,150, legend=KGcattab[21:39, "KGcode"], col=colors[21:39], pch=15, cex=cex)
	legend(70,150, legend=KGcattab[21:39, "color"], col=colors[21:39], pch=15, cex=cex)
	
}

KGlegend2 = function(colors=KGrgbhex, KGcattab=KGcat, newwindow=FALSE) {
	#Quick check of map colors
	if (newwindow) {
		quartz(width=6,height=4)
	}
	cex = 0.65
	plot(0,0, xlim=c(-180,180),ylim=c(-90,90), type="n", bty="n", xaxt="n", yaxt="n",xlab="",ylab="")
	par(xpd=TRUE)
	#colors=KGrgbhex	
	#legend(-180, 150, legend=KGcattab[1:20,"num"], col=colors[1:20], pch=15, cex=cex)
	legend(-150, 150, legend=KGcattab[1:20,"KGcode"], col=colors[1:20], pch=15, cex=cex)
	#legend(-110,150, legend=KGcattab[1:20,"color"], col=colors[1:20], pch=15, cex=cex)

	#legend(0,150, legend=KGcattab[21:39, "num"], col=colors[21:39], pch=15, cex=cex)
	legend(30,150, legend=KGcattab[21:39, "KGcode"], col=colors[21:39], pch=15, cex=cex)
	#legend(70,150, legend=KGcattab[21:39, "color"], col=colors[21:39], pch=15, cex=cex)
	
}


KGlegend3 = function(colors=KGrgbhex, KGcattab=KGcat, cex=0.6, pt.cex=1.1, spc=40, newwindow=FALSE) {
	#Quick check of map colors
	if (newwindow) {
		quartz(width=6,height=4)
	}
	plot(0,0, xlim=c(-200,200),ylim=c(-90,90), type="n", bty="n", xaxt="n", yaxt="n",xlab="",ylab="")
	par(xpd=TRUE)
	x0=-200
	x = x0
	legend(x, 150, legend=KGcattab[1:4,"KGcode"], col=colors[1:4], pch=15, cex=cex, pt.cex=pt.cex, bty="n")
	x = x + spc
	legend(x, 150, legend=KGcattab[5:8,"KGcode"], col=colors[5:8], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
	x = x + spc
	legend(x, 150, legend=KGcattab[9:11,"KGcode"], col=colors[9:11], pch=15, cex=cex, pt.cex=pt.cex,bty="n") #Leave out Csd, neither Kottek nor Beck distinguish
	x = x + spc
	legend(x, 150, legend=KGcattab[13:15,"KGcode"], col=colors[13:15], pch=15, cex=cex, pt.cex=pt.cex,bty="n")  #Leave out Cwd, does not exist
	x = x + spc
	legend(x, 150, legend=KGcattab[17:19,"KGcode"], col=colors[17:20], pch=15, cex=cex, pt.cex=pt.cex,bty="n")  #Leave out Cfd, does not exist
	x = x + spc
	legend(x, 150, legend=KGcattab[21:24,"KGcode"], col=colors[21:24], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
	x = x + spc
	legend(x,150, legend=KGcattab[25:28, "KGcode"], col=colors[25:28], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
	x = x + spc
	legend(x,150, legend=KGcattab[29:32, "KGcode"], col=colors[29:32], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
	x = x + spc
	legend(x,150, legend=KGcattab[33:34, "KGcode"], col=colors[33:36], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
#	x = x + spc
#	legend(x,150, legend=KGcattab[33:36, "KGcode"], col=colors[33:36], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
#	x = x + spc
#	legend(x,150, legend=KGcattab[37:40, "KGcode"], col=colors[37:40], pch=15, cex=cex, pt.cex=pt.cex,bty="n")
				
}


KGcolor = function(KGcode) {
	#Return map color RGB 0-255 for given Koeppen-Geiger climate code
	KGcodeset = c()
}

summer = function(hemi) {
        #From Franz Rubel (2015-01-21): "Summer northern hemisphere (winter southern hemisphere) is defined as April-September. For eq. 2.1 the same half-years should be applied."
	if (hemi=='N') {
		return(c(F,F,F,F,F,T,T,T,F,F,F)) #JJA
	} else if (hemi=='S') {
		return(c(T,T,F,F,F,F,F,F,F,F,T)) #DJF
	}
}

winter = function(hemi) {
	if (hemi=='N') {
		return(c(T,T,F,F,F,F,F,F,F,F,F,T)) #DJF
	} else if (hemi=='S') {
		return(c(F,F,F,F,F,T,T,T,F,F,F,F)) #JJA
	}	
}

summeryr.4 = function(hemi) {
	#1/3-year season
	#Modification to Kottek & Rubel (2006), using 4-month seasons for As and Aw (northern hemisphere, summer = June-September, winter = November-February).  This also identifies the rain shadow areas in East Africa, Sri Lanka, and maybe a little too much of northeastern Brazil.
	if (hemi=='N') {
		return(c(F,F,F,F,F,T,T,T,T,F,F,F)) #-----JJAS---
	} else if (hemi=='S') {
		return(c(T,T,F,F,F,F,F,F,F,F,T,T)) #JF--------ND
	}	
}
winteryr.4 = function(hemi) {
	#1/3-years season
        #Modification to Kottek & Rubel (2006), using 4-month seasons for As and Aw (northern hemisphere, summer = June-September, winter = November-February).  This also identifies the rain shadow areas in East Africa, Sri Lanka, and maybe a little too much of northeastern Brazil.
	if (hemi=='N') {
		return(c(T,T,F,F,F,F,F,F,F,F,T,T)) #JF--------ND
	} else if (hemi=='S') {
		return(c(F,F,F,F,F,T,T,T,T,F,F,F)) #-----JJAS---
	}	
}

summeryr = function(hemi) {
	#Half-years between the equinoxes
	if (hemi=='N') {
		return(c(F,F,F,T,T,T,T,T,T,F,F,F)) #---AMJJAS---
	} else if (hemi=='S') {
		return(c(T,T,T,F,F,F,F,F,F,T,T,T)) #JFM------OND
	}	
}
winteryr = function(hemi) {
	#Half-years between the equinoxes
	if (hemi=='N') {
		return(c(T,T,T,F,F,F,F,F,F,T,T,T)) #JFM------OND
	} else if (hemi=='S') {
		return(c(F,F,F,T,T,T,T,T,T,F,F,F)) #---AMJJAS---
	}	
}

Phemi = function(IM, JM, PmmIJ, hemi, Pval) {
	#Return hemisphere extreme precip values
	#IM = longitude resolution
	#JM = latitude resolution
	#PmmIJ = array(, dim=c(JM,IM,12)) of monthly precip mm
	#hemi = 'N'=northern hemisphere, 'S'=southern hemisphere
	#Pval = 'Psmin','Psmax','Pwmin','Pwmax' where s-summeryr, w-winteryr
	
	if (Pval=="Psmin" | Pval=="Psmax") {
		season = summeryr(hemi)
	} else {
		season = winteryr(hemi)
	}
	
	if (Pval=="Psmin" | Pval=="Pwmin") {
		fnapp = "na.min"
	} else {
		fnapp = "na.max"
	}
	
	if (hemi=="N") {
		hemindex = 1: (JM/2)
	} else { #hemi=="S"
		hemindex = (JM/2 + 1):JM	
	}
	
	return( apply(t( apply(PmmIJ[hemindex,,], 2, fnapp)), 1, fnapp))
}


E.polar = function(TCmon) {
	return( na.max(TCmon) < 10)
}

E.polar.sub = function(TCmon) {
	KGcode=NA
	if (na.max(TCmon)>= 0 & na.max(TCmon) < 10) {
		KGcode = "ET" #Polar tundra
	} else if (na.max(TCmon) < 0) {
		KGcode = "EF" #Polar frost
	} else {
		KGcode = "UE"
		#print(c("UE", E.polar(TCmon), "TC", TCmon, "P", Pmmmon))

	}
	return( KGcode)
}

B.Pthresh = function(TCmon,Pmmmon, hemi) {
	#Return Pth threshold value
	TCann = na.mean(TCmon)
	Pmmann = sum(Pmmmon)
	Pth = NA
	if ( sum(Pmmmon[winter(hemi)]) >= 2/3*Pmmann ) {
		Pth = 2 * TCann
	} else if (sum(Pmmmon[summeryr(hemi)]) >= 2/3*Pmmann ) {
		Pth = 2 * TCann + 28.0
	} else {
		Pth = 2 * TCann + 14.0
	}
	return( Pth )
}

B.arid.Pth = function(TCmon, Pmmmon, hemi) {
	#Return logical B.arid and var Pth threshold value
	if (!E.polar(TCmon)) {
		Pth = B.Pthresh(TCmon, Pmmmon, hemi)
		#print(paste(c("Pth", Pth, sum(Pmmmon) < 10 * Pth, TCmon, Pmmmon, hemi)))
		return( list( is.arid = sum(Pmmmon) < 10 * Pth,  B.Pth=Pth ) )
	}
}

B.arid.sub = function(TCmon, Pmmmon, hemi) {
	#Return 3-character classification
	KGcode=NA
	TCann = na.mean(TCmon)
	Pmmann = sum(Pmmmon)
	B.arid.res = B.arid.Pth(TCmon, Pmmmon, hemi)
	if (B.arid.res$is.arid) {
		Pth = B.arid.res$B.Pth
		#print(paste("Pth okay", Pth))

		if (sum(Pmmmon) > 5 * Pth) {  #BS-Steppe
			if (TCann >= 18) {
				KGcode = "BSh"   #Hot steppe
			} else {
				KGcode = "BSk"   #Cold steppe
			}
		} else  { #if (Pmmman <= 5 * Pth) {  #BW-Desert
			if (TCann >= 18) {
				KGcode = "BWh"   #Hot desert
			} else {
				KGcode = "BWk"   #Cold desert
			}
		}
	} else {
		KGcode = "UB"
	}
	return(KGcode)
}


A.equatorial = function(TCmon) {
	#logical: TRUE=A.equatorial, FALSE=not A.equatorial
	#TCmon = average monthly temperature Celsius, each month (array 12)
	
	return(na.min(TCmon)>=18) 
}

A.equatorial.sub = function(TCmon, Pmmmon, hemi) {
	#2-character string, see descriptions below
	#TCmon = average monthly temperature Celsius, each month (array 12)
	#Pmmmon = monthly precipitation mm, each month (array 12)
	#hemi = 'N'-northern hemisphere, 'S'-southern hemisphere	
	#Kottek&Rubel (2006): The order of checking for As and Aw in K&R is As then Aw.  NYK discussed with Rubel that switching the order replicated their published results.
        #  Code here retains K&R order.
	KGcode = NA
	if (A.equatorial(TCmon)) {
	
		if (na.min(Pmmmon) >= 60) {
			KGcode = "Af" #Equatorial rainforest, fully humid
		} else if (sum(Pmmmon) >= 25.0*(100 - na.min(Pmmmon))) {
		  	KGcode = "Am" #Equatorial monsoon
		} else if (na.min(Pmmmon[summeryr.4(hemi)]) < 60) {
			KGcode = "As" #Equatorial savannah with dry summer
			#print(c("As", hemi, "TC", TCmon, "P", Pmmmon))
		} else if (na.min(Pmmmon[winteryr.4(hemi)]) < 60) {
			KGcode = "Aw" #Equatorial savannah with dry winter
		} else {
			KGcode = "UAu"
			#print(c("UAu", hemi, "TC", TCmon, "P", Pmmmon, na.min(Pmmmon[winteryr(hemi)])))
		}
	} else {
		KGcode = "UA"
		#print(c("UA", A.equatorial(TCmon), hemi, "TC", TCmon, "P", Pmmmon))
	}
	return( KGcode )
}

CD.letter3 = function(TCmon, Pmmmon) {
	#Gives the 3rd letter classification for C.warmtemp.sub and D.snow.sub	
	#From Table 2 in Kottek et al. (2006)
	
	letter3 = NA
	if (na.max(TCmon) >= 22.0) {
		letter3 = "a"  #Hot summer
	} else if ( na.max(TCmon < 22.0) & sum(TCmon >= 10.0) >= 4) {
		letter3 = "b"  #Warm summer
	} else if (na.min(TCmon) > -38.0) {
		letter3 = "c"  #Cool summer and cold winter
	} else if (na.min(TCmon) <= -30.0) {
		letter3 = "d"  #extremely continental
	} else {
		letter3 = "u"
	}
	return(letter3)
}


C.warmtemp = function(TCmon) {
	return ( na.min(TCmon) > -3 & na.min(TCmon) < 18)
}

D.snow = function(TCmon) {
	return(na.min(TCmon)<= -3.0)
}

CD.warmtemp.snow.sub = function(TCmon, Pmmmon, hemi) {
	
	Psmin = na.min(Pmmmon[summeryr(hemi)])
	Psmax = na.max(Pmmmon[summeryr(hemi)])
	Pwmin = na.min(Pmmmon[winteryr(hemi)])
	Pwmax = na.max(Pmmmon[winteryr(hemi)])
	
	if (C.warmtemp(TCmon)) {
		letter1="C"  #Warm temperate
	} else if (D.snow(TCmon)) {
		letter1="D"  #Snow
	} else {
		letter1="U"  #Unknown
	}
	
	if (Psmin<Pwmin & Pwmax>3.0*Psmin & Psmin<40.0) {
		letter2 = "s"  #dry summer
	} else if (Pwmin<Psmin & Psmax>10*Pwmin) {
		letter2 = "w"  #dry winter
	} else {
		letter2 = "f"  #fully humid
		#print(c("Cf", Psmin, Psmax,Pwmin, Pwmax,"P",Pmmmon ))
	}

	letter3 = CD.letter3(TCmon, Pmmmon)

	return( paste(letter1, letter2, letter3, sep=""))
}


KGclim = function(TCmon, Pmmmon, hemi) {
#Assign a Koeppen-Geiger climate classification code, given monthly temperature (C), precipitation (mm), and hemispheric summary values.  The monthly values could be the mean values for a single grid cell, or for a cluster.
	#TCmon = average monthly temperature Celsius, each month (array 12)
	#Pmmmon = monthly precipitation mm, each month (array 12)
	#hemi = 'N'-northern hemisphere, 'S'-southern hemisphere	
	
	KGcode = "Uuu" #Initialize Unknown
	
	if (is.na(sum(TCmon)) | is.na(sum(Pmmmon))) {
		KGcode = "Uuu"
	} else if (E.polar(TCmon)) {
		KGcode = E.polar.sub(TCmon)
		#if (length(KGcode)!=1) {
			#print(paste(c("E.polar",KGcode, TCmon, Pmmmon, hemi)))
		#}
		
	} else if (B.arid.Pth(TCmon, Pmmmon, hemi)$is.arid) {
		KGcode = B.arid.sub(TCmon, Pmmmon, hemi)
		#if (length(KGcode)!=1) {
			#print(paste(KGcode))
			#print(paste(c("B.arid",KGcode, TCmon, Pmmmon, hemi)))
		#}
	} else if (A.equatorial(TCmon)) {
		KGcode = A.equatorial.sub(TCmon, Pmmmon, hemi)
		#if (length(KGcode)!=1) {
			#print(paste(KGcode))
			#print(paste(c("A.equatorial",KGcode, TCmon, Pmmmon, hemi)))
		#}
	} else  if (C.warmtemp(TCmon)) {
		KGcode = CD.warmtemp.snow.sub(TCmon, Pmmmon, hemi)
		#if (length(KGcode)!=1) {
			#print(paste(KGcode))
			#print(paste(c("C.warmtemp",KGcode, TCmon, Pmmmon, hemi)))
		#}
	} else if (D.snow(TCmon)) {
		KGcode = CD.warmtemp.snow.sub(TCmon, Pmmmon, hemi)		
		#if (length(KGcode)!=1) {
			#print(paste(KGcode))
			#print(paste(c("D.snow",KGcode, TCmon, Pmmmon, hemi)))
		#}
	} else {
		KGcode="Uu"
	}
	
	if (length(KGcode)!=1) {
		#print(paste(c(KGcode, TCmon, Pmmmon, hemi)))
		KGcode="Uu"
	}
	return( KGcode )
}

KGscript2 = function(IM, JM, TCIJ, PmmIJ, clusfile=NULL, type="map") {
#Version 2 with TCIJ and PmmIJ arrays dim=c(IM,JM,12).
#Main routine to classify either a climate map, or cluster, assigning the Koeppen-Geiger code.
	#IM = grid cells for longitude (e.g. 360 for 1 degree)
	#JM = grid cells for latitude (e.g. 180 for 1 degree)
	#TCIJ = dim=c(IM,JM,12) array of monthly temperature (C).  Should be CSV, 	
	#  (I,J, TC, Pmm, MONTH), I=1=West, J=1=South
	#PmmIJ = dim=c(IM,JM,12) array of monthly precip (mm).
	#clusfile = optional lm cluster. CSV of i, j, TC, Pmm, MONTH
	
	#Column numbers
	icol=1
	jcol=2
	tcol=3
	pcol=4
	mcol=5
		

	#Classify map
	print("Classifying climate map")
	#print(paste("dim(TCIJ):", IM, JM, dim(TCIJ)))
	#print(paste("dim(PmmIJ):", IM, JM, dim(PmmIJ)))

	KGmap = array(NA,dim=c(IM,JM))
	for (i in 1:IM) {
		for (j in 1:JM) {
			if (j<= JM/2) {
				hemi="S"
			} else {
				hemi="N"
			}
			#print(c(i,j,hemi))
			TCmon = TCIJ[i,j,]
			Pmmmon = PmmIJ[i,j,]
			KGmap[i,j] = KGclim(TCmon, Pmmmon, hemi)
		}
	}
	print("Done classifying climate map")
	
	#Classify cluster
	if (!is.null(clusfile)) {
		print("Classifying cluster")
		clusread = read.table(clusfile, sep=",",header=TRUE) #dim=c(12*npoint,5)
		npoint = nrow(clusread)/12
		clus = array(t(clusread),dim=c(5,12,npoint))
		index.s = clus[jcol,,] <= JM/2 #dim(12,npoint), j is in column 2
		clus.s = clus[,,index.s[1,]] #Clusters in southern hemisphere
		clus.n = clus[,,!index.s[1,]]
		
		TCmon = apply(clus.s[tcol,],2,na.mean)
		Pmmmon = apply(clus.s[pcol,],2,na.mean)
		KG.south = KGclim(TCmon, Pmmmon, "S")
		
		TCmon = apply(clus.n[tcol,],2,na.mean)
		Pmmmon = apply(clus.n[pcol,],2,na.mean)
		KG.north = KGclim(TCmon, Pmmmon, "N")
		print("Done classifying cluster")
	} else {
		KG.south=NA
		KG.north=NA
	}
	
	return(list(KGmap, KG.south, KG.north))
}

KGscript = function(IM, JM, TCIJ, PmmIJ, clusfile=NULL, type="map") {
#Version 2 with TCIJ and PmmIJ arrays dim=c(JM,IM,12).
#Main routine to classify either a climate map, or cluster, assigning the Koeppen-Geiger code.
	#IM = grid cells for longitude (e.g. 360 for 1 degree)
	#JM = grid cells for latitude (e.g. 180 for 1 degree)
	#TCIJ = dim=c(JM,IM,12) array of monthly temperature (C).  Should be CSV, 	
	#  (I,J, TC, Pmm, MONTH), I=1=West, J=1=South
	#PmmIJ = dim=c(JM,IM,12) array of monthly precip (mm).
	#clusfile = optional lm cluster. CSV of i, j, TC, Pmm, MONTH
	
	#Column numbers
	icol=1
	jcol=2
	tcol=3
	pcol=4
	mcol=5
		

	#Classify map
	print("Classifying climate map")
	KGmap = array(NA,dim=c(IM,JM))
	for (i in 1:IM) {
		for (j in 1:JM) {
			if (j<= JM/2) {
				hemi="S"
			} else {
				hemi="N"
			}
			#print(c(i,j,hemi))
			TCmon = TCIJ[j,i,]
			Pmmmon = PmmIJ[j,i,]
			KGmap[j,i] = KGclim(TCmon, Pmmmon, hemi)
		}
	}
	print("Done classifying climate map")
	
	#Classify cluster
	if (!is.null(clusfile)) {
		print("Classifying cluster")
		clusread = read.table(clusfile, sep=",",header=TRUE) #dim=c(12*npoint,5)
		npoint = nrow(clusread)/12
		clus = array(t(clusread),dim=c(5,12,npoint))
		index.s = clus[jcol,,] <= JM/2 #dim(12,npoint), j is in column 2
		clus.s = clus[,,index.s[1,]] #Clusters in southern hemisphere
		clus.n = clus[,,!index.s[1,]]
		
		TCmon = apply(clus.s[tcol,],2,na.mean)
		Pmmmon = apply(clus.s[pcol,],2,na.mean)
		KG.south = KGclim(TCmon, Pmmmon, "S")
		
		TCmon = apply(clus.n[tcol,],2,na.mean)
		Pmmmon = apply(clus.n[pcol,],2,na.mean)
		KG.north = KGclim(TCmon, Pmmmon, "N")
		print("Done classifying cluster")
	} else {
		KG.south=NA
		KG.north=NA
	}
	
	return(list(KGmap, KG.south, KG.north))
}


KGcode2num = function(KGmap) {
	IM = dim(KGmap)[2]
	JM = dim(KGmap)[1]
	
	KGnummap = array(NA, dim=c(JM,IM))
	for (i in 1: IM) {
		for (j in 1:JM) {
			index = KGcat[,"KGcode"]==KGmap[j,i]
			if (sum(index)==1) {
				KGnummap[j,i] = KGcat[index,"num"]
			} else {
				KGnummap[j,i] = NA
			}
		}
	}
	print("Converted KG classes to lookup table numbers")
	return(KGnummap)
}


Climdata.read = function(fname="", IM=360, JM=180, Klayers=12) {
	climdata = array(NA, dim=c(JM,IM, Klayers))
	
	for (i in 1:Klayers) {
		#layervals=t(array(scan(file=fname,skip=(1+2*(i-1)),nmax=IM*JM), dim=c(IM,JM)))
		layervals=t(array(scan(file=fname,skip=(1+2*(i-1)),nmax=IM*JM), dim=c(IM,JM)))
		climdata[,,i] = layervals
	}
	return(climdata)
}

Sheffield.KG.script = function(Tname="", Pname="", Tshift=-273.15, Pfactor=10e6, IM=360, JM=180) {
	TCIJ = Sheffield.read(Tname, IM, JM) + Tshift #temperature in Celsius
	PmmIJ = Sheffield.read(Pname, IM, JM) * Pfactor #precip in mm
	
	KGresult = KGscript(IM, JM, TCIJ, PmmIJ, clusfile=NULL, type="map")
	return(KGresult)
}

Cluster.read = function(file="", IM, JM, Tshift=-273.15,Pfactor=1e6, clustnum=NULL) {
	clus = read.table(file=file, header=TRUE, sep=",")
	clus[,"TEMP"] = clus[,"TEMP"]+Tshift
	clus[,"PERC"] = clus[,"PERC"]*Pfactor
	#Replace month names with number
	monn = array(NA, nrow(clus))
	tmean = array(NA,12)
	tsd = array(NA,12)
	pmean = array(NA,12)
	psd = array(NA,12)
	for (m in 1:12) {
		index= clus[,"MON"]==MONTH[m] #MONTHcap[m]
		monn[index] = m
		tmean[m] = na.mean(clus[index,"TEMP"])
		tsd[m] = sd(clus[index, "TEMP"])
		pmean[m] = na.mean(clus[index,"PERC"])
		psd[m] = sd(clus[index,"PERC"])
	}
	#scatter.smooth(monn, clus[,"TEMP"],lpars=list(pch="."))
	#scatter.smooth(monn, clus[,"PERC"],lpars=list(pch="."))
	plot(monn, clus[,"TEMP"],pch=".",xlab="month",ylab="Celsius",ylim=c(-70,40))
	lines(1:12, tmean)
	if (!is.null(clustnum)) {
		mtext(paste("Cluster",clustnum),cex=0.9)
	}
	mtext(line=-8, "month",cex=0.7)
	plot(monn, clus[,"PERC"],pch=".", xlab="month",ylab="mm/month?",ylim=c(0,100))
	lines(1:12, pmean)
	if (!is.null(clustnum)) {
		mtext(paste("Cluster",clustnum),cex=0.9)
	}
	mtext(line=-8, "month",cex=0.7)
	#if (JM==90) {    #144x90
	#	equator = 45 #Just south of
	#} else if (JM==180) { #360x180
	#	equator = 90 #Just south of
	#} else {
	#	print("Add new grid case")
	#    return(0)
	#}
	
	#north = clus[,"j"]>equator
	#south = clus[,"j"]<= equator
	#kg2 = KGclim(TCmon=tmeannorth, Pmmmon=pmeansouth, hemi, Psmin,Psmax,Pwmin,Pwmax) 
	
	return(list(clus=cbind(clus,monn), stat=cbind(mon=1:12,tmean,tsd,pmean,psd)))
}


plot.cluster.subkg = function(clusnum, kgnum, res=NULL, if.frac=TRUE, if.clim=FALSE, climdata=NULL) {
	#Map a cluster using the KG class nearest the cluster center, with gradations of that color for different clusters in the KG class.
	clusvec = as.numeric(names(table(clusnum)))
	print(clusvec)
	kgvec = as.numeric(names(table(kgnum)))
	kgnumfrac = kgnum
	print(kgvec)
	newcat = NULL
	for (k in kgvec) {
		index = clusnum[kgnum==k]
		subkg = table(index)
		subn = length(subkg)
		print(c(k, subn, subkg)) #Number of cluster classes in a KG class
		frac = 0
		for (j in as.numeric(names(subkg))) {  #Assign fraction increment to KG class number for each subclass
			kgnumfrac[kgnum==k & clusnum==j] = k + frac
			KGrow = KGcat[k,]
			KGrow[,c("r","g","b")] = KGrow[,c("r","g","b")] * (1-frac)
			newcat = rbind(newcat, c(kgfrac=k+frac, KGrow))
			frac = frac + 1/subn/3
		}
	}
	plot.grid.categorical(kgnum, res=res,colors=KGrgbhex[na.min(kgnum):na.max(kgnum)])
	
	if (if.frac) {
	for (i in 1:nrow(newcat)) {
		rgbhex = rgb(newcat[i,"r"], newcat[i,"g"], newcat[i,"b"])
		index = kgnumfrac==newcat[i,1]
		kgz = kgnumfrac
		kgz[!index] = NA
		plot.grid.categorical(kgz, res=res,colors=rgbhex, ADD=TRUE)
	}}
	plot(coastsCoarse, add=TRUE)
	
	return(newcat)
}

make.kgclusclim = function(clus, clim) {
	#Make a data frame of month, kgclim, clusnum, kgclus, temp, precip
	#clus = cluster list with names "temp" "prcp" "lbls" "IM"   "JM"   "kg" 
	#       where temp and precip are JM x IM x 12
	#       and kg is nearest kg class to cluster manifold
	#clim = climate data with "temp" "prcp" "lbls" "IM"   "JM"   "kg" 

	climkg = clim$kg
	#kgvec = sort(as.numeric(unique(c(clus$kg, climkg))))
	kgvec = sort(as.numeric(unique(c(climkg))))
	
	month=NULL
	temp = NULL
	precip = NULL
	kgclim = NULL
	clusnum = NULL
	kgclus = NULL
	checksum = 0
	for (k in kgvec) {
		#year vectors for kg class k
		my = NULL
		ty = NULL
		py = NULL
		kgclimy = NULL
		clusnumy = NULL
		kgclusy = NULL
		index = climkg==k
		n = na.sum(index)
		checksum = checksum + n
		print(paste(k, n, checksum))
			#HACK R bug??  THIS IS ONLY FOR THE 144X90 CLIMATE
			if (k==4) {
				nHACK = n+1					
			} else {
				nHACK = n
			}
		if (n>0) {
			for (m in 1:12) {
				print(c(m, n, na.sum(index)))
				my = c(my, rep(m,nHACK))
				ty = c(ty, clim$temp[,,m][index])
				py = c(py, clim$prcp[,,m][index])
				kgclimy = c(kgclimy, rep(k, nHACK))
				clusnumy = c(clusnumy, clus$lbls[index])
				kgclusy = c(kgclusy, clus$kg[index])
			}
			#plot.kgclusclim.k(cbind(month=my, kgclim=kgclimy, clusnum=clusnumy, kgclus=kgclusy,
			#	temp=ty, precip-py))
		} else {
			print(paste(k, "no k"))
		}
		print(c(length(my),length(ty),length(py),length(kgclimy),length(clusnumy),length(kgclusy))/12)
		print(table(index))
		month = c(month, my)
		temp = c(temp, ty)
		precip = c(precip,py)
		kgclim = c(kgclim, kgclimy)
		clusnum = c(clusnum, clusnumy)
		kgclus = c(kgclus, kgclusy)
	}
	print(c(length(month),length(temp),length(precip),length(kgclim),length(clusnum),length(kgclus)))
	kgclusclim = cbind(month,kgclim,clusnum,kgclus, temp,precip)		
	#plot.kg.clus.climate(kgclusclim)
	
	print("REMOVE HACK FOR 144x90 CLIMATE!!!")
	print("REMOVE HACK FOR 144x90 CLIMATE!!!")
	print("REMOVE HACK FOR 144x90 CLIMATE!!!")
	return(kgclusclim)
}

plot.kg.clus.climate = function(kgclusclim) {
	#Plots time plots of monthly temp and precip by KG class, and colors points of clusters within the KG class
	#kgclusclim = data frame of month, kgclim, clusnum, kgclus, temp, precip

	quartz(width=8.5, height=11)
	par(mfrow=c(5,3))
	
	for (k in unique(kgclusclim[,"kg"])) {
		index = kgclusclim[,"kg"]==k
		for (m in 1:12) {
			tmean = na.mean(kgclusclim[index & kgclusclim[,"month"]==m,"temp"])
			pmean = na.mean(kgclusclim[index & kgclusclim[,"month"]==m,"precip"])
		}
		#Temperature
		plot(1:12, rep(0,12),type="n", xlab="month", ylab="temperature (C)", ylim=c(-50, 35))
		title(paste("KG =",k))
		mtext("temperature")
		col = 1
		for (cn in unique(kgclusclim[index,"clusnum"])) {
			indexc = index & kgclusclim[,"clusnum"]
			points(kgclusclim[indexc,"month"], kgclusclim[indexc,"temp"], pch=16,col=col)
			col = col + 1
		}
		lines(1:12, tmean)
		#Precip
		plot(1:12, rep(0,12),type="n", xlab="month", ylab="precip (mm/month)", ylim=c(0, 200))
		title(paste("KG =",k))
		mtext("precipitation")
		col = 1
		for (cn in unique(kgclusclim[index,"clusnum"])) {
			indexc = index & kgclusclim[,"clusnum"]
			points(kgclusclim[indexc,"month"], kgclusclim[indexc,"precip"], pch=16,col=col)
			col = col + 1
		}
		lines(1:12, pmean)	
	}	
}

plot.kgclusclim.k = function(kgclusclimk, class="kgclim", subc="clusnum", if.legend=FALSE, if.abslim=FALSE) {
	#Plot time plots of temp and precip for a single KG class k.
	#kgclusclimk is a data frame with columns:  month, kgclim, clusnum, kgclus, temp, precip

	k = unique(kgclusclimk[,class])
	print(paste("k",k))
	tmean = NULL
	pmean = NULL
	for (m in 1:12) {
		print(m)
		tmean = c(tmean, na.mean(kgclusclimk[kgclusclimk[,"month"]==m,"temp"]))
		pmean = c(pmean, na.mean(kgclusclimk[kgclusclimk[,"month"]==m,"precip"]))
	}

	#Temperature
	if (if.abslim) {
		ylim=c(-50,50)
	} else {
		ylim = c(na.min(kgclusclimk[,"temp"]), na.max(kgclusclimk[,"temp"]))
	}
	plot(1:12, rep(0,12),type="n", xlab="month", ylab="temperature (C)", ylim=ylim)
	mtext("temperature")
	col = 1
	for (cn in unique(kgclusclimk[,subc])) {
		indexc = kgclusclimk[,subc]==cn
		print(c(cn, sum(indexc)))
		if (sum(indexc)>0) {
			points(kgclusclimk[indexc,"month"], kgclusclimk[indexc,"temp"], pch=16,col=col, cex=0.5)
			col = col + 1
		}
	}
	lines(1:12, tmean)
	if (class=="kgclim") {
		title(paste(k, as.character(KGcat[k,"KGcode"])),adj=0)
		if (if.legend) {legend(1,ylim[2], legend=names(table(kgclusclimk[,subc])), col=1:col, pch=16, bty="n")}	
	} else { #class="clusnum"
		title(paste("Clus", k), adj=0)
		if (if.legend) {legend(1,ylim[2], legend=KGcat[as.numeric(names(table(kgclusclimk[,subc]))),"KGcode"], col=1:col, pch=16, bty="n")	}
	}
	title(paste("n =",nrow(kgclusclimk)), adj=1)

	
	#Precipitation
	#ylim = c(0,max(600,na.max(kgclusclimk[,"precip"])))
	ylim = c(0, 1000)
	plot(1:12, rep(0,12),type="n", xlab="month", ylab="precip (mm/month)", 
		ylim=ylim)
	mtext("precipitation")
	col = 1
	for (cn in unique(kgclusclimk[,subc])) {
		indexc = kgclusclimk[,subc]==cn
		points(kgclusclimk[indexc,"month"], kgclusclimk[indexc,"precip"], pch=16,col=col, cex=0.5)
		col = col + 1
	}
	lines(1:12, pmean)	
	if (class=="kgclim") {
		title(paste(k, as.character(KGcat[k,"KGcode"])),adj=0)
		if (if.legend) {legend(1,ylim[2], legend=names(table(kgclusclimk[,subc])), col=1:col, pch=16, bty="n")}	
	} else { #class="clusnum"
		title(paste("Clus", k), adj=0)
		if (if.legend) {legend(1,ylim[2], legend=KGcat[as.numeric(names(table(kgclusclimk[,subc]))),"KGcode"], col=1:col, pch=16, bty="n")	}
	}
	title(paste("n =",nrow(kgclusclimk)), adj=1)
}



run.KG = function(Tnc, Pnc, Tname="tsurf", Pname="prec", IM=144, JM=90, undef=-1e30, ttext="", ptext="", if.new=TRUE, if.coasts=TRUE, if.plot=FALSE) {
	# Generate Koeppen-Geiger classification of climate.
	#Tnc:  monthly surface temperature in Celsius, netcdf file of dimension [IM, JM, 12] for 12 months
	#Pnc:  monthly precipitation in mm, netcdf file of dimension [IM, JM, 12] for 12 months
	#Tname:  netcdf variable name for surface temperature
	#Pname:  netcdf variable name for precipitation
	#IM:  grid size for longitude
	#JM:  grid size for latitude
	#undef:  _FillValue_ for the provided files
	#ttext:  optional text for title on plot of temperature
	#ptext:  optional text ofr title on plot of precipitation
	#if.new:  boolean to open a new plot window
	#if.plot.TP:  optional boolean also to map the temperature and precip values.
	
	res = res.from.IM.JM (IM, JM)
	
	#1) Read in climate data
	
	nc <- open.nc(Tnc, write=FALSE)
	junk=var.get.nc(nc, Tname)
	TCIJ = junk  #Dimension (IM, JM, months), e.g. (720,360,12) for 0.5 degree
	close.nc(nc)
	
	nc <- open.nc(Pnc, write=FALSE)
	junk=var.get.nc(nc,Pname)
	PmmIJ = junk
	close.nc(nc)

	TCIJ[TCIJ==-1e30] = NA
	PmmIJ[PmmIJ==-1e30] = NA

	#2)  Do classification
	KGresult = KGscript2(IM, JM, TCIJ, PmmIJ, clusfile=NULL, type="map")
	
	#3)  Convert KGcodes to numbers.
	KGnum =KGcode2num(KGresult[[1]])
	
	if (if.plot) {
   	  #4)  Plots
#		continentmap <- getMap(resolution="coarse")

	  #5) Plot KG
		plot.KG(KGnum, if.new=if.new, if.coasts=if.coasts)
	}

	return(KGnum)
	
}

plot.KG = function(KGnum, if.new=TRUE, if.coasts=TRUE ) {
	#Given map array of Koeppen-Geiger classes, plot with legend.
	#KGnum:  array of dimension (IM, JM) of Koeppen-Geiger class numbers.
	#if.new:  option to open new plot window
	#if.coasts: option to add outlines of coasts
	
	IM.JM = dim(KGnum)
	res = res.from.IM.JM( IM.JM[1], IM.JM[2])
        
        if (if.new) {	
	    quartz(width=9.6, height=6)
	   #quartz(width=10.6, height=6)
        }
	par(omi=c(0,0,0,1)) #(bottom, left, top, right)
	par(omi=c(0,0,0,0), oma=c(0,0,0,4)) #(bottom, left, top, right) #Use for single

	plot.grid.categorical(KGnum, res=res,colors=KGrgbhex[na.min(KGnum):na.max(KGnum)])
	par(xpd=NA)
	if (if.coasts) {
		plot(coastsCoarse, add=TRUE, col=gray(0.3), lwd=0.5)
	}
	#legend.gradient(cbind(x = c(200,210,210,200), y = c(80,80,-80,-80)), 
        #         cols = KGrgbhex, title = "", limits = c(1,40))
	par(xpd=TRUE)
	legend(-180, 112, legend=KGcat[1:20,"KGcode"],col=KGrgbhex[1:20], pt.cex=2, pch=15, cex=0.6, horiz=TRUE, bty="n")
	legend(-180, 101, legend=KGcat[21:40,"KGcode"],col=KGrgbhex[21:40], pt.cex=2, pch=15, cex=0.6, horiz=TRUE, bty="n")

}

write.KoeppenGeiger.netcdf =function(KGnum, fname="KGclasses.nc", varname="KG", undef=-1e30, description="") {
	IM.JM = dim(KGnum)
	res = res.from.IM.JM(IM.JM[1], IM.JM[2])
	
	create.map.template.nc(res, varname=varname, longname="Koeppen-Geiger class", 
		units="1-40", vardescr="Koeppen-Geiger class", description=description,
		undef=undef,
		fileout=fname, 
		contact="Nancy.Y.Kiang@nasa.gov", vartype='NC_FLOAT')
	
	KGnum.undef = KGnum
	KGnum.undef[KGnum==40] = undef
	ncid = open.nc(con=fname, write=TRUE)
	var.put.nc(ncid, varname, KGnum.undef)
	close.nc(ncid)
}

Entlc_to_KG = function(fileentlc, filekglut) {
	#Return Koeppen-Geiger class map.
	#Estimate the KG class that matches a mix of Ent PFTs cover fractions for a single grid cell.
	#e.g. given Ent lc map layers that could be from somebody's reconstruction or alternative model.
	#fileentlc = NetCDF file of Ent land cover fractions EntGVSD_PFTs (18 cover types, including bright and dark soil), in format of ModelE VEG input file.
	#fileKGlut = NetCDF file of Koeppen-Geiger lookup table of format in R (kgn, lcn)=(40, 18) from "lc" array generated by Ent_utils/kglut_modelE programs.  
	#		 E.g. EntGVSDv1.0_V2X2H_KoeppenGeigerLUT_17e3459.nc
	
#Get the KG LUT
nc = open.nc(con=filekglut, write=FALSE)
kglut = var.get.nc(nc, "lc")  #dim=(40, 18)
close.nc(nc)

#Get the Ent lc array
nc = open.nc(con=fileentlc, write=FALSE)
IM = dim.inq.nc(nc, "lon")$length; JM = dim.inq.nc(nc, "lat")$length
ncov = length(EntGVSD_PFTs)
entlc = array(0, c(IM, JM, ncov))
for (p in 1:ncov) {
	entlc[,,p] = var.get.nc(nc, trim(EntGVSD_PFTs[p]))
}
close.nc(nc)

kgn = nrow(kglut)
kgmap = matrix(NA, IM, JM)
for (j in 1:JM) {
	for (i in 1:IM) {
		if (sum(entlc[i,j,])>0) {
			kgsumsq = array(0, kgn)
			for (k in 1:kgn) {
				index = entlc[i,j,]>0
				kgsumsq[k] = sum( (entlc[i,j,index] - kglut[k,index])^2 )
			}
			kgnum = match(min(kgsumsq), kgsumsq)
			kgmap[i,j] = kgnum
		}
	}
}

#plot.KG(kgmap)
	
return(kgmap)
}

