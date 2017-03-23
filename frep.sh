#!/bin/bash

# frep v0.9.3 beta
# macOS File Reporter

LANG=en_US.UTF-8

# set -x
# PS4=':$LINENO+'

# calculate human readable (binary)
humanbinary () {
    echo "$1" | /usr/bin/awk 'function human(x) {
		s=" B   KiB MiB GiB TiB EiB PiB YiB ZiB"
    	while (x>=1024 && length(s)>1)
        	{x/=1024; s=substr(s,5)}
    	s=substr(s,1,4)
    	xf=(s==" B  ")?"%5d   ":"%8.2f"
    	return sprintf( xf"%s\n", x, s)
    }
	{gsub(/^[0-9]+/, human($1)); print}' | xargs
}

# calculate human readable (decimal)
humandecimal () {
    echo "$1" | /usr/bin/awk 'function human(x) {
		s=" B    KB  MB  GB  TB  EB  PB  YB  ZB"
    	while (x>=1000 && length(s)>1)
        	{x/=1000; s=substr(s,5)}
    	s=substr(s,1,4)
    	xf=(s==" B  ")?"%5d   ":"%8.2f"
    	return sprintf( xf"%s\n", x, s)
    }
	{gsub(/^[0-9]+/, human($1)); print}' | xargs
}

for FILEPATH in "$@"
do

tabs 30

echo "*** BEGIN FILE REPORT ***"
SEDPATH=$(echo "$FILEPATH" | /usr/bin/awk '{gsub("/","\\/");print}')

# stat first
STAT=$(/usr/bin/stat "$FILEPATH")
STATS=$(/usr/bin/stat -s "$FILEPATH")

# file & volume info
BASENAME=$(/usr/bin/basename "$FILEPATH")
echo -e "Basename:\t$BASENAME"

DIRNAME=$(/usr/bin/dirname "$FILEPATH")
echo -e "Path:\t$DIRNAME"

FPDF=$(/bin/df "$FILEPATH" | tail -1)
FSYSTEM=$(echo "$FPDF" | /usr/bin/awk '{print $1}')
echo -e "Filesystem:\t$FSYSTEM"

MPOINT=$(echo "$FPDF" | /usr/bin/awk '{print $9}')
echo -e "Mount Point:\t$MPOINT"

VOL_NAME=$(/usr/sbin/diskutil info "$FSYSTEM" | /usr/bin/awk -F":" '/Volume Name/{print $2}' | xargs)
[[ "$VOL_NAME" == "" ]] && VOL_NAME="n/a"
echo -e "Volume Name:\t$VOL_NAME"

# check if Spotlight is enabled
MDUTIL=$(/usr/bin/mdutil -s "$MPOINT" 2>&1 | tail -n 1)
if [[ $(echo "$MDUTIL" | /usr/bin/grep "Indexing enabled.") != "" ]] ; then
	SL_STATUS="enabled"
else
	SL_STATUS="disabled"
fi
echo -e "Spotlight:\t$SL_STATUS"

# Shared folder
SHARE_INFO=$(/usr/bin/dscl . -read SharePoints/"$BASENAME" 2>&1)
if [[ $(echo "$SHARE_INFO" | /usr/bin/grep "$FILEPATH") != "" ]] ; then
	SHARED="TRUE"
else
	SHARED="FALSE"
fi
echo -e "Shared:\t$SHARED"

# file type (Unix)
LISTING=$(ls -aldO "$FILEPATH")
[[ $(echo "$LISTING" | /usr/bin/grep "^-") != "" ]] && FTYPEX="File"
[[ $(echo "$LISTING" | /usr/bin/grep "^d") != "" ]] && FTYPEX="Directory"
[[ $(echo "$LISTING" | /usr/bin/grep "^l") != "" ]] && FTYPEX="Symbolic Link"
[[ $(echo "$LISTING" | /usr/bin/grep "^p") != "" ]] && FTYPEX="Pipe/FIFO"
[[ $(echo "$LISTING" | /usr/bin/grep "^c") != "" ]] && FTYPEX="Character Device"
[[ $(echo "$LISTING" | /usr/bin/grep "^s") != "" ]] && FTYPEX="Socket"
[[ $(echo "$LISTING" | /usr/bin/grep "^b") != "" ]] && FTYPEX="Block"
[[ $(echo "$LISTING" | /usr/bin/grep "^w") != "" ]] && FTYPEX="Whiteout"
echo -e "File Type:\t$FTYPEX"

# symlink target
if [[ "$FTYPEX" == "Symbolic Link" ]] ; then
	SLTARGET="-> $(/usr/bin/stat -f '%Y' "$FILEPATH")"
	echo -e "Reference:\t$SLTARGET"
fi

# sticky bit
STICKY="FALSE"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == *"t" ]] && STICKY="TRUE"
echo -e "Sticky Bit:\t$STICKY"

