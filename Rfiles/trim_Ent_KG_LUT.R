ourctrim_Ent_KG_LUT.R
#Trimming of small cover fractions in regression of Ent types in Koeppen-Geiger biomes
#To run:
# 1. Edit local R paths.
# 2. Edit file names and option below.
# 3. R CMD BATCH trim_Ent_KG_LUT.R

#----------- Edit R locations --------------
#R path for R utility scripts
Rpath = "../Rfiles/"

#R packages needed. Installed locally. Comment out if already installed previously.
#R CMD INSTALL -l "/discover/nobackup/projects/giss_ana/users/nkiang/aDATA/Rfiles/Rlibraries/"  mypackage.tgz
#install.packages("glue", lib=Rlib.loc, repos="https://mirrors.nics.utk.edu/cran/")
#install.packages("base", lib=Rlib.loc, repos="https://mirrors.nics.utk.edu/cran/")
Rlib.loc = "/discover/nobackup/projects/giss_ana/users/nkiang/aDATA/Rfiles/Rlibraries/"
library("glue", lib.loc=Rlib.loc) #Needed for trim
library("base", lib.loc=Rlib.loc) #Needed for Sys.Date

#----------- Edit file names ---------------
#Input file: should be the output from KG_run.R, generated from KG_run_template.R.
#filein = "/mypathin/entKG_regressionlc_YYYY-MM-DD.csv"
filein = "@@LC_CSV_FILE_RAW"
outdir = "@@OUTDIR"
#Output file
#fileout="/mypathout/entKG_regressionlc_trim_natveg_YYYY-MM-DD.csv"
fileout=paste(outdir,"@@LC_CSV_FILE", sep="")

#----------- Optional: edit trimfrac ------
#trimfrac is threshold to trim out cover fractions produced by the regression that are less than trimfrac.
#The default trimfrac is 0.08.
#If a different trimfrac threshold is desired, edit the value here:
trimfrac = @@LCTRIMFRAC

#============================================================================================================

#R script utilities created for Ent processing.
source(paste(Rpath, "utils_noSDMTools.R", sep=""))

#Routine to do the trimming
trim_Ent_KG_LUT = function(filein, fileout, trimfrac = trimfrac) {
	#Trim small cover fractions from regression of Ent types in KG biomes
	#Output csv file of trimmed cover fractions
	
entkg = read.table(filein, sep=",", header=TRUE, row.names=1) 


ent.kg.mean = entkg[(1:(nrow(entkg)/2)*2)-1,]
ent.kg.std = entkg[(1:(nrow(entkg)/2)*2),]

# No crops: assign crop cover to 0.
ent.kg.mean.nocrops = ent.kg.mean
ent.kg.mean.nocrops[trim(EntGVSD_PFTs)=="crops_herb",] = 0
tot.mean.nocrops = apply(ent.kg.mean.nocrops, 2, sum)

# No crops scale:  scale up cover fractions to sum to 1, without crops.
ent.kg.mean.nocrops.sc = ent.kg.mean.nocrops
notzero = tot.mean.nocrops>0
ent.kg.mean.nocrops.sc[,notzero] = t(t(ent.kg.mean.nocrops[,notzero])/tot.mean.nocrops[notzero])
tot.mean.nocrops.sc = apply(ent.kg.mean.nocrops.sc, 2, sum)

# No crops scale trim:  Trim out any cover fractions < trimfrac
ent.kg.mean.nocrops.sc.trim = ent.kg.mean.nocrops.sc
ent.kg.mean.nocrops.sc.trim[ent.kg.mean.nocrops.sc<trimfrac] = 0.0
tot.mean.nocrops.sc.trim = apply(ent.kg.mean.nocrops.sc.trim, 2, sum)

# No crops scale trim scale:  Scale up so that cover fractions sum to 1.
ent.kg.mean.nocrops.sc.trim.sc = ent.kg.mean.nocrops.sc.trim
notzero = tot.mean.nocrops.sc.trim > 0
ent.kg.mean.nocrops.sc.trim.sc[,notzero] = t(t(ent.kg.mean.nocrops.sc.trim[,notzero])/tot.mean.nocrops.sc.trim[notzero])
tot.mean.nocrops.sc.trim.sc = apply(ent.kg.mean.nocrops.sc.trim.sc, 2, sum)
tot.mean.nocrops.sc.trim.sc

# No crops scale trim scale sig:  Round to 2 decimal places.
ent.kg.mean.nocrops.sc.trim.sc.sig = round(ent.kg.mean.nocrops.sc.trim.sc, 2)
tot.mean.nocrops.sc.trim.sc.sig = apply(ent.kg.mean.nocrops.sc.trim.sc.sig, 2, sum)
options(digits=4)
tot.mean.nocrops.sc.trim.sc.sig

# No crops scale trim scale sig roundoff:  Check for round-off error.
notzero = tot.mean.nocrops.sc.trim.sc.sig>0
diff1 = tot.mean.nocrops.sc.trim.sc.sig
diff1[notzero] = tot.mean.nocrops.sc.trim.sc.sig[notzero] - 1
diff1  #Look to see where round-off error is.

# Fix roundoff error. Subtract diff2 from max PFT.
ent.kg.mean.nocrops.sc.trim.sc.sig.fix = ent.kg.mean.nocrops.sc.trim.sc.sig
for (i in 1:length(diff1)) {
	if (diff1[i]!=0) {
		index = ent.kg.mean.nocrops.sc.trim.sc.sig.fix[,i]== max(ent.kg.mean.nocrops.sc.trim.sc.sig.fix[,i])
		ent.kg.mean.nocrops.sc.trim.sc.sig.fix[index,i] = ent.kg.mean.nocrops.sc.trim.sc.sig.fix[index,i] - diff1[i]
	}
}
tot.mean.nocrops.sc.trim.sc.sig.fix = apply(ent.kg.mean.nocrops.sc.trim.sc.sig.fix, 2, sum)

print(paste("Writing", fileout))
write.table(file=fileout, ent.kg.mean.nocrops.sc.trim.sc.sig.fix, row.names=row.names(ent.kg.mean.nocrops.sc.trim.sc.sig.fix), sep=",")
}

#Call the subroutine to do the trimming.
trim_Ent_KG_LUT(filein = filein, fileout=fileout, trimfrac = trimfrac)



