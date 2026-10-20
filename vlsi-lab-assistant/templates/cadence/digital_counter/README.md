# Counter starter (Xcelium + Genus)

```
cp -r templates/cadence/digital_counter projects/counter && cd projects/counter
vlab xrun -w tb_counter.v counter.v      # expect "TEST PASSED" in the log
# edit LIB_PATH / LIB_FILES in syn.tcl, then:
vlab genus -w syn.tcl                     # reports/ and outputs/
```
