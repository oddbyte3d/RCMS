#!/bin/bash


echo $1
echo $2

find . -iname "*$1" | rename -v -f "s/$1/$2/g"
