# vlab: Claude-powered VLSI lab assistant

`vlab` turns your allocated VLSI-lab Linux PC into a machine you can work on from
anywhere through the **Claude app** (phone, laptop, or claude.ai/code). Claude runs
**on the lab PC itself**. It can run Synopsys **Sentaurus TCAD** and **Cadence** tools
(Spectre, OCEAN, Virtuoso/SKILL, Xcelium, Genus, Innovus) in batch mode, watch long
simulations, read the logs, pull out the numbers, and report back to you.

```
 You (Claude app, anywhere) ──► Anthropic ◄── claude remote-control (lab PC, in tmux)
                                                 │
                                                 ├─ vlab sde / sdevice / swb ...   (Sentaurus)
                                                 ├─ vlab spectre / ocean / skill ... (Cadence)
                                                 ├─ job logs in <workspace>/.vlab/runs
                                                 └─ your files on the local disk / college network drive
```

No root or admin rights are needed. Everything installs into your home directory.

---

## 0. Before you start
- **Get permission.** Ask your lab in-charge / faculty advisor whether it's OK to run
  an AI agent on the lab PC and to keep it running remotely. Some labs restrict
  outbound connections or long-running processes.
- **Claude account.** Claude Code needs a paid Claude plan (Pro/Max/Team/Edu) or an
  API key. Remote Control needs a claude.ai login (not just an API key).
- **Internet from the lab PC.** The PC must reach `claude.ai` and `api.anthropic.com`,
  possibly through the campus proxy.
