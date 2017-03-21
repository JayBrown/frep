#!/bin/bash

# frep v0.9.0 beta
# macOS File Reporter

LANG=en_US.UTF-8

# set -x
# PS4=':$LINENO+'

# round function
round () {
	echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | /usr/bin/bc))
}

# calculate megabyte or kilobyte
megabyte () {
	MB_RAW=$(/usr/bin/bc -l <<< "scale=6; $1/1000000")
	MB_FINAL=$(round "$MB_RAW" 3)
	if [[ "$MB_FINAL" == "0.000" ]] ; then
		KB_RAW=$(/usr/bin/bc -l <<< "scale=6; $1/1000")
		KB_FINAL=$(round "$KB_RAW" 3)
		echo "$KB_FINAL kB"
	else
		echo "$MB_FINAL MB"
	fi
}

# calculate mebibyte or kibibyte
mebibyte () {
	MIB_RAW=$(/usr/bin/bc -l <<< "scale=6; $1/1048576")
	MIB_FINAL=$(round "$MIB_RAW" 3)
	if [[ "$MIB_FINAL" == "0.000" ]] ; then
		KIB_RAW=$(/usr/bin/bc -l <<< "scale=6; $1/1024")
		KIB_FINAL=$(round "$KIB_RAW" 3)
		echo "$KIB_FINAL kiB"
	else
		echo "$MIB_FINAL MiB"
	fi
}

for FILEPATH in "$@"
do

# stat first
STAT=$(/usr/bin/stat "$FILEPATH")

# file & volume info
BASENAME=$(/usr/bin/basename "$FILEPATH")
if [[ "$BASENAME" == "."* ]] ; then
	TINV="TRUE"
else
	TINV="FALSE"
fi
DIRNAME=$(/usr/bin/dirname "$FILEPATH")
SEDPATH=$(echo "$FILEPATH" | /usr/bin/awk '{gsub("/","\\/");print}')
FPDF=$(/bin/df "$FILEPATH" | tail -1)
MPOINT=$(echo "$FPDF" | /usr/bin/awk '{print $9}')
FSYSTEM=$(echo "$FPDF" | /usr/bin/awk '{print $1}')
VOL_NAME=$(/usr/sbin/diskutil info "$FSYSTEM" | /usr/bin/awk -F":" '/Volume Name/{print $2}' | xargs)
[[ "$VOL_NAME" == "" ]] && VOL_NAME="n/a"

# check if Spotlight is enabled
MDUTIL=$(/usr/bin/mdutil -s "$MPOINT" | tail -n 1 | xargs)
if [[ "$SL_STATUS" == "Indexing enabled." ]] ; then
	SL_STATUS="true"
else
	SL_STATUS="false"
fi

# read all kinds of other file/dir info into variables for later parsing
ENTITLEMENTS=$(/usr/bin/codesign -d --entitlements - "$FILEPATH" 2>&1)
STATS=$(/usr/bin/stat -s "$FILEPATH")
MDLS=$(/usr/bin/mdls "$FILEPATH" 2>/dev/null)
ASSESS=$(/usr/sbin/spctl -v --assess "$FILEPATH" 2>&1)
LISTING=$(ls -alO "$FILEPATH" | /usr/bin/head -2 | /usr/bin/tail -1)

