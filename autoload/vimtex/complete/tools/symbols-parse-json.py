"""Blahrg."""
import json


with open('symbols.json') as fin:
    with open('symbols-json', 'w') as fout:
        for vals in json.load(fin).values():
            if 'commands' in vals:
                for k, v in vals['commands'].items():
                    if (v['symbol'] is not None
                            and len(k) > 3
                            and len(v['symbol']) == 1):
                        fout.write(
                            k[1:] + ' ' + v['symbol'] + "\n")
