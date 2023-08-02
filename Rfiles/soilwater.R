#soilwater.R
#Author: Nancy.Y.Kiang@nasa.gov
#Given input ModelE aij netcdf file, output netcdf of soil relative saturation and REW by soil layer, and other soil water quantities.

#Input files
args = commandArgs(trailingOnly=TRUE)
cat(paste('soilwater.R args: ', args, "\n"))

numargs = length(args)
if (numargs < 2) {
cat("Usage:  Rscript $R_Ent/soilwater.R <SOIL file> <aij file>\n" )
cat("Generate netcdf file of soil water metrics.\n")
cat("SOIL = ModelE SOIL input file used for run.\n")
cat("aij = ModelE aij or gij diagnostics netcdf file.\n")
cat("\nSample command:\n")
cat("Rscript $R_Ent/soilwater.R /discover/nobackup/projects/giss/prod_input_files/planet/SOIL/soil_siltloam_4x5.nc /discover/nobackup/projects/giss_ana/users/rruedy/planet_runs/LP065nSM40/quasi_clim/ANN1002-1101.aijLP065nSM40.nc \n")
quit()
} 

SOIL = args[1]
AIJ = args[2]

print(SOIL)
print(AIJ)

#----------------------------------------
Rpath = paste0(Sys.getenv("R_Ent"), "/")
cat("Rpath: ", Rpath, "\n")

#source("/discover/nobackup/nkiang/Ent_utils/Rfunctions/utils_noSDMTools.R")
source(paste0(Rpath,"utils_noSDMTools.R"))
#source("lp_fn.R")
source(paste0(Rpath, "land_utils.R")) #ngm, imt, s_sat, s_hygro, functions

library(RNetCDF)
library(ncdf4)


#----------------------------------------
#SOIL file
ncsoil = open.nc(con=SOIL, write=FALSE) #SOIL input file
dz = var.get.nc(ncsoil, "dz"); cat('dim dz:', dim(dz), '\n') #[IM,JM,ngm]
q = var.get.nc(ncsoil, "q") #soil texture array reads in as q(JM,IM,imt,ngm)
close.nc(ncsoil)

soildepth.m = sum(dz[1,1,])
cat("soil layer thickness (m):", dz[1,1,], ";  soil depth (m): ", soildepth.m, "\n")
dimdz = dim(dz)  #(IM,JM,ngm)
IM = dimdz[1]; JM = dimdz[2]; ngm=dimdz[3] #soil layers
imt = dim(q)[3] #soil texture sa/si/cl/peat/bedrock

#aij file
ncid = open.nc(con=AIJ, write=FALSE)
nc4 = nc_open(AIJ)

gwtr.kg.m2 = get.nc4(ncid, nc4, "gwtr")[[1]]
gice.kg.m2 = get.nc4(ncid, nc4, "gice")[[1]]

bs_wlay = array(NA, dim=c(dim(dz[,,1]),ngm))
bs_iflay = array(NA, dim=c(dim(dz[,,1]),ngm))
vs_wlay = array(NA, dim=c(dim(dz[,,1]),ngm))
vs_iflay = array(NA, dim=c(dim(dz[,,1]),ngm))

for (k in 1:ngm) { 
        #get.nc4 formerly called lp.get.aij
	bs_wlay[,,k] = get.nc4(ncid, nc4, paste0("bs_wlay",k))[[1]] #kgH2O m-2
	bs_iflay[,,k] = get.nc4(ncid, nc4, paste0("bs_iflay",k))[[1]] #fraction that is frozen
	vs_wlay[,,k] = get.nc4(ncid, nc4, paste0("vs_wlay",k))[[1]] #kgH2O m-2
	vs_iflay[,,k] = get.nc4(ncid, nc4, paste0("vs_iflay",k))[[1]] #fraction that is frozen
}
bs_wlay[is.na(bs_wlay)] = 0.0
vs_wlay[is.na(vs_wlay)] = 0.0
bs_iflay[is.na(bs_iflay)] = 0.0
vs_iflay[is.na(vs_iflay)] = 0.0
undef=-1.e30
rerr=-1.e-6 #round-off error allowed
bifindex=(1.-bs_iflay)<0.0 & (1.-bs_iflay)> rerr #For fixing round-off errors. Use small number instead zero to check for actual errors. 
vifindex=(1.-vs_iflay)<0.0 & (1.-vs_iflay)> rerr #For fixing round-off errors

