# Inverter starter (Spectre)

```
cp -r templates/cadence/spectre_inverter projects/inv && cd projects/inv
vlab spectre -w inverter_tb.scs
vlab psf2csv inverter_tb.raw          # -> inverter_tb.raw/csv/tran1.tran.tran.csv etc.
```
Then ask Claude for tpHL, tpLH, rise/fall time and average power from the CSV.
