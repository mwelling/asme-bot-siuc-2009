CON
  
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  serialRxPin = 0
  serialTxPin = 1
  serialMode = 0
  serialBaud = 115200

  LDrivePin = 2
  RDrivePin = 3
  ClawPin = 4
  GatePin = 5
  ConvPin = 6
  LEDPin  = 7

  Delay = 1_000_000
OBJ
  PARSER : "Parser"
  PWM  : "Servo32v3"
  UTIL   : "Util"
VAR
   long DRIVEvalue
   long STEERvalue
   long CLAWvalue
   long CONVvalue
   long GATEvalue

   long Drive[2]


PUB Main| i

  dira[LEDPin]~~
  repeat i from LDrivePin to (LDrivePin + 4)  ' Preset all PWM's
    PWM.Set(i,1500)
  PARSER.start(serialRxPin, serialTxPin, serialMode, serialBaud)

  repeat
   !outa[LEDpin]
   
   DRIVEvalue := Parser.DRIVE
   STEERvalue := Parser.STEER
   CLAWvalue := Parser.CLAW
   GATEvalue := Parser.GATE 
   CONVvalue := Parser.CONV

   Drive := UTIL.mix(DRIVEvalue, STEERvalue) 'Get Motor Values for Arcade Mix 

   PWM.Set(Drive[0], LDrivePin)
   PWM.set(Drive[1], RDrivePin)
   PWM.Set(ClawPin, CLAWvalue)
   PWM.Set(GatePin, GATEvalue)
   PWM.Set(ConvPin, CONVvalue)

   waitcnt(Delay + cnt)
  