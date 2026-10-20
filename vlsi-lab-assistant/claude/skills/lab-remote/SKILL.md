---
name: lab-remote
description: How to work well when the student is driving this lab workstation remotely from the Claude app - checking on long simulations, reporting progress, handling disconnects, sharing results, and keeping shared lab resources (licenses, network drive, CPU) fair. Use when asked about job status, "is my simulation done", lab machine health, or how to get results to the user's phone/laptop.
---

# Working remotely on the lab machine

- **Status questions** ("is it done?", "what's running?"): run `vlab jobs` and then
  `vlab show <job>` for anything failed or recently finished. Give a short answer: job,
  state, elapsed time, the key result or the first real error.
- **Long jobs:** start them with `vlab ...` without `-w`, tell the user the job id, then
  `vlab wait <job>` in loops of up to 9 minutes while there's still useful work to do.
  Jobs keep running if the remote connection drops.
- **Machine health:** `uptime`, `free -h`, `df -h $VLAB_WORKSPACE`, and `vlab lic` for
  license usage. Network-drive quotas fill up fast with `.tdr` and PSF files. Point out
  big result folders (`du -sh projects/*`) and offer to clean up only the user's own
  old runs.
- **Getting results to the user:** they can't open files on this machine from their
  phone. Summarise the numbers in chat. Put small tables in markdown. Save plots as PNG
  in the project folder and tell the user where they are. If the user wants files off
  the machine, suggest committing them to their own git repo or copying them to their
  own folder on the network drive.
- **GUI-only steps** (drawing a schematic or layout by hand): say plainly that this needs
  the user at the machine or a remote desktop session. Offer the scripted route instead
  (SKILL to create instances and wires, or netlist-level simulation).
- **Fair use:** the lab's licenses and the network drive are shared by everyone at
  IIITDM. Don't start large parameter sweeps without asking. Space out licensed jobs.
  Kill anything you started that hangs.
