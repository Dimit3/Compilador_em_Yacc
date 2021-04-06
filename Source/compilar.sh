#!/bin/bash

make clean
flex tp2.l
yacc -d tp2.y
gcc -o tp2 y.tab.c
./tp2 teste out
