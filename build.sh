#!/bin/bash
# Original Live by cybojenix <anthonydking@gmail.com>
# New Live/Menu by Caio Oliveira aka Caio99BR <caiooliveirafarias0@gmail.com>
# Colors by Aidas Lukošius aka aidasaidas75 <aidaslukosius75@yahoo.com>
# Toolchains by Suhail aka skyinfo <sh.skyinfo@gmail.com>
# Rashed for the base of zip making
# And the internet for filling in else where

# You need to download https://github.com/TeamVee/android_prebuilt_toolchains
# Clone in the same folder as the kernel to choose a toolchain and not specify a location

# Main Process - Start
maindevice() {
clear
echo "-${bldgrn}Device choice${txtrst}-"
echo
_name=${name}
_variant=${variant}
_defconfig=${defconfig}
unset name variant defconfig
echo "0) ${bldyel}LG L1 II${txtrst} | Single/Dual | E410 E411 E415 E420"
echo "1) ${bldblu}LG L3 II${txtrst} | Single/Dual | E425 E430 E431 E435"
echo "2) ${bldred}LG L5${txtrst}    | NFC         | E610"
echo "3) ${bldred}LG L5${txtrst}    | NoNFC       | E612 E617"
echo "4) ${bldgrn}LG L7${txtrst}    | NFC         | P700"
echo "5) ${bldgrn}LG L7${txtrst}    | NoNFC       | P705"
echo "6) ${bldgrn}LG L7${txtrst}    | NFC - 8m    | P708"
echo
echo "*) Any other key to Exit"
echo
read -p "Choice: " -n 1 -s x
case "${x}" in
	0 ) defconfig="cyanogenmod_v1_defconfig"; name="L1II"; variant="SD";;
	1 ) defconfig="cyanogenmod_vee3_defconfig"; name="L3II"; variant="SD";;
	2 ) defconfig="cyanogenmod_m4_defconfig"; name="L5"; variant="NFC";;
	3 ) defconfig="cyanogenmod_m4_nonfc_defconfig"; name="L5"; variant="NoNFC";;
	4 ) defconfig="cyanogenmod_u0_defconfig"; name="L7"; variant="NFC";;
	5 ) defconfig="cyanogenmod_u0_nonfc_defconfig"; name="L7"; variant="NoNFC";;
	6 ) defconfig="cyanogenmod_u0_8m_defconfig"; name="L7"; variant="NFC-8m";;
	* ) ;;
esac
if [ "${defconfig}" == "" ]
then
	name=${_name}
	variant=${_variant}
	defconfig=${_defconfig}
	unset _name _variant _defconfig
else
	make ${defconfig} &> /dev/null | echo "${x} - ${name} ${variant}, setting..."
	unset buildprocesscheck zippackagecheck defconfigcheck
fi
}

maintoolchain() {
clear
echo "-Toolchain choice-"
echo
if [ -f ../android_prebuilt_toolchains/aptess.sh ]
then
	. ../android_prebuilt_toolchains/aptess.sh
else
	if [ -d ../android_prebuilt_toolchains ]
	then
		echo "You not have APTESS Script in Android Prebuilt Toolchain folder"
		echo "Check the folder"
		echo "We will use Manual Method now"
	else
		echo "-You don't have TeamVee Prebuilt Toolchains-"
	fi
	echo
	echo "Please specify a location"
	echo "and the prefix of the chosen toolchain at the end"
	echo "GCC 4.6 ex. ../arm-eabi-4.6/bin/arm-eabi-"
	echo
	echo "/home/jonas/Dev/android-toolchain-eabi/bin/arm-eabi-"
	echo "Stay blank if you want to exit"
	echo
	read -p "Place: " CROSS_COMPILE
	if ! [ "${CROSS_COMPILE}" == "" ]
	then
		ToolchainCompile="${CROSS_COMPILE}"
	fi
fi
if ! [ "${CROSS_COMPILE}" == "" ]
then
	unset buildprocesscheck zippackagecheck
fi
}
# Main Process - End

# Build Process - Start
buildprocess() {
if [ -f .config ]
then
	echo "${x} - Building ${customkernel}"

	if [ -f arch/${ARCH}/boot/zImage ]
	then
		rm -rf arch/${ARCH}/boot/zImage | echo "Removing old kernel image before build to prevent fail"
	fi

	NR_CPUS=$(($(grep -c ^processor /proc/cpuinfo) + 1))
	echo "${bldblu}Building ${customkernel} with ${NR_CPUS} jobs at once${txtrst}"

	START=$(date +"%s")
	if [ "${buildoutput}" == "OFF" ]
	then
		make -j${NR_CPUS} &>/dev/null | loop
	else
		make -j${NR_CPUS}
	fi
	END=$(date +"%s")
	BUILDTIME=$((${END} - ${START}))

	if [ -f arch/${ARCH}/boot/zImage ]
	then
		buildprocesscheck="${_d}"
	else
		buildprocesscheck="Something goes wrong"
	fi
else
	ops
fi
}