# parse the stat information
INODE_DEV=$(echo "$STAT" | /usr/bin/awk '{print $1}')
INODE=$(echo "$STAT" | /usr/bin/awk '{print $2}')
HARDLINKS=$(echo "$STAT" | /usr/bin/awk '{print $4}')
RDEV=$(echo "$STAT" | /usr/bin/awk '{print $7}') # special file inode device type
PERMISSIONS=$(echo "$STAT" | /usr/bin/awk '{print $3}')
MODEA=$(/usr/bin/stat -f '%A' "$FILEPATH")
MODEB=$(echo "$STATS" | /usr/bin/awk '{print $3}' | /usr/bin/awk -F= '{print $2}')
MODE="$MODEB ($MODEA)"
UIDN=$(echo "$STAT" | /usr/bin/awk '{print $5}')
UIDNO=$(echo "$STATS" | /usr/bin/awk '{print $5}' | /usr/bin/awk -F= '{print $2}')
GIDN=$(echo "$STAT" | /usr/bin/awk '{print $6}')
GIDNO=$(echo "$STATS" | /usr/bin/awk '{print $6}' | /usr/bin/awk -F= '{print $2}')
FLAGSA=$(echo "$STATS" | /usr/bin/awk '{print $15}' | /usr/bin/awk -F= '{print $2}')
FLAGSB=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $9}' | /usr/bin/awk '{print $3}')
USERFLAGS="$FLAGSB ($FLAGSA)"
BLOCKSNO=$(echo "$STATS" | /usr/bin/awk '{print $14}' | /usr/bin/awk -F= '{print $2}')
FILEGENNO=$(/usr/bin/stat -f '%v')

# file flags
THIDDEN="FALSE" ; TOPAQUE="FALSE" ; TARCH="FALSE" ; TNODUMP="FALSE" ; TSAPPND="FALSE" ; TSCHG="FALSE" ; TUAPPND="FALSE" ; TUCHG="FALSE" ; TRESTR="FALSE" ; TCOMPR="FALSE" ; TUUNLNK="FALSE" ; TSUNLNK="FALSE" # macOS
TOFFLINE="FALSE" ; TSPARSE="FALSE" ; TSNAP="FALSE" # BSD etc.
TRDONLY="FALSE" ; TSYSTEM="FALSE" ; TREPARSE="FALSE" # Windows/CIFS
CHFLAGS=$(echo "$LISTING" | /usr/bin/awk '{print $5}' | /usr/bin/awk '{gsub(","," ");print}')
# macOS
[[ $(echo "$CHFLAGS" | /usr/bin/grep "restricted") != "" ]] && TRESTR="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "arch") != "" ]] && TARCH="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "opaque") != "" ]] && TOPAQUE="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "nodump") != "" ]] && TNODUMP="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "sappnd") != "" ]] && TSAPPND="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "schg") != "" ]] && TSCHG="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "uappnd") != "" ]] && TUAPPND="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "uchg") != "" ]] && TUCHG="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "hidden") != "" ]] && THIDDEN="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "compressed") != "" ]] && TCOMPR="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "uunl") != "" ]] && TUUNLNK="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "sunl") != "" ]] && TSUNLNK="TRUE"
# BSD (macOS recognized)
[[ $(echo "$CHFLAGS" | /usr/bin/grep "snapshot") != "" ]] && TSNAP="TRUE"
# Windows/CIFS
[[ $(echo "$CHFLAGS" | /usr/bin/grep "only") != "" ]] && TRDONLY="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "system") != "" ]] && TSYSTEM="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "reparse") != "" ]] && TREPARSE="TRUE"
# BSD etc.
[[ $(echo "$CHFLAGS" | /usr/bin/grep "offline") != "" ]] && TOFFLINE="TRUE"
[[ $(echo "$CHFLAGS" | /usr/bin/grep "sparse") != "" ]] && TSPARSE="TRUE"

# sticky bit
STICKY="FALSE"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == *"t" ]] && STICKY="TRUE"

# SUID/GUID
SUIDSET="not set" ; GUIDSET="not set"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"s"* ]] && SUIDSET="enabled (ux)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ???"S"* ]] && SUIDSET="enabled"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"s"* ]] && GUIDSET="enabled (gx)"
[[ $(echo "$LISTING" | /usr/bin/awk '{print $1}') == ??????"S"* ]] && GUIDSET="enabled"

