#!/bin/bash

# frep v0.9.11 beta
# macOS File Reporter

SCRNAME=$(/usr/bin/basename $0)

# check for single user
SINGLEUSER=$(/usr/sbin/sysctl -n kern.singleuser)
if [[ "$SINGLEUSER" == "1" ]] ; then
	echo "Error! $SCRNAME is not meant for single-user mode."
	exit
fi

# check for argument(s)
if [ $# -lt 1 ] ; then
    echo "Usage: [sudo] $SCRNAME <PATH>"
    exit
fi

### LATER
### add arguments -b and --bitbar for sending paths to BitBar plugin
### method to determine the default "open with" application for a file?
### WebDAV checks/support
### SSHFS checks/support
### AFP checks/support?  (might not be necessary: will be dropped with APFS)

STANDOUT=$(tput smso)
BOLD=$(tput bold)
RESET=$(tput sgr0)

export LANG=en_US.UTF-8
LOGNAME=$(who am i | /usr/bin/awk '{print $1}')
EXECUSER=$(/usr/bin/id -un)

ACCOUNT=$(/usr/bin/id -unr "$LOGNAME")
USERID=$(/usr/bin/id -ur "$LOGNAME")
UGROUP=$(/usr/bin/id -gnr "$LOGNAME")
UGROUPID=$(/usr/bin/id -gr "$LOGNAME")

USERGROUPS=$(/usr/bin/id -Gn "$ACCOUNT")
USERGROUPSN=$(/usr/bin/id -G "$ACCOUNT")

# set -x
# PS4=':$LINENO+'

# round function
round () {
	echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | /usr/bin/bc))
}

# calculate human readable (binary)
humanbinary () {
    BINSIZE=$(echo "$1" | /usr/bin/awk 'function human(x) {
		s=" B   KiB MiB GiB TiB EiB PiB YiB ZiB"
    	while (x>=1024 && length(s)>1)
        	{x/=1024; s=substr(s,5)}
    	s=substr(s,1,4)
    	xf=(s==" B  ")?"%5d   ":"%8.2f"
    	return sprintf( xf"%s\n", x, s)
    }
	{gsub(/^[0-9]+/, human($1)); print}' | xargs)
	[[ "$BINSIZE" != *" B" ]] && echo "$BINSIZE"
}

# calculate human readable (decimal)
humandecimal () {
    DECSIZE=$(echo "$1" | /usr/bin/awk 'function human(x) {
		s=" B    KB  MB  GB  TB  EB  PB  YB  ZB"
    	while (x>=1000 && length(s)>1)
        	{x/=1000; s=substr(s,5)}
    	s=substr(s,1,4)
    	xf=(s==" B  ")?"%5d   ":"%8.2f"
    	return sprintf( xf"%s\n", x, s)
    }
	{gsub(/^[0-9]+/, human($1)); print}' | xargs)
	[[ "$DECSIZE" != *" B" ]] && echo "$DECSIZE"
}

for FILEPATH in "$@"
do

# check if exists
if [[ ! -a "$FILEPATH" ]] ; then
	echo "Error! $FILEPATH does not exist!"
	continue
fi

# check if readable
if [[ "$EXECUSER" != "root" ]] ; then
	if [[ ! -r "$FILEPATH" ]] ; then
		echo "Error! Target is not readable."
		echo "Please run the script again as root using 'sudo $SCRNAME'"
		continue
	fi
	if [[ -d "$FILEPATH" ]] ; then
		echo "Running preliminary read permissions check. Please wait..."
		cd "$FILEPATH"
		NRCONTENT=$(find . ! -user "$ACCOUNT" -exec [ ! -r {} ] \; -print -quit)
		cd /
		if [[ "$NRCONTENT" != "" ]] ; then
			echo "Error! At least one item is not readable."
			echo "Please run the script again as root using 'sudo $SCRNAME'"
			continue
		else
			echo ""
		fi
	fi
else
	echo ""
fi

tabs 31

echo -e "${STANDOUT}                              ${BOLD}macOS File Report       ${RESET}"

# stat first
STAT=$(/usr/bin/stat "$FILEPATH")
STATS=$(/usr/bin/stat -s "$FILEPATH")

# some volume info first
FPDF=$(/bin/df -Pi "$FILEPATH" | /usr/bin/tail -1)
FSYSTEM=$(echo "$FPDF" | /usr/bin/awk '{print $1}')
DISKUTIL=$(/usr/sbin/diskutil info "$FSYSTEM" 2>&1)
[[ "$DISKUTIL" == "Could not find disk:"* ]] && DISKUTIL=""
SECTORSIZE=$(echo "$DISKUTIL" | /usr/bin/awk '/Device Block Size/{print $4}')
if [[ "$SECTORSIZE" == "" ]] ; then
	SECTORSIZE="0"
fi

echo ""
echo -e "\t${STANDOUT}File Information        ${RESET}"

# file info
BASENAME=$(/usr/bin/basename "$FILEPATH")
echo -e "Basename:${RESET}\t$BASENAME"

if [[ "$BASENAME" == *"."* ]] ; then
	EXTENSION=".${BASENAME##*.}"
	FILENAME="${BASENAME%.*}"
else
	EXTENSION="-"
	FILENAME="$BASENAME"
fi
echo -e "Extension:\t$EXTENSION"

DIRNAME=$(/usr/bin/dirname "$FILEPATH")
echo -e "Path:\t$DIRNAME"

# file type (Unix)
LISTING=$(ls -dlAO "$FILEPATH")
[[ $(echo "$LISTING" | /usr/bin/grep "^-") != "" ]] && FTYPEX="File"
[[ $(echo "$LISTING" | /usr/bin/grep "^d") != "" ]] && FTYPEX="Directory"
[[ $(echo "$LISTING" | /usr/bin/grep "^l") != "" ]] && FTYPEX="Symbolic Link"
[[ $(echo "$LISTING" | /usr/bin/grep "^p") != "" ]] && FTYPEX="Pipe/FIFO"
[[ $(echo "$LISTING" | /usr/bin/grep "^c") != "" ]] && FTYPEX="Character Device"
[[ $(echo "$LISTING" | /usr/bin/grep "^s") != "" ]] && FTYPEX="Socket"
[[ $(echo "$LISTING" | /usr/bin/grep "^b") != "" ]] && FTYPEX="Block"
[[ $(echo "$LISTING" | /usr/bin/grep "^w") != "" ]] && FTYPEX="Whiteout"
echo -e "File Type:\t$FTYPEX"

if [[ "$FTYPEX" == "Symbolic Link" ]] ; then
	cd "$DIRNAME"
	SYMTARGET="$BASENAME"
	while [ -L "$SYMTARGET" ]
	do
		SYMTARGET=$(/usr/bin/readlink "$SYMTARGET")
		cd "$(/usr/bin/dirname "$SYMTARGET")"
		SYMTARGET="$(/usr/bin/basename "$SYMTARGET")"
	done
	ABSDIR=$(pwd -P)
	ABSPATH="$ABSDIR/$SYMTARGET"
	echo -e "Reference:\t$ABSPATH"
	cd /
	[[ -d "$ABSPATH" ]] && DIRREF="true"
fi

# file type (specific)
FILETYPE=$(/usr/bin/file "$FILEPATH" | /usr/bin/awk -F": " '{print $2}')
echo -e "File Content:\t$FILETYPE"

# invisible (true dot file, not macOS "hidden" flag)
if [[ "$BASENAME" == "."* ]] ; then
	TINV="true"
else
	TINV="false"
fi
echo -e "Invisible:\t$TINV"

# stat info output
INODE_DEV=$(echo "$STAT" | /usr/bin/awk '{print $1}')
echo -e "Device:\t$INODE_DEV"

INODE=$(echo "$STAT" | /usr/bin/awk '{print $2}')
echo -e "Inode:\t$INODE"

RDEV=$(echo "$STAT" | /usr/bin/awk '{print $7}')
echo -e "Device Type:\t$RDEV"

HARDLINKS=$(echo "$STAT" | /usr/bin/awk '{print $4}')
echo -e "Links:\t$HARDLINKS"

FILEGENNO=$(/usr/bin/stat -f '%v' "$FILEPATH")
echo -e "File Generation Number:\t$FILEGENNO"

# checksums

if [[ "$FTYPEX" != "Directory" ]] && [[ "$DIRREF" != "true" ]] ; then

	echo ""
	echo -e "\t${STANDOUT}Checksums               ${RESET}"

	CRC32HASH=$(/usr/bin/crc32 "$FILEPATH" 2>/dev/null)
	[[ "$CRC32HASH" == "" ]] && CRC32HASH="-"
	echo -e "CRC-32:\t$CRC32HASH"

	MD5CHECKSUM=$(/sbin/md5 -q "$FILEPATH" 2>/dev/null)
	[[ "$MD5CHECKSUM" == "" ]] && MD5CHECKSUM="-"
	echo -e "MD5:\t$MD5CHECKSUM"

	SHA1CHECKSUM=$(/usr/bin/shasum -a 1 "$FILEPATH" 2>/dev/null | /usr/bin/awk '{print $1}')
	[[ "$SHA1CHECKSUM" == "" ]] && SHA1CHECKSUM="-"
	echo -e "SHA-1:\t$SHA1CHECKSUM"

	SHA2CHECKSUM=$(/usr/bin/shasum -a 256 "$FILEPATH" 2>/dev/null | /usr/bin/awk '{print $1}')
	[[ "$SHA2CHECKSUM" == "" ]] && SHA2CHECKSUM="-"
	echo -e "SHA-2 (256 bit):\t$SHA2CHECKSUM"

fi

# path owner & permissions

echo ""
echo -e "\t${STANDOUT}Path Owner & Permissions${RESET}"