loop() {
LEND=$(date +"%s")
LBUILDTIME=$((${LEND} - ${START}))
echo -ne "\r\033[K"
echo -ne "${bldgrn}Build Time: $((${LBUILDTIME} / 60)) minutes and $((${LBUILDTIME} % 60)) seconds.${txtrst}"
if ! [ -f arch/${ARCH}/boot/zImage ]
then
	sleep 1
	loop
fi
}

updatedefconfig(){
if [ -f .config ]; then
	clear
	echo "-${bldgrn}Updating defconfig${txtrst}-"
	echo
	if [ $(cat arch/${ARCH}/configs/${defconfig} | grep "Automatically" | wc -l) -ge 1 ]
	then
		defconfigformat="Usual copy of .config format  | Complete"
	else
		defconfigformat="Default Linux Kernel format   | Small"
	fi
	echo "The actual defconfig is a:"
	echo "--${defconfigformat}--"
	echo
	echo "Update defconfig to:"
	echo "1) Default Linux Kernel format  | Small"
	echo "2) Usual copy of .config format | Complete"
	echo
	echo "*) Any other key to Exit"
	echo
	read -p "Choice: " -n 1 -s x
	case "${x}" in
		1 ) echo "Building..."; make savedefconfig &>/dev/null; mv defconfig arch/${ARCH}/configs/${defconfig};;
		2 ) cp .config arch/${ARCH}/configs/${defconfig};;
		* ) ;;
	esac
else
	ops
fi
}
# Build Process - End

