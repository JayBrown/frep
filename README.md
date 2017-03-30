![frep-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![frep-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![frep-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/frep/blob/master/license.md)

# frep: macOS File Report <img src="https://github.com/JayBrown/frep/blob/master/img/jb-img.png" height="20px"/>
**Shell script that outputs lots of Unix, FS, macOS, Finder, and Spotlight information on any file type**

## Current status
beta; already works, but might have some errors

## Installation
* `git clone`, `chmod +x`, and `ln -s` to one of your bin directories as e.g. `frep`
* *alternative*: download, unpack, `chmod +x`, `mv` or `cp` to one of your bin directories as e.g. `frep`
* **best practice:** run as root with `sudo frep <TARGET>` to bypass the preliminary check for read permissions
* full functionality only on systems with **Xcode** (or **Developer Tools**) and Rixstep `gde` installed

## Sample output

```
 ❯ sudo frep /Applications/TextEdit.app
Password:

macOS File Report

File Information
Basename:	TextEdit.app
Extension:	.app
Path:	/Applications
File Type:	Directory
File Content:	directory
Invisible:	false
Device:	16777218
Inode:	658757
Device Type:	0
Links:	3
File Generation Number:	0

Path Owner & Permissions
Owner:	root:admin (0:80)
Permissions:	rwxrwxr-x

File Owner & Permissions
Owner:	root:wheel (0:0)
Mode:	040755 (755)
Permissions:	rwxr-xr-x
Permissions (501):	read list execute enter
Sticky Bit:	- [no effect on macOS]
Set GID:	-
Set UID:	-
System/User Flags:	0x80000 (524288)
Attributes:	restricted
ACE 0:	group:everyone deny delete
Other Permissions (501):	-

Extended Attributes
Xattr 1:	com.apple.rootless

Root Object Information
Data Size [stat]:	102 B
Extended Attributes [stat]:	0 B
Size On Volume:	102 B

Sizes & Disk Usage
Device Blocks:	8864
Size On Disk [stat]:	4,538,368 B (4.54 MB, 4.33 MiB)
Disk Usage [du]:	4,538,368 B (4.54 MB, 4.33 MiB)
Virtual Size [mdls]:	8,646,656 B (8.65 MB, 8.25 MiB)
Data Size [stat]:	6,423,871 B (6.42 MB, 6.13 MiB)
Resource Forks [stat]:	0 B
Apparent Size:	6,423,871 B (6.42 MB, 6.13 MiB)
Logical Size [mdls]:	6,423,871 B (6.42 MB, 6.13 MiB)
File System Size [mdls]:	6,423,871 B (6.42 MB, 6.13 MiB)
Slack Space:	none
Compression Ratio:	47.51 %
Extended Attributes [stat]:	0 B
Data Size On Volume:	6,423,871 B (6.42 MB, 6.13 MiB)

Unix Dates
Created:	Aug 23 03:46:48 2015
Changed:	May 17 00:07:52 2016
Modified:	May 17 00:07:52 2016
Accessed:	Mar 30 18:57:47 2017

macOS Dates
Added:	Oct 27 22:38:43 2015
Downloaded:	-
Metadata Modified:	-
Last Used:	Mar 29 02:59:43 2017

macOS File Information
Shared:	false
Package:	true
Bundle:	true
Hidden Extension:	true
Info.plist:	true
Executable:	/Applications/TextEdit.app/Contents/MacOS/TextEdit
Architecture:	x86_64
Uniform Type Identifier:	com.apple.application-bundle
Kind:	Application
Finder Flags:	0
Content Creator:	-
Node Count:	1
Label:	0
OpenMeta Tags:	-
Finder Comment:	-
Item Copyright:	Copyright © 1995-2015 Apple Inc. All rights reserved.
Download URL:	-
App Store Category:	Productivity (public.app-category.productivity)
Use Count:	678

macOS Security
Source:	Apple System
App Store Receipt:	false
Sandboxed:	true
Code Signature:	true
Code Signing:	valid certificate
Certificate Authority:	Apple Root CA
Intermediate CA:	Apple Code Signing Certification Authority
Leaf Certificate:	Software Signing
Team Identifier:	not set
Signed:	no date
Security:	accepted
Gatekeeper:	security disabled
Quarantine:	false

macOS Bundle Information
Bundle Name:	TextEdit
Bundle Executable:	TextEdit
Executable Type:	Mach-O 64-bit executable x86_64
Bundle Type:	APPL
Bundle Signature:	ttxt
Principal Class:	NSApplication
Scriptable:	true
Bundle Version:	1.11
Bundle Identifier:	com.apple.TextEdit
Bundle Info:	-
Copyright:	Copyright © 1995-2015, Apple Inc. All rights reserved.
Bundle Development Region:	English
Build Machine OS Build:	15W4247
Compiler:	com.apple.compilers.llvm.clang.1_0
Platform Build:	15W4247
Platform Version:	GM
SDK Build:	15W4247
SDK Name:	macosx10.11internal
XCode:	0700
Xcode Build:	7A176g
Minimum System Version:	10.10
Required:	-

File Contents
Contains:	782 items
Files:	703
Directories:	78
Symbolic Links:	1
restricted:	782
compressed:	693
cloaked:	-
ACE Total:	1

User Information
Effective User & Group:	root:wheel (0:0)
Real User & Group:	jbraun:staff (501:20)
Group 1:	staff (20)
Group 2:	access_bpf (502)
Group 3:	everyone (12)
Group 4:	localaccounts (61)
Group 5:	_appserverusr (79)
Group 6:	admin (80)
Group 7:	_appserveradm (81)
Group 8:	_lpadmin (98)
Group 9:	com.apple.sharepoint.group.1 (402)
Group 10:	_appstore (33)
Group 11:	_lpoperator (100)
Group 12:	_developer (204)
Group 13:	com.apple.access_ftp (395)
Group 14:	com.apple.access_screensharing (398)
Group 15:	com.apple.access_ssh (399)

Volume Information
File System:	/dev/disk0s2
Mount Point:	/
File System Owner:	root:wheel (0:0)
File System Type:	hfs
Available Inodes:	121,886,742
Free Inodes:	47,422,946
Used Inodes:	74,463,796 (61%)
Device Block Size:	512 B
Allocation Block Size:	4096 B
Available Blocks:	975,093,952
Free Blocks:	379,383,568
Used Blocks:	595,198,384 (62%)
File System Personality:	Journaled HFS+
Journal:	Journal size 40960 KB at offset 0xe8a000
Volume Name:	Macintosh HD
Spotlight:	enabled

macOS Information
Product Name:	Mac OS X
Product Version:	10.11.6
Build Version:	15G1421
System Integrity Protection:	disabled
Kernel:	Darwin 15.6.0 (199506)
UUID:	[withheld]
```
