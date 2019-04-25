#!/bin/bash
### tests
#find . -name '*.js' -exec grep -H 'import*' {} \; | grep -E "*from '[.]+/[a-zA-Z0-9/]*';[\w]*$" |sed 's/^[.\/]*/ /g'
#find . -name '*.js' -exec grep -H 'import*' {} \; | grep -E "*from '[.]+/[a-zA-Z0-9/]*';[\w]*$" |sed 's/^[.\/]*/ /g' | sed 's/:import//g' | sed 's/^ //g'| sed 's/from//g'   | awk '{for (i = 1; i <= NF; i++) {print i": "$i;}}'
#find . -name '*.js' -exec grep -H 'import*' {} \; | grep -E "*from '[.]+/[a-zA-Z0-9/]*';[\w]*$" |sed 's/^[.\/]*/ /g' | sed 's/:import//g' | sed 's/^ //g'| sed 's/from//g' | awk '{x=""; for (i = 1; i <= NF; i++) {x=x" "$i;} {print x}}
FIND='/usr/bin/find'
GREP='/bin/grep'
AWK='/usr/bin/awk'
SED='/bin/sed'

if [ -z "$1" ] ; then
  echo
  echo "Usage: js-dep-walker-2-puml.sh Output-File-Basename"
  echo "start the script in the sources root folder to generate a plantUML Output-File-Basename.puml"
  echo
  echo "This script will travers through the tree starting in '.',"
  echo "and generates a package for each subdirectory (recursively)"
  echo "and classes for each js found."
  echo "Each import in each js referencing other js files in the source"
  echo "are added as '-->' in the puml."
  exit 1
fi

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
echo "@startuml "`pwd` \
  > "${1}.puml"
echo `pwd` | $AWK '{n=split($0,a,"/"); print "package " a[n]" {";}' \
  >> "${1}.puml"

# all classes and packages fom the *.js files starting in currentfolder including subdirectories
$FIND . -name '*.js' -print | \
  $SED 's/^[.\/]*//g' | \
  $SED 's/.js$//g' | \
  $AWK '{n=split($0,a,"/"); tabs=""; for (i = 1; i <= n; i++) { tabs="\t"tabs; if(i<n) print tabs"package "a[i]" {"; else print tabs"class "a[i]; } if(n>1) print tabs"}";}' \
  >>  "${1}.puml"
# add dependencies
$FIND . -name '*.js' -exec grep -H 'import*' {} \; | \
  $GREP -E "*from '[.]+/[a-zA-Z0-9/]*';[\w]*$" | \
  $SED 's/^[.\/]*/ /g' | \
  $SED 's/:import//g' | \
  $SED 's/^ //g' | \
  $SED 's/from//g' | \
  $SED 's/.js//g' | \
  $SED "s/';$//g" | \
  $AWK '{n=split($1,a,"/"); m=split($(NF),b,"/"); print "\t\t"a[n]" ..> "b[m];}' \
  >> "${1}.puml"

echo "}" >> "${1}.puml"
echo "@enduml" >> "${1}.puml"