axyp = var.get.nc(ncid, "axyp")
soilfr = var.get.nc(ncid, "soilfr")/100
bsfr = var.get.nc(ncid, "bsfr")/100
vsfr = var.get.nc(ncid, "vsfr")/100
lakefr = var.get.nc(ncid, "lakefr")/100

#Make 3D arrays for cover fractions
soilfrz = array(soilfr, dim=dimdz)
bsfrz = array(bsfr, dim=dimdz)
vsfrz = array(vsfr, dim=dimdz)


#-- Calculations ---------------------------------------------------------------
#Porosity.texture = saturated volumetric fraction by layer (volume pore space / volume conductive soil)
    qnorm = q 
    qnorm[,,5,] = 0.0 #Zero out bedrock to just get soil texture (sand/silt/clay/peat)
    qtexturetot = apply(qnorm, c(1,2,4), sum) #Sum mineral + peat fractions, get array[JM,IM,ngm]
    for (k in 1:6) { #normalize
      for (p in 1:(imt-1)) {
      	qnorm[,,,k] = qnorm[,,p,k]/qtexturetot[,,k]
      }
    }
    poros.texture = array(NA, dim=dim(qtexturetot))
    for (k in 1:6) {
      for (i in 1:IM) {
        for (j in 1:JM) {
         poros.texture[i,j,k] = s_sat %*% qnorm[i,j,1:(imt-1),k]  #weighted average by particle class fractions
        }
      }
    }

#Porosity by soil volume, accounting for bedrock (volume pore space / volume all soil + bedrock)
    poros = array(NA, dim=dim(dz))
    for (k in 1:6) {
      for (i in 1:IM) {
        for (j in 1:JM) {
         poros[i,j,k] = c(s_sat,0.0) %*% q[i,j,1:imt,k]  #weighted average by particle class fractions and bedrock
        }
      }
    }
    #cat('poros: \n'); summary(poros)

#Hygroscopic.texture volumetric fraction by soil texture only by layer (volume hygroscopic water / volume conductive soil)
    hygro.texture = array(NA, dim=dim(qtexturetot))
    for (k in 1:6) {
      for (i in 1:IM) {
        for (j in 1:JM) {
         hygro.texture[i,j,k] = s_hygro %*% qnorm[i,j,1:(imt-1),k]
        }
      }
    }

#Hygroscopic volumetric fraction, accounting for bedrock (volume hygroscopic water / volume all soil + bedrock)
    hygro = array(NA, dim=dim(dz))
    for (k in 1:6) {
      for (i in 1:IM) {
        for (j in 1:JM) {
         hygro[i,j,k] = c(s_hygro,0.0) %*% q[i,j,1:imt,k]
        }
      }
    }

#Volumetric soil water (vol. soil water / vol. soil)
cat('\n svol \n')
     svol_bs_lay = bs_wlay/(dz * rho.h2o)
     svol_vs_lay = vs_wlay/(dz * rho.h2o)
     svol_lay = div0.array3( num=(svol_bs_lay*bsfrz + svol_vs_lay*vsfrz), div=soilfrz, undefin = undef, undefout=0)

