#map_Ent_domlc.R

#--------------------
Rpath = paste0(Sys.getenv("R_Ent"), "/")

args = commandArgs(trailingOnly=TRUE)
print(args)
numargs = length(args)
if (numargs < 3) {
cat('Usage:  Rscript $R_Ent/map_Ent_domlc.R <path> <filename> <file type> <numPFT> ', '\n' )
cat('Generate a map of dominant land cover from either a VEG file or an aij or gij file that has Ent ra diagnostics.', '\n')
cat('path = path where file is', '\n')
cat('filename = file to be plotted', '\n')
cat('file type = VEG | aij | gij', '\n')
cat('numPFT (optional) = default 16 PFTs + bare/bright soil; other option for 20 cover types',  '\n')
cat('       Currently supported:  MMSF \n')
quit()
}

path = args[1]
file = args[2]
filetype = args[3]
if (filetype == "aij" | filetype=="gij") {
  cat('Option to map from aij or gij forthcoming. \n')
  q()
}
if (length(args)==4) {
	cat('Default 16 PFTs.  Others option forthcoming \n')
	return()
	numPFT = args[4]
} else {
	numPFT = 16  #default
}

source(paste0(Rpath, "utils_noSDMTools.R"))

#-------------------

if (filetype=="VEG") {
  domlc = Ent_calc_domlc_GISS(paste0(path,"/",file))
  Entcolors = Entcolors16
} else if (filetype == "aij" | filetype=="gij") {
  cat('Option to map from aij or gij forthcoming. \n')
  return()
  #domlc = Ent_calc_domlc_GISS_Entra(paste0(path,"/", file))
  #Entcolors = Entcolors16  #one layer for all bare soil
}

  res = res.from.IM.JM(dim(domlc)[1],dim(domlc)[2])
 
  fileoutnc = paste0(file,"_domlc.nc")
  create.map.template.nc(res=res.from.IM.JM(dim(domlc)[1],dim(domlc)[2]), varname="domlc", longname="dominant Ent land cover", units="category", vardescr="dominant Ent land cover catergory", description=paste("source file:", file), undef=-1e30,  fileout=fileoutnc, contact="Nancy.Y.Kiang@nasa.gov", vartype='NC_FLOAT')
nc = open.nc(con=fileoutnc, write=TRUE)
var.put.nc(nc, "domlc", domlc)
  close.nc(nc)
 
  pdf(paste0(file,"_domlc.pdf"), width=10, height=6)
  Ent_domlc_plot(lctype=domlc, numpft=numPFT, res=res, legend.cex=0.6, Entcolors=Entcolors, if.new=FALSE)
  mtext(outer=TRUE, file, line=-1.5)
  mtext("Dominant land cover type")
  dev.off()

 
