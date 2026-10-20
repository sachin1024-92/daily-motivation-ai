# PN diode starter (Sentaurus)

```
cp -r templates/sentaurus/pn_diode projects/diode && cd projects/diode
vlab sde -w diode_dvs.cmd
vlab sdevice -w diode_des.cmd
vlab plt2csv diode_des.plt iv.csv --cols "anode"
```
This is a minimal example to check that the toolchain, licenses and vlab work end to
end. For real devices (MOSFET, FinFET, power devices), start from the
`Applications_Library` that ships with your Sentaurus release.
