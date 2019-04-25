#!/bin/bash
# tools used
FIND='/usr/bin/find'
GREP='/bin/grep'
AWK='/usr/bin/awk'
SED='/bin/sed'
EXDIRSTR=''

# help text
if [ -z "$1" ] ; then
  echo
  echo "Usage: js-dep-walker-2-puml.sh basefilename exclude-dir1,exclude-dir2,... 'pantUMLSettings1,pantUMLSettings2,...'"
  echo "start the script in the sources root folder to generate a plantUML basefilename.puml"
  echo
  echo "This script will travers through the tree starting in '.',"
  echo "and generates a package for each subdirectory (recursively)"
  echo "and classes for each js found."
  echo "Each import in each js referencing other js files in the source"
  echo "are added as '-->' in the puml."
  exit 1
fi

# check if all tools are installed
if [ ! -x "$FIND" ] ; then
  echo "find Not Installed"
  exit 1
fi
if [ ! -x "$AWK" ] ; then
  echo "awk Not Installed"
  exit 1
fi
if [ ! -x "$GREP" ] ; then
  echo "grep Not Installed"
  exit 1
fi
if [ ! -x "$SED" ] ; then
  echo "sed Not Installed"
  exit 1
fi

# generating puml
echo "generating plantUML file "${1}.puml" from "`pwd`
if [ -n "$2" ] ; then
  echo "excluding the following directories: "$2
  read EXDIRSTR <<< $( echo $2 | $AWK '{n=split($0,exdirs,","); findstr="( -path "exdirs[1]; for(i = 2; i <= n; i++) {findstr=findstr" -o -path "exdirs[i];} findstr=findstr" ) -prune -o "; print findstr;}' )
  #echo "excluded dirs in find: " $EXDIRSTR
fi

# open tag @startuml
echo "@startuml "`pwd` \
  > "${1}.puml"

if [ -n "$3" ] ; then
  echo "adding plantUML settings on top: " $3
  echo $3 | $AWK '{n=split($0,a,",");for(i = 1; i <= n; i++) {print a[i];}}' \
  >> "${1}.puml"
fi

echo `pwd` | $AWK '{n=split($0,a,"/"); print "package " a[n]" {";}' \
  >> "${1}.puml"

# all classes and packages fom the *.js files starting in currentfolder including subdirectories
$FIND . $EXDIRSTR -name '*.js' -print | \
  $SED 's/^[.\/]*//g' | \
  $SED 's/.js$//g' | \
  $AWK '{n=split($0,a,"/"); tabs=""; for (i = 1; i <= n; i++) { tabs="\t"tabs; if(i<n) print tabs"package "a[i]" {"; else print tabs"class "a[i]; } if(n>1) print tabs"}";}' \
  >>  "${1}.puml"
# add dependencies -- simple imports in one js line like: import Sorting from './Sorting'; 
# DOES NOT handle 
# import {
#   MainLandscapeContentContainer,
#   ...
# }
$FIND . $EXDIRSTR -name '*.js' -exec grep -H 'import*' {} \; | \
  $GREP -E "*from '[.]+/[.a-zA-Z0-9/]*';[\w]*$" | \
  $SED 's/^[.\/]*/ /g' | \
  $SED 's/:import//g' | \
  $SED 's/^ //g' | \
  $SED 's/from//g' | \
  $SED 's/.js//g' | \
  $SED "s/';$//g" | \
  $AWK '{n=split($1,a,"/"); m=split($(NF),b,"/"); if(a[n] != "") print "\t\t"a[n]" ..> "b[m];}' \
  >> "${1}.puml"

# closing tag
echo "}" >> "${1}.puml"
echo "@enduml" >> "${1}.puml"