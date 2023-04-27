#land_utils.R
#Author: nancy.y.kiang@nasa.gov
#Utilities for analyzing ModelE GHY diagnostics.

library(ncdf4)


#Constants
s_sat = c(0.394, 0.537, 0.577, 0.885) #saturated soil volume fraction = porosity, GHY.f parameter sat(imt-1) for sand/silt/clay/peat
s_hygro = c(0.03090648479747210, 0.0678256437284463, 0.1850070544076210, 0.1170386207495620) #hygroscopic soil volume fraction, at matric potential = -1000 m
s_hygro_relsat = c(0.0784428548159, 0.126304736924481, 0.815689919401980, 0.117038620749562) #hygroscopic soil relative saturated fraction, at matric potential = -1000 m; multiply by s_sat porosity to get s_hygro (vol/vol)
 
#SOIL texture and layers
    ngm = 6 #soil layers
    imt = 5 #soil particle classes (sand/silt/clay/peat/bedrock)
    rho.h2o = 1000. #kg/m3

#Functions

get.nc4 = function(ncid, nc4, varname) {
    #print(ncid)
    #print(varname)
    mapz = var.get.nc(ncid, varname)
    #print(mapz)
    units = att.get.nc(ncid, varname, "units")
    #print(units)
    if (ncatt_get(nc4, varname, "missing_value")$hasatt) { #ncatt_get is library(ncdf4)
       undef = att.get.nc(ncid, varname, "missing_value")
       mapz[mapz==undef] = NA
    } else {
       undef = NA
    }
    #print(undef)
    return( list(mapz, units, undef) )
}