# file type (Unix)
[[ $(echo "$LISTING" | /usr/bin/grep "^-") != "" ]] && FTYPEX="File"
[[ $(echo "$LISTING" | /usr/bin/grep "^d") != "" ]] && FTYPEX="Directory"
[[ $(echo "$LISTING" | /usr/bin/grep "^l") != "" ]] && FTYPEX="Symbolic Link"
[[ $(echo "$LISTING" | /usr/bin/grep "^p") != "" ]] && FTYPEX="Pipe/FIFO"
[[ $(echo "$LISTING" | /usr/bin/grep "^c") != "" ]] && FTYPEX="Character Device"
[[ $(echo "$LISTING" | /usr/bin/grep "^s") != "" ]] && FTYPEX="Socket"
[[ $(echo "$LISTING" | /usr/bin/grep "^b") != "" ]] && FTYPEX="Block"
[[ $(echo "$LISTING" | /usr/bin/grep "^w") != "" ]] && FTYPEX="Whiteout"

# symlink target
if [[ "$FTYPEX" == "Symbolic Link" ]] ; then
	SLTARGET="-> $(/usr/bin/stat -f '%Y' "$FILEPATH")"
else
	SLTARGET="n/a"
fi

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

# file type (specific) & kind (macOS)
FILETYPE=$(/usr/bin/file "$FILEPATH" | /usr/bin/awk -F": " '{print $2}')
CONTENT_TYPE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemContentType/{print $2}' | /usr/bin/head -n 1 | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$CONTENT_TYPE" == "" ]] || [[ "$CONTENT_TYPE" == "(null)" ]] ; then
	CONTENT_TYPE="n/a"
fi
KIND=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemKind/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$KIND" == "" ]] || [[ "$KIND" == "(null)" ]] ; then
	KIND="n/a"
fi

# Finder tags & commend & type/creator & hidden extension
TAGS=$(/usr/bin/mdls -raw -name kMDItemUserTags "$FILEPATH" | /usr/bin/sed -e '1,1d' -e '$d' | xargs)
if [[ "$TAGS" == "(null)" ]] || [[ "$TAGS" == "" ]] ; then
	TAGS="not tagged"
fi
FCOMMENT=$(/usr/bin/mdls -raw -name kMDItemFinderComment "$FILEPATH" 2>&1)
if [[ "$FCOMMENT" == "(null)" ]] || [[ "$FCOMMENT" == "" ]] ; then
	FCOMMENT="n/a"
fi
CREATORCODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSCreatorCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$CREATORCODE" == "(null)" ]] || [[ "$CREATORCODE" == "" ]] ; then
	CREATORCODE="n/a"
fi
TYPECODE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSTypeCode/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$TYPECODE" == "(null)" ]] || [[ "$TYPECODE" == "" ]] ; then
	TYPECODE="n/a"
fi
HIDDENEXT=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSIsExtensionHidden/{print $2}')
if [[ "$HIDDENEXT" == "1" ]] ; then
	HIDDENEXT="TRUE"
else
	HIDDENEXT="FALSE"
fi

# Shared folder
SHARE_INFO=$(/usr/bin/dscl . -read SharePoints/"$BASENAME" 2>&1)
if [[ $(echo "$SHARE_INFO" | /usr/bin/grep "$FILEPATH") != "" ]] ; then
	SHARED="TRUE"
else
	SHARED="FALSE"
fi

tabs 30

echo "*** BEGIN FILE REPORT ***"

echo -e "Basename:\t$BASENAME"
echo -e "Path:\t$DIRNAME"
echo -e "Filesystem:\t$FSYSTEM"
echo -e "Mount Point:\t$MPOINT"
echo -e "Volume Name:\t$VOL_NAME"
echo -e "Shared:\t$SHARED"