# SUID/GUID
SUIDSET="not set" ; GUIDSET="not set"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"s"* ]] && SUIDSET="enabled (ux)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"S"* ]] && SUIDSET="enabled"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"s"* ]] && GUIDSET="enabled (gx)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"S"* ]] && GUIDSET="enabled"
echo -e "GUID:\t$GUIDSET"
echo -e "SUID:\t$SUIDSET"

# file type (specific)
FILETYPE=$(/usr/bin/file "$FILEPATH" | /usr/bin/awk -F": " '{print $2}')
echo -e "File Content:\t$FILETYPE"

# check if bundle/directory
if [[ "$FTYPEX" == "Directory" ]] ; then
	PATH_TYPE=$(/usr/bin/mdls -name kMDItemContentTypeTree "$FILEPATH" | /usr/bin/grep -e "bundle")
	if [[ "$PATH_TYPE" != "" ]] ; then
		TTYPE="bundle"
		BUNDLE_INFO="TRUE"
	else
		BUNDLE_INFO="FALSE"
	fi
else
	BUNDLE_INFO="FALSE"
fi
echo -e "Bundle:\t$BUNDLE_INFO"

### method to read the default "open with" application for a file?

# MDLS
MDLS=$(/usr/bin/mdls "$FILEPATH" 2>/dev/null)

# content type
CONTENT_TYPE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemContentType/{print $2}' | /usr/bin/head -n 1 | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$CONTENT_TYPE" == "" ]] || [[ "$CONTENT_TYPE" == "(null)" ]] ; then
	CONTENT_TYPE="n/a"
fi
echo -e "Uniform Type Identifier:\t$CONTENT_TYPE"

# kind
KIND=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemKind/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$KIND" == "" ]] || [[ "$KIND" == "(null)" ]] ; then
	KIND="n/a"
fi
echo -e "Kind:\t$KIND"

# Finder: type
TYPECODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSTypeCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$TYPECODE" == "(null)" ]] || [[ "$TYPECODE" == "" ]] ; then
	TYPECODE="n/a"
fi
echo -e "Type:\t$TYPECODE"

# Finder: creator
CREATORCODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSCreatorCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$CREATORCODE" == "(null)" ]] || [[ "$CREATORCODE" == "" ]] ; then
	CREATORCODE="n/a"
fi
echo -e "Creator\t$CREATORCODE"

# OpenMeta
TAGS=$(/usr/bin/mdls -raw -name kMDItemUserTags "$FILEPATH" | /usr/bin/sed -e '1,1d' -e '$d' | xargs)
if [[ "$TAGS" == "(null)" ]] || [[ "$TAGS" == "" ]] ; then
	TAGS="n/a"
fi
echo -e "OpenMeta Tags:\t$TAGS"

# Finder comment
FCOMMENT=$(/usr/bin/mdls -raw -name kMDItemFinderComment "$FILEPATH" 2>&1)
if [[ "$FCOMMENT" == "(null)" ]] || [[ "$FCOMMENT" == "" ]] ; then
	FCOMMENT="n/a"
fi
echo -e "Finder Comment:\t$FCOMMENT"

# extension hidden in Finder?
HIDDENEXT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSIsExtensionHidden/{print $2}')
if [[ "$HIDDENEXT" == "1" ]] ; then
	HIDDENEXT="TRUE"
else
	HIDDENEXT="FALSE"
fi
echo -e "Hidden Extension:\t$HIDDENEXT"

# Invisible (true dot file, not macOS "hidden" flag)
if [[ "$BASENAME" == "."* ]] ; then
	TINV="TRUE"
else
	TINV="FALSE"
fi
echo -e "Invisible:\t$TINV"