#Volumetric soil LIQUID water (vol. soil water / vol. soil)
cat('\n svol_liq \n')
     svol_liq_bs_lay = (1.-bs_iflay)*bs_wlay/(dz * rho.h2o); svol_liq_bs_lay[bifindex]=0.0
     svol_liq_vs_lay = (1.-vs_iflay)*vs_wlay/(dz * rho.h2o); svol_liq_vs_lay[vifindex]=0.0
     svol_liq_lay = div0.array3( (svol_liq_bs_lay*bsfrz + svol_liq_vs_lay*vsfrz), soilfrz, undefin = -1e30, undefout=0)
     #cat(svol_liq_bs_lay[144,86,6], bs_iflay[144,86,6], bs_wlay[144,86,6], dz[144,86,6], '\n')

#Hygroscopic water in liquid fraction of soil by layer ( volume unfrozen hygroscopic water / volume soil)
cat('\n hygro \n')
    hygro_bs_lay = (1.0-bs_iflay)*hygro; hygro_bs_lay[bsfrz==0.0] = 0.0; hygro_bs_lay[bifindex]=0.0
    hygro_vs_lay = (1.0-vs_iflay)*hygro; hygro_vs_lay[vsfrz==0.0] = 0.0; hygro_vs_lay[vifindex]=0.0
    hygro_lay = div0.array3( (hygro_bs_lay*bsfrz + hygro_vs_lay*vsfrz), soilfrz, undefin = undef, undefout=0)

#Relative saturation (liquid water / porosity)
cat('\n relsat \n')
     relsat_bs_lay = div0.array3(svol_liq_bs_lay, poros, undefin=undef, undefout=0)
     relsat_vs_lay = div0.array3(svol_liq_vs_lay, poros, undefin=undef, undefout=0) 
     #summary(relsat_bs_lay); summary(bsfrz);  summary(relsat_vs_lay); summary(vsfrz); summary(soilfrz)
     #summary(relsat_bs_lay*bsfrz); summary(relsat_vs_lay*vsfrz)
     relsat_lay = div0.array3( (relsat_bs_lay*bsfrz + relsat_vs_lay*vsfrz ), soilfrz, undefin = undef, undefout=0)

     relsat = array(NA, dim=dim(soilfr))
     for (i in 1:IM) {
       for (j in 1:JM) {
         relsat[i,j] = (dz[1,1,]/soildepth.m) %*% relsat_lay[i,j,]
       }
     }
 

#Relative extractable water (REW) = (svol - s_hygro)/(s_sat - s_hygro)  ( fraction of porosity excluding hygroscopic fraction)
cat('\n rew \n')
    # As fraction of total soil volume available pore space
    rew_bs_lay = div0.array3((svol_liq_bs_lay - hygro_bs_lay), (poros - hygro), undefin=undef, undefout=0); rew_bs_lay[rew_bs_lay<0.0 & rew_bs_lay>rerr] = 0.0 #fix round-off error
    rew_vs_lay = div0.array3((svol_liq_vs_lay - hygro_vs_lay), (poros - hygro), undefin=undef, undefout=0); rew_vs_lay[rew_vs_lay<0.0 & rew_vs_lay>rerr] = 0.0 #fix round-off error
    # As fraction of non-frozen fraction
    ##rew_bs_lay = (svol_liq_bs_lay - hygro_bs_lay) /((1-bs_iflay)*(poros - hygro))
    ##rew_vs_lay = (svol_liq_vs_lay - hygro_vs_lay) /((1-vs_iflay)*(poros - hygro))
    rew_lay = div0.array3((rew_bs_lay*bsfrz + rew_vs_lay*vsfrz), soilfrz, undefin = undef, undefout=0)
    rew = array(NA, dim=dim(soilfr))
    for (i in 1:IM) { 
      for (j in 1:JM) {
        rew[i,j] = (dz[1,1,]/soildepth.m) %*% rew_lay[i,j,]
      }
    }

