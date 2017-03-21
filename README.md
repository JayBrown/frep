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

## Sample output

```
❯ frep /Applications/TextEdit.app
*** BEGIN FILE REPORT ***
Basename:	TextEdit.app
Path:	/Applications
Filesystem:	/dev/disk0s2
Mount Point:	/
Volume Name:	Macintosh HD
Shared:	FALSE
File Type:	Directory
Reference:	n/a
Sticky Bit:	FALSE
GUID:	not set
SUID:	not set
File Content:	directory
Bundle:	TRUE
Uniform Type Identifier:	com.apple.application-bundle
Kind:	Application
Type:	n/a
Creator	n/a
OpenMeta Tags:	not tagged
Finder Comment:	n/a
Invisible:	FALSE
Hidden Extension:	TRUE
Hidden:	FALSE
Opaque:	FALSE
Restricted:	TRUE
Compressed:	FALSE
Immutable (User):	FALSE
Immutable (System):	FALSE
Append (User):	FALSE
Append (System):	FALSE
No Unlink (User):	FALSE
No Unlink (System): 	FALSE
No Dump:	FALSE
Archived:	FALSE
Snapshot:	FALSE
Offline:	FALSE
Sparse:	FALSE
Read-Only (Windows):	FALSE
Reparse (Windows):	FALSE
System (Windows):	FALSE
Physical Size (du):	4538368 B (4.538 MB, 4.328 MiB)
Physical Size (mdls):	8646656 B (8.647 MB, 8.246 MiB)
Logical Size (mdls):	6423871 B (6.424 MB, 6.126 MiB)
File System Size (mdls):	6423871 B (6.424 MB, 6.126 MiB)
Total Data Size:	6423871 B (6.424 MB, 6.126 MiB)
Data Size (stat):	6423871 B (6.424 MB, 6.126 MiB)
Extended Attributes (ls):	0 B (0.000 kB, 0.000 kiB)
Resource Forks (ls):	0 B (0.000 kB, 0.000 kiB)
Root Object Total Size:	102 B (0.102 kB, 0.100 kiB)
Root Object Size (stat):	102 B (0.102 kB, 0.100 kiB)
Device:	16777218
Inode:	658757
Device Type:	0
Blocks:	0
Optimal Block Size:	4096 B
System/User Flags:	0x80000 (524288)
File Generation Number:	0
Mode:	040755 (755)
Links:	3
Permissions:	drwxr-xr-x
Owner:	root (0)
Group:	wheel (0)
ACE 0:	group:everyone deny delete
Created:	Aug 23 03:46:48 2015
Changed:	May 17 00:07:52 2016
Modified:	May 17 00:07:52 2016
Accessed:	Mar 21 13:01:07 2017
Used:	Mar 21 12:18:42 2017
Source:	Apple System
App Store Receipt:	FALSE
Sandboxed:	TRUE
Code Signature:	TRUE
Code Signing:	valid certificate
Certificate Authority:	Apple Root CA
Intermediate CA:	Apple Code Signing Certification Authority
Leaf Certificate:	Software Signing
Team Identifier:	not set
Signed:	n/a
Security:	accepted
Gatekeeper:	security disabled
Quarantine:	FALSE
Download URL:	n/a
Download Date:	n/a
Contains:	782 objects
Directories:	78
Files:	703
Symbolic Links:	1
Pipes/FIFO:	0
Sockets:	0
Character Devices:	0
Blocks:	0
Whiteouts:	0
Invisible:	0
.DS_Store:	0
.localized:	0
Invisible (other):	0
Hidden:	0
Opaque:	0
Restricted:	782
Compressed:	693
Immutable (User):	0
Immutable (System):	0
Append (User):	0
Append (System):	0
No Unlink (User):	0
No Unlink (System): 	0
No Dump:	0
Archived:	0
Snapshot:	0
Offline:	0
Sparse:	0
Read-Only (Windows):	0
Reparse (Windows):	0
System (Windows):	0
```
