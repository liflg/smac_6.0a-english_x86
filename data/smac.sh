#!/bin/sh
###############################################################################
#
## LIFLG Startup Script
#
# Copyright (C) 2004-2010  Team LIFLG http://www.liflg.org/
#
#
#
# This script is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
###############################################################################
#
# The game binary
GAME_BINARY="smac.dynamic"

# Subdirectory
SUBDIR="."

# Library directory
LIBDIR=""

# Additional commandline options for mods etc.
CMD_ARGS=""

# Directory for Loki-Compat libs
LOKICOMPATDIR="Loki_Compat"

# settings for xephyr
ENABLE_XEPHYR="false"
XEPHYR_FULLSCREEN="true" # if enabled, ENABLE_RANDR should be set to "true" and vice versa
XEPHYR_FULLSCREEN_RESOLUTION="1024x768"
XEPHYR_STARTUP_TIME=3 #give Xephyr enougth time to start, maybe we have to ajust this value

#allows us to change the resolution bevore starting the game. Usefull in combination with Xephyr
ENABLE_RANDR="false"
RANDR_RESOLUTION="1024x768"

# Prevent failures with hardware acceleration
# only for use with Loki-Compat libs
#DISABLE_SDL_VIDEO_YUV_HWACCEL="true"

# set if and how long the CPU should be stressed. This helps to prevent games from running too fast on dynamic frequence scaling cpu's.
ENABLE_CPU_BURN="false"
CPU_BURN_IN_SECONDS=5
NUMBER_OF_CPUS=`sed -n 's$processor.*:.*\([0-9]\)$\1$p' /proc/cpuinfo|wc -l`

# http://www.libsdl.org/faq.php?action=listentries&category=3#32
#ENABLE_SDL_DSP_NOSELECT="true"

# Set the sdl audio driver (default: oss)
# More at http://icculus.org/lgfaq/#setthatdriver
#SDL_AUDIODRIVER="alsa"

# Use US keyboard layout
#USLAYOUT="true"

# Set gamma for the game
#GAMMA="1.000"

###############################################################################
## DO NOT EDIT BELOW THIS LINE
###############################################################################
export LANG="POSIX"

test -n "${SDL_AUDIODRIVER}" && export SDL_AUDIODRIVER


# readlink replacement for older bash versions
readlink() {
	path=$1
 
	if [ -L "$path" ]
	then
		ls -l "$path" | sed 's/^.*-> //'
	else
		return 1
	fi
}

cpuburn() {
	TIMENOW=`date +%s`
	TIMETOEND=`expr $TIMENOW + $1`
	while [ `date +%s` -le $TIMETOEND ]
	do
		b=`expr 1 + 1`
	done
}

setuslayout() {
	setxkbmap -model pc101 us -print | xkbcomp - ${DISPLAY} 2>/dev/null
}
trap setxkbmap EXIT

resetgamma() {
	if [ -n "${XGAMMA}" ]
	then
		exec ${XGAMMA}
	fi
}
trap resetgamma EXIT

setresolution() {

	type xrandr >/dev/null 2>&1
	if [ "$?" -a "$ENABLE_RANDR" = "true" ]; then
		xrandr -s $RANDR_RESOLUTION
	else
		ENABLE_RANDR="false"
	fi
}

resetresolution() {
	type xrandr >/dev/null 2>&1
	if [ "$?" -a "$ENABLE_RANDR" = "true" ]; then
		xrandr -s 0 # should be in almost any case be correct, but still not that nicely
	fi
}

