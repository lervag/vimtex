#!/usr/bin/env python
"""Add symbols to complete files"""
import os


with open('tools/symbols') as f:
    D = dict([line.strip().split(' ') for line in f.readlines()])


def merge(filename):
    """Do the actions"""
    changed = False
    lines = []
    with open(filename) as f:
        for line in f.readlines():
            parts = line.strip().split()
            if len(parts) > 0:
                command = parts[0]
                symbol = D.get(command, '')
                if symbol:
                    changed = True
                    symbol = ' ' + symbol
                lines.append(command + symbol + "\n")

    if changed:
        print('Updated: ',filename)
        with open(filename, 'w') as f:
            for line in lines:
                f.write(line)


files = [f for f in os.listdir('.') if os.path.isfile(f)]
for f in files:
    merge(f)
