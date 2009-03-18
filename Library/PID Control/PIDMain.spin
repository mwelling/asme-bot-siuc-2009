'DPG 19-Dec-07
'Stable Hover PID Loop
'Only models Translation movement, not Rotation

VAR
long CP[6]            'PID Current Point, Input
long SP[6]            'PID Set Points, in the form of [AccMainx AccMainy AccMainz AccTailx AccTaily AccTailz]
long Gain[6]          'PID Gain
long IT[6]            'PID Integral Time
long i




'Sensors
long AccMainx
long AccMainy
long AccMainz
long AccTailx
long AccTaily
long AccTailz 

'Outputs
long output[4]
long rotorpitch
long rotorroll
long rotorbladepitch
long tailbladepitch

            

CON

_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
DAT
  modehover byte  "HOVER", 0

OBJ
PIDControl : "PIDControl"


  

PUB Main(mode) | count

waitcnt(1_000_000 + cnt)
                      'Want to ensure that all accelerations are stable  This is only applicable for hovering mode.
                      'Eventually will have to allow to get new input for dynamic flight.

'Read all acceleration sensors
CP[0] := AccMainx
CP[1] := AccMainy
CP[2] := AccMainz
CP[3] := AccTailx
CP[4] := AccTaily
CP[5] := AccTailz

'Make set points equal to Stable Hover Mode                  


'Define Motion Outputs
output[0] := rotorpitch
output[1] := rotorroll
output[2] := rotorbladepitch
output[3] := tailbladepitch

  if strcomp(@mode, @modehover)
    SP[0] := 0
    SP[1] := 0
    SP[2] := -1
    SP[3] := 0
    SP[4] := 0
    SP[5] := -1



repeat i from 0 to 5
  Gain[i] := 10
  IT[i] := 1

PIDControl.Start(@CP,@SP,@Gain,@IT,@output)
    
