; 2D PN diode - Sentaurus Structure Editor (run: vlab sde -w diode_dvs.cmd)
; Starter template. Syntax can differ slightly between releases. If a command
; errors, compare with the Applications_Library examples of your release.
; Units: um. y points into the silicon (depth).
(sde:clear)

(define W 1.0)        ; width
(define D 2.0)        ; depth
(define Nsub 1e16)    ; n-type substrate doping [cm^-3]
(define Npeak 1e19)   ; p+ anode peak doping [cm^-3]
(define Xj 0.3)       ; junction depth [um]

; ---- geometry
(sdegeo:create-rectangle (position 0 0 0) (position W D 0) "Silicon" "R.Si")

; ---- contacts
(sdegeo:define-contact-set "anode"   4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "cathode" 4 (color:rgb 0 0 1) "##")
(sdegeo:set-current-contact-set "anode")
(sdegeo:define-2d-contact (find-edge-id (position (/ W 2) 0 0)) "anode")
(sdegeo:set-current-contact-set "cathode")
(sdegeo:define-2d-contact (find-edge-id (position (/ W 2) D 0)) "cathode")

; ---- doping
(sdedr:define-constant-profile "DP.Sub" "PhosphorusActiveConcentration" Nsub)
(sdedr:define-constant-profile-region "PL.Sub" "DP.Sub" "R.Si")
(sdedr:define-refeval-window "BL.Anode" "Line" (position 0 0 0) (position W 0 0))
(sdedr:define-gaussian-profile "DP.Anode" "BoronActiveConcentration"
  "PeakPos" 0 "PeakVal" Npeak "ValueAtDepth" Nsub "Depth" Xj "Gauss" "Factor" 0.8)
(sdedr:define-analytical-profile-placement "AP.Anode" "DP.Anode" "BL.Anode"
  "Positive" "NoReplace" "Eval")

; ---- mesh: coarse everywhere, fine near the junction
(sdedr:define-refeval-window "RW.All" "Rectangle" (position 0 0 0) (position W D 0))
(sdedr:define-refinement-size "RS.All" 0.1 0.1 0.02 0.005)
(sdedr:define-refinement-function "RS.All" "DopingConcentration" "MaxTransDiff" 1)
(sdedr:define-refinement-placement "RP.All" "RS.All" "RW.All")

; writes diode_msh.tdr
(sde:build-mesh "" "diode")
