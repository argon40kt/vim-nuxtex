#!/usr/bin/env python3
import sys
# print(sys.argv[0])
viewer = sys.argv[1]
src = sys.argv[2].split(':', 2)
# @line:@col:@tex
line = src[0]
col = src[1]
tex = src[2]
print(viewer)
print("line = " + line)
print("column = " + col)
print("tex = " + tex)