#Available liquid water in soil (kg m-2)
cat('\n gavail \n')
    gavail_bs_lay.kg.m2.soil = (1.0-bs_iflay)*bs_wlay - hygro_bs_lay*dz*rho.h2o; gavail_bs_lay.kg.m2.soil[gavail_bs_lay.kg.m2.soil<0.0 & gavail_bs_lay.kg.m2.soil>rerr]=0.0
    gavail_vs_lay.kg.m2.soil = (1.0-vs_iflay)*vs_wlay - hygro_vs_lay*dz*rho.h2o; gavail_vs_lay.kg.m2.soil[gavail_vs_lay.kg.m2.soil<0.0 & gavail_vs_lay.kg.m2.soil>rerr]=0.0
    gavail_lay.kg.m2.soil = div0.array3( (gavail_bs_lay.kg.m2.soil*bsfrz + gavail_vs_lay.kg.m2.soil*vsfrz), soilfrz, undefin = undef, undefout=0)

    ghygro.kg.m2.soil = apply( hygro_lay*dz*rho.h2o, c(1,2), sum)
    gavail.kg.m2.soil = (gwtr.kg.m2-gice.kg.m2-ghygro.kg.m2.soil); gavail.kg.m2.soil[gavail.kg.m2.soil<0.0]=0.0

#Create netcdf file
temp = strsplit(AIJ, "/")[[1]]
fileout=paste0(temp[length(temp)],"_soilwater.nc")
cat("Writing ",fileout, "\n")
res = res.from.IM.JM(dimdz[1], dimdz[2])

create.map.template.nc(res=res, varname="axyp", longname="gridcell area", units="m^2", vardescr="", 
   timedim=NULL, timeunits="", timedescr="", 
   description=paste("Sources: ", SOIL,", ", AIJ), undef=undef,  fileout=fileout, contact="Nancy.Y.Kiang at nasa.gov", vartype="NC_FLOAT") 

#Define all variables.
nco = open.nc(con=fileout, write=TRUE)

dim.def.nc(nco, "ngm", ngm)
dim.def.nc(nco, "imt", imt)

var.def.nc(nco, "dz", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "dz", "long_name", "NC_CHAR", "SOIL LAYER THICKNESS")
att.put.nc(nco, "dz", "units", "NC_CHAR", "m^2")
att.put.nc(nco, "dz", "missing_value", "NC_FLOAT", undef)

#cat("soilfr \n")
var.def.nc(nco, "soilfr", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "soilfr", "long_name", "NC_CHAR", "SOIL FRACTION")
att.put.nc(nco, "soilfr", "units", "NC_CHAR", "1")
att.put.nc(nco, "soilfr", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "bsfr", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "bsfr", "long_name", "NC_CHAR", "BARE SOIL FRACTION")
att.put.nc(nco, "bsfr", "units", "NC_CHAR", "1")

#cat(" \n")
var.def.nc(nco, "vsfr", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "vsfr", "long_name", "NC_CHAR", "VEGETATION FRACTION")
att.put.nc(nco, "vsfr", "units", "NC_CHAR", "1")

#cat(" \n")
var.def.nc(nco, "lakefr", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "lakefr", "long_name", "NC_CHAR", "LAKE FRACTION")
att.put.nc(nco, "lakefr", "units", "NC_CHAR", "1")