- Leave the PC **switched on** (don't shut it down when you leave) if you want to
  reach it from outside.

## 1. Install (on the lab PC, in a terminal)
Copy this `vlsi-lab-assistant` folder to the lab PC (git clone, pen drive, or the
network drive), then:

```bash
cd vlsi-lab-assistant
./install.sh
```
The installer:
1. copies vlab to `~/.local/share/vlab` and puts the `vlab` command in `~/.local/bin`
   (and adds that to PATH in `~/.bashrc`, plus `~/.cshrc` if you use tcsh/csh);
2. runs `vlab setup`, which asks for your **network-drive path**, your **workspace**
   folder and the **proxy**, auto-detects Sentaurus/Cadence install folders and setup
   scripts, and writes `~/.config/vlab/vlab.conf`;
3. installs Claude Code if it isn't there yet (into your home directory);
4. puts Claude's lab instructions (`CLAUDE.md`), permissions and skills into your
   workspace.

## 2. Tell vlab how your lab loads the tools
Open `~/.config/vlab/vlab.conf` and fill in what your lab uses. Usually you copy it
from your `~/.cshrc` or the lab's setup notes:

```bash
VLAB_ENV_SCRIPTS=(
  "/cad/cadence/cshrc.cadence"            # csh scripts are imported automatically
  "/cad/synopsys/sentaurus/setup.csh"
)
VLAB_EXPORTS=(
  "SNPSLMD_LICENSE_FILE=27020@licserver"  # ask the lab admin
  "CDS_LIC_FILE=5280@licserver"
)
```
`config/vlab.conf.example` lists every option. Then check:

```bash
vlab doctor
```
Fix anything marked `[FAIL]` / `[warn]` that matters to you: tools not found,
license server unreachable, no internet, and so on.

## 3. Log in to Claude once (at the lab PC)
```bash
cd ~/vlab-work          # your workspace
claude                  # type /login, finish in the browser, accept "trust this folder"
```
Exit with `/exit`.

## 4. Turn on remote access
```bash
vlab remote start       # runs `claude remote-control` inside tmux; it keeps running after you log out
vlab remote autostart   # optional: brings it back after reboots or crashes (uses your crontab)
```
Now open the **Claude app → Code** (or claude.ai/code) on your phone or laptop. The lab
PC's session shows up there. Type what you want, for example:

> Run the PN diode template in Sentaurus and give me the forward current at 0.7 V.

> My Workbench project is in projects/finfet. Run node 12 and extract Vth and SS.

> Simulate my inverter_tb schematic in myLib at tt/27 °C and report tpHL, tpLH and power.

> Is my sdevice job done yet? Any convergence errors?

Useful commands: `vlab remote status`, `vlab remote attach` (look at the live session;
detach with `Ctrl-b d`), `vlab remote log`, `vlab remote restart`, `vlab remote stop`.

You can also just work at the PC: `vlab start` opens Claude Code with all tools loaded.

---

## Command reference
| Command | What it does |
|---|---|
| `vlab setup` / `vlab doctor` | first-time setup / health check |
| `vlab env` | `eval "$(vlab env)"` loads the tool environment into a bash shell |
| `vlab start [dir]` | Claude Code in the terminal with the tool environment loaded |
| `vlab remote start\|stop\|status\|attach\|log\|autostart` | Remote Control session |
| `vlab sde\|sprocess\|sdevice\|svisual\|inspect [-w] FILE` | Sentaurus tools in batch |
| `vlab swb [-w] PROJECT` | whole Sentaurus Workbench project (`VLAB_SWB_CMD`) |
| `vlab spectre\|ocean\|skill\|genus\|innovus [-w] FILE` | Cadence tools in batch |
| `vlab xrun [-w] ARGS` | Xcelium |
| `vlab run [-n name] [-d dir] [-w] -- CMD...` | run any command as a logged job |
| `vlab jobs` / `show` / `log [-f]` / `wait` / `kill` / `clean` | manage jobs |
| `vlab plt2csv FILE.plt` | Sentaurus curves → CSV |
| `vlab psf2csv RAWDIR` | Spectre PSF-ASCII → CSV |
| `vlab lic` | license usage (lmstat) |
| `vlab snap` | screenshot of the X display, so Claude can look at a GUI |

Every job runs detached (`setsid`) with its own folder in
`<workspace>/.vlab/runs/<id>/`: `log`, `cmd`, `cwd`, `exit_code`, timings. A job keeps
running if you or Claude disconnect. `-w` waits up to `VLAB_WAIT_TIMEOUT` seconds
(default 9 min, so it fits in one Claude tool call) and prints the status and the end of
the log.

## Templates
`templates/` (also linked into your workspace) contains small known-good starters:
- `sentaurus/pn_diode`: SDE + sdevice forward I-V. Use it as a first smoke test.
- `cadence/spectre_inverter`: an inverter with built-in level-1 models (no PDK needed).
- `cadence/digital_counter`: Verilog + testbench (xrun) + Genus script.

## Network drive notes
- Keep your workspace inside **your own folder** on the drive. Claude is told never to
  touch other people's folders, PDKs or tool installs. Permissions for `rm`/`mv` always
  ask you first.
- Large `.tdr` / PSF results on a network drive are slow and eat quota. For heavy runs,
  a workspace on the local disk (e.g. `/home/<you>` or `/scratch/<you>` if your lab has
  one) is faster. Copy final results to the drive.
- Your Claude login lives in `~/.claude`. If your home folder is on the shared drive,
  `vlab doctor` checks that it isn't readable by others (`chmod 700 ~/.claude`).
  **Never** put API keys or passwords in files on the shared drive.

## Troubleshooting
- **`claude` doesn't install or crashes (old OS, e.g. CentOS 7 / glibc 2.17):** the
  current Claude Code needs a newer Linux than some lab images ship. Options: ask the
  admin for a newer OS image, or run Claude Code on a newer Linux machine you have
  access to and let it `ssh` into the lab PC to run tools there.
- **No internet / proxy:** set `VLAB_HTTPS_PROXY` in the config, then `vlab remote restart`.
- **Session not showing in the app:** `vlab remote attach`. It may be waiting for a
  login, an update, or the "trust this folder" prompt. Answer it, then detach.
- **Tool not found:** `vlab doctor` lists what is on PATH. Add the tool's `bin` folder to
  `VLAB_EXTRA_PATH`, or its setup script to `VLAB_ENV_SCRIPTS`.
- **License errors:** `vlab lic` shows who holds the licenses. Ask the admin for the
  correct `port@host`.
- **tmux missing:** vlab falls back to `screen`. If neither exists, ask the admin to
  install tmux.

## Uninstall
```bash
vlab remote stop; vlab remote no-autostart
rm -rf ~/.local/share/vlab ~/.local/bin/vlab ~/.config/vlab
```
Your workspace and results are left untouched.
