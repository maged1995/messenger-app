#!/bin/bash

green=$(date -d "$1" +%s)
blue=$(date -d "$2" +%s)

if [ $green -gt $blue ] ; then
echo green
elif [ $green -eq $blue ] ; then
echo blue
else
echo blue
fi