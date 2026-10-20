* Forward I-V of the PN diode (run: vlab sdevice -w diode_des.cmd)
* Then: vlab plt2csv diode_des.plt iv.csv --cols "anode"

File {
  Grid    = "diode_msh.tdr"
  Plot    = "diode_des.tdr"
  Current = "diode_des.plt"
  Output  = "diode_des.log"
}

Electrode {
  { Name="anode"   Voltage=0.0 }
  { Name="cathode" Voltage=0.0 }
}

Physics {
  Mobility( DopingDependence HighFieldSaturation )
  Recombination( SRH( DopingDependence ) Auger )
  EffectiveIntrinsicDensity( OldSlotboom )
}

Plot {
  eDensity hDensity
  ElectricField/Vector Potential SpaceCharge
  Doping DonorConcentration AcceptorConcentration
  eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
  SRHRecombination
}

Math {
  Extrapolate
  Derivatives
  RelErrControl
  Digits=5
  Iterations=20
  Notdamped=50
}

Solve {
  Coupled(Iterations=100) { Poisson }
  Coupled { Poisson Electron Hole }
  Quasistationary(
    InitialStep=0.01 MinStep=1e-5 MaxStep=0.04 Increment=1.4
    Goal { Name="anode" Voltage=1.0 }
  ) { Coupled { Poisson Electron Hole } }
}