echo -e "File Type:\t$FTYPEX"
echo -e "Reference:\t$SLTARGET"
echo -e "Sticky Bit:\t$STICKY"
echo -e "GUID:\t$GUIDSET"
echo -e "SUID:\t$SUIDSET"
echo -e "File Content:\t$FILETYPE"
echo -e "Bundle:\t$BUNDLE_INFO"
echo -e "Uniform Type Identifier:\t$CONTENT_TYPE"
echo -e "Kind:\t$KIND"
echo -e "Type:\t$TYPECODE"
echo -e "Creator\t$CREATORCODE"
echo -e "OpenMeta Tags:\t$TAGS"
echo -e "Finder Comment:\t$FCOMMENT"
echo -e "Invisible:\t$TINV"
echo -e "Hidden Extension:\t$HIDDENEXT"
echo -e "Hidden:\t$THIDDEN"
echo -e "Opaque:\t$TOPAQUE"
echo -e "Restricted:\t$TRESTR"
echo -e "Compressed:\t$TCOMPR"
echo -e "Immutable (User):\t$TUCHG"
echo -e "Immutable (System):\t$TSCHG"
echo -e "Append (User):\t$TUAPPND"
echo -e "Append (System):\t$TSAPPND"
echo -e "No Unlink (User):\t$TUUNLNK"
echo -e "No Unlink (System): \t$TSUNLNK"
echo -e "No Dump:\t$TNODUMP"
echo -e "Archived:\t$TARCH"

echo -e "Snapshot:\t$TSNAP"

echo -e "Offline:\t$TOFFLINE"
echo -e "Sparse:\t$TSPARSE"

echo -e "Read-Only (Windows):\t$TRDONLY"
echo -e "Reparse (Windows):\t$TREPARSE"
echo -e "System (Windows):\t$TSYSTEM"

# actual disk usage size
DISK_USAGE=$(/usr/bin/du -k -d 0 "$FILEPATH" | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}')
DU_SIZE=$(echo "$DISK_USAGE * 1024" | /usr/bin/bc -l)
DU_SIZE_MB=$(megabyte "$DU_SIZE")
DU_SIZE_MIB=$(mebibyte "$DU_SIZE")
DU_SIZE_INFO="$DU_SIZE B ($DU_SIZE_MB, $DU_SIZE_MIB)"

# physical size as reported by macOS (mdls) -- might be larger than actual disk usage (virtual size ignoring HFS+ compression)
PHYSICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemPhysicalSize/{print $2}')
if [[ "$PHYSICAL_SIZE" == "" ]] || [[ "$PHYSICAL_SIZE" == "(null)" ]] ; then
	PHYS="false"
	PHYSICAL_SIZE_INFO="n/a"