setupxephyr() {
	if [ "$ENABLE_XEPHYR" = "true" ]; then
		echo "Trying to start Xephyr-Server"
		if type Xephyr >/dev/null 2>&1;then
			echo "Xephyr binary found, using it"
			if [ -n "$DISPLAY" ]; then
				TMPDISPLAY="`echo $DISPLAY|sed -n 's$.*:\([0-9]*\)\(\.*\)\([0-9]*\)$\1$p'`" # forget the hostname part, hope that's not a problem
				TMPDISPLAY=":`expr $TMPSCREEN + 1`"
			else
				TMPDISPLAY=":1" # fallback. Maybe we should rather just quit
			fi

			echo "Starting new Xephyr server on $TMPDISPLAY"

			if [ "$XEPHYR_FULLSCREEN" = "true" ];then
				Xephyr $TMPDISPLAY -ac -br -fullscreen -reset -extension Composite &
			else
				Xephyr $TMPDISPLAY -ac -br -screen $XEPHYR_FULLSCREEN_RESOLUTION -reset -extension Composite &
			fi
			XEPHYR_PID=$!
			
			export OLD_DISPLAY=$DISPLAY
			export DISPLAY=$TMPDISPLAY
			
			sleep $XEPHYR_STARTUP_TIME
		else
			echo "Xephyr binary not found, falling back to standard server"
			ENABLE_XEPHYR="false"
		fi
	fi
}

stopxephyr(){
	if [ "$ENABLE_XEPHYR" = "true" ]; then
		kill $XEPHYR_PID
		DISPLAY=$OLD_DISPLAY
		echo ""
	fi
}

SCRIPT="$0"
SCRIPTDIR=$(dirname "${0}")
COUNT=0
while [ -L "${SCRIPT}" ]
do
	SCRIPT=$(readlink ${SCRIPT})
	COUNT=$(expr ${COUNT} + 1)
	if [ ${COUNT} -gt 100 ]
	then
		echo "Too many symbolic links"
		exit 1
	fi
done
GAMEDIR=$(dirname "${SCRIPT}")

setresolution
setupxephyr

#games are better played with us keyboard layout
if [ "${USLAYOUT}" = "true" ]; then
	setuslayout
fi

# save gamma value and set wanted
if [ -n "${GAMMA}" ]; then
	XGAMMA=$(xgamma 2>&1 | sed -e "s/.*Red \(.*\), Green \(.*\), Blue \(.*\)/xgamma -rgamma\1 -ggamma\2 -bgamma\3/")
	xgamma -gamma ${GAMMA}
fi

if [ "x${SCRIPTDIR}" != "x${GAMEDIR}" ]
then
	cd "${SCRIPTDIR}"
fi

cd "${GAMEDIR}"
cd "${SUBDIR}"

# export game library directory
test -n "${LIBDIR}" && export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LIBDIR}"

# start the game

if [ "${ENABLE_SDL_DSP_NOSELECT}" = "true" ]
then
	export SDL_DSP_NOSELECT=1
fi

	
if [ "${DISABLE_SDL_VIDEO_YUV_HWACCEL}" = "true" ]
then
	export SDL_VIDEO_YUV_HWACCEL=0
fi

if [ "$ENABLE_CPU_BURN" = "true" ]
then
	echo stressing $NUMBER_OF_CPUS CPU\(s\) for $CPU_BURN_IN_SECONDS seconds
	COUNT=0
	while [ $COUNT -lt $NUMBER_OF_CPUS ]
	do
		cpuburn $CPU_BURN_IN_SECONDS &
		COUNT=`expr $COUNT + 1`
	done
fi

#detect if loki-compat libs are installed
if [ -d "$LOKICOMPATDIR" ]
then
	echo "Running WITH lokicompat libs!"
	LD_LIBRARY_PATH="$LOKICOMPATDIR" "$LOKICOMPATDIR"/ld-linux.so.2 ./${GAME_BINARY} ${CMD_ARGS} "$@"
else
	./${GAME_BINARY} ${CMD_ARGS} "$@"
fi

EXITCODE="$?"

if [ "${USLAYOUT}" = "true" ]; then
	# reset kb layout
	setxkbmap >/dev/null 2>&1

	# reset xmodmap
	test -r ${HOME}/.Xmodmap && xmodmap ${HOME}/.Xmodmap >/dev/null 2>&1
fi

stopxephyr
resetresolution

# reset gamma - which is done by the trap call - see line 98

exit ${EXITCODE}
