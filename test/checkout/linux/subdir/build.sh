#!/bin/bash
FILE='!#$%&'\''()*+,-.0123456789:;<=>?@[\]^_`{|}~.tex'
cp test.tex $FILE
cluttex -e uplatex --synctex=1 $FILE