else
	PHYS="true"
	PHYSICAL_SIZE_MB=$(megabyte "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_MIB=$(mebibyte "$PHYSICAL_SIZE")
	PHYSICAL_SIZE_INFO="$PHYSICAL_SIZE B ($PHYSICAL_SIZE_MB, $PHYSICAL_SIZE_MIB)"
fi

# data size (total byte count)
DATA_SIZE=$(ls -Ral "$FILEPATH" | /usr/bin/grep -v '^d' | /usr/bin/awk '{total += $5} END {print total}')
DATA_SIZE_MB=$(megabyte "$DATA_SIZE")
DATA_SIZE_MIB=$(mebibyte "$DATA_SIZE")
DATA_SIZE_INFO="$DATA_SIZE B ($DATA_SIZE_MB, $DATA_SIZE_MIB)"

# Xattr & Resource fork size
EXTRA_LIST=$(ls -Ral@ "$FILEPATH" | /usr/bin/awk 'NF<=2' | /usr/bin/sed -e '/^$/d' -e '/^total /d' -e '/^'"$SEDPATH"'/d')
RES_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {print total}')
[[ "$RES_SIZE" == "" ]] && RES_SIZE="0"
RES_SIZE_MB=$(megabyte "$RES_SIZE")
RES_SIZE_MIB=$(mebibyte "$RES_SIZE")
RES_SIZE_INFO="$RES_SIZE B ($RES_SIZE_MB, $RES_SIZE_MIB)"
XATTR_SIZE=$(echo "$EXTRA_LIST" | /usr/bin/grep -v "com.apple.ResourceFork" | /usr/bin/awk '{total += $2} END {print total}')
[[ "$XATTR_SIZE" == "" ]] && XATTR_SIZE="0"
XATTR_SIZE_MB=$(megabyte "$XATTR_SIZE")
XATTR_SIZE_MIB=$(mebibyte "$XATTR_SIZE")
XATTR_SIZE_INFO="$XATTR_SIZE B ($XATTR_SIZE_MB, $XATTR_SIZE_MIB)"

# logical size (data+resources+xattr) = total size
TOTAL_SIZE=$(echo "$RES_SIZE + $XATTR_SIZE + $DATA_SIZE" | /usr/bin/bc -l)
TOTAL_SIZE_MB=$(megabyte "$TOTAL_SIZE")
TOTAL_SIZE_MIB=$(mebibyte "$TOTAL_SIZE")
TOTAL_SIZE_INFO="$TOTAL_SIZE B ($TOTAL_SIZE_MB, $TOTAL_SIZE_MIB)"

# logical size as reported by macOS (mdls) -- should be the same as total byte count
LOGICAL_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLogicalSize/{print $2}')
if [[ "$LOGICAL_SIZE" == "" ]] || [[ "$LOGICAL_SIZE" == "(null)" ]] ; then
	LOGICAL="false"
	LOGICAL_SIZE_INFO="n/a"
else
	LOGICAL_SIZE_MB=$(megabyte "$LOGICAL_SIZE")
	LOGICAL_SIZE_MIB=$(mebibyte "$LOGICAL_SIZE")
	LOGICAL_SIZE_INFO="$LOGICAL_SIZE B ($LOGICAL_SIZE_MB, $LOGICAL_SIZE_MIB)"
fi

# file system size as reported by FS to macOS
FS_SIZE=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemFSSize/{print $2}' | /usr/bin/sed 's/^"\(.*\)"$/\1/')
if [[ "$FS_SIZE" == "" ]] || [[ "$FS_SIZE" == "(null)" ]] ; then
	FS_SIZE_INFO="n/a"
else
	FS_SIZE_MB=$(megabyte "$FS_SIZE")
	FS_SIZE_MIB=$(mebibyte "$FS_SIZE")
	FS_SIZE_INFO="$FS_SIZE B ($FS_SIZE_MB, $FS_SIZE_MIB)"
fi

# root size
STATSIZE_B=$(echo "$STAT" | /usr/bin/awk '{print $8}')
STATSIZE_MB=$(megabyte "$STATSIZE_B")
STATSIZE_MIB=$(mebibyte "$STATSIZE_B")
STATSIZE="$STATSIZE_B B ($STATSIZE_MB, $STATSIZE_MIB)"
if [[ "$FTYPEX" == "Directory" ]] ; then
	ROOT_LIST=$(ls -laO@ "$FILEPATH" | /usr/bin/tail -n +3)
else
	ROOT_LIST=$(ls -laO@ "$FILEPATH" | /usr/bin/tail -n +2)
fi
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

ROOT_TOTAL=$(echo "$STATSIZE_B + $XTRASIZE" | /usr/bin/bc -l)
ROOT_TOTAL_MB=$(megabyte "$ROOT_TOTAL")
ROOT_TOTAL_MIB=$(mebibyte "$ROOT_TOTAL")
ROOT_TSIZE="$ROOT_TOTAL B ($ROOT_TOTAL_MB, $ROOT_TOTAL_MIB)"

# block size
BLOCKSIZE=$(echo "$STATS" | /usr/bin/awk '{print $13}' | /usr/bin/awk -F= '{print $2}')

echo -e "Physical Size (du):\t$DU_SIZE_INFO" # object's actual disk usage size (might be smaller than virtual size due to HFS+ compression)
echo -e "Physical Size (mdls):\t$PHYSICAL_SIZE_INFO" # physical size reported my macOS (can be a virtual value = uncompressed)
echo -e "Logical Size (mdls):\t$LOGICAL_SIZE_INFO" # logical size reported by maOS (should be the same as total byte count minus xattr)
echo -e "File System Size (mdls):\t$FS_SIZE_INFO" # alternate size reported by macOS (should be the same as logical size)
echo -e "Total Data Size:\t$TOTAL_SIZE_INFO" # byte count total
echo -e "Data Size (stat):\t$DATA_SIZE_INFO" # only the readable data parts of the total byte count
echo -e "Extended Attributes (ls):\t$XATTR_SIZE_INFO" # only the xattr parts of the total byte count
echo -e "Resource Forks (ls):\t$RES_SIZE_INFO" # only the resource fork parts of the total byte count
echo -e "Root Object Total Size:\t$ROOT_TSIZE" # size of root object incl. xattr and resources
echo -e "Root Object Size (stat):\t$STATSIZE" # only the size of the root object

# dates
LASTACCESS=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $2}')
LASTMODIFY=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $4}')
LASTSTATUSCHANGE=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $6}')
BIRTHTIME=$(echo "$STAT" | /usr/bin/awk -F"\"" '{print $8}')
LASTUSED=$(echo "$MDLS" | /usr/bin/awk -F"= " '/kMDItemLastUsedDate/{print $2}')
if [[ "$LASTUSED" == "" ]] || [[ "$LASTUSED" == "(null)" ]] ; then
	LASTUSED="n/a"
