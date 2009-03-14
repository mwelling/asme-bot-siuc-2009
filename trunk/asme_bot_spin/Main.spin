CON
  
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  serialRxPin = 1
  serialTxPin = 0
  serialMode = 0
  serialBaud = 115200


  LEDPin  = 7

  Delay = 80_000_000
OBJ
  PARSER : "Parser"

VAR

PUB Main| i
  
  dira[LEDPin]~~
  PARSER.start(serialRxPin, serialTxPin, serialMode, serialBaud)
  repeat
    !outa[LEDpin]
    waitcnt(Delay + cnt)
  