#cat(" \n")
var.def.nc(nco, "porosity.texture", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "porosity.texture", "long_name", "NC_CHAR", "POROSITY OF NON-BEDROCK SOIL TEXTURE")
att.put.nc(nco, "porosity.texture", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "porosity.texture", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "porosity", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "porosity", "long_name", "NC_CHAR", "POROSITY OF TOTAL SOIL VOLUME INCL. BEDROCK")
att.put.nc(nco, "porosity", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "porosity", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "hygro.texture", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "hygro.texture", "long_name", "NC_CHAR", "HYGROSCOPIC SOIL WATER BASED ON NON-BEDROCK SOIL TEXTURE (vol. H2O / vol. soil)")
att.put.nc(nco, "hygro.texture", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "hygro.texture", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "hygro", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "hygro", "long_name", "NC_CHAR", "HYGROSCOPIC SOIL WATER OF TOTAL SOIL VOLUME INCL. BEDROCK (vol. H2O / vol. bare soil)")
att.put.nc(nco, "hygro", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "hygro", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "hygro_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "hygro_bs_lay", "long_name", "NC_CHAR", "BARE SOIL HYGROSCOPIC WATER IN NON-FROZEN SOIL (vol. H2O / vol. bare soil)")
att.put.nc(nco, "hygro_bs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "hygro_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "hygro_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "hygro_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL HYGROSCOPIC WATER IN NON-FROZEN SOIL (vol. H2O / vol. veg soil)")
att.put.nc(nco, "hygro_vs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "hygro_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "vs_iflay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "vs_iflay", "long_name", "NC_CHAR", "VEGETATED SOIL WATER ICE FRACTION")
att.put.nc(nco, "vs_iflay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "vs_iflay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "bs_iflay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "bs_iflay", "long_name", "NC_CHAR", "BARE SOIL WATER ICE FRACTION")
att.put.nc(nco, "bs_iflay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "bs_iflay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_bs_lay", "long_name", "NC_CHAR", "BARE SOIL VOLUMETRIC SOIL WATER (vol. H2O / vol. bare soil)")
att.put.nc(nco, "svol_bs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_liq_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_liq_bs_lay", "long_name", "NC_CHAR", "BARE SOIL VOLUMETRIC LIQUID SOIL WATER (vol. H2O / vol. bare soil)")
att.put.nc(nco, "svol_liq_bs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_liq_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL VOLUMETRIC SOIL WATER (vol. H2O / vol. veg soil)")
att.put.nc(nco, "svol_vs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_liq_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_liq_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL VOLUMETRIC LIQUID SOIL WATER (vol. H2O / vol. veg soil)")
att.put.nc(nco, "svol_liq_vs_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_liq_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_lay", "long_name", "NC_CHAR", "VOLUMETRIC SOIL WATER (vol. H2O / vol. soil)")
att.put.nc(nco, "svol_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "svol_liq_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "svol_liq_lay", "long_name", "NC_CHAR", "VOLUMETRIC LIQUID SOIL WATER (vol. H2O / vol. soil)")
att.put.nc(nco, "svol_liq_lay", "units", "NC_CHAR", "vol/vol")
att.put.nc(nco, "svol_liq_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "relsat_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "relsat_bs_lay", "long_name", "NC_CHAR", "BARE SOIL RELATIVE SATURATION")
att.put.nc(nco, "relsat_bs_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "relsat_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "relsat_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "relsat_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL RELATIVE SATURATION")
att.put.nc(nco, "relsat_vs_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "relsat_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "relsat_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "relsat_lay", "long_name", "NC_CHAR", "SOIL RELATIVE SATURATION")
att.put.nc(nco, "relsat_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "relsat_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "relsat", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "relsat", "long_name", "NC_CHAR", "SOIL RELATIVE SATURATION DEPTH AVERAGE")
att.put.nc(nco, "relsat", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "relsat", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "rew_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "rew_bs_lay", "long_name", "NC_CHAR", "BARE SOIL RELATIVE EXTRACTABLE WATER")
att.put.nc(nco, "rew_bs_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "rew_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "rew_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "rew_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL RELATIVE EXTRACTABLE WATER")
att.put.nc(nco, "rew_vs_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "rew_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "rew_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "rew_lay", "long_name", "NC_CHAR", "SOIL RELATIVE EXTRACTABLE WATER")
att.put.nc(nco, "rew_lay", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "rew_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "rew", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "rew", "long_name", "NC_CHAR", "SOIL RELATIVE EXTRACTABLE WATER DEPTH AVERAGE")
att.put.nc(nco, "rew", "units", "NC_CHAR", "fraction")
att.put.nc(nco, "rew", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "gavail_bs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "gavail_bs_lay", "long_name", "NC_CHAR", "BARE SOIL AVAILABLE WATER")
att.put.nc(nco, "gavail_bs_lay", "units", "NC_CHAR", "kg/m^2 bare soil")
att.put.nc(nco, "gavail_bs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "gavail_vs_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "gavail_vs_lay", "long_name", "NC_CHAR", "VEGETATED SOIL AVAILABLE WATER")
att.put.nc(nco, "gavail_vs_lay", "units", "NC_CHAR", "kg/m^2 veg soil")
att.put.nc(nco, "gavail_vs_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "gavail_lay", "NC_FLOAT", dimensions=c("lon","lat","ngm"))
att.put.nc(nco, "gavail_lay", "long_name", "NC_CHAR", "SOIL AVAILABLE WATER")
att.put.nc(nco, "gavail_lay", "units", "NC_CHAR", "kg/m^2 soil")
att.put.nc(nco, "gavail_lay", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
#var.def.nc(nco, "ghygro_tot", "NC_FLOAT", dimensions=c("lon","lat"))
#att.put.nc(nco, "ghygro_tot", "long_name", "NC_CHAR", "TOTAL SOIL HYGROSCOPIC WATER")
#att.put.nc(nco, "ghygro_tot", "units", "NC_CHAR", "kg/m^2 soil")
#att.put.nc(nco, "ghygro_tot", "missing_value", "NC_FLOAT", undef)

#cat(" \n")
var.def.nc(nco, "gavail_tot", "NC_FLOAT", dimensions=c("lon","lat"))
att.put.nc(nco, "gavail_tot", "long_name", "NC_CHAR", "TOTAL SOIL AVAILABLE WATER")
att.put.nc(nco, "gavail_tot", "units", "NC_CHAR", "kg/m^2 soil")
att.put.nc(nco, "gavail_tot", "missing_value", "NC_FLOAT", undef)

#-- Put variables


var.put.nc(nco, "axyp", axyp)
var.put.nc(nco, "dz", dz)
var.put.nc(nco, "soilfr", soilfr)
var.put.nc(nco, "bsfr", bsfr)
var.put.nc(nco, "vsfr", vsfr)
var.put.nc(nco, "lakefr", lakefr)
var.put.nc(nco, "porosity.texture", poros.texture)
var.put.nc(nco, "porosity", poros)
var.put.nc(nco, "hygro.texture",hygro.texture)
var.put.nc(nco, "hygro",hygro)
var.put.nc(nco, "hygro_bs_lay", hygro_bs_lay)
var.put.nc(nco, "hygro_vs_lay", hygro_vs_lay)
var.put.nc(nco, "bs_iflay", bs_iflay)
var.put.nc(nco, "vs_iflay", vs_iflay)
var.put.nc(nco, "svol_bs_lay", svol_bs_lay)
var.put.nc(nco, "svol_vs_lay", svol_vs_lay)
var.put.nc(nco, "svol_liq_bs_lay", svol_liq_bs_lay)
var.put.nc(nco, "svol_liq_vs_lay", svol_liq_vs_lay)
var.put.nc(nco, "svol_lay", svol_lay)
var.put.nc(nco, "svol_liq_lay", svol_liq_lay)
var.put.nc(nco, "relsat_bs_lay",relsat_bs_lay )
var.put.nc(nco, "relsat_vs_lay", relsat_vs_lay)
var.put.nc(nco, "relsat_lay", relsat_lay)
var.put.nc(nco, "relsat", relsat)
var.put.nc(nco, "rew_bs_lay", rew_bs_lay)
var.put.nc(nco, "rew_vs_lay", rew_vs_lay)
var.put.nc(nco, "rew_lay", rew_lay)
var.put.nc(nco, "rew", rew)
var.put.nc(nco, "gavail_bs_lay", gavail_bs_lay.kg.m2.soil)
var.put.nc(nco, "gavail_vs_lay", gavail_vs_lay.kg.m2.soil)
var.put.nc(nco, "gavail_lay", gavail_lay.kg.m2.soil)
var.put.nc(nco, "gavail_tot", gavail.kg.m2.soil)

close.nc(nco)

cat("Done.\n")

