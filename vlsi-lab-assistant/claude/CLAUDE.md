<!-- vlab-managed: this file is installed by `vlab setup`; your edits are kept unless you re-run setup -->
# VLSI lab workstation: working notes for Claude

You're running on a student's allocated Linux workstation in the VLSI lab at
IIITDM. The student often drives you remotely from the Claude app (Remote
Control), so they usually **can't see this screen**. Report what you did and
what you found in text, and include numbers.

## Environment
- `vlab` is the helper CLI for this machine (`vlab help`). Run `vlab doctor` first if
  anything about tools, licenses or paths seems off.
- EDA tools are loaded by `vlab` from the user's config (`~/.config/vlab/vlab.conf`).
  In a fresh shell, run `eval "$(vlab env)"` before you call a tool directly.
- Synopsys **Sentaurus TCAD** (sde, sprocess, sdevice, svisual, inspect, swb/gsub) and
  **Cadence** (virtuoso, spectre, ocean, xrun, genus, innovus) may be installed. Check
  with `command -v <tool>` before assuming.
- This workspace may be on the **shared college network drive**. Other students' and
  staff folders sit next to it.

## Hard rules
1. **Don't delete, move or overwrite anything outside this workspace.** On the network
   drive, never touch other people's folders, PDK/library installs, or tool installs.
2. **Treat PDKs, foundry decks and tool installs as read-only.** Copy what you need into
   the project.
3. **Never write passwords, license keys, tokens or SSH keys** into files, and never
   print them. Don't read `~/.ssh` or `~/.claude/.credentials.json`.
4. **Licenses are shared by the whole lab.** Don't launch more than 2 licensed jobs at
   once unless the user asks for it. Check `vlab jobs` and `vlab lic` first. Kill jobs
   you started that hang.
5. **Run long work with `vlab`, not with a bare command.** Simulations can outlast your
   10-minute tool timeout and the remote connection. `vlab` detaches the job, logs it,
   and keeps it running.
6. GUIs (Virtuoso, Sentaurus Workbench, svisual) need a display the remote user can't
   see. Use batch modes. If you must check a GUI, use `vlab snap` to take a
   screenshot and then read the PNG.
7. Ask before you run anything that takes more than about 30 minutes or uses more than
   4 cores, and before any change to `~/.cshrc`, `~/.bashrc` or crontab.

## How to run things
```
vlab sde -w device_dvs.cmd        # -w waits up to ~9 min, then prints status + log tail
vlab sdevice device_des.cmd       # without -w: returns immediately with a job id
vlab wait <job>                   # wait again (prints status + last 40 log lines)
vlab show <job>                   # errors/warnings summary
vlab jobs | vlab log -n 200 <job> | vlab kill <job>
vlab spectre -w tb.scs            # PSF-ASCII results in tb.raw/
vlab psf2csv tb.raw               # -> tb.raw/csv/*.csv
vlab plt2csv n1_des.plt --list    # Sentaurus curves -> CSV
vlab run -n name -d dir -- <any command>
```
If `vlab wait` returns "still running", keep calling `vlab wait <job>` (each call is
under 10 min). Tell the user the job id so they can check later with `vlab jobs`.

## Workflow for any task
1. Work in `projects/<short-name>/`. Make the folder if needed and keep inputs,
   scripts and results together.
2. Before you write a deck from scratch, look for a working example to adapt:
   - Sentaurus: `$STROOT/tcad/$STRELEASE/Applications_Library` (or search under
     `$STROOT` for `*_dvs.cmd`, `*_des.cmd`, `*_fps.cmd`).
   - Cadence: the PDK's docs/examples and the user's existing libraries (`cds.lib`).
3. Run the tool, then **read the log** for errors before you report success.
   Convergence failures, missing licenses and missing models are the usual causes.
4. Pull out results numerically (plt2csv / psf2csv, then python3) and report the key
   numbers (Vth, Ion/Ioff, SS, delay, power, gain, and so on). Save plots as PNG if
   matplotlib is available (`python3 -c "import matplotlib"`).
5. Write a short `projects/<name>/NOTES.md`: what was run, the command lines,
   results, and open issues. The student reads it later.

See the skills in `.claude/skills/` for tool-specific recipes, and `templates/` for
starter decks.
