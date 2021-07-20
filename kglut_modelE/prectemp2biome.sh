# !/bin/bash

# *** Takes 1 single input, a tab-separated file in the format "PREC.nc TEMP.nc OUTPUT.nc" with each input separated by a line

if [ $# -ne 1 ]; then
	echo "Incorrect number of arguments"
	exit 1
fi

if ! [ -f $1 ]; then
	echo "File does not exist"
	exit 2
fi

# Check if the R module is loaded

Rinstance=$(module list | grep -c "R/")
if [ $Rinstance -eq 0 ]; then
	# module load R/3.6.3
	# eval $("/usr/share/lmod/lmod/libexec/lmod" bash "load" "R/3.6.3") && eval $(: -s sh)
	# I can't actually get it to load, so just exit if it's not loaded
	echo "R is not loaded, run the command "module load R/3.6.3" (or the latest version) and try again"
	exit 3
fi

# Loop over the input file

while IFS=$'\t' read -r -a args; do
	prec=${args[0]}
	temp=${args[1]}
	out=${args[2]}

	echo "Precipitation file: $prec"
	echo "Temperature file: $temp"

	# Check if input files exist
	if ! [ -f $prec ]; then
		echo "Precipitation file does not exist"
	fi
	if ! [ -f $temp ]; then
		echo "Temperature file does not exist"
	fi
	# Make a copy of the template file and replace all variables

	# Replace file variables
	cp "../Rfiles/KG_run_template.R" "KG_run.R"
	sed -i "s|TEMPERATURE_DATA|$(echo $temp | sed 's/\./\\\./g')|g" "KG_run.R"	
	sed -i "s|PRECIPITATION_DATA|$(echo $prec | sed 's/\./\\\./g')|g" "KG_run.R"
	sed -i "s|OUTPUT_FILE_NAME|$(echo $out | sed 's/\./\\\./g')|g" "KG_run.R"

#	ex "KG_run.R" <<EOF
#		1,\$s/TEMPERATURE_DATA/$temp/g
#		1,\$s/PRECIPITATION_DATA/$prec/g
#		1,\$s/OUTPUT_FILE_NAME/$out/g
#		wq
#EOF

	# Replace I J variables
	echo "$(ncdump -h $prec)" > "nc.tmp"
	lonprec=$(sed -n "s|[[:blank:]]lon = \([[:digit:]]\+\) ;$|\1|p" "nc.tmp")
	latprec=$(sed -n "s|[[:blank:]]lat = \([[:digit:]]\+\) ;$|\1|p" "nc.tmp")

	echo "$(ncdump -h $temp)" > "nc.tmp"
	lontemp=$(sed -n "s|[[:blank:]]lon = \([[:digit:]]\+\) ;$|\1|p" "nc.tmp")
	lattemp=$(sed -n "s|[[:blank:]]lat = \([[:digit:]]\+\) ;$|\1|p" "nc.tmp")
	
	rm "nc.tmp"
	# Make sure they are the same in both files
	if [ $lonprec -ne $lontemp ] || [ $latprec -ne $lattemp ]; then
		echo "Dimensions of the input files are not the same"
		exit 4
	fi
	sed -i -e "s|I_ARRAY_LEN|$lonprec|g" -e "s|J_ARRAY_LEN|$latprec|g" "KG_run.R"
	echo "Dimensions: $lonprec $latprec"

	Rscript "KG_run.R"
	rm "KG_run.R"
done < $1

exit 0