DIRSTAT=$(/usr/bin/stat "$DIRNAME")
DIRSTATS=$(/usr/bin/stat -s "$DIRNAME")
PUIDN=$(echo "$DIRSTAT" | /usr/bin/awk '{print $5}')
PGIDN=$(echo "$DIRSTAT" | /usr/bin/awk '{print $6}')
PUIDNO=$(echo "$DIRSTATS" | /usr/bin/awk '{print $5}' | /usr/bin/awk -F= '{print $2}')
PGIDNO=$(echo "$DIRSTATS" | /usr/bin/awk '{print $6}' | /usr/bin/awk -F= '{print $2}')
echo -e "Owner:\t$PUIDN:$PGIDN ($PUIDNO:$PGIDNO)"

DIRPERM=$(echo "$DIRSTAT" | /usr/bin/awk '{print $3}')
echo -e "Permissions:\t${DIRPERM:1}"

# file owner & permissions

echo ""
echo -e "\t${STANDOUT}File Owner & Permissions${RESET}"

# owner

UIDN=$(echo "$STAT" | /usr/bin/awk '{print $5}')
GIDN=$(echo "$STAT" | /usr/bin/awk '{print $6}')
UIDNO=$(echo "$STATS" | /usr/bin/awk '{print $5}' | /usr/bin/awk -F= '{print $2}')
GIDNO=$(echo "$STATS" | /usr/bin/awk '{print $6}' | /usr/bin/awk -F= '{print $2}')
UFILEACCESS=""
if [[ "$UIDN" == "$USERID" ]] || [[ $(echo "$USERGROUPS" | /usr/bin/grep -w "$GIDN") != "" ]] ; then
	UFILEACCESS="true"
fi
echo -e "Owner:\t$UIDN:$GIDN ($UIDNO:$GIDNO)"

# mode

MODEA=$(/usr/bin/stat -f '%A' "$FILEPATH")
MODEB=$(echo "$STATS" | /usr/bin/awk '{print $3}' | /usr/bin/awk -F= '{print $2}')
MODE="$MODEB ($MODEA)"
echo -e "Mode:\t$MODE"

# permissions

PERMISSIONS=$(echo "$STAT" | /usr/bin/awk '{print $3}')
echo -e "Permissions:\t${PERMISSIONS:1}"

GDIRACCESS=""
if [[ "$UIDNO" == "$USERID" ]] ; then
	PERMHR=${PERMISSIONS:1:3}
	ID_INFO="$USERID"
	GDIRACCESS="true"
else
	if [[ $(echo "$USERGROUPS" | /usr/bin/grep -w "$GIDN") != "" ]] ; then
		ID_INFO="$UGROUPID"
		PERMHR=${PERMISSIONS:4:3}
		GDIRACCESS="true"
	else
		PERMHR=${PERMISSIONS:7:3}
		ID_INFO="$USERID"
	fi
fi
if [[ "$FTYPEX" != "Directory" ]] ; then
	PERMHR=$(echo "$PERMHR" | /usr/bin/sed -e 's/\(.\)/\1 /g' -e s/"-"//g -e s/"T"// -e s/"x "/execute\ / -e s/"t "/execute\ / -e s/"w "/write\ modify\ / -e s/"r "/read\ / | xargs)
else
	PERMHR=$(echo "$PERMHR" | /usr/bin/sed -e 's/\(.\)/\1 /g' -e s/"-"//g -e s/"T"// -e s/"x "/execute\ enter\ / -e s/"t "/execute\ enter\ / -e s/"w "/write\ modify\ / -e s/"r "/read\ list\ / | xargs)
fi
echo -e "Permissions ($ID_INFO):\t$PERMHR"

# additional permissions

ADDIDINFO="$USERID"
ADDPERM="-"
if [[ "$USERID" == "$PUIDNO" ]] ; then
	DIRPERM=${DIRPERM:1:3}
	if [[ "$DIRPERM" == ?"w"? ]] ; then
		ADDPERM="rename delete"
		ADDIDINFO="$USERID"
	fi
elif [[ $(echo "$USERGROUPSN" | /usr/bin/grep "$PGIDNO") != "" ]] ; then
	DIRPERM=${DIRPERM:4:3}
	if [[ "$DIRPERM" == ?"w"? ]] ; then
		ADDIDINFO="$PGIDNO"
		ADDPERM="rename delete"
	fi
else
	DIRPERM=${DIRPERM:7:3}
	if [[ "$DIRPERM" == ?"w"? ]] ; then
		ADDIDINFO="12"
		ADDPERM="rename delete"
	fi
fi

# sticky bit
STICKY="-"
STLIST=$(echo "$LISTING" | /usr/bin/awk '{print $1}')
if [[ "$STLIST" == *"t" ]] || [[ "$STLIST" == *"t"? ]] ; then
	STICKY="set with execution bit"
	STICKYBIT="t"
elif [[ "$STLIST" == *"T" ]] || [[ "$STLIST" == *"T"? ]] ; then
	STICKY="set without execution bit"
	STICKYBIT="T"
fi
echo -e "Sticky Bit:\t$STICKY [no effect on macOS]"

# SUID/GUID
SUIDSET="-" ; GUIDSET="-"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"s"* ]] && SUIDSET="enabled (ux)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"S"* ]] && SUIDSET="enabled"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"s"* ]] && GUIDSET="enabled (gx)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"S"* ]] && GUIDSET="enabled"
echo -e "Set GID:\t$GUIDSET"
echo -e "Set UID:\t$SUIDSET"

# system/user flags
FLAGSA=$(echo "$STATS" | /usr/bin/awk '{print $15}' | /usr/bin/awk -F= '{print $2}')
FLAGSB=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $9}' | /usr/bin/awk '{print $3}')
USERFLAGS="$FLAGSB ($FLAGSA)"
echo -e "System/User Flags:\t$USERFLAGS"

