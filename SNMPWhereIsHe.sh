#!/bin/sh 
ROUTERLIST=""
ROUTERLIST="$ROUTERLIST"" ""router1.example.com"
ROUTERLIST="$ROUTERLIST"" ""router2.example.com"
ROUTERLIST="$ROUTERLIST"" ""switch1.example.com"
SNMPCOM="public"

INPUTADDR="$1"
SEARCHADDR=`echo "$1" |
 tr "abcdef" "ABCDEF" |
 sed -e "s/^\(..\)\(..\)[:\.]\(..\)\(..\)[:\.]\(..\)\(..\)$/\1:\2:\3:\4:\5:\6/" |
 tr ":." "  "`

ADDR161=`echo $SEARCHADDR | cut -d " " -f 1`
ADDR162=`echo $SEARCHADDR | cut -d " " -f 2`
ADDR163=`echo $SEARCHADDR | cut -d " " -f 3`
ADDR164=`echo $SEARCHADDR | cut -d " " -f 4`
ADDR165=`echo $SEARCHADDR | cut -d " " -f 5`
ADDR166=`echo $SEARCHADDR | cut -d " " -f 6`
ADDR101=`printf "%d" 0x$ADDR161`
ADDR102=`printf "%d" 0x$ADDR162`
ADDR103=`printf "%d" 0x$ADDR163`
ADDR104=`printf "%d" 0x$ADDR164`
ADDR105=`printf "%d" 0x$ADDR165`
ADDR106=`printf "%d" 0x$ADDR166`

echo "#" Searching [$SEARCHADDR]

for RouterName in $ROUTERLIST; do
 NextMIB=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.17.4.3.1.1.$ADDR101.$ADDR102.$ADDR103.$ADDR104.$ADDR105.$ADDR106  |
  grep "$SEARCHADDR"  |
  cut -d ' ' -f 1 |
  sed -e 's/17\.4\.3\.1\.1/17.4.3.1.2/'`
 if test "`echo $NextMIB | grep -v '^$' | wc -l`" -eq "1" ; then
  InterfaceInfo=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" "$NextMIB" | 
   sed -e 's/^.*INTEGER: \(.*\)$/\1/'`
  InterfaceInfo=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.17.1.4.1.2 |
   grep "INTEGER: $InterfaceInfo" |
   sed -e 's/^.*INTEGER: \(.*\)$/\1/'`
  InterfaceName=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.31.1.1.1.1.$InterfaceInfo  |
   sed -e 's/^.*STRING: \(.*\)$/\1/'`
  InterfaceDesc=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.31.1.1.1.18.$InterfaceInfo  |
   sed -e 's/^.*STRING: \(.*\)$/\1/'`
  echo "$RouterName: $InterfaceName($InterfaceDesc)"
 else
  echo "$RouterName: ---------"
 fi
done
