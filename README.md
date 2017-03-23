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

## Sample output

```
❯ frep /Applications/TextEdit.app
Running preliminary read permissions check.
Please wait...
**********************************************
**************************	macOS File Report *
**********************************************
Basename:					TextEdit.app
Path:						/Applications
Filesystem:					/dev/disk0s2
Mount Point:				/
Volume Name:				Macintosh HD
Spotlight:					enabled
Shared:						FALSE
File Type:					Directory
Sticky Bit:					FALSE
GUID:						not set
SUID:						not set
File Content:				directory
Bundle:						TRUE
Uniform Type Identifier:	com.apple.application-bundle
Kind:						Application
Type:						n/a
Creator:					n/a
OpenMeta Tags:				n/a
Finder Comment:				n/a
Finder Flags:				0
Hidden Extension:			TRUE
Invisible:					FALSE
Flags:						restricted
Disk Usage:					4,538,368 B (4.54 MB, 4.33 MiB)
Physical Size:				8,646,656 B (8.65 MB, 8.25 MiB)
Logical Size:				6,423,871 B (6.42 MB, 6.13 MiB)
File System Size:			6,423,871 B (6.42 MB, 6.13 MiB)
Data Size:					6,423,871 B (6.42 MB, 6.13 MiB)
Resource Forks:				0 B
Apparent Data Size:			6,423,871 B (6.42 MB, 6.13 MiB)
Extended Attributes:		0 B
Total Data Size:			6,423,871 B (6.42 MB, 6.13 MiB)
Root Object Data Size:		102 B
Root Object Xattr:			0 B
Root Object Total Size:		102 B
Device:						16777218
Inode:						658757
Device Type:				0
Blocks:						0
Optimal Block Size:			4096 B
System/User Flags:			0x80000 (524288)
File Generation Number:		0
Mode:						040755 (755)
Links:						3
Permissions:				drwxr-xr-x
Owner:						root (0)
Group:						wheel (0)
ACE 0:						group:everyone deny delete
Created:					Aug 23 03:46:48 2015
Changed:					May 17 00:07:52 2016
Modified:					May 17 00:07:52 2016
Accessed:					Mar 23 23:37:09 2017
Used:						Mar 23 18:08:32 2017
Source:						Apple System
App Store Receipt:			FALSE
Sandboxed:					TRUE
Code Signature:				TRUE
Code Signing:				valid certificate
Certificate Authority:		Apple Root CA
Intermediate CA:			Apple Code Signing Certification Authority
Leaf Certificate:			Software Signing
Team Identifier:			not set
Signed:						no date
Security:					accepted
Gatekeeper:					security disabled
Quarantine:					FALSE
Download URL:				n/a
Download Date:				n/a
Info.plist:					TRUE
Bundle Name:				TextEdit
Bundle Executable:			TextEdit
Executable Type:			Mach-O 64-bit executable x86_64
Bundle OS Type:				APPL
Principal Class:			NSApplication
Bundle Version:				1.11
Bundle Identifier:			com.apple.TextEdit
Copyright:					Copyright © 1995-2015, Apple Inc. All rights reserved.
Bundle Development Region:	English
Build Machine OS Build:		15W4247
Compiler:					com.apple.compilers.llvm.clang.1_0
Platform Build:				15W4247
Platform Version:			GM
SDK Build:					15W4247
SDK Name:					macosx10.11internal
XCode:						0700
Xcode Build:				7A176g
Minimum System Version:		10.10
Contains:					782 items
Files:						703
Directories:				78
Symbolic Links:				1
restricted:					782
compressed:					693
```