# file attributes
CHFLAGS=$(echo "$LISTING" | /usr/bin/awk '{print $5}' | /usr/bin/awk '{gsub(","," ");print}')
ROOTFLAGS=$(echo "$CHFLAGS" | /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{print $2}' | xargs)
echo -e "Attributes:\t$ROOTFLAGS"

# check for SIP
MACOS=$(/usr/bin/sw_vers)
MACOSV=$(echo "$MACOS" | /usr/bin/awk -F: '/ProductVersion/{print $2}' | xargs)
OSMAJ=$(echo "$MACOSV" | /usr/bin/awk -F. '{print $1}')
OSMIN=$(echo "$MACOSV" | /usr/bin/awk -F. '{print $2}')
if [[ ${OSMAJ} -eq 10 ]] && [[ ${OSMIN} -lt 11 ]] ; then
	SIPSTATUS="not available"
fi
if [[ ${OSMAJ} -eq 10 ]] && [[ ${OSMIN} -ge 11 ]]; then
	SIPSTATUS=$(/usr/bin/csrutil status | awk -F": " '{print $2}' | /usr/bin/sed 's/\.$//')
fi

# check attributes for permissions restrictions
if [[ "$ACCOUNT" != "root" ]] ; then
	if [[ $(echo "$ROOTFLAGS" | /usr/bin/grep -w 'sunlnk') != "" ]] ; then
		if [[ "$UFILEACCESS" == "" ]] && [[ "$GDIRACCESS" == "" ]] ; then
			ADDPERM="-"
			ADDIDINFO="$USERID"
		fi
	elif [[ $(echo "$ROOTFLAGS" | /usr/bin/grep -w 'restricted') != "" ]] ; then
		ADDPERM="-"
		ADDIDINFO="$USERID"
	fi
else
	if [[ $(echo "$ROOTFLAGS" | /usr/bin/grep -w 'restricted') != "" ]] && [[ "$SIPSTATUS" == "enabled" ]] ; then
		ADDPERM="-"
		ADDIDINFO="$USERID"
	fi
fi

# ACL
ACE_LIST=$(ls -dlAe "$FILEPATH" | /usr/bin/tail -n +2)

ACL=""
while read -r ACE
do
	ACE=$(echo "$ACE" | /usr/bin/awk -F": " '{print substr($0, index($0,$2))}')
	ACL=$(echo "$ACL
$ACE")
done < <(echo "$ACE_LIST")

ACL=$(echo "$ACL" | /usr/bin/tail -n +2)

if [[ "$ACL" == "" ]] ; then
	echo -e "ACE:\t-"
else # parse ACL for ACE
	ACE_COUNT="0"
	while read -r ACE
	do
		echo -e "ACE $ACE_COUNT:\t$ACE"
		((ACE_COUNT++))
	done < <(echo "$ACL")
fi

# parse ACL for further permissions restrictions
if [[ "$ACCOUNT" != "root" ]] ; then
	USERACL=$(echo "$ACL" | /usr/bin/grep "$ACCOUNT")
	if [[ "$USERACL" != "" ]] ; then
		[[ $(echo "$USERACL" | /usr/bin/grep "$ACCOUNT deny delete") != "" ]] && ADDPERM="-"
	fi
	GROUPACL=$(echo "$ACL" | /usr/bin/grep "group:")
	if [[ "$GROUPACL" != "" ]] ; then
		while read -r GROUPACE
		do
			ACEGROUP=$(echo "$GROUPACE" | /usr/bin/awk '{print $1}' | /usr/bin/awk -F: '{print $2}')
			if [[ $(echo "$USERGROUPS" | /usr/bin/grep -w "$ACEGROUP") != "" ]] ; then
				[[ $(echo "$GROUPACE" | /usr/bin/grep "deny delete") != "" ]] && ADDPERM="-"
			fi
		done < <(echo "$GROUPACL")
	fi
fi

# check final schg attribute (can only be changed/deleted by root in single-user mode)
if [[ $(echo "$ROOTFLAGS" | /usr/bin/grep -w 'schg') != "" ]] ; then
	ADDPERM="-"
fi

echo -e "Other Permissions ($ADDIDINFO):\t$ADDPERM"

# extended attributes
XTRALIST=$(ls -dlAO@ "$FILEPATH" | /usr/bin/tail -n +2)
XATTRLIST=$(echo "$XTRALIST" | /usr/bin/grep -v "com.apple.ResourceFork")
if [[ "$XATTRLIST" != "" ]] ; then
	echo ""
	echo -e "\t${STANDOUT}Extended Attributes     ${RESET}"
	XATTRCOUNT="0"
	while read -r XATTR
	do
		(( XATTRCOUNT++ ))
		XATTRN=$(echo "$XATTR" | /usr/bin/awk '{print $1}' | xargs)
		echo -e "Xattr $XATTRCOUNT:\t$XATTRN"
	done < <(echo "$XATTRLIST")
fi

# root object information

if [[ "$FTYPEX" == "Directory" ]] ; then

	echo ""
	echo -e "\t${STANDOUT}Root Object Information ${RESET}"

	STATSIZE_B=$(echo "$STAT" | /usr/bin/awk '{print $8}')
	STATSIZE_MB=$(humandecimal "$STATSIZE_B")
	STATSIZE_MIB=$(humanbinary "$STATSIZE_B")
	STATSIZE_HR=$(echo "$STATSIZE_B" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$STATSIZE_MB" == "" ]] && [[ "$STATSIZE_MIB" == "" ]] ; then
		STATSIZE="$STATSIZE_HR B"
	else
		STATSIZE="$STATSIZE_HR B ($STATSIZE_MB, $STATSIZE_MIB)"
	fi
	echo -e "Data Size [stat]:\t$STATSIZE"


	XTRASIZE=$(echo "$XTRALIST" | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
	[[ "$XTRASIZE" == "" ]] && XTRASIZE="0"
	if [[ "$XTRASIZE" != "0" ]] ; then
		XTRASIZE_MB=$(humandecimal "$XTRASIZE")
		XTRASIZE_MIB=$(humanbinary "$XTRASIZE")
		XTRASIZE_HR=$(echo "$XTRASIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
		if [[ "$XTRASIZE_MB" == "" ]] && [[ "$XTRASIZE_MIB" == "" ]] ; then
			XTRASIZE_INFO="$XTRASIZE_HR B"
		else
			XTRASIZE_INFO="$XTRASIZE_HR B ($XTRASIZE_MB, $XTRASIZE_MIB)"
		fi
	else
		XTRASIZE_INFO="0 B"
	fi
	echo -e "Extended Attributes [stat]:\t$XTRASIZE_INFO"

	ROOT_TOTAL=$(echo "$STATSIZE_B + $XTRASIZE" | /usr/bin/bc -l)
	ROOT_TOTAL_MB=$(humandecimal "$ROOT_TOTAL")
	ROOT_TOTAL_MIB=$(humanbinary "$ROOT_TOTAL")
	ROOT_TOTAL_HR=$(echo "$ROOT_TOTAL" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$ROOT_TOTAL_MB" == "" ]] && [[ "$ROOT_TOTAL_MIB" == "" ]] ; then
		ROOT_TSIZE="$ROOT_TOTAL_HR B"
	else
		ROOT_TSIZE="$ROOT_TOTAL_HR B ($ROOT_TOTAL_MB, $ROOT_TOTAL_MIB)"
	fi
	echo -e "Size On Volume:\t$ROOT_TSIZE"

fi

# content sizes

echo ""
echo -e "\t${STANDOUT}Sizes & Disk Usage      ${RESET}"

# total list
TOTAL_LIST=$(ls -ReAlOs@ "$FILEPATH" | /usr/bin/sed '/^$/d')
SEDPATH=$(echo "$FILEPATH" | /usr/bin/awk '{gsub("/","\\/");print}')
SIZE_LIST=$(echo "$TOTAL_LIST" | /usr/bin/sed '/^'"$SEDPATH"'/d' | /usr/bin/awk 'NF>=11 {print substr($0, index($0,$2))}')

# blocks on disk
BLOCKLIST=$(echo "$TOTAL_LIST" | /usr/bin/sed '/^'"$SEDPATH"'/d' | /usr/bin/awk 'NF>=11' | /usr/bin/awk '{print $2,$1}')
BLOCKSONDISK=$(echo "$BLOCKLIST" | /usr/bin/grep -v '^d' | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
echo -e "Device Blocks:\t$BLOCKSONDISK"

# disk usage calculation with du
DISK_USAGE=$(/usr/bin/du -k -d 0 "$FILEPATH" | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}')
DU_SIZE=$(echo "$DISK_USAGE * 1024" | /usr/bin/bc -l)
[[ "$DU_SIZE" == "" ]] && DU_SIZE="0"

# size on disk calculated from ls/stat output
if [[ "$SECTORSIZE" != "0" ]] ; then

	SOD_ADD=""
	SIZEONDISK=$(echo "$BLOCKSONDISK * $SECTORSIZE" | /usr/bin/bc -l)
	[[ "$SIZEONDISK" == "" ]] && SIZEONDISK="0"
	SOD_MB=$(humandecimal "$SIZEONDISK")
	SOD_MIB=$(humanbinary "$SIZEONDISK")
	SOD_T=$(echo "$SIZEONDISK" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$SOD_MB" == "" ]] && [[ "$SOD_MIB" == "" ]] ; then
		SOD_INFO="$SOD_T B"
	else
		SOD_INFO="$SOD_T B ($SOD_MB, $SOD_MIB)"
	fi

else
	if [[ "$DU_SIZE" != "0" ]] ; then

		SECTORSIZE_RAW=$(echo "$DU_SIZE / $BLOCKSONDISK" | /usr/bin/bc)

		if [[ "$SECTORSIZE_RAW" -le 511 ]] ; then
			SECTORSIZEC=512
		elif [[ "$SECTORSIZE_RAW" -ge 4097 ]] ; then
			SECTORSIZEC=4096
		else
			DIV512=$(round $(echo "512 / $SECTORSIZE_RAW" | /usr/bin/bc -l) 17)
			DIV1024=$(round $(echo "1024 / $SECTORSIZE_RAW" | /usr/bin/bc -l) 17)
			DIV2048=$(round $(echo "2048 / $SECTORSIZE_RAW" | /usr/bin/bc -l) 17)
			DIV4096=$(round $(echo "4096 / $SECTORSIZE_RAW" | /usr/bin/bc -l) 17)
			SUBTR512=$(echo "1 - $DIV512" | /usr/bin/bc -l)
			SUBTR1024=$(echo "1 - $DIV1024" | /usr/bin/bc -l)
			SUBTR2048=$(echo "1 - $DIV2048" | /usr/bin/bc -l)
			SUBTR4096=$(echo "1 - $DIV4096" | /usr/bin/bc -l)
			[[ "$SUBTR512" == "-."* ]] && SUBTR512=$(echo "1+ $SUBTR512" | /usr/bin/bc -l)
			[[ "$SUBTR1024" == "-."* ]] && SUBTR1024=$(echo "0 - $SUBTR1024" | /usr/bin/bc -l)
			[[ "$SUBTR2048" == "-."* ]] && SUBTR2048=$(echo "0 - $SUBTR2048" | /usr/bin/bc -l)
			[[ "$SUBTR4096" == "-."* ]] && SUBTR4096=$(echo "0 - $SUBTR4096" | /usr/bin/bc -l)
			ALLNUMS="$SUBTR512 512
$SUBTR1024 1024
$SUBTR2048 2048
$SUBTR4096 4096"
			MINVALUE=$(echo "$ALLNUMS" | /usr/bin/sed '/^-/d' | /usr/bin/awk '{if(min==""){min=$1}; if($1<min) {min=$1}} END {print min}')
			SECTORSIZEC=$(echo "$ALLNUMS" | /usr/bin/grep -w "$MINVALUE" | /usr/bin/awk '{print $2}')
		fi

		SOD_ADD=" [estimated]"
		SIZEONDISK=$(echo "$BLOCKSONDISK * $SECTORSIZEC" | /usr/bin/bc -l)
		[[ "$SIZEONDISK" == "" ]] && SIZEONDISK="0"
		SOD_MB=$(humandecimal "$SIZEONDISK")
		SOD_MIB=$(humanbinary "$SIZEONDISK")
		SOD_T=$(echo "$SIZEONDISK" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
		if [[ "$SOD_MB" == "" ]] && [[ "$SOD_MIB" == "" ]] ; then
			SOD_INFO="$SOD_T B"
		else
			SOD_INFO="$SOD_T B ($SOD_MB, $SOD_MIB)"
		fi

	else
		SOD_INFO="-"
		SOD_ADD=" [unknown device block size]"
		SECTORSIZEC="-"
	fi
fi

echo -e "Size On Disk [stat]:\t$SOD_INFO$SOD_ADD"

# disk usage reported by HFS+ to du
DU_SIZE_MB=$(humandecimal "$DU_SIZE")
DU_SIZE_MIB=$(humanbinary "$DU_SIZE")
DU_SIZE_T=$(echo "$DU_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
if [[ "$DU_SIZE" != "$SIZEONDISK" ]] ; then
	if [[ "$SECTORSIZE" == "0" ]] ; then
		echo -e "Disk Usage [du]:\t$DU_SIZE_T B ($DU_SIZE_MB, $DU_SIZE_MIB) [approximate]"
	else
		echo -e "Disk Usage [du]:\t$DU_SIZE_T B [probable HFS+ error]"
	fi
else
	if [[ "$DU_SIZE_MB" == "" ]] && [[ "$DU_SIZE_MIB" == "" ]] ; then
		DU_SIZE_INFO="$DU_SIZE_T B"
	else
		DU_SIZE_INFO="$DU_SIZE_T B ($DU_SIZE_MB, $DU_SIZE_MIB)"
	fi
	echo -e "Disk Usage [du]:\t$DU_SIZE_INFO"
fi

# MDLS
MDLS=$(/usr/bin/mdls "$FILEPATH" 2>/dev/null)

# physical size as reported by macOS (mdls) -- might be larger than actual disk usage (virtual size ignoring HFS+ compression)
PHYSICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemPhysicalSize/{print $2}')
if [[ "$PHYSICAL_SIZE" == "" ]] || [[ "$PHYSICAL_SIZE" == "(null)" ]] ; then
	PHYS="false"
	PHYSICAL_SIZE_INFO="-"
else
	PHYS="true"
	PHYSICAL_SIZE_MB=$(humandecimal "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_MIB=$(humanbinary "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_T=$(echo "$PHYSICAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$PHYSICAL_SIZE_MB" == "" ]] && [[ "$PHYSICAL_SIZE_MIB" == "" ]] ; then
		PHYSICAL_SIZE_INFO="$PHYSICAL_SIZE_T B"
	else
		PHYSICAL_SIZE_INFO="$PHYSICAL_SIZE_T B ($PHYSICAL_SIZE_MB, $PHYSICAL_SIZE_MIB)"
	fi
fi

# compression ratio
if [[ "$PHYS" == "true" ]] ; then
	if [[ "$PHYSICAL_SIZE" -gt "$SIZEONDISK" ]] ; then
		COMPRESSED="true"
		echo -e "Virtual Size [mdls]:\t$PHYSICAL_SIZE_INFO"
	else
		COMPRESSED="false"
		echo -e "Physical Size [mdls]:\t$PHYSICAL_SIZE_INFO"
	fi
else
	echo -e "Physical Size [mdls]:\t$PHYSICAL_SIZE_INFO"
	COMPRESSED="unknown"
fi

# data size (total byte count)
DATA_SIZE=$(echo "$SIZE_LIST" | /usr/bin/grep -v '^d' | /usr/bin/awk '{total += $6} END {printf "%.0f", total}')
DATA_SIZE_MB=$(humandecimal "$DATA_SIZE")
DATA_SIZE_MIB=$(humanbinary "$DATA_SIZE")
DATA_SIZE_T=$(echo "$DATA_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
if [[ "$DATA_SIZE_MB" == "" ]] && [[ "$DATA_SIZE_MIB" == "" ]] ; then
	DATA_SIZE_INFO="$DATA_SIZE_T B"
else
	DATA_SIZE_INFO="$DATA_SIZE_T B ($DATA_SIZE_MB, $DATA_SIZE_MIB)"
fi
echo -e "Data Size [stat]:\t$DATA_SIZE_INFO"

# Resource fork size
EXTRA_LIST=$(echo "$TOTAL_LIST" | /usr/bin/sed '/^'"$SEDPATH"'/d' | /usr/bin/awk 'NF<=2' | /usr/bin/sed '/^total /d')
RES_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
[[ "$RES_SIZE" == "" ]] && RES_SIZE="0"
if [[ "$RES_SIZE" != "0" ]]; then
	RES_SIZE_MB=$(humandecimal "$RES_SIZE")
	RES_SIZE_MIB=$(humanbinary "$RES_SIZE")
	RES_SIZE_T=$(echo "$RES_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$RES_SIZE_MB" == "" ]] && [[ "$RES_SIZE_MIB" == "" ]] ; then
		RES_SIZE_INFO="$RES_SIZE_T B"
	else
		RES_SIZE_INFO="$RES_SIZE_T B ($RES_SIZE_MB, $RES_SIZE_MIB)"
	fi
else
	RES_SIZE_INFO="0 B"
fi
echo -e "Resource Forks [stat]:\t$RES_SIZE_INFO"

# apparent size (stat total + resource forks)
APPARENT_SIZE=$(echo "$RES_SIZE + $DATA_SIZE" | /usr/bin/bc -l)
APPARENT_SIZE_MB=$(humandecimal "$APPARENT_SIZE")
APPARENT_SIZE_MIB=$(humanbinary "$APPARENT_SIZE")
APPARENT_SIZE_T=$(echo "$APPARENT_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
if [[ "$APPARENT_SIZE_MB" == "" ]] && [[ "$APPARENT_SIZE_MIB" == "" ]] ; then
	APPARENT_SIZE_INFO="$APPARENT_SIZE_T B"
else
	APPARENT_SIZE_INFO="$APPARENT_SIZE_T B ($APPARENT_SIZE_MB, $APPARENT_SIZE_MIB)"
fi
echo -e "Apparent Size:\t$APPARENT_SIZE_INFO"

# logical size as reported by macOS (mdls) -- should be the same as total byte count
LOGICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLogicalSize/{print $2}')
if [[ "$LOGICAL_SIZE" == "" ]] || [[ "$LOGICAL_SIZE" == "(null)" ]] ; then
	LOGICAL="false"
	LOGICAL_SIZE_INFO="-"
else
	LOGICAL_SIZE_MB=$(humandecimal "$LOGICAL_SIZE")
	LOGICAL_SIZE_MIB=$(humanbinary "$LOGICAL_SIZE")
	LOGICAL_SIZE_T=$(echo "$LOGICAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$LOGICAL_SIZE_MB" == "" ]] && [[ "$LOGICAL_SIZE_MIB" == "" ]] ; then
		LOGICAL_SIZE_INFO="$LOGICAL_SIZE_T B"
	else
		LOGICAL_SIZE_INFO="$LOGICAL_SIZE_T B ($LOGICAL_SIZE_MB, $LOGICAL_SIZE_MIB)"
	fi
fi
echo -e "Logical Size [mdls]:\t$LOGICAL_SIZE_INFO"

# file system size as reported by FS to macOS
FS_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSSize/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$FS_SIZE" == "" ]] || [[ "$FS_SIZE" == "(null)" ]] ; then
	FS_SIZE_INFO="-"
else
	FS_SIZE_MB=$(humandecimal "$FS_SIZE")
	FS_SIZE_MIB=$(humanbinary "$FS_SIZE")
	FS_SIZE_T=$(echo "$FS_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$FS_SIZE_MB" == "" ]] && [[ "$FS_SIZE_MIB" == "" ]] ; then
		FS_SIZE_INFO="$FS_SIZE_T B"
	else
		FS_SIZE_INFO="$FS_SIZE_T B ($FS_SIZE_MB, $FS_SIZE_MIB)"
	fi
fi
echo -e "File System Size [mdls]:\t$FS_SIZE_INFO"

# slack space (physical size, uncompressed - datasize incl. resource forks)
SLACK=$(echo "$SIZEONDISK - $APPARENT_SIZE" | /usr/bin/bc -l)
if [ "$SLACK" -lt 0 ] ; then
	SLACK_INFO="none"
else
	SLACK_MB=$(humandecimal "$SLACK")
	SLACK_MIB=$(humanbinary "$SLACK")
	SLACK_T=$(echo "$SLACK" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$SLACK_MB" == "" ]] && [[ "$SLACK_MIB" == "" ]] ; then
		SLACK_INFO="$SLACK_T B"
	else
		SLACK_INFO="$SLACK_T B ($SLACK_MB, $SLACK_MIB)"
	fi
fi
echo -e "Slack Space:\t$SLACK_INFO"
if [[ "$COMPRESSED" == "true" ]] ; then
	CRATIO=$(echo "$PHYSICAL_SIZE / $SIZEONDISK" | /usr/bin/bc -l)
	CPERCENT=$(echo "100 / $CRATIO" | /usr/bin/bc -l)
	CPERCENT=$(echo "100 - $CPERCENT" | /usr/bin/bc -l)
	CPERCENT=$(round "$CPERCENT" 2)
	echo -e "Compression Ratio:\t$CPERCENT %"
fi

# Xattr size
XATTR_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep -v "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
[[ "$XATTR_SIZE" == "" ]] && XATTR_SIZE="0"
if [[ "$XATTR_SIZE" != "0" ]] ; then
	XATTR_SIZE_MB=$(humandecimal "$XATTR_SIZE")
	XATTR_SIZE_MIB=$(humanbinary "$XATTR_SIZE")
	XATTR_SIZE_T=$(echo "$XATTR_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	if [[ "$XATTR_SIZE_MB" == "" ]] && [[ "$XATTR_SIZE_MIB" == "" ]] ; then
		XATTR_SIZE_INFO="$XATTR_SIZE_T B"
	else
		XATTR_SIZE_INFO="$XATTR_SIZE_T B ($XATTR_SIZE_MB, $XATTR_SIZE_MIB)"
	fi
else
	XATTR_SIZE_INFO="0 B"
fi
echo -e "Extended Attributes [stat]:\t$XATTR_SIZE_INFO"

# total size (data+resources+xattr) = total size
TOTAL_SIZE=$(echo "$APPARENT_SIZE + $XATTR_SIZE" | /usr/bin/bc -l)
TOTAL_SIZE_MB=$(humandecimal "$TOTAL_SIZE")
TOTAL_SIZE_MIB=$(humanbinary "$TOTAL_SIZE")
TOTAL_SIZE_T=$(echo "$TOTAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
if [[ "$TOTAL_SIZE_MB" == "" ]] && [[ "$TOTAL_SIZE_MIB" == "" ]] ; then
	TOTAL_SIZE_INFO="$TOTAL_SIZE_T B"
else
	TOTAL_SIZE_INFO="$TOTAL_SIZE_T B ($TOTAL_SIZE_MB, $TOTAL_SIZE_MIB)"
fi
echo -e "Data Size On Volume:\t$TOTAL_SIZE_INFO"

echo ""
echo -e "\t${STANDOUT}Unix Dates              ${RESET}"

# dates
BIRTHTIME=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $8}')
echo -e "Created:\t$BIRTHTIME"

LASTSTATUSCHANGE=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $6}')
echo -e "Changed:\t$LASTSTATUSCHANGE"

LASTMODIFY=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $4}')
echo -e "Modified:\t$LASTMODIFY"

LASTACCESS=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $2}')
echo -e "Accessed:\t$LASTACCESS"

echo ""
echo -e "\t${STANDOUT}macOS Dates             ${RESET}"

ADD_DATE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemDateAdded/{print $2}')
if [[ "$ADD_DATE" == "" ]] || [[ "$ADD_DATE" == "(null)" ]] ; then
	ADD_DATE="-"
else
	ADD_DATE=$(/bin/date -f'%F %T %z' -j "$ADD_DATE" +'%b %e %H:%M:%S %Y')
fi
echo -e "Added:\t$ADD_DATE"

DL_DATE_RAW=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemDownloadedDate/{getline;print $2}')
if [[ "$DL_DATE_RAW" == "" ]] || [[ "$DL_DATE_RAW" == "(null)" ]] ; then
	DL_DATE="-"
else
	DL_DATE=$(/bin/date -f'%F %T %z' -j "$DL_DATE_RAW" +'%b %e %H:%M:%S %Y')
fi
echo -e "Downloaded:\t$DL_DATE"

METAMOD_EPOCH=$(echo "$MDLS" | /usr/bin/awk -F"= " '/com_apple_metadata_modtime/{print $2}')
if [[ "$METAMOD_EPOCH" == "" ]] || [[ "$METAMOD_EPOCH" == "0" ]] ; then
	METAMOD="-"
else
	METAMOD=$(/bin/date -r "$METAMOD_EPOCH" +'%b %e %H:%M:%S %Y')
fi
echo -e "Metadata Modified:\t$METAMOD"

LASTUSED=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLastUsedDate/{print $2}')
if [[ "$LASTUSED" == "" ]] || [[ "$LASTUSED" == "(null)" ]] ; then
	LASTUSED="-"
else
	LASTUSED=$(/bin/date -f'%F %T %z' -j "$LASTUSED" +'%b %e %H:%M:%S %Y')
fi
echo -e "Last Used:\t$LASTUSED"

# macOS file information

echo ""
echo -e "\t${STANDOUT}macOS File Information  ${RESET}"

# Shared folder
SHARE_INFO=$(/usr/bin/dscl . -read SharePoints/"$BASENAME" 2>&1)
if [[ $(echo "$SHARE_INFO" | /usr/bin/grep "$FILEPATH") != "" ]] ; then
	SHARED="true"
else
	SHARED="false"
fi
echo -e "Shared:\t$SHARED"

# check if bundle/directory
if [[ "$FTYPEX" == "Directory" ]] ; then
	PATH_TYPE=$(/usr/bin/mdls -name kMDItemContentTypeTree "$FILEPATH")
	PACKAGE_CHECK=$(echo "$PATH_TYPE" | /usr/bin/grep -e "com.apple.package")
	if [[ "$PACKAGE_CHECK" != "" ]] ; then
		TTYPE="package"
		PACKAGE_INFO="true"
	else
		PACKAGE_INFO="false"
	fi
	BUNDLE_CHECK=$(echo "$PATH_TYPE" | /usr/bin/grep -e "com.apple.bundle")
	if [[ "$BUNDLE_CHECK" != "" ]] ; then
		TTYPE="package"
		BUNDLE_INFO="true"
	else
		BUNDLE_INFO="false"
	fi
else
	BUNDLE_INFO="false"
	PACKAGE_INFO="false"
	TTYPE="directory"
fi
echo -e "Package:\t$PACKAGE_INFO"
echo -e "Bundle:\t$BUNDLE_INFO"

# extension hidden in Finder
HIDDENEXT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSIsExtensionHidden/{print $2}')
if [[ "$HIDDENEXT" == "(null)" ]] || [[ "$HIDDENEXT" == "" ]] ; then
	HIDDENEXT="-"
else
	if [[ "$HIDDENEXT" == "1" ]] ; then
		HIDDENEXT="true"
	else
		HIDDENEXT="false"
	fi
fi
echo -e "Hidden Extension:\t$HIDDENEXT"

# read bundle's Info.plist
if [[ "$TTYPE" == "package" ]] ; then
	PLIST_PATH="$FILEPATH/Contents/Info.plist"
	if [[ ! -f "$PLIST_PATH" ]] ; then
		PLIST_INFO="false"
		EXEC_SEARCH="$FILEPATH/Contents/MacOS/$FILENAME"
		if [[ -f "$EXEC_SEARCH" ]] ; then
			BUNDLE_EXEC="$EXEC_SEARCH"
		else
			BUNDLE_EXEC="-"
		fi
	else
		PLIST_INFO="true"
		JPLIST=$(/usr/bin/plutil -convert json -r -o - "$PLIST_PATH")
		BUNDLE_EXEC=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleExecutable/{print $4}')
		[[ "$BUNDLE_EXEC" == "" ]] && BUNDLE_EXEC="-"
	fi
	echo -e "Info.plist:\t$PLIST_INFO"
	if [[ "$BUNDLE_EXEC" != "-" ]] ; then
		EXEC_PPATH="$FILEPATH/Contents/MacOS/$BUNDLE_EXEC"
		if [[ -e "$EXEC_PPATH" ]] ; then
			EXEC_INFO="true"
		else
			EXEC_INFO="false"
			EXEC_INFO="-"
		fi
	else
		EXEC_INFO="false"
		EXEC_PPATH="-"
	fi
	echo -e "Executable:\t$EXEC_PPATH"
else
	EXEC_PPATH="$FILEPATH"
	EXEC_INFO="true"
fi

# lipo
if [[ "$EXEC_INFO" == "true" ]] ; then
	LIPO=$(/usr/bin/lipo -info "$EXEC_PPATH" 2>/dev/null)
	if [[ "$LIPO" != "" ]] ; then
		LIPO_INFO=$(echo "$LIPO" | /usr/bin/awk -F": " '{print $3}')
		echo -e "Architecture:\t$LIPO_INFO"
	fi
fi

# content type
CONTENT_TYPE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemContentType/{print $2}' | /usr/bin/head -n 1 | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$CONTENT_TYPE" == "" ]] || [[ "$CONTENT_TYPE" == "(null)" ]] ; then
	CONTENT_TYPE="-"
fi
echo -e "Uniform Type Identifier:\t$CONTENT_TYPE"

# kind
KIND=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemKind/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$KIND" == "" ]] || [[ "$KIND" == "(null)" ]] ; then
	KIND="-"
fi
echo -e "Kind:\t$KIND"
if [[ "$KIND" == "Alias" ]] ; then
	if [[ $(/bin/ps axo pid,command | /usr/bin/grep -iw "[F]inder") != "" ]] ; then
		ATARGET=$(/usr/bin/osascript 2>/dev/null << EOF
tell application "Finder"
	set thePath to (POSIX file "$FILEPATH") as alias
	set theOriginal to (POSIX path of ((original item of thePath) as text))
end tell
theOriginal
EOF)
		if [[ "$ATARGET" != "" ]] ; then
			echo -e "Original:\t${ATARGET%/}"
		fi
	fi
fi

# Finder flags
FINDERFLAGS=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSFinderFlags/{print $2}')
if [[ "$FINDERFLAGS" == "(null)" ]] || [[ "$FINDERFLAGS" == "" ]] ; then
	FINDERFLAGS="-"
fi
echo -e "Finder Flags:\t$FINDERFLAGS"

if [[ "$FTYPEX" != "Directory" ]] ; then
	# Finder: type
	TYPECODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSTypeCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
	if [[ "$TYPECODE" == "(null)" ]] || [[ "$TYPECODE" == "" ]] ; then
		TYPECODE="-"
	fi
	echo -e "Type:\t$TYPECODE"

	# Finder: creator
	CREATORCODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSCreatorCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
	if [[ "$CREATORCODE" == "(null)" ]] || [[ "$CREATORCODE" == "" ]] ; then
		CREATORCODE="-"
	fi
	echo -e "Creator:\t$CREATORCODE"
fi

# Content Creator
CCREATOR=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemCreator/{print $2}')
if [[ "$CCREATOR" == "(null)" ]] || [[ "$CCREATOR" == "" ]] ; then
	CCREATOR="-"
fi
echo -e "Content Creator:\t$CCREATOR"

# Node Count
if [[ "$FTYPEX" == "Directory" ]] ; then
	NODEC=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSNodeCount/{print $2}')
	if [[ "$NODEC" == "(null)" ]] || [[ "$NODEC" == "" ]] ; then
		NODEC="-"
	fi
	echo -e "Node Count:\t$NODEC"
fi

# Label
LABEL=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSLabel/{print $2}')
if [[ "$LABEL" == "(null)" ]] || [[ "$LABEL" == "" ]] ; then
	LABEL="-"
fi
echo -e "Label:\t$LABEL"

# OpenMeta
TAGS=$(/usr/bin/mdls -raw -name kMDItemUserTags "$FILEPATH" | /usr/bin/sed -e '1,1d' -e '$d' | xargs)
if [[ "$TAGS" == "(null)" ]] || [[ "$TAGS" == "" ]] ; then
	TAGS="-"
fi
echo -e "OpenMeta Tags:\t$TAGS"

# Finder comment
FCOMMENT=$(/usr/bin/mdls -raw -name kMDItemFinderComment "$FILEPATH" 2>&1)
if [[ "$FCOMMENT" == "(null)" ]] || [[ "$FCOMMENT" == "" ]] ; then
	FCOMMENT="-"
fi
echo -e "Finder Comment:\t$FCOMMENT"

# item copyright
ITEMCOPYRIGHT=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemCopyright/{print $2}')
if [[ "$ITEMCOPYRIGHT" == "(null)" ]] || [[ "$ITEMCOPYRIGHT" == "" ]] ; then
	ITEMCOPYRIGHT="-"
fi
echo -e "Item Copyright:\t$ITEMCOPYRIGHT"

# download URL
DL_SOURCE=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemWhereFroms/{getline;print $2}')
if [[ "$DL_SOURCE" == "" ]] || [[ "$DL_SOURCE" == "(null)" ]] ; then
	DL_SOURCE="-"
fi
echo -e "Download URL:\t$DL_SOURCE"

# App Store category
if [[ "$TTYPE" == "package" ]] ; then
	MASCAT=$(echo "$MDLS" | /usr/bin/grep -w "kMDItemAppStoreCategory" | /usr/bin/awk -F"= " '{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
	if [[ "$MASCAT" == "" ]] || [[ "$MASCAT" == "(null)" ]] ; then
		MASCAT="-"
	fi
	MASCATID=$(echo "$MDLS" | /usr/bin/grep -w "kMDItemAppStoreCategoryType" | /usr/bin/awk -F"= " '{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
	if [[ "$MASCATID" == "" ]] || [[ "$MASCATID" == "(null)" ]] ; then
		MASCATID=""
	else
		MASCATID="($MASCATID)"
	fi
	echo -e "App Store Category:\t$MASCAT $MASCATID"
fi

# Use count
USECOUNT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemUseCount/{print $2}')
if [[ "$USECOUNT" == "" ]] ; then
	USECOUNT="0"
elif [[ "$USECOUNT" == "(null)" ]] ; then
	USECOUNT="-"
fi
echo -e "Use Count:\t$USECOUNT"

echo ""
echo -e "\t${STANDOUT}macOS Security          ${RESET}"

# macOS security & App Store info
ASSESS=$(/usr/sbin/spctl -v --assess "$FILEPATH" 2>&1)

# Source
SOURCE=$(echo "$ASSESS" | /usr/bin/awk -F"=" '/source=/{print $2}')
if [[ "$SOURCE" == "" ]] || [[ "$SOURCE" == "obsolete resource envelope" ]] ; then
	SPCTL_STATUS="context"
	SOURCE=$(/usr/sbin/spctl -a -t open --context context:primary-signature -v "$FILEPATH" 2>&1 | /usr/bin/awk -F"=" '/source=/{print $2}')
else
	SPCTL_STATUS=""
fi
echo -e "Source:\t$SOURCE"

# MAS receipt & Sandboxing
if [[ "$TTYPE" == "package" ]] ; then
	MAS_RECEIPT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemAppStoreHasReceipt/{print $2}')
	if [[ "$MAS_RECEIPT" == "1" ]] ; then
		APPSTORE="true"
	elif [[ "$MAS_RECEIPT" == "0" ]] ; then
		 APPSTORE="false"
	else
		if [[ -f "$FILEPATH/Contents/_MASReceipt/receipt" ]] ; then
			APPSTORE="true"
		else
			APPSTORE="false"
		fi
	fi
	echo -e "App Store Receipt:\t$APPSTORE"
fi

# Sandboxing
ENTITLEMENTS=$(/usr/bin/codesign -d --entitlements - "$FILEPATH" 2>&1)
SANDBOX=$(echo "$ENTITLEMENTS" | /usr/bin/awk '/com.apple.security.app-sandbox/ {getline;print}')
if [[ $(echo "$SANDBOX" | /usr/bin/grep "true") != "" ]] ; then
	SANDBOX_STATUS="true"
else
	SANDBOX_STATUS="false"
fi
echo -e "Sandboxed:\t$SANDBOX_STATUS"

# Codesigning info
EXEC_PATH_RAW=$(/usr/bin/codesign -d "$FILEPATH" 2>&1)
if [[ $(echo "$EXEC_PATH_RAW" | /usr/bin/grep "not signed") == "" ]] ; then
	if [[ $(echo "$EXEC_PATH_RAW" | /usr/bin/grep "not signed at all") != "" ]] ; then
		CODESIGN_STATUS="false" ; CODESIGN="-" ; CA_CERT="-" ; ICA="-" ; LEAF="-" ; SIGNED="-" ; TEAM_ID="-"
	elif [[ $(echo "$EXEC_PATH_RAW" | /usr/bin/grep "bundle format unrecognized, invalid, or unsuitable") != "" ]] ; then
		CODESIGN_STATUS="false" ; CODESIGN="-" ; CA_CERT="-" ; ICA="-" ; LEAF="-" ; SIGNED="-" ; TEAM_ID="-"
	else
		EXEC_PATH=$(echo "$EXEC_PATH_RAW" | /usr/bin/awk -F"=" '{print $2}' | /usr/bin/head -1)
		CS_ALL=$(/usr/bin/codesign -dvvvv "$EXEC_PATH" 2>&1)
		if [[ $(echo "$CS_ALL" | /usr/bin/grep "Signature=adhoc") != "" ]] ; then
			CODESIGN_STATUS="true"
			CODESIGN="adhoc signature"
			CA_CERT="-"
			ICA="-"
			LEAF="-"
			SIGNED="-"
			TEAM_ID=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/TeamIdentifier/{print $2}')
		else
			SIGNED=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/Timestamp/{print $2}' | /usr/bin/awk '{print $2 " " $1 " " $4 " " $3}')
			[[ "$SIGNED" == "" ]] && SIGNED="no date"
			TEAM_ID=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/TeamIdentifier/{print $2}')
			[[ "$TEAM_ID" == "" ]] && TEAM_ID="-"
			CS_CERTS=$(echo "$CS_ALL" | /usr/bin/grep "Authority")
			CS_COUNT=$(echo "$CS_CERTS" | /usr/bin/wc -l | xargs)
			if [[ "$CS_COUNT" -gt 1 ]] ; then
				CA_CERT=$(echo "$CS_CERTS" | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
				if [[ "$CS_COUNT" == "2" ]] ; then
					LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
					ICA="none"
				elif [[ "$CS_COUNT" == "3" ]] ; then
					LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
					ICA=$(echo "$CS_CERTS" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
				else
					LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
					ICA=$(echo "$CS_CERTS" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
					ICA="$ICA (issuer)"
				fi
				if [[ "$CA_CERT" == "Apple Root CA" ]] ; then
					CODESIGN_STATUS="true"
					CODESIGN="valid certificate"
				else
					CODESIGN_STATUS="true"
					CODESIGN="invalid certificate (issued)"
				fi
			elif [[ "$CS_COUNT" == "1" ]] ; then
				LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
				CODESIGN_STATUS="true"
				CODESIGN="invalid certificate (self-signed)"
				CA_CERT="none"
				ICA="none"
			else
				CODESIGN_STATUS="true"
				CODESIGN="internal error"
				CA_CERT="internal error"
				ICA="internal error"
				LEAF="internal error"
			fi
		fi
	fi
	echo -e "Code Signature:\t$CODESIGN_STATUS"
	echo -e "Code Signing:\t$CODESIGN"
	echo -e "Certificate Authority:\t$CA_CERT"
	echo -e "Intermediate CA:\t$ICA"
	echo -e "Leaf Certificate:\t$LEAF"
	echo -e "Team Identifier:\t$TEAM_ID"
	echo -e "Signed:\t$SIGNED"
else
	echo -e "Code Signature\tfalse"
fi

# Gatekeeper
if [[ "$SPCTL_STATUS" == "context" ]] ; then
	SEC_STATUS=$(/usr/sbin/spctl -a -t open --context context:primary-signature -v "$FILEPATH" 2>&1 | /usr/bin/head -n +1 | /usr/bin/awk -F": " '{print $2}')
else
	SEC_STATUS=$(echo "$ASSESS" | /usr/bin/grep "$FILEPATH:" | /usr/bin/awk -F": " '{print $2}')
	if [[ "$SEC_STATUS" == "" ]] ; then
		SEC_STATUS=$(echo "$ASSESS" | /usr/bin/grep "$BASENAME" | rev | /usr/bin/awk '{print $1}' | rev)
	fi
fi
echo -e "Security:\t$SEC_STATUS"
GATEKEEPER=$(echo "$ASSESS" | /usr/bin/awk -F"=" '/override=/{print $2}')
echo -e "Gatekeeper:\t$GATEKEEPER"

# Quarantine
QUARANTINE=$(/usr/bin/xattr -p com.apple.quarantine "$FILEPATH" 2>&1)
[[ $(echo "$QUARANTINE" | /usr/bin/grep "No such xattr: com.apple.quarantine") != "" ]] && QUARANTINE="false"
echo -e "Quarantine:\t$QUARANTINE"

# read info from bundle's Info.plist
if [[ "$TTYPE" == "package" ]] && [[ "$PLIST_INFO" == "true" ]] ; then

	echo ""
	echo -e "\t${STANDOUT}macOS Bundle Information${RESET}"

	BUNDLE_NAME=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleName/{print $4}')
	[[ "$BUNDLE_NAME" == "" ]] && BUNDLE_NAME="-"
	echo -e "Bundle Name:\t$BUNDLE_NAME"

	echo -e "Bundle Executable:\t$BUNDLE_EXEC"

	if [[ "$BUNDLE_EXEC" != "-" ]] ; then
		EXEC_TYPE=$(/usr/bin/file "$FILEPATH/Contents/MacOS/$BUNDLE_EXEC" | /usr/bin/awk -F": " '{print $2}')
	else
		EXEC_TYPE="-"
	fi
	echo -e "Executable Type:\t$EXEC_TYPE"

	BUNDLE_OSTYPE=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundlePackageType/{print $4}')
	[[ "$BUNDLE_OSTYPE" == "" ]] && BUNDLE_OSTYPE="-"
	echo -e "Bundle Type:\t$BUNDLE_OSTYPE"

	BUNDLE_SIG=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleSignature/{print $4}')
	[[ "$BUNDLE_SIG" == "" ]] && BUNDLE_SIG="-"
	echo -e "Bundle Signature:\t$BUNDLE_SIG"

	PRINCIPAL_CLASS=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/NSPrincipalClass/{print $4}')
	[[ "$PRINCIPAL_CLASS" == "" ]] && PRINCIPAL_CLASS="-"
	echo -e "Principal Class:\t$PRINCIPAL_CLASS"

	SCRIPTABLE=$(echo "$JPLIST" | /usr/bin/awk -F": " '/NSAppleScriptEnabled/{print $2}')
	if [[ "$SCRIPTABLE" == "true," ]] || [[ "$SCRIPTABLE" == "\"YES\"," ]] ; then
		SCRIPTABLE="true"
	else
		SCRIPTABLE="false"
	fi
	echo -e "Scriptable:\t$SCRIPTABLE"

	BUNDLE_VERSION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleShortVersionString/{print $4}')
	[[ "$BUNDLE_VERSION" == "" ]] && BUNDLE_VERSION="-"
	echo -e "Bundle Version:\t$BUNDLE_VERSION"

	BUNDLE_IDENTIFIER=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleIdentifier/{print $4}' | /usr/bin/head -1)
	[[ "$BUNDLE_IDENTIFIER" == "" ]] && BUNDLE_IDENTIFIER="-"
	echo -e "Bundle Identifier:\t$BUNDLE_IDENTIFIER"

	BINFO=$(echo "$JPLIST" | /usr/bin/perl -0777 -CSDA -MJSON::PP -MEncode -E '$p=decode_json(encode_utf8(<>));say $p->{CFBundleGetInfoString}' | xargs)
	[[ "$BINFO" == "" ]] && BINFO="-"
	echo -e "Bundle Info:\t$BINFO"

	COPYRIGHT=$(echo "$JPLIST" | /usr/bin/perl -0777 -CSDA -MJSON::PP -MEncode -E '$p=decode_json(encode_utf8(<>));say $p->{NSHumanReadableCopyright}' | xargs)
	[[ "$COPYRIGHT" == "" ]] && COPYRIGHT="-"
	echo -e "Copyright:\t$COPYRIGHT"

	DEV_REGION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleDevelopmentRegion/{print $4}')
	[[ "$DEV_REGION" == "" ]] && DEV_REGION="-"
	echo -e "Bundle Development Region:\t$DEV_REGION"

	BUILDMACHINE_OSBUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/BuildMachineOSBuild/{print $4}')
	[[ "$BUILDMACHINE_OSBUILD" == "" ]] && BUILDMACHINE_OSBUILD="-"
	echo -e "Build Machine OS Build:\t$BUILDMACHINE_OSBUILD"

	COMPILER=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTCompiler/{print $4}')
	[[ "$COMPILER" == "" ]] && COMPILER="-"
	echo -e "Compiler:\t$COMPILER"

	PLATFORM_BUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/BuildMachineOSBuild/{print $4}')
	[[ "$PLATFORM_BUILD" == "" ]] && PLATFORM_BUILD="-"
	echo -e "Platform Build:\t$PLATFORM_BUILD"

	PLATFORM_VERSION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTPlatformVersion/{print $4}')
	[[ "$PLATFORM_VERSION" == "" ]] && PLATFORM_VERSION="-"
	echo -e "Platform Version:\t$PLATFORM_VERSION"

	SDK_BUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTSDKBuild/{print $4}')
	[[ "$SDK_BUILD" == "" ]] && SDK_BUILD="-"
	echo -e "SDK Build:\t$SDK_BUILD"

	SDK_NAME=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTSDKName/{print $4}')
	[[ "$SDK_NAME" == "" ]] && SDK_NAME="-"
	echo -e "SDK Name:\t$SDK_NAME"

	XCODE=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTXcode/{print $4}')
	XCODE_VERSION=$(echo "$XCODE" | /usr/bin/head -n 1)
	[[ "$XCODE_VERSION" == "" ]] && XCODE_VERSION="-"
	XCODE_BUILD=$(echo "$XCODE" | /usr/bin/tail -n +2)
	[[ "$XCODE_BUILD" == "" ]] && XCODE_BUILD="-"
	echo -e "XCode:\t$XCODE_VERSION"
	echo -e "Xcode Build:\t$XCODE_BUILD"

	MINIMUM_OS=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/LSMinimumSystemVersion/{print $4}')
	[[ "$MINIMUM_OS" == "" ]] && MINIMUM_OS="-"
	echo -e "Minimum System Version:\t$MINIMUM_OS"

	REQUIRED=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/OSBundleRequired/{print $4}')
	[[ "$REQUIRED" == "" ]] && REQUIRED="-"
	echo -e "Required:\t$REQUIRED"

fi

# directory contents
if [[ "$FTYPEX" == "Directory" ]] ; then

	echo ""
	echo -e "\t${STANDOUT}File Contents           ${RESET}"

	FULL_LIST=$(echo "$TOTAL_LIST" | /usr/bin/sed '/^'"$SEDPATH"'/d' | /usr/bin/awk 'NF>=11 {print substr($0, index($0,$2))}' | /usr/bin/sed -e '/\ \.$/d' -e '/\ \.\.$/d' -e '/^.\//d')
	if [[ "$FULL_LIST" != "" ]] ; then

		RES_NUMBER=$(echo "$TOTAL_LIST" | /usr/bin/sed '/^'"$SEDPATH"'/d' | /usr/bin/grep "com.apple.ResourceFork" | /usr/bin/wc -l | xargs)

		ITEM_COUNT=$(echo "$FULL_LIST" | /usr/bin/wc -l | xargs)
		ITEM_FULL=$(echo "$ITEM_COUNT + $RES_NUMBER" | /usr/bin/bc -l)
		echo -e "Contains:\t$ITEM_FULL items"

		FTYPES_ALL=$(echo "$FULL_LIST" | /usr/bin/awk '{print $1}' | /usr/bin/cut -c 1)
		FTYPES_COUNT=$(echo "$FTYPES_ALL" | /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{print $2 ":\t" $1}' \
		| /usr/bin/sed -e '/^-:/s/-:/Files:/g' -e '/^d:/s/d:/Directories:/g' -e '/^l:/s/l:/Symbolic Links:/g' -e '/^p:/s/p:/Pipes\/FIFO:/g' -e '/^c:/s/c:/Character Devices:/g' -e '/^s:/s/s:/Sockets:/g' -e '/^b:/s/b:/Blocks:/g' -e '/^w:/s/w:/Whiteouts:/g')
		echo -e "$FTYPES_COUNT"

		[[ "$RES_NUMBER" != "0" ]] && echo -e "Resource Forks:\t$RES_NUMBER"

		ALIASES=$(/usr/bin/mdfind -onlyin "$FILEPATH" "kMDItemContentType == 'com.apple.alias-file'" 2>/dev/null | /usr/bin/wc -l | xargs)
		[[ "$ALIASES" != "0" ]] && echo -e "Aliases:\t$ALIASES"

		INV_LIST=$(echo "$FULL_LIST" | /usr/bin/awk '{print $10}')
		INV_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\." | /usr/bin/wc -l | xargs)
		[[ "$INV_CONTAIN" == "" ]] && INV_CONTAIN="0"
		DSSTORE_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.DS_Store" | /usr/bin/wc -l | xargs)
		[[ "$DSSTORE_CONTAIN" == "" ]] && DSSTORE_CONTAIN="0"
		LOCAL_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.localized" | /usr/bin/wc -l | xargs)
		[[ "$LOCAL_CONTAIN" == "" ]] && LOCAL_CONTAIN="0"
		DOTHIDDEN_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.hidden" | /usr/bin/wc -l | xargs)
		[[ "$DOTHIDDEN_CONTAIN" == "" ]] && DOTHIDDEN_CONTAIN="0"
		TM_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.com.apple.timemachine.supported" | /usr/bin/wc -l | xargs)
		[[ "$TM_CONTAIN" == "" ]] && DOTHIDDEN_CONTAIN="0"
		OTHER_INV=$(echo "$INV_CONTAIN - $DSSTORE_CONTAIN - $LOCAL_CONTAIN - $DOTHIDDEN_CONTAIN - $TM_CONTAIN" | /usr/bin/bc -l)
		[[ "$OTHER_INV" == "" ]] && OTHER_INV="0"
		if [[ "$OTHER_INV" == "$INV_CONTAIN" ]] && [[ "$INV_CONTAIN" != "0" ]] ; then
			echo -e "invisible:\t$INV_CONTAIN"
		else
			[[ "$INV_CONTAIN" != "0" ]] && echo -e "invisible:\t$INV_CONTAIN"
			[[ "$DSSTORE_CONTAIN" != "0" ]] && echo -e ".DS_Store:\t$DSSTORE_CONTAIN"
			[[ "$LOCAL_CONTAIN" != "0" ]] && echo -e ".localized:\t$LOCAL_CONTAIN"
			[[ "$DOTHIDDEN_CONTAIN" != "0" ]] && echo -e ".hidden:\t$DOTHIDDEN_CONTAIN"
			[[ "$TM_CONTAIN" != "0" ]] && echo -e ".timemachine.supported:\t$TM_CONTAIN"
			[[ "$OTHER_INV" != "0" ]] && echo -e "invisible (other):\t$OTHER_INV"
		fi

		CHFLAGS_ALL=$(echo "$FULL_LIST" | /usr/bin/awk '{print $5}')
		FLAGS_COUNT=$(echo "$CHFLAGS_ALL" | /usr/bin/grep -v "-" | /usr/bin/awk '{gsub(","," ");print}'| /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{print $2 ":\t" $1}')
		[[ "$FLAGS_COUNT" != "" ]] && echo -e "$FLAGS_COUNT"

		GDE=$(which gde)
		if [[ "$GDE" != "" ]] && [[ "$GDE" != "gde not found" ]] && [[ "$FTYPEX" == "Directory" ]] ; then
			ROOTLIST=$(ls -lA "$FILEPATH")
			ROOTCOUNT=$(( $(echo "$ROOTLIST" | /usr/bin/wc -l | xargs) - 1 ))
			RGDECOUNT=$(( $("$GDE" "$FILEPATH" | /usr/bin/wc -l | xargs) - 9 ))
			RCLOAKED=$(( $RGDECOUNT - $ROOTCOUNT ))
			RFILECOUNT=$(echo "$ROOTLIST" | /usr/bin/grep -v "^d" | /usr/bin/wc -l | xargs)
			DIRCOUNT=$(echo "$FTYPES_COUNT" | /usr/bin/awk -F":" '/Directories:/{print $2}' | xargs)
			[[ "$DIRCOUNT" == "" ]] && DIRCOUNT="0"
			FILECOUNT=$(( $ITEM_COUNT - $DIRCOUNT  - $RFILECOUNT + 1 ))
			RDIRCOUNT=$(echo "$ROOTLIST" | /usr/bin/grep "^d" | /usr/bin/wc -l | xargs)
			DIRLIST=$(echo "$TOTAL_LIST" | /usr/bin/grep "$FILEPATH" | /usr/bin/sed 's/.$//')
			GDESUBTRACT=$(( $DIRCOUNT * 9 ))

			GDESUBCOUNT="0"
			while read -r SUBFOLDER
			do
				GDESUB_ADD=$("$GDE" "$SUBFOLDER" | /usr/bin/wc -l | xargs)
				GDESUBCOUNT=$(( $GDESUBCOUNT + $GDESUB_ADD ))
			done < <(echo "$DIRLIST")
			CLOAKCOUNT=$(( $GDESUBCOUNT - $GDESUBTRACT - $FILECOUNT - $DIRCOUNT + $RDIRCOUNT + $RCLOAKED ))
			[[ "$CLOAKCOUNT" -le 0 ]] && CLOAKCOUNT="-"
			echo -e "cloaked:\t$CLOAKCOUNT"
		fi

		ACESALL=$(echo "$TOTAL_LIST" | /usr/bin/awk 'NF<=2' | /usr/bin/grep -v "com.apple.ResourceFork" | /usr/bin/sed -e '/^'"$SEDPATH"'/d' -e '/^total /d' -e '/^$/d')
		if [[ "$ACESALL" != "" ]] ; then
			ACESTOTAL=$(echo "$ACESALL" | /usr/bin/wc -l | xargs)
			echo -e "ACE Total:\t$ACESTOTAL"
		fi

	else
		echo -e "Contains:\t0 items"
	fi

fi

# user information

echo ""
echo -e "\t${STANDOUT}User Information        ${RESET}"

XUID=$(/usr/bin/id -u)
XUGROUP=$(/usr/bin/id -gn)
XUGROUPID=$(/usr/bin/id -g)
echo -e "Effective User & Group:\t$EXECUSER:$XUGROUP ($XUID:$XUGROUPID)"

echo -e "Real User & Group:\t$ACCOUNT:$UGROUP ($USERID:$UGROUPID)"

GROUP_COUNT="0"
for USERGROUP in ${USERGROUPS}
do
	(( GROUP_COUNT++ ))
	USERGROUPN=$(echo "$USERGROUPSN" | /usr/bin/awk '{print $'"$GROUP_COUNT"'}')
	echo -e "Group $GROUP_COUNT:\t$USERGROUP ($USERGROUPN)"
done

# volume info

echo ""
echo -e "\t${STANDOUT}Volume Information      ${RESET}"

echo -e "File System:\t$FSYSTEM"

MPOINT=$(echo "$FPDF" | /usr/bin/awk '{ for(i=9; i<=NF; i++) printf "%s",$i (i==NF?ORS:OFS) }')
echo -e "Mount Point:\t$MPOINT"

MPLIST=$(ls -dl "$MPOINT")
FSOWNER=$(echo "$MPLIST" | /usr/bin/awk '{print $3}')
[[ "$FSOWNER" == "" ]] && FSOWNER="-"
FSGROUP=$(echo "$MPLIST" | /usr/bin/awk '{print $4}')
[[ "$FSGROUP" == "" ]] && FSGROUP="-"
FSOWNERN=$(/usr/bin/id -u "$FSOWNER")
[[ "$FSOWNERN" == "" ]] && FSOWNERN="-"
FSGROUPN=$(/usr/bin/id -g "$FSOWNER")
[[ "$FSGROUPN" == "" ]] && FSGROUPN="-"
echo -e "File System Owner:\t$FSOWNER:$FSGROUP ($FSOWNERN:$FSGROUPN)"

FSTYPE=$(echo "$DISKUTIL" | /usr/bin/awk -F":" '/Type \(Bundle\)/{print $2}' | xargs)
[[ "$FSTYPE" == "" ]] && FSTYPE="-"
echo -e "File System Type:\t$FSTYPE"

IUSED=$(echo "$FPDF" | /usr/bin/awk '{print $6}')
IFREE=$(echo "$FPDF" | /usr/bin/awk '{print $7}')
ITOTAL=$(( $IUSED + $IFREE ))
ITOTAL=$(echo "$ITOTAL" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
IFREE=$(echo "$IFREE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
IUSED=$(echo "$IUSED" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
IPERC=$(echo "$FPDF" | /usr/bin/awk '{print $8}')
echo -e "Available Inodes:\t$ITOTAL"
echo -e "Free Inodes:\t$IFREE"
echo -e "Used Inodes:\t$IUSED ($IPERC)"

if [[ "$SECTORSIZE" != "0" ]] ; then
	echo -e "Device Block Size:\t$SECTORSIZE B"
else
	echo -e "Device Block Size:\t$SECTORSIZEC B$SOD_ADD"
fi

BLOCKSIZE=$(echo "$STATS" | /usr/bin/awk '{print $13}' | /usr/bin/awk -F= '{print $2}')
echo -e "Allocation Block Size:\t$BLOCKSIZE B"

BUSED=$(echo "$FPDF" | /usr/bin/awk '{print $3}')
BUSED=$(echo "$BUSED" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
BFREE=$(echo "$FPDF" | /usr/bin/awk '{print $4}')
BFREE=$(echo "$BFREE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
BTOTAL=$(echo "$FPDF" | /usr/bin/awk '{print $2}')
BTOTAL=$(echo "$BTOTAL" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
BPERC=$(echo "$FPDF" | /usr/bin/awk '{print $5}')
echo -e "Available Blocks:\t$BTOTAL"
echo -e "Free Blocks:\t$BFREE"
echo -e "Used Blocks:\t$BUSED ($BPERC)"

FSPERSONA=$(echo "$DISKUTIL" | /usr/bin/awk -F":" '/File System Personality/{print $2}' | xargs)
[[ "$FSPERSONA" == "" ]] && FSPERSONA="-"
echo -e "File System Personality:\t$FSPERSONA"

JOURNAL=$(echo "$DISKUTIL" | /usr/bin/awk -F":" '/Journal:/{print $2}' | xargs)
[[ "$JOURNAL" == "" ]] && JOURNAL="-"
echo -e "Journal:\t$JOURNAL"

VOL_NAME=$(echo "$DISKUTIL" | /usr/bin/awk -F":" '/Volume Name/{print $2}' | xargs)
[[ "$VOL_NAME" == "" ]] && VOL_NAME="-"
echo -e "Volume Name:\t$VOL_NAME"

if [[ "$VOL_NAME" == "-" ]] ; then
	SMB=$(/usr/bin/smbutil statshares -m "$MPOINT" 2>/dev/null)
	if [[ "$SMB" != "" ]] ; then
		SMBSERVER=$(echo "$SMB" | /usr/bin/awk '/SERVER_NAME/{print substr($0, index($0,$2))}')
		echo -e "SMB Server:\t$SMBSERVER"
		SMBSERVER=$(echo "$SMBSERVER" | /usr/bin/awk '{gsub(" ","%20");print}')
		EXTVOLNAME=$(echo "$FSYSTEM" | /usr/bin/awk -F"$SMBSERVER/" '{print $2}')
		echo -e "Server Volume Name:\t$EXTVOLNAME"
	fi
fi

# check if Spotlight is enabled
MDUTIL=$(/usr/bin/mdutil -s "$MPOINT" 2>&1 | /usr/bin/tail -n 1)
if [[ $(echo "$MDUTIL" | /usr/bin/grep "Indexing enabled.") != "" ]] ; then
	SL_STATUS="enabled"
else
	SL_STATUS="disabled"
fi
echo -e "Spotlight:\t$SL_STATUS"

# macOS information

echo ""
echo -e "\t${STANDOUT}macOS Information       ${RESET}"

MACOSP=$(echo "$MACOS" | /usr/bin/awk -F: '/ProductName/{print $2}' | xargs)
echo -e "Product Name:\t$MACOSP"

echo -e "Product Version:\t$MACOSV"

MACOSB=$(echo "$MACOS" | /usr/bin/awk -F: '/BuildVersion/{print $2}' | xargs)
echo -e "Build Version:\t$MACOSB"

echo -e "System Integrity Protection:\t$SIPSTATUS"

SYSCTL=$(/usr/sbin/sysctl -n kern.ostype kern.osrelease kern.osrevision kern.uuid | xargs)

KERNEL=$(echo "$SYSCTL" | /usr/bin/awk '{print $1,$2 " (" $3 ")"}')
echo -e "Kernel:\t$KERNEL"

UUID=$(echo "$SYSCTL" | /usr/bin/awk '{print $4}')
echo -e "UUID:\t$UUID"

done

exit
