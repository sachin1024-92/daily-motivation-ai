#!/usr/bin/env python3
"""Convert a Sentaurus DF-ISE xyplot file (*.plt) to CSV.

usage: vlab plt2csv file.plt [out.csv] [--list] [--cols "pat1,pat2"]

  --list         only print the dataset (column) names
  --cols a,b     keep columns whose name contains any of the substrings
Without out.csv the CSV is written next to the input (file.csv).
Python 3.6+, no third-party packages.
"""
import re
import sys


def parse_plt(text):
    m = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m:
        raise ValueError("no 'datasets = [...]' block - is this a DF-ISE .plt file?")
    names = re.findall(r'"([^"]*)"', m.group(1))
    d = re.search(r"Data\s*\{(.*)\}", text, re.S)
    if not d:
        raise ValueError("no 'Data { ... }' block")
    values = d.group(1).split()
    n = len(names)
    if n == 0:
        raise ValueError("no datasets")
    rows = [values[i:i + n] for i in range(0, len(values) - len(values) % n, n)]
    return names, rows


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opts = argv
    if not args or "-h" in opts or "--help" in opts:
        print(__doc__)
        return 2
    src = args[0]
    with open(src, errors="replace") as fh:
        names, rows = parse_plt(fh.read())
    if "--list" in opts:
        for i, nm in enumerate(names):
            print("%3d  %s" % (i, nm))
        print("(%d points)" % len(rows))
        return 0
    keep = list(range(len(names)))
    if "--cols" in opts:
        pats = opts[opts.index("--cols") + 1].split(",")
        args = [a for a in args if a != opts[opts.index("--cols") + 1]]
        keep = [i for i, nm in enumerate(names) if any(p.strip() in nm for p in pats)]
        if not keep:
            raise SystemExit("no column matches %s" % pats)
    out = args[1] if len(args) > 1 else re.sub(r"\.plt$", "", src) + ".csv"
    with open(out, "w") as fh:
        fh.write(",".join('"%s"' % names[i] for i in keep) + "\n")
        for r in rows:
            fh.write(",".join(r[i] for i in keep) + "\n")
    print("wrote %s  (%d columns x %d points)" % (out, len(keep), len(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
