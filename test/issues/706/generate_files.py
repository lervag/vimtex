#!/usr/bin/env python

for fname in ['example_%05d.tex' % numb for numb in range(100000)]:
    with open(fname, 'w'):
        pass
