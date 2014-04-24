#!/bin/sh 

ROUTERLIST=""
# デフォルトのルータリスト
#ROUTERLIST="$ROUTERLIST"" ""192.168.10.253"
#ROUTERLIST="$ROUTERLIST"" ""192.168.10.254"
#SNMPCOM="public"

while getopts c:h: opt; do
 case ${opt} in
 c)
  SNMPCOM=${OPTARG};;
 h)
  ROUTERLIST=${OPTARG};;
  esac
done
shift `expr $OPTIND - 1`

if test "$1" = ""; then
 echo "need mac addr"
 exit
fi

# サポートするFDB MIB ID
# BRIDGE-MIB::dot1dTpFdbAddress.
mibid_bridge=".1.3.6.1.2.1.17.4.3.1.1"
# Q-BRIDGE-MIB::dot1qTpFdbPort
mibid_qbridge=".1.3.6.1.2.1.17.7.1.2.2.1.2.7"

# アドレスの編集
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

# FDBMIBはエントリを
# c8:60:00:01:02:03 であれば FDBMIB..200.96.0.1.2.3
# のように、16進数にして、適当に"."で区切ってqueryする必要がある

echo "#" Searching [$SEARCHADDR]

for RouterName in $ROUTERLIST; do
 is_exist=0
 if test `snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" $mibid_bridge 2> /dev/null | wc -l ` -ge 2 ; then
   echo "USING BRIDGE"
   targetmib=$mibid_bridge
   NextMIB=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" "$targetmib".$ADDR101.$ADDR102.$ADDR103.$ADDR104.$ADDR105.$ADDR106 2> /dev/null  |
   grep "$SEARCHADDR"  |
   cut -d ' ' -f 1 |
   sed -e 's/17\.4\.3\.1\.1/17.4.3.1.2/'`
   if test "`echo $NextMIB | grep -v '^$' | wc -l`" -eq "1" ; then
    InterfaceInfo=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" "$NextMIB"  2> /dev/null | 
     sed -e 's/^.*INTEGER: \(.*\)$/\1/'`
    InterfaceInfo=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.17.1.4.1.2 2> /dev/null|
     grep "INTEGER: $InterfaceInfo" |
     sed -e 's/^.*INTEGER: \(.*\)$/\1/'`
    is_exist=1
  fi
 fi

 if test `snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" $mibid_qbridge 2> /dev/null | wc -l ` -ge 2 ; then
   echo "USING QBRIDGE"
   targetmib=$mibid_qbridge
   InterfaceInfo=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" "$targetmib".$ADDR101.$ADDR102.$ADDR103.$ADDR104.$ADDR105.$ADDR106 2> /dev/null |
    grep "INTEGER: $InterfaceInfo" |
    sed -e 's/^.*INTEGER: \(.*\)$/\1/'`
   is_exist=1
 fi

 if test "$is_exist" -eq 1 ; then
  InterfaceName=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.31.1.1.1.1.$InterfaceInfo  2> /dev/null |
   sed -e 's/^.*STRING: \(.*\)$/\1/'`
  InterfaceDesc=`snmpwalk -On -c "$SNMPCOM" -v 2c "$RouterName" .1.3.6.1.2.1.31.1.1.1.18.$InterfaceInfo  2> /dev/null |
   sed -e 's/^.*STRING: \(.*\)$/\1/'`
  echo "$RouterName: $InterfaceName($InterfaceDesc)"
 else
  echo "$RouterName: ---------"
 fi
done