else
	LASTUSED=$(/bin/date -f'%F %T %z' -j "$LASTUSED" | /usr/bin/awk '{print $2 " " $3 " " $4 " " $6}')
fi

# ACL/ACE
if [[ "$FTYPEX" == "Directory" ]] ; then
	ACE_LIST=$(ls -lae "$FILEPATH" | /usr/bin/tail -n +3)
else
	ACE_LIST=$(ls -lae "$FILEPATH" | /usr/bin/tail -n +2)
fi
CUTLINE=$(echo "$ACE_LIST" | /usr/bin/grep "\ \.\.")
ACL=""
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
ACL=$(echo "$ACL" | /usr/bin/tail -n +2)

echo -e "Device:\t$INODE_DEV"
echo -e "Inode:\t$INODE"

echo -e "Device Type:\t$RDEV"
echo -e "Blocks:\t$BLOCKSNO"
echo -e "Optimal Block Size:\t$BLOCKSIZE B"
echo -e "System/User Flags:\t$USERFLAGS"
echo -e "File Generation Number:\t$FILEGENNO"

echo -e "Mode:\t$MODE"
echo -e "Links:\t$HARDLINKS"
echo -e "Permissions:\t$PERMISSIONS"
echo -e "Owner:\t$UIDN ($UIDNO)"
echo -e "Group:\t$GIDN ($GIDNO)"

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

echo -e "Created:\t$BIRTHTIME"
echo -e "Changed:\t$LASTSTATUSCHANGE"
echo -e "Modified:\t$LASTMODIFY"
echo -e "Accessed:\t$LASTACCESS"
echo -e "Used:\t$LASTUSED"

# method to read the default "open with" application for a file?

# macOS security & App Store info
GATEKEEPER=$(echo "$ASSESS" | /usr/bin/awk -F"=" '/override=/{print $2}')

SEC_STATUS=$(echo "$ASSESS" | /usr/bin/grep "$FILEPATH:" | /usr/bin/awk -F": " '{print $2}')

SOURCE=$(echo "$ASSESS" | /usr/bin/awk -F"=" '/source=/{print $2}')
if [[ "$SOURCE" == "" ]] ; then
	SOURCE=$(/usr/sbin/spctl -a -t open --context context:primary-signature -v "$FILEPATH" 2>&1 | /usr/bin/awk -F"=" '/source=/{print $2}')
fi

SANDBOX=$(echo "$ENTITLEMENTS" | /usr/bin/awk '/com.apple.security.app-sandbox/ {getline;print}')
if [[ $(echo "$SANDBOX" | /usr/bin/grep "true") != "" ]] ; then
	SANDBOX_STATUS="TRUE"
else
	SANDBOX_STATUS="FALSE"
fi

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

# read bundle's Info.plist
if [[ "$TTYPE" == "Bundle" ]] ; then
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

QUARANTINE=$(/usr/bin/xattr -p com.apple.quarantine "$FILEPATH" 2>&1)
[[ $(echo "$QUARANTINE" | /usr/bin/grep "No such xattr: com.apple.quarantine") != "" ]] && QUARANTINE="FALSE"

