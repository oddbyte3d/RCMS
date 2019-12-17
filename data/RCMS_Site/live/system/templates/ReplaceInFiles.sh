#!/bin/bash

echo "------------------"
echo $1
echo $2
echo $3
echo "------------------"
find . -name "*$1" -exec sed -i -e "s/$2/$3/g" {} \;
