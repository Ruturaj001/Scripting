#!/bin/bash
# Ruturaj Hagawane
# Calculate strength of team for perticular year using previous years standings


# find teams full name using assocative array
# find team name in standing, and using it find wins, losses and ties
# update total wins, loosses and ties
searchAndUpdate () {
	word=$1	
	
	#look up in assocative array
	fullname=${list[$word]}

	#find that team in standing and its win loss and ties
	linenumb=`grep -n "$fullname" standings.$prevyear.download |cut -f1 -d:`
	part=`sed -n "$((linenumb+7))p" standings.$prevyear.download`
	win=${part//[!0-9]}
	part=`sed -n "$((linenumb+15))p" standings.$prevyear.download`
	loss=${part//[!0-9]}
	part=`sed -n "$((linenumb+23))p" standings.$prevyear.download`
	tie=${part//[!0-9]}

	#add current teams win loss and ties to total win loss and ties			
	total_win=$((total_win+win))
	total_loss=$((total_loss+loss))
	total_tie=$((total_tie+tie))
}


#check to ensure 1 arguments is given
if [ $# -ne 1 ]
	then
	echo "Usage: $0 <year>" 1>&2
	exit 1
fi


#check if given year is not future year
if [ $1 -ge 2015 ]
	then
	echo "Usage: $0 <past-year>" 1>&2
	exit 2
fi


#assigning argument 1 to variable year ( to avoid confusion)
year=$1


#calculating previous year
prevyear=$((year-1))


#signal traps, prints type of signal and exists
trap "echo SIGHUP; exit" SIGHUP
trap "echo SIGINT; exit" SIGINT
trap "echo SIGTERM; exit" SIGTERM


#download previous years standing file if not present
if [ ! -f standings.$prevyear.download ]; then
	wget -O standings.$prevyear.download -q  "http://www.nfl.com/standings?category=div&season=$prevyear-REG"
fi


#declaration of assocative array
declare -A list


#making a key value pair with teams shortform as key and full name as fair
#for fast lookup
while read line
do
	#The % character means Remove the smallest suffix of the expansion matching the pattern.
	key=${line%:*}

	#The # character says Remove the smallest prefix of the expansion matching the pattern.
	value=${line#*:}

	list[$key]=$value
done <LUT

list["JAX"]="Jacksonville Jaguars"
list["WSH"]="Washington Redskins"


#read each line from scedule
while read line
do
	#if line is blank just continue
	if [ -z "$line" ]
	then
		continue
	fi

	#removing all '@' signs from line 
	line=${line//@}	

	#local variables
	i=0
	total_win=0
	total_loss=0
	total_tie=0

	#for each team in line
	for word in $line
	do
		#if it first word then it is team whos strength we are calculating
		if [ $i == 0 ]
		then
			team=${list[$word]}	
		#BYE is not any time so we just ignore it
		elif [ $word == "BYE" ]
		then
			:
		#call search function
		else
			searchAndUpdate $word
		fi	
		i=$((i+1))
	done
	#calculate for team
	strength=`echo "scale=3; ($total_win+$total_tie/2)/($total_win+$total_loss+$total_tie)" | bc`

	#create line containing information in proper format 	
	newline=`printf "%-24s\t%s\t\t%d-%d-%d" "$team" "$strength" "$total_win" "$total_loss" "$total_tie"`
	
	#append line to previous lines
	final_list=("${final_list[@]}" "$newline")
done <schedule.$year.download


#print sorted output in proper format
printf "%s\n" "${final_list[@]}" | sort -k1 | sort -t$'\t' -s -r -k2,2

