---
name: sentaurus
description: Run and debug Synopsys Sentaurus TCAD (sde, sprocess, sdevice, svisual, inspect, Sentaurus Workbench / swb / gsub) in batch mode on this lab machine, and extract device metrics such as Id-Vg, Vth, SS, Ion/Ioff and breakdown. Use for any TCAD, device simulation, *_dvs.cmd, *_des.cmd, *_fps.cmd, .plt or .tdr task.
---

# Sentaurus TCAD in batch mode

## Tools and file conventions
| Tool | Input | Batch command (via vlab) | Main outputs |
|---|---|---|---|
| Sentaurus Structure Editor | `*_dvs.cmd` (Scheme) | `vlab sde -w file_dvs.cmd` → `sde -e -l` | `*_msh.tdr` mesh |
| Sentaurus Process | `*_fps.cmd` (Tcl) | `vlab sprocess -w file_fps.cmd` | `*_fps.tdr` |
| Sentaurus Device | `*_des.cmd` | `vlab sdevice -w file_des.cmd` | `*_des.plt` (curves), `*_des.tdr` (fields), `*_des.log` |
| Sentaurus Visual | Tcl | `vlab svisual -w script.tcl` → `svisual -b` | images and exported data |
| Inspect (legacy) | `*.cmd` | `vlab inspect -w file.cmd` | |
| Workbench project | project dir with `gtree.dat` | `vlab swb -w <project>` (uses `$VLAB_SWB_CMD`, default `gsub -e all`) | `n<node>_*` files |

Sentaurus finds its install through `STROOT` / `STRELEASE` (set by the env scripts in
the vlab config). Check with `vlab doctor`.

## Recipes
**Run a single deck chain (no Workbench):**
```
cd projects/<name>
vlab sde -w diode_dvs.cmd          # builds diode_msh.tdr
vlab sdevice -w diode_des.cmd      # simulates, writes diode_des.plt
vlab plt2csv diode_des.plt --list  # see curve names
vlab plt2csv diode_des.plt iv.csv --cols "OuterVoltage,TotalCurrent"
```
In a Workbench project the files use `@node@` / `@param@` substitution. You can't
run them standalone until you replace those (or use `vlab swb`).

**Run a Workbench project headless:** `vlab swb -w ~/path/to/project`. Run `gsub -h`
first to confirm the syntax for this release. Some releases also ship `swbcli`. For one
node: `gsub -e "n5" <project>`. Results are in the project dir as `n<node>_des.plt`.

**Find working examples first:**
```
ls $STROOT/tcad/$STRELEASE/Applications_Library 2>/dev/null
find $STROOT -name '*_des.cmd' -path '*Applications_Library*' | head
```
Copy an example into `projects/` and adapt it. Don't write a deck from scratch
when a library example is close.

## Extracting metrics (python3, from the CSV)
- **Vth (constant current):** Vg where Id/(W/L) crosses 1e-7 A (or the lab's
  convention). Without W, sdevice 2D current is per µm of width (A/µm).
- **Vth (max gm / linear extrapolation):** gm = dId/dVg; at the max-gm point, extrapolate
  the tangent to Id = 0 and subtract Vd/2 for linear-region data.
- **SS:** min over the subthreshold region of dVg/dlog10(Id), in mV/dec.
- **Ion / Ioff:** Id at Vg = Vdd / Vg = 0 at Vd = Vdd.
- **DIBL:** (Vth_lin - Vth_sat) / (Vd_sat - Vd_lin), in mV/V.
Report units and the extraction method you used.

## Debugging checklist (read `*_des.log` / the vlab log)
- `license` / `checkout failed` → `vlab lic`; another job may hold the license. Wait or
  tell the user.
- "did not converge" / tiny step size near the end of a ramp → refine the mesh where the
  doping changes, lower `MaxStep`, add `Extrapolate`, and ramp contacts one at a time
  (`Quasistationary` with `Goal` per electrode). Solve `Poisson` alone first, then
  `Coupled { Poisson Electron Hole }`.
- Electrode / region name mismatches between the `_dvs.cmd` contacts and the `Electrode{}`
  section are a common silent error. Compare the names.
- Mesh too big / slow → check the node count in the SDE log. Coarsen the refinement
  outside the active region.
- For field plots the remote user wants to see: use svisual batch to export a PNG, or
  explain the result in numbers.
