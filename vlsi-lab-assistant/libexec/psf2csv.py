#!/usr/bin/env python3
"""Convert Spectre PSF-ASCII results to CSV (best effort).

usage: vlab psf2csv <psf-file | raw-dir> [out.csv | out-dir] [--list]

Run Spectre with `-format psfascii` (vlab spectre does this) so results are
text. Given a raw directory, every analysis file in it is converted.
Swept analyses (tran, dc sweep, ac) become one row per sweep point; complex
AC values become <name>_re/_im/_mag/_db/_phase_deg columns.
Non-swept results (dcOp, info) become two columns: name,value.
Python 3.6+, no third-party packages.
"""
import math
import os
import re
import sys

TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"|\(|\)|[^\s()]+')
SECTIONS = ("HEADER", "TYPE", "SWEEP", "TRACE", "VALUE", "END")


def tokens(text):
    for t in TOKEN.findall(text):
        yield t


def is_num(t):
    try:
        float(t)
        return True
    except ValueError:
        return t.lower() in ("nan", "inf", "-inf")


def parse_psf(text):
    """Return (sweep_name or None, columns, rows) where rows are dicts."""
    if "VALUE" not in text:
        raise ValueError("not a PSF-ASCII file (no VALUE section)")
    head, _, body = text.partition("\nVALUE")
    sweep = None
    m = re.search(r'\nSWEEP\s+"([^"]+)"', head)
    if m:
        sweep = m.group(1)
    body = body.rsplit("\nEND", 1)[0]
    toks = list(tokens(body))
    rows, cur, cols = [], None, []
    i = 0

    def put(name, val):
        if name not in cols:
            cols.append(name)
        cur[name] = val

    if sweep is None:
        cur = {}
    while i < len(toks):
        t = toks[i]
        if not t.startswith('"'):
            i += 1
            continue
        name = t[1:-1]
        i += 1
        # optional type name, e.g. "V" / "I" / "real"
        if i < len(toks) and toks[i].startswith('"'):
            i += 1
        if i >= len(toks):
            break
        if toks[i] == "(":
            j = toks.index(")", i)
            parts = [p for p in toks[i + 1:j] if is_num(p)]
            i = j + 1
            val = complex(float(parts[0]), float(parts[1])) if len(parts) >= 2 else (
                float(parts[0]) if parts else None)
        elif is_num(toks[i]):
            val = float(toks[i])
            i += 1
        else:
            val = toks[i].strip('"')
            i += 1
        # skip PROP( ... ) blocks after a value
        if i < len(toks) and toks[i] == "PROP":
            depth = 0
            while i < len(toks):
                if toks[i] == "(":
                    depth += 1
                elif toks[i] == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
        if sweep is not None and name == sweep:
            cur = {}
            rows.append(cur)
        if cur is None:
            continue
        put(name, val)
    if sweep is None:
        rows = [cur]
    return sweep, cols, rows


def fmt(v):
    return "" if v is None else ("%.9g" % v if isinstance(v, float) else str(v))


def write_csv(sweep, cols, rows, out):
    with open(out, "w") as fh:
        if sweep is None:
            fh.write("name,value\n")
            for c in cols:
                v = rows[0].get(c)
                if isinstance(v, complex):
                    v = "%g%+gj" % (v.real, v.imag)
                fh.write('"%s",%s\n' % (c, fmt(v)))
            return len(cols)
        cplx = {c for c in cols for r in rows[:5] if isinstance(r.get(c), complex)}
        hdr = []
        for c in cols:
            hdr += ["%s_re" % c, "%s_im" % c, "%s_mag" % c, "%s_db" % c, "%s_phase_deg" % c] if c in cplx else [c]
        fh.write(",".join('"%s"' % h for h in hdr) + "\n")
        for r in rows:
            out_vals = []
            for c in cols:
                v = r.get(c)
                if c in cplx:
                    v = v if isinstance(v, complex) else complex(v or 0)
                    mag = abs(v)
                    db = 20 * math.log10(mag) if mag > 0 else float("-inf")
                    out_vals += [fmt(v.real), fmt(v.imag), fmt(mag), fmt(db),
                                 fmt(math.degrees(math.atan2(v.imag, v.real)))]
                else:
                    out_vals.append(fmt(v))
            fh.write(",".join(out_vals) + "\n")
        return len(rows)


def convert(path, out, list_only):
    with open(path, errors="replace") as fh:
        text = fh.read()
    sweep, cols, rows = parse_psf(text)
    if list_only:
        print("%s: sweep=%s, %d signals, %d points" % (path, sweep, len(cols), len(rows)))
        for c in cols[:200]:
            print("   ", c)
        return
    n = write_csv(sweep, cols, rows, out)
    print("wrote %s  (%d %s)" % (out, n, "rows" if sweep else "values"))


def main(argv):
    list_only = "--list" in argv
    args = [a for a in argv if not a.startswith("--")]
    if not args or "-h" in argv:
        print(__doc__)
        return 2
    src = args[0]
    if os.path.isdir(src):
        outdir = args[1] if len(args) > 1 else os.path.join(src, "csv")
        if not list_only:
            os.makedirs(outdir, exist_ok=True)
        for f in sorted(os.listdir(src)):
            p = os.path.join(src, f)
            if not os.path.isfile(p) or f in ("logFile", "artistLogFile") or f.endswith(".csv"):
                continue
            try:
                with open(p, errors="replace") as fh:
                    if not fh.read(64).lstrip().startswith("HEADER"):
                        continue
                convert(p, os.path.join(outdir, f + ".csv"), list_only)
            except Exception as e:  # keep going on odd files
                print("skip %s: %s" % (f, e))
        return 0
    out = args[1] if len(args) > 1 else src + ".csv"
    convert(src, out, list_only)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