DL_SOURCE=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemWhereFroms/{getline;print $2}')
if [[ "$DL_SOURCE" == "" ]] || [[ "$DL_SOURCE" == "(null)" ]] ; then
	DL_SOURCE="n/a"
fi

DL_DATE_RAW=$(echo "$MDLS" | /usr/bin/awk -F"\"" '/kMDItemDownloadedDate/{getline;print $2}')
if [[ "$DL_DATE_RAW" == "" ]] || [[ "$DL_DATE_RAW" == "(null)" ]] ; then
	DL_DATE="n/a"
else
	DL_DATE=$(/bin/date -f'%F %T %z' -j "$DL_DATE_RAW" | /usr/bin/awk '{print $2 " " $3 " " $4 " " $6}')
fi

echo -e "Source:\t$SOURCE"
echo -e "App Store Receipt:\t$APPSTORE"
echo -e "Sandboxed:\t$SANDBOX_STATUS"
echo -e "Code Signature:\t$CODESIGN_STATUS"
echo -e "Code Signing:\t$CODESIGN"
echo -e "Certificate Authority:\t$CA_CERT"
echo -e "Intermediate CA:\t$ICA"
echo -e "Leaf Certificate:\t$LEAF"
echo -e "Team Identifier:\t$TEAM_ID"
echo -e "Signed:\t$SIGNED"
echo -e "Security:\t$SEC_STATUS"
echo -e "Gatekeeper:\t$GATEKEEPER"

echo -e "Quarantine:\t$QUARANTINE"
echo -e "Download URL:\t$DL_SOURCE"
echo -e "Download Date:\t$DL_DATE"