# Unix file flags
CHFLAGS=$(echo "$LISTING" | /usr/bin/awk '{print $5}' | /usr/bin/awk '{gsub(","," ");print}')
ROOTFLAGS=$(echo "$CHFLAGS" | /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{gsub("-","none");print $2}' | xargs)
echo -e "Flags:\t$ROOTFLAGS"

# actual disk usage size
DISK_USAGE=$(/usr/bin/du -k -d 0 "$FILEPATH" | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}')
DU_SIZE=$(echo "$DISK_USAGE * 1024" | /usr/bin/bc -l)
DU_SIZE_MB=$(humandecimal "$DU_SIZE")
DU_SIZE_MIB=$(humanbinary "$DU_SIZE")
DU_SIZE_T=$(echo "$DU_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
DU_SIZE_INFO="$DU_SIZE_T B ($DU_SIZE_MB, $DU_SIZE_MIB)"
echo -e "Disk Usage:\t$DU_SIZE_INFO"

# physical size as reported by macOS (mdls) -- might be larger than actual disk usage (virtual size ignoring HFS+ compression)
PHYSICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemPhysicalSize/{print $2}')
if [[ "$PHYSICAL_SIZE" == "" ]] || [[ "$PHYSICAL_SIZE" == "(null)" ]] ; then
	PHYS="false"
	PHYSICAL_SIZE_INFO="n/a"
else
	PHYS="true"
	PHYSICAL_SIZE_MB=$(humandecimal "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_MIB=$(humanbinary "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_T=$(echo "$PHYSICAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	PHYSICAL_SIZE_INFO="$PHYSICAL_SIZE_T B ($PHYSICAL_SIZE_MB, $PHYSICAL_SIZE_MIB)"
fi
echo -e "Physical Size:\t$PHYSICAL_SIZE_INFO"

# logical size as reported by macOS (mdls) -- should be the same as total byte count
LOGICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLogicalSize/{print $2}')
if [[ "$LOGICAL_SIZE" == "" ]] || [[ "$LOGICAL_SIZE" == "(null)" ]] ; then
	LOGICAL="false"
	LOGICAL_SIZE_INFO="n/a"
else
	LOGICAL_SIZE_MB=$(humandecimal "$LOGICAL_SIZE")
	LOGICAL_SIZE_MIB=$(humanbinary "$LOGICAL_SIZE")
	LOGICAL_SIZE_T=$(echo "$LOGICAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	LOGICAL_SIZE_INFO="$LOGICAL_SIZE_T B ($LOGICAL_SIZE_MB, $LOGICAL_SIZE_MIB)"
fi
echo -e "Logical Size:\t$LOGICAL_SIZE_INFO"

# file system size as reported by FS to macOS
FS_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSSize/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$FS_SIZE" == "" ]] || [[ "$FS_SIZE" == "(null)" ]] ; then
	FS_SIZE_INFO="n/a"
else
	FS_SIZE_MB=$(humandecimal "$FS_SIZE")
	FS_SIZE_MIB=$(humanbinary "$FS_SIZE")
	FS_SIZE_T=$(echo "$FS_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	FS_SIZE_INFO="$FS_SIZE_T B ($FS_SIZE_MB, $FS_SIZE_MIB)"
fi
echo -e "File System Size:\t$FS_SIZE_INFO"

# total list
TOTAL_LIST=$(ls -RalO@ "$FILEPATH" | /usr/bin/sed -e '/^$/d' -e '/^'"$SEDPATH"'/d')
SIZE_LIST=$(echo "$TOTAL_LIST" | /usr/bin/awk 'NF>2')

# data size (total byte count)
DATA_SIZE=$(echo "$SIZE_LIST" | /usr/bin/grep -v '^d' | /usr/bin/awk '{total += $6} END {printf "%.0f", total}')
DATA_SIZE_MB=$(humandecimal "$DATA_SIZE")
DATA_SIZE_MIB=$(humanbinary "$DATA_SIZE")
DATA_SIZE_T=$(echo "$DATA_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
DATA_SIZE_INFO="$DATA_SIZE_T B ($DATA_SIZE_MB, $DATA_SIZE_MIB)"
echo -e "Data Size:\t$DATA_SIZE_INFO" # only the readable data parts of the total byte count

# Resource fork size
EXTRA_LIST=$(echo "$TOTAL_LIST" | /usr/bin/awk 'NF<=2' | /usr/bin/sed -e '/^total /d' -e '/^'"$SEDPATH"'/d')
RES_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
if [[ "$RES_SIZE" != "" ]] && [[ "$RES_SIZE" != "0" ]]; then
	RES_SIZE_MB=$(humandecimal "$RES_SIZE")
	RES_SIZE_MIB=$(humanbinary "$RES_SIZE")
	RES_SIZE_T=$(echo "$RES_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	RES_SIZE_INFO="$RES_SIZE_T B ($RES_SIZE_MB, $RES_SIZE_MIB)"
else
	RES_SIZE="0"
	RES_SIZE_INFO="0 B"
fi
echo -e "Resource Forks:\t$RES_SIZE_INFO" # only the resource fork parts of the total byte count

# apparent size (stat total + resource forks)
APPARENT_SIZE=$(echo "$RES_SIZE + $DATA_SIZE" | /usr/bin/bc -l)
APPARENT_SIZE_MB=$(humandecimal "$APPARENT_SIZE")
APPARENT_SIZE_MIB=$(humanbinary "$APPARENT_SIZE")
APPARENT_SIZE_T=$(echo "$APPARENT_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
APPARENT_SIZE_INFO="$APPARENT_SIZE_T B ($APPARENT_SIZE_MB, $APPARENT_SIZE_MIB)"
echo -e "Apparent Data Size:\t$APPARENT_SIZE_INFO"

# Xattr size
XATTR_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep -v "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {printf "%.0f", total}')
if [[ "$XATTR_SIZE" != "" ]] && [[ "$XATTR_SIZE" != "0" ]] ; then
	XATTR_SIZE_MB=$(humandecimal "$XATTR_SIZE")
	XATTR_SIZE_MIB=$(humanbinary "$XATTR_SIZE")
	XATTR_SIZE_T=$(echo "$XATTR_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
	XATTR_SIZE_INFO="$XATTR_SIZE_T B ($XATTR_SIZE_MB, $XATTR_SIZE_MIB)"
else
	XATTR_SIZE="0"
	XATTR_SIZE_INFO="0 B"
fi
echo -e "Extended Attributes:\t$XATTR_SIZE_INFO"

# total size (data+resources+xattr) = total size
TOTAL_SIZE=$(echo "$APPARENT_SIZE + $XATTR_SIZE" | /usr/bin/bc -l)
TOTAL_SIZE_MB=$(humandecimal "$TOTAL_SIZE")
TOTAL_SIZE_MIB=$(humanbinary "$TOTAL_SIZE")
TOTAL_SIZE_T=$(echo "$TOTAL_SIZE" | /usr/bin/awk '{printf("%'"'"'d\n",$1);}')
TOTAL_SIZE_INFO="$TOTAL_SIZE_T B ($TOTAL_SIZE_MB, $TOTAL_SIZE_MIB)"
echo -e "Total Data Size:\t$TOTAL_SIZE_INFO"

# root size
if [[ "$FTYPEX" == "Directory" ]] ; then
	STATSIZE_B=$(echo "$STAT" | /usr/bin/awk '{print $8}')
	STATSIZE_MB=$(humandecimal "$STATSIZE_B")
	STATSIZE_MIB=$(humanbinary "$STATSIZE_B")
	STATSIZE="$STATSIZE_B B ($STATSIZE_MB, $STATSIZE_MIB)"
	echo -e "Root Object Data Size:\t$STATSIZE"

	ROOT_LIST=$(ls -laO@ "$FILEPATH" | /usr/bin/tail -n +3)
	CUTLINE=$(echo "$ROOT_LIST" | /usr/bin/grep "\ \.\.")
	XTRASIZE="0"
	while read -r EXTRA
	do
		if [[ "$EXTRA" == "$CUTLINE" ]] ; then
			break
		else
			XTRA_ADD=$(echo "$EXTRA" | /usr/bin/awk '{print $2}')
			XTRASIZE=$(echo "$XTRASIZE + $XTRA_ADD" | /usr/bin/bc -l)
		fi
	done < <(echo "$ROOT_LIST")
	if [[ "$XTRASIZE" != "0" ]] ; then
		XTRASIZE_MB=$(humandecimal "$XTRASIZE")
		XTRASIZE_MIB=$(humanbinary "$XTRASIZE")
		XTRASIZE_INFO="$XTRASIZE B ($XTRASIZE_MB, $XTRASIZE_MIB)"
	else
		XTRASIZE_INFO="0 B"
	fi
	echo -e "Root Object Xattr:\t$XTRASIZE_INFO"

	ROOT_TOTAL=$(echo "$STATSIZE_B + $XTRASIZE" | /usr/bin/bc -l)
	ROOT_TOTAL_MB=$(humandecimal "$ROOT_TOTAL")
	ROOT_TOTAL_MIB=$(humanbinary "$ROOT_TOTAL")
	ROOT_TSIZE="$ROOT_TOTAL B ($ROOT_TOTAL_MB, $ROOT_TOTAL_MIB)"
	echo -e "Root Object Total Size:\t$ROOT_TSIZE"
fi

# stat info output
INODE_DEV=$(echo "$STAT" | /usr/bin/awk '{print $1}')
echo -e "Device:\t$INODE_DEV"

INODE=$(echo "$STAT" | /usr/bin/awk '{print $2}')
echo -e "Inode:\t$INODE"

RDEV=$(echo "$STAT" | /usr/bin/awk '{print $7}')
echo -e "Device Type:\t$RDEV"

BLOCKSNO=$(echo "$STATS" | /usr/bin/awk '{print $14}' | /usr/bin/awk -F= '{print $2}')
echo -e "Blocks:\t$BLOCKSNO"

BLOCKSIZE=$(echo "$STATS" | /usr/bin/awk '{print $13}' | /usr/bin/awk -F= '{print $2}')
echo -e "Optimal Block Size:\t$BLOCKSIZE B"

FLAGSA=$(echo "$STATS" | /usr/bin/awk '{print $15}' | /usr/bin/awk -F= '{print $2}')
FLAGSB=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $9}' | /usr/bin/awk '{print $3}')
USERFLAGS="$FLAGSB ($FLAGSA)"
echo -e "System/User Flags:\t$USERFLAGS"

FILEGENNO=$(/usr/bin/stat -f '%v')
echo -e "File Generation Number:\t$FILEGENNO"

MODEA=$(/usr/bin/stat -f '%A' "$FILEPATH")
MODEB=$(echo "$STATS" | /usr/bin/awk '{print $3}' | /usr/bin/awk -F= '{print $2}')
MODE="$MODEB ($MODEA)"
echo -e "Mode:\t$MODE"

HARDLINKS=$(echo "$STAT" | /usr/bin/awk '{print $4}')
echo -e "Links:\t$HARDLINKS"

PERMISSIONS=$(echo "$STAT" | /usr/bin/awk '{print $3}')
echo -e "Permissions:\t$PERMISSIONS"

UIDN=$(echo "$STAT" | /usr/bin/awk '{print $5}')
UIDNO=$(echo "$STATS" | /usr/bin/awk '{print $5}' | /usr/bin/awk -F= '{print $2}')
echo -e "Owner:\t$UIDN ($UIDNO)"

GIDN=$(echo "$STAT" | /usr/bin/awk '{print $6}')
GIDNO=$(echo "$STATS" | /usr/bin/awk '{print $6}' | /usr/bin/awk -F= '{print $2}')
echo -e "Group:\t$GIDN ($GIDNO)"

# ACL/ACE
if [[ "$FTYPEX" == "Directory" ]] ; then
	ACE_LIST=$(ls -lae "$FILEPATH" | /usr/bin/sed -n '/^-.* \..*$/!p' | /usr/bin/sed -n '/\ \.$/,$p' | /usr/bin/tail -n +2)
else
	ACE_LIST=$(ls -lae "$FILEPATH" | /usr/bin/tail -n +2)
fi

ACL=""
if [[ "$FTYPEX" == "Directory" ]] ; then
	CUTLINE=$(echo "$ACE_LIST" | /usr/bin/grep "\ \.\.")
	while read -r ACE
	do
		if [[ "$ACE" == "$CUTLINE" ]] ; then
			break
		else
			ACE=$(echo "$ACE" | /usr/bin/awk -F": " '{print substr($0, index($0,$2))}')
			ACL=$(echo "$ACL
$ACE")
		fi
	done < <(echo "$ACE_LIST")
else
	while read -r ACE
	do
		ACE=$(echo "$ACE" | /usr/bin/awk -F": " '{print substr($0, index($0,$2))}')
		ACL=$(echo "$ACL
$ACE")
	done < <(echo "$ACE_LIST")
fi

ACL=$(echo "$ACL" | /usr/bin/tail -n +2)
if [[ "$ACL" == "" ]] ; then
	echo -e "ACE:\tnone"
else
	ACE_COUNT="0"
	while read -r ACE
	do
		echo -e "ACE $ACE_COUNT:\t$ACE"
		((ACE_COUNT++))
	done < <(echo "$ACL")
fi

# dates
BIRTHTIME=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $8}')
echo -e "Created:\t$BIRTHTIME"

LASTSTATUSCHANGE=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $6}')
echo -e "Changed:\t$LASTSTATUSCHANGE"

LASTMODIFY=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $4}')
echo -e "Modified:\t$LASTMODIFY"

LASTACCESS=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $2}')
echo -e "Accessed:\t$LASTACCESS"

LASTUSED=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLastUsedDate/{print $2}')
if [[ "$LASTUSED" == "" ]] || [[ "$LASTUSED" == "(null)" ]] ; then
	LASTUSED="n/a"
else
	LASTUSED=$(/bin/date -f'%F %T %z' -j "$LASTUSED" | /usr/bin/awk '{print $2 " " $3 " " $4 " " $6}')
fi
echo -e "Used:\t$LASTUSED"

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
if [[ "$BUNDLE_INFO" == "TRUE" ]] ; then
	MAS_RECEIPT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemAppStoreHasReceipt/{print $2}')
	if [[ "$MAS_RECEIPT" == "1" ]] ; then
		APPSTORE="TRUE"
	elif [[ "$MAS_RECEIPT" == "0" ]] ; then
		 APPSTORE="FALSE"
	else
		if [[ -f "$FILEPATH/Contents/_MASReceipt/receipt" ]] ; then
			APPSTORE="TRUE"
		else
			APPSTORE="FALSE"
		fi
	fi
	echo -e "App Store Receipt:\t$APPSTORE"
fi

# Sandboxing
ENTITLEMENTS=$(/usr/bin/codesign -d --entitlements - "$FILEPATH" 2>&1)
SANDBOX=$(echo "$ENTITLEMENTS" | /usr/bin/awk '/com.apple.security.app-sandbox/ {getline;print}')
if [[ $(echo "$SANDBOX" | /usr/bin/grep "true") != "" ]] ; then
	SANDBOX_STATUS="TRUE"
else
	SANDBOX_STATUS="FALSE"
fi
echo -e "Sandboxed:\t$SANDBOX_STATUS"

# Codesigning info
EXEC_PATH_RAW=$(/usr/bin/codesign -d "$FILEPATH" 2>&1)
if [[ $(echo "$EXEC_PATH_RAW" | /usr/bin/grep "not signed at all") != "" ]] ; then
	CODESIGN_STATUS="FALSE" ; CODESIGN="n/a" ; CA_CERT="n/a" ; ICA="n/a" ; LEAF="n/a" ; SIGNED="n/a" ; TEAM_ID="n/a"
elif [[ $(echo "$EXEC_PATH_RAW" | /usr/bin/grep "bundle format unrecognized, invalid, or unsuitable") != "" ]] ; then
	CODESIGN_STATUS="FALSE" ; CODESIGN="n/a" ; CA_CERT="n/a" ; ICA="n/a" ; LEAF="n/a" ; SIGNED="n/a" ; TEAM_ID="n/a"
else
	EXEC_PATH=$(echo "$EXEC_PATH_RAW" | /usr/bin/awk -F"=" '{print $2}' | /usr/bin/head -1)
	CS_ALL=$(/usr/bin/codesign -dvvvv "$EXEC_PATH" 2>&1)
	if [[ $(echo "$CS_ALL" | /usr/bin/grep "Signature=adhoc") != "" ]] ; then
		CODESIGN_STATUS="TRUE"
		CODESIGN="adhoc signature"
		CA_CERT="n/a"
		ICA="n/a"
		LEAF="n/a"
		SIGNED="n/a"
		TEAM_ID=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/TeamIdentifier/{print $2}')
	else
		SIGNED=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/Timestamp/{print $2}' | /usr/bin/awk '{print $2 " " $1 " " $4 " " $3}')
		[[ "$SIGNED" == "" ]] && SIGNED="n/a"
		TEAM_ID=$(echo "$CS_ALL" | /usr/bin/awk -F"=" '/TeamIdentifier/{print $2}')
		[[ "$TEAM_ID" == "" ]] && TEAM_ID="n/a"
		CS_CERTS=$(echo "$CS_ALL" | /usr/bin/grep "Authority")
		CS_COUNT=$(echo "$CS_CERTS" | /usr/bin/wc -l | xargs)
		if [[ "$CS_COUNT" -gt 1 ]] ; then
			CA_CERT=$(echo "$CS_CERTS" | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
			if [[ "$CS_COUNT" == "2" ]] ; then
				LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
				ICA="n/a"
			elif [[ "$CS_COUNT" == "3" ]] ; then
				LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
				ICA=$(echo "$CS_CERTS" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
			else
				LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
				ICA=$(echo "$CS_CERTS" | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/awk -F= '{print $2}')
				ICA="$ICA (issuer)"
			fi
			if [[ "$CA_CERT" == "Apple Root CA" ]] ; then
				CODESIGN_STATUS="TRUE"
				CODESIGN="valid certificate"
			else
				CODESIGN_STATUS="TRUE"
				CODESIGN="invalid certificate (issued)"
			fi
		elif [[ "$CS_COUNT" == "1" ]] ; then
			LEAF=$(echo "$CS_CERTS" | /usr/bin/head -1 | /usr/bin/awk -F= '{print $2}')
			CODESIGN_STATUS="TRUE"
			CODESIGN="invalid certificate (self-signed)"
		else
			CODESIGN_STATUS="TRUE"
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

# Gatekeeper
if [[ "$SPCTL_STATUS" == "context" ]] ; then
	SEC_STATUS=$(/usr/sbin/spctl -a -t open --context context:primary-signature -v "$FILEPATH" 2>&1 | /usr/bin/head -n +1 | /usr/bin/awk -F": " '{print $2}')
else
	SEC_STATUS=$(echo "$ASSESS" | /usr/bin/grep "$FILEPATH:" | /usr/bin/awk -F": " '{print $2}')
fi
echo -e "Security:\t$SEC_STATUS"
GATEKEEPER=$(echo "$ASSESS" | /usr/bin/awk -F"=" '/override=/{print $2}')
echo -e "Gatekeeper:\t$GATEKEEPER"

# Quarantine
QUARANTINE=$(/usr/bin/xattr -p com.apple.quarantine "$FILEPATH" 2>&1)
[[ $(echo "$QUARANTINE" | /usr/bin/grep "No such xattr: com.apple.quarantine") != "" ]] && QUARANTINE="FALSE"
echo -e "Quarantine:\t$QUARANTINE"

# Download info
DL_SOURCE=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemWhereFroms/{getline;print $2}')
if [[ "$DL_SOURCE" == "" ]] || [[ "$DL_SOURCE" == "(null)" ]] ; then
	DL_SOURCE="n/a"
fi
echo -e "Download URL:\t$DL_SOURCE"
DL_DATE_RAW=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemDownloadedDate/{getline;print $2}')
if [[ "$DL_DATE_RAW" == "" ]] || [[ "$DL_DATE_RAW" == "(null)" ]] ; then
	DL_DATE="n/a"
else
	DL_DATE=$(/bin/date -f'%F %T %z' -j "$DL_DATE_RAW" | /usr/bin/awk '{print $2 " " $3 " " $4 " " $6}')
fi
echo -e "Download Date:\t$DL_DATE"

# read bundle's Info.plist
if [[ "$BUNDLE_INFO" == "TRUE" ]] ; then
	PLIST_PATH="$FILEPATH/Contents/Info.plist"

	if [[ ! -f "$PLIST_PATH" ]] ; then
		echo -e "Info.plist:\tFALSE"
	else
		echo -e "Info.plist:\tTRUE"
		JPLIST=$(/usr/bin/plutil -convert json -r -o - "$PLIST_PATH")

		BUNDLE_NAME=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleName/{print $4}')
		[[ "$BUNDLE_NAME" == "" ]] && BUNDLE_NAME="n/a"
		echo -e "Bundle Name:\t$BUNDLE_NAME"

		BUNDLE_EXEC=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleExecutable/{print $4}')
		[[ "$BUNDLE_EXEC" == "" ]] && BUNDLE_EXEC="n/a"
		echo -e "Bundle Executable:\t$BUNDLE_EXEC"

		if [[ "$BUNDLE_EXEC" != "n/a" ]] ; then
			EXEC_TYPE=$(/usr/bin/file "$FILEPATH/Contents/MacOS/$BUNDLE_EXEC" | /usr/bin/awk -F": " '{print $2}')
		else
			EXEC_TYPE="n/a"
		fi
		echo -e "Executable Type:\t$EXEC_TYPE"

		BUNDLE_OSTYPE=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundlePackageType/{print $4}')
		[[ "$BUNDLE_OSTYPE" == "" ]] && BUNDLE_OSTYPE="n/a"
		echo -e "Bundle OS Type:\t$BUNDLE_OSTYPE"

		PRINCIPAL_CLASS=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/NSPrincipalClass/{print $4}')
		[[ "$PRINCIPAL_CLASS" == "" ]] && PRINCIPAL_CLASS="n/a"
		echo -e "Principal Class:\t$PRINCIPAL_CLASS"

		BUNDLE_VERSION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleShortVersionString/{print $4}')
		[[ "$BUNDLE_VERSION" == "" ]] && BUNDLE_VERSION="n/a"
		echo -e "Bundle Version:\t$BUNDLE_VERSION"

		BUNDLE_IDENTIFIER=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleIdentifier/{print $4}')
		[[ "$BUNDLE_IDENTIFIER" == "" ]] && BUNDLE_IDENTIFIER="n/a"
		echo -e "Bundle Identifier:\t$BUNDLE_IDENTIFIER"

		COPYRIGHT=$(echo "$JPLIST" | /usr/bin/perl -0777 -CSDA -MJSON::PP -MEncode -E '$p=decode_json(encode_utf8(<>));say $p->{NSHumanReadableCopyright}' | xargs)
		[[ "$COPYRIGHT" == "" ]] && COPYRIGHT="n/a"
		echo -e "Copyright:\t$COPYRIGHT"

		DEV_REGION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/CFBundleDevelopmentRegion/{print $4}')
		[[ "$DEV_REGION" == "" ]] && DEV_REGION="n/a"
		echo -e "Bundle Development Region:\t$DEV_REGION"

		BUILDMACHINE_OSBUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/BuildMachineOSBuild/{print $4}')
		[[ "$BUILDMACHINE_OSBUILD" == "" ]] && BUILDMACHINE_OSBUILD="n/a"
		echo -e "Build Machine OS Build:\t$BUILDMACHINE_OSBUILD"

		COMPILER=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTCompiler/{print $4}')
		[[ "$COMPILER" == "" ]] && COMPILER="n/a"
		echo -e "Compiler:\t$COMPILER"

		PLATFORM_BUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/BuildMachineOSBuild/{print $4}')
		[[ "$PLATFORM_BUILD" == "" ]] && PLATFORM_BUILD="n/a"
		echo -e "Platform Build:\t$PLATFORM_BUILD"

		PLATFORM_VERSION=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTPlatformVersion/{print $4}')
		[[ "$PLATFORM_VERSION" == "" ]] && PLATFORM_VERSION="n/a"
		echo -e "Platform Version:\t$PLATFORM_VERSION"

		SDK_BUILD=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTSDKBuild/{print $4}')
		[[ "$SDK_BUILD" == "" ]] && SDK_BUILD="n/a"
		echo -e "SDK Build:\t$SDK_BUILD"

		SDK_NAME=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTSDKName/{print $4}')
		[[ "$SDK_NAME" == "" ]] && SDK_NAME="n/a"
		echo -e "SDK Name:\t$SDK_NAME"

		XCODE=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/DTXcode/{print $4}')
		XCODE_VERSION=$(echo "$XCODE" | /usr/bin/head -n 1)
		[[ "$XCODE_VERSION" == "" ]] && XCODE_VERSION="n/a"
		XCODE_BUILD=$(echo "$XCODE" | /usr/bin/tail -n +2)
		[[ "$XCODE_BUILD" == "" ]] && XCODE_BUILD="n/a"
		echo -e "XCode:\t$XCODE_VERSION"
		echo -e "Xcode Build:\t$XCODE_BUILD"

		MINIMUM_OS=$(echo "$JPLIST" | /usr/bin/awk -F"\"" '/LSMinimumSystemVersion/{print $4}')
		[[ "$MINIMUM_OS" == "" ]] && MINIMUM_OS="n/a"
		echo -e "Minimum System Version:\t$MINIMUM_OS"
	fi

fi

# directory contents
if [[ "$FTYPEX" == "Directory" ]] ; then
	FULL_LIST=$(echo "$TOTAL_LIST" | /usr/bin/awk 'NF>2' | /usr/bin/sed -e '/\ \.$/d' -e '/\ \.\.$/d' -e '/^.\//d')
	if [[ "$FULL_LIST" != "" ]] ; then

		RES_NUMBER=$(echo "$TOTAL_LIST" | /usr/bin/grep "com.apple.ResourceFork" | /usr/bin/wc -l | xargs)

		ITEM_COUNT=$(echo "$FULL_LIST" | /usr/bin/wc -l | xargs) # total item count
		ITEM_FULL=$(echo "$ITEM_COUNT + $RES_NUMBER" | /usr/bin/bc -l)
		echo -e "Contains:\t$ITEM_FULL items"

		FTYPES_ALL=$(echo "$FULL_LIST" | /usr/bin/awk '{print $1}' | /usr/bin/cut -c 1)
		FTYPES_COUNT=$(echo "$FTYPES_ALL" | /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{print $2 ":\t" $1}' \
		| /usr/bin/sed -e '/^-:/s/-:/Files:/g' -e '/^d:/s/d:/Directories:/g' -e '/^l:/s/l:/Symbolic Links:/g' -e '/^p:/s/p:/Pipes\/FIFO:/g' -e '/^c:/s/c:/Character Devices:/g' -e '/^s:/s/s:/Sockets:/g' -e '/^b:/s/b:/Blocks:/g' -e '/^w:/s/w:/Whiteouts:/g')
		echo -e "$FTYPES_COUNT"
		### HFS+ cloaked files >>> HOW?
		### HFS+ special file system files (locations, private data) >>> HOW?

		echo -e "Resource Forks:\t$RES_NUMBER"

		CHFLAGS_ALL=$(echo "$FULL_LIST" | /usr/bin/awk '{print $5}')
		FLAGS_COUNT=$(echo "$CHFLAGS_ALL" | /usr/bin/grep -v "-" | /usr/bin/awk '{gsub(","," ");print}'| /usr/bin/awk '{for(w=1;w<=NF;w++) print $w}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -nr | /usr/bin/awk '{print $2 ":\t" $1}')
		[[ "$FLAGS_COUNT" != "" ]] && echo -e "$FLAGS_COUNT"

		INV_LIST=$(echo "$FULL_LIST" | /usr/bin/awk '{print $10}')
		INV_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\." | /usr/bin/wc -l | xargs)
		# $(find "$FILEPATH" \( -iname ".*" \) | /usr/bin/wc -l | xargs)
		# [[ "$INV_CONTAIN" == "" ]] && INV_CONTAIN="0"
		echo -e "Invisible:\t$INV_CONTAIN"

		DSSTORE_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.DS_Store" | /usr/bin/wc -l | xargs)
		# $(find "$FILEPATH" \( -iname ".DS_Store" \) | /usr/bin/wc -l | xargs)
		# [[ "$DSSTORE_CONTAIN" == "" ]] && DSSTORE_CONTAIN="0"
		echo -e ".DS_Store:\t$DSSTORE_CONTAIN"

		LOCAL_CONTAIN=$(echo "$INV_LIST" | /usr/bin/grep "^\.localized" | /usr/bin/wc -l | xargs)
		# $(find "$FILEPATH" \( -iname ".localized" \) | /usr/bin/wc -l | xargs)
		# [[ "$LOCAL_CONTAIN" == "" ]] && LOCAL_CONTAIN="0"
		echo -e ".localized:\t$LOCAL_CONTAIN"

		OTHER_INV=$(echo "$INV_CONTAIN - $DSSTORE_CONTAIN - $LOCAL_CONTAIN" | /usr/bin/bc -l)
		[[ "$OTHER_INV" == "" ]] && OTHER_INV="0"
		echo -e "Invisible (other):\t$OTHER_INV"

	else
		echo -e "Contains:\t0 items"
	fi
else
	echo -e "Contains:\t0 items"
fi

done

exit
