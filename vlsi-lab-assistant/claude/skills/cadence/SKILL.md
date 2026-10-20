---
name: cadence
description: Drive Cadence tools headless on this lab machine - Spectre circuit simulation, OCEAN scripts, Virtuoso SKILL in -nograph mode (netlisting, library queries, layout/schematic automation), Xcelium (xrun) for Verilog/SystemVerilog, Genus synthesis and Innovus place-and-route. Use for any analog/digital circuit, schematic, layout, netlist, .scs, .ocn, .il, RTL or synthesis task.
---

# Cadence tools in batch mode

| Task | Command (via vlab) | Notes |
|---|---|---|
| Spectre netlist sim | `vlab spectre -w tb.scs` | runs `spectre +escchars -format psfascii -raw tb.raw +log tb.spectre.log tb.scs` |
| Results → CSV | `vlab psf2csv tb.raw` | one CSV per analysis in `tb.raw/csv/` |
| OCEAN script | `vlab ocean -w run.ocn` | script **must end with `exit`** or it hangs |
| SKILL (no GUI) | `vlab skill -w script.il` | `virtuoso -nograph -replay`; **end with `(exit)`**; log in `script.CDS.log` |
| Verilog/SV sim | `vlab xrun -w tb.sv dut.v -access +r` | add `-gui` only if the user is at the machine |
| Synthesis | `vlab genus -w syn.tcl` | script ends with `exit` |
| P&R | `vlab innovus -w pnr.tcl` | script ends with `exit` |

Virtuoso and the netlister must start in the directory that holds the user's `cds.lib`
(often `~/cadence` or a course folder). Find it with `find ~ -maxdepth 3 -name cds.lib`.
Run SKILL/OCEAN from there with `vlab run -d <that dir> -- ...`. The `vlab skill`
shortcut runs in the script's own folder, so put the script next to `cds.lib`
or use `vlab run`.

## Recipes
**Simulate a schematic the user drew in Virtuoso (no GUI):**
1. Netlist it with OCEAN (in the cds.lib dir):
   ```
   simulator('spectre)
   design("myLib" "inv_tb" "schematic")
   resultsDir("./sim/inv_tb")
   modelFile('("/path/from/PDK/models.scs" "tt"))   ; copy from the user's ADE state or PDK docs
   analysis('tran ?stop "10n")
   temp(27)
   run()
   selectResult('tran)
   ocnPrint(v("/out") ?output "./sim/inv_tb/out.txt" ?numberNotation 'scientific)
   printf("delay=%g\n" delay(?wf1 v("/in") ?value1 0.9 ?edge1 'rising ?wf2 v("/out") ?value2 0.9 ?edge2 'falling))
   exit
   ```
   Get the PDK model file and corner from the user's ADE setup or the PDK's docs. Don't
   guess.
2. Run: `vlab run -n inv_tb -d <cds.lib dir> --wait -- ocean -nograph -replay run.ocn`

**Plain netlist (no PDK needed for quick checks):** see `templates/cadence/inverter_tb.scs`.
It uses built-in level-1 models. Replace them with PDK models for real work.

**SKILL query example (list cells of a library):**
```
lib = ddGetObj("myLib")
foreach(c lib~>cells printf("%s %L\n" c~>name c~>views~>name))
exit()
```

**Digital flow:** RTL → `vlab xrun` (functional sim) → `vlab genus` (needs the .lib and
LEF from the standard-cell kit; find them under the PDK) → `vlab innovus`. Report area,
timing slack (WNS/TNS) and power from the Genus/Innovus reports (`report_timing`,
`report_area`, `report_power`).

## Reading results
- Spectre logs: the "Notice/Warning/Error" lines in `*.spectre.log`. Look for
  "No DC solution", "timestep too small", or missing models/subckts.
- PSF ASCII → `vlab psf2csv`, then compute metrics in python3: delay (50% crossings),
  rise/fall (10-90%), average power (`-mean(I(VDD))*VDD`), gain/UGB/phase margin from AC
  (`_db` and phase from `_re`/`_im`).
- Report numbers with units and the corner and temperature used.

## Don'ts
- Don't edit the PDK, `cds.lib` entries of other users, or shared libraries on the
  network drive. Make your own copy of the library when you need changes, and ask first.
- Don't leave Virtuoso running headless. Every script must `exit`, because a hung
  Virtuoso holds a license. If one hangs: `vlab kill <job>`.