# contains what?
if [[ "$FTYPEX" == "Directory" ]] ; then
	FULL_LIST=$(ls -RalO "$FILEPATH" | /usr/bin/sed -e '/ .$/d' -e '/ ..$/d' -e '/^$/d' -e '/^total /d' -e '/^.\//d' -e '/^'"$SEDPATH"'/d')
	if [[ "$FULL_LIST" != "" ]] ; then
		### XYZ all with FULL_LIST !!!
		INV_CONTAIN=$(find "$FILEPATH" \( -iname ".*" \) | /usr/bin/wc -l | xargs) # invisible items
		[[ "$INV_CONTAIN" == "" ]] && INV_CONTAIN="0"
		DSSTORE_CONTAIN=$(find "$FILEPATH" \( -iname ".DS_Store" \) | /usr/bin/wc -l | xargs) # .DS_Store
		[[ "$DSSTORE_CONTAIN" == "" ]] && DSSTORE_CONTAIN="0"
		LOCAL_CONTAIN=$(find "$FILEPATH" \( -iname ".localized" \) | /usr/bin/wc -l | xargs) # .localized
		[[ "$LOCAL_CONTAIN" == "" ]] && LOCAL_CONTAIN="0"
		OTHER_INV=$(echo "$INV_CONTAIN - $DSSTORE_CONTAIN - $LOCAL_CONTAIN" | /usr/bin/bc -l) # other invisible items calculation
		[[ "$OTHER_INV" == "" ]] && OTHER_INV="0"
		ITEM_COUNT=$(echo "$FULL_LIST" | /usr/bin/wc -l | xargs) # total item count
		FILE_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^-" | /usr/bin/wc -l | xargs) # total file count
		DIR_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^d" | /usr/bin/wc -l | xargs) # total directory count
		SYM_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^l" | /usr/bin/wc -l | xargs) # total symlink count
		PIPE_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^p" | /usr/bin/wc -l | xargs) # total pipe count
		DEV_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^c" | /usr/bin/wc -l | xargs) # total character device file count
		SOCKET_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^s" | /usr/bin/wc -l | xargs) # total socket file count
		BLOCK_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^b" | /usr/bin/wc -l | xargs) # total block file count
		WO_CONTAIN=$(echo "$FULL_LIST" | /usr/bin/grep "^w" | /usr/bin/wc -l | xargs) # total whiteout count
		HIDDEN="0" ; OPAQUE="0" ; ARCH="0" ; NODUMP="0" ; SAPPND="0" ; SCHG="0" ; UAPPND="0" ; UCHG="0" ; RESTR="0" ; COMPR="0" ; UUNLNK="0" ; SUNLNK="0"  # macOS
		OFFLINE="0" ; SPARSE="0" ; SNAP="0" # BSD etc.
		RDONLY="0" ; SYSTEM="0" ; REPARSE="0" # Windows/CIFS
		while read -r CHFLAG
		do
			# macOS
			[[ $(echo "$CHFLAG" | /usr/bin/grep "restricted") != "" ]] && ((RESTR++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "arch") != "" ]] && ((ARCH++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "opaque") != "" ]] && ((OPAQUE++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "nodump") != "" ]] && ((NODUMP++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "sappnd") != "" ]] && ((SAPPND++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "schg") != "" ]] && ((SCHG++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "uappnd") != "" ]] && ((UAPPND++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "uchg") != "" ]] && ((UCHG++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "hidden") != "" ]] && ((HIDDEN++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "compressed") != "" ]] && ((COMPR++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "uunl") != "" ]] && ((UUNLNK++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "sunl") != "" ]] && ((SUNLNK++))
			# BSD (macOS recognized)
			[[ $(echo "$CHFLAG" | /usr/bin/grep "snapshot") != "" ]] && ((SNAP++))
			# Windows/CIFS
			[[ $(echo "$CHFLAG" | /usr/bin/grep "only") != "" ]] && ((RDONLY++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "system") != "" ]] && ((SYSTEM++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "reparse") != "" ]] && ((REPARSE++))
			# BSD etc.
			[[ $(echo "$CHFLAG" | /usr/bin/grep "offline") != "" ]] && ((OFFLINE++))
			[[ $(echo "$CHFLAG" | /usr/bin/grep "sparse") != "" ]] && ((SPARSE++))
		done < <(echo "$FULL_LIST" | /usr/bin/awk '{print $5}')

		# HFS+ cloaked files >>> HOW?
		# HFS+ special file system files (locations, private data) >>> HOW?

		echo -e "Contains:\t$ITEM_COUNT objects"
		echo -e "Directories:\t$DIR_CONTAIN"
		echo -e "Files:\t$FILE_CONTAIN"
		echo -e "Symbolic Links:\t$SYM_CONTAIN"
		echo -e "Pipes/FIFO:\t$PIPE_CONTAIN"
		echo -e "Sockets:\t$SOCKET_CONTAIN"
		echo -e "Character Devices:\t$DEV_CONTAIN"
		echo -e "Blocks:\t$BLOCK_CONTAIN"
		echo -e "Whiteouts:\t$WO_CONTAIN"
		echo -e "Invisible:\t$INV_CONTAIN"
		echo -e ".DS_Store:\t$DSSTORE_CONTAIN"
		echo -e ".localized:\t$LOCAL_CONTAIN"
		echo -e "Invisible (other):\t$OTHER_INV"
		echo -e "Hidden:\t$HIDDEN"
		echo -e "Opaque:\t$OPAQUE"
		echo -e "Restricted:\t$RESTR"
		echo -e "Compressed:\t$COMPR"
		echo -e "Immutable (User):\t$UCHG"
		echo -e "Immutable (System):\t$SCHG"
		echo -e "Append (User):\t$UAPPND"
		echo -e "Append (System):\t$SAPPND"
		echo -e "No Unlink (User):\t$UUNLNK"
		echo -e "No Unlink (System): \t$SUNLNK"
		echo -e "No Dump:\t$NODUMP"
		echo -e "Archived:\t$ARCH"

		echo -e "Snapshot:\t$SNAP"

		echo -e "Offline:\t$OFFLINE"
		echo -e "Sparse:\t$SPARSE"

		echo -e "Read-Only (Windows):\t$RDONLY"
		echo -e "Reparse (Windows):\t$REPARSE"
		echo -e "System (Windows):\t$SYSTEM"
	else
		echo -e "Contains:\t0 objects"
	fi
else
	echo -e "Contains:\t0 objects"
fi

done

exit