# Zip Process - Start
zippackage() {
if ! [ "${defconfig}" == "" ]
then
	if [ -f arch/$ARCH/boot/zImage ]
	then
		echo "${x} - Ziping ${customkernel}"

		zipdirout="zip-creator-out"
		rm -rf ${zipdirout}
		mkdir ${zipdirout}

		cp -r zip-creator/base/* ${zipdirout}/
		cp arch/${ARCH}/boot/zImage ${zipdirout}/

		echo "${customkernel}" >> ${zipdirout}/device.prop
		echo "${name}" >> ${zipdirout}/device.prop
		echo "${variant}" >> ${zipdirout}/device.prop
		echo "${release}" >> ${zipdirout}/device.prop

		mkdir ${zipdirout}/modules
		find . -name *.ko | xargs cp -a --target-directory=${zipdirout}/modules/ &> /dev/null
		${CROSS_COMPILE}strip --strip-unneeded ${zipdirout}/modules/*.ko

		cd ${zipdirout}
		zip -r ${zipfile} * -x .gitignore &> /dev/null
		cd ..

		cp ${zipdirout}/${zipfile} zip-creator/
		rm -rf ${zipdirout}

		zippackagecheck="${_d}"
	else
		ops
	fi
else
	ops
fi
}
# Zip Process - End

# ADB - Start
adbcopy() {
if [ -f zip-creator/${zipfile} ]; then
	clear
	echo "-Coping ${customkernel}-"
	echo
	echo "You want to copy:"
	echo
	echo "i) For Internal Card (sdcard0)"
	echo "e) For External Card (sdcard1)"
	echo
	echo "*) Any other key for exit"
	echo
	read -p "Choice: " -n 1 -s x
	case "$x" in
		i ) echo "Coping to Internal Card..."; _ac="sdcard0" ;;
		e ) echo "Coping to External Card..."; _ac="sdcard1" ;;
		* ) ;;
	esac
	if ! [ ${_ac} == "" ]
	then
		adb shell rm -rf /storage/${_ac}/${zipfile} &> /dev/null
		adb push zip-creator/${zipfile} /storage/${_ac}/${zipfile} &> /dev/null
		unset _ac
	fi
else
	ops
fi
}
# ADB - End

# Menu - Start
buildsh() {
clear
echo "Simple Linux Kernel ${kernelversion}.${kernelpatchlevel}.${kernelsublevel} Build Script ($(date +%d"/"%m"/"%Y))"
echo "${customkernel} Release $(date +%d"/"%m"/"%Y) Build #${build}"
echo "-${bldred}Clean Menu${txtrst}-"
echo "1) Zip Packages      | ${bldred}${cleanzipcheck}${txtrst}"
echo "2) Kernel            | ${bldred}${cleankernelcheck}${txtrst}"
echo "-${bldgrn}Main Menu${txtrst}-"
echo "3) Device Choice     | ${bldgrn}${name} ${variant}${txtrst}"
echo "4) Toolchain Choice  | ${bldgrn}${ToolchainCompile}${txtrst}"
echo "-${bldyel}Build Menu${txtrst}-"
echo "5) Build Kernel      | ${bldyel}${buildprocesscheck}${txtrst}"
if ! [ "${BUILDTIME}" == "" ]
then
	echo "   Build Time        | ${bldcya}$((${BUILDTIME} / 60))m$((${BUILDTIME} % 60))s${txtrst}"
fi
echo "6) Build Zip Package | ${bldyel}$zippackagecheck${txtrst}"
if [ -f zip-creator/${zipfile} ]
then
	echo "   Zip Saved         | ${bldcya}zip-creator/${zipfile}${txtrst}"
fi
echo "-${bldblu}Special Device Menu${txtrst}-"
echo "7) Update Defconfig  | ${bldblu}${defconfigcheck}${txtrst}"
echo "8) Copy Zip          | ${bldblu}${zipcopycheck}${txtrst}"
echo "9) Reboot to recovery"
echo "-${bldmag}Script Options${txtrst}-"
echo "o) View Build Output | ${buildoutput}"
echo "g) Git Gui  |  k) GitK  |  s) Git Push  |  l) Git Pull"
echo "q) Quit"
echo
read -n 1 -p "${txtbld}Choice: ${txtrst}" -s x
case ${x} in
	1) echo "${x} - Cleaning Zips"; rm -rf zip-creator/*.zip; unset zippackagecheck;;
	2) echo "${x} - Cleaning Kernel"; make clean mrproper &> /dev/null; unset buildprocesscheck name variant defconfig BUILDTIME;;
	3) maindevice;;
	4) maintoolchain;;
	5) buildprocess;;
	6) zippackage;;
	7) updatedefconfig;;
	8) adbcopy;;
	9) echo "${x} - Rebooting to Recovery..."; adb reboot recovery;;
	o) if [ "${buildoutput}" == "OFF" ]; then unset buildoutput; else buildoutput="OFF"; fi;;
	q) echo "${x} - Ok, Bye!"; break;;
	g) echo "${x} - Opening Git Gui"; git gui;;
	k) echo "${x} - Opening GitK"; gitk;;
	s) echo "${x} - Pushing to remote repo"; git push --verbose --all; sleep 3;;
	l) echo "${x} - Pushing to local repo"; git pull --verbose --all; sleep 3;;
	*) ops;;
esac
}

# Menu - End

# The core of script is here!

ops() {
echo "${x} - This option is not valid"; sleep 1
}

if [ ! "${BASH_VERSION}" ]
	then echo "Please do not use sh to run this script, just use . build.sh"
elif [ -e build.sh ]; then
	# Stock Color
	txtrst=$(tput sgr0)
	# Bold Colors
	txtbld=$(tput bold) # Bold
	bldred=${txtbld}$(tput setaf 1) # red
	bldgrn=${txtbld}$(tput setaf 2) # green
	bldyel=${txtbld}$(tput setaf 3) # yellow
	bldblu=${txtbld}$(tput setaf 4) # blue
	bldmag=${txtbld}$(tput setaf 5) # magenta
	bldcya=${txtbld}$(tput setaf 6) # cyan
	bldwhi=${txtbld}$(tput setaf 7) # white
	# Common Messages
	_d="Already Done!"
	_r="Ready to do!"
	# Main Variables
	customkernel=CAFKernel
	export ARCH=arm

	while true
	do
		if [ "${buildoutput}" == "" ]
		then
			buildoutput="${bldmag}ON${txtrst}"
		fi
		if [ "${zippackagecheck}" == "${_d}" ]
		then
			zipcopycheck="${_r}"
		else
			zipcopycheck="Use 6 first"
		fi
		if [ "${buildprocesscheck}" == "" ]
		then
			buildprocesscheck="${_r}"
			zippackagecheck="Use 5 first"
		fi
		if [ "${buildprocesscheck}" == "${_d}" ]
		then
			if ! [ "$zippackagecheck" == "${_d}" ]
			then
				zippackagecheck="${_r}"
			fi
		fi
		if [ "${CROSS_COMPILE}" == "" ]
		then
			buildprocesscheck="Use 4 first"
		fi
		if [ "${defconfig}" == "" ]
		then
			buildprocesscheck="Use 3 first"
			defconfigcheck="Use 3 first"
		else
			defconfigcheck="${_r}"
		fi
		if [ -f zip-creator/*.zip ]
		then
			unset cleanzipcheck
		else
			cleanzipcheck="${_d}"
		fi
		if [ -f .config ]
		then
			unset cleankernelcheck
		else
			cleankernelcheck="${_d}"
		fi
		if ! [ -f .version ]
		then
			echo "0" > .version
		fi
		kernelversion=$(cat Makefile | grep VERSION | cut -c 11- | head -1)
		kernelpatchlevel=$(cat Makefile | grep PATCHLEVEL | cut -c 14- | head -1)
		kernelsublevel=$(cat Makefile | grep SUBLEVEL | cut -c 12- | head -1)
		kernelname=$(cat Makefile | grep NAME | cut -c 8- | head -1)
		release=$(date +%d""%m""%Y)
		build=$(cat .version)
		export zipfile="${customkernel}-${name}-${variant}-${release}-${build}.zip"

		buildsh
	done
else
	echo
	echo "Ensure you run this file from the SAME folder as where it was,"
	echo "otherwise the script will have problems running the commands."
	echo "After you 'cd' to the correct folder, start the build script"
	echo "with the . build.sh command, NOT with any other command!"
	echo
fi
