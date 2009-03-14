{ mIZZLE }
CON

  CR = 13                                               ' ASCII <CR>
  LF = 10                                               ' ASCII <LF>
  ES = 27
  
  comlen = 5
  Delay = 100_000

  LDrivePin = 2
  RDrivePin = 3
  ClawPin = 4
  GatePin = 5
  ConvPin = 6
  
VAR
   long serialstack[1024] 'Cut me some stack 

   long DRIVEvalue
   long STEERvalue
   long CLAWvalue
   long CONVvalue
   long GATEvalue
   
   byte serialbuff[80],Rx',cksum
   long cog,cptr,ptr,arg
   
OBJ

  UART :  "FullDuplexSerial"
  UTIL :  "Util"
  PWM  : "Servo32v3"

DAT

  DRIVEcon  byte  "DRIVE", 0
  STEERcon  byte  "STEER", 0
  CLAWcon   byte  "CLAW_", 0
  CONVcon   byte  "CONV_", 0
  GATEcon   byte  "GATE_", 0

PUB start(serialRxPin, serialTxPin, serialMode, serialBaud) : okay

'' Starts uart object (at baud specified) in a cog
'' -- returns false if no cog available
  okay := UART.start(serialRxPin,serialTxPin,serialMode,serialBaud)
  
  return cog := cognew(readserialport,@serialstack) + 1 

PUB  readserialport | i, j, teststr, strvalue, LDrive, RDrive

  repeat i from LDrivePin to (LDrivePin + 4)  ' Preset all PWM's
    PWM.Set(i,1500)

  PWM.Start
  
  repeat
  
    longfill(serialbuff,14,0)

    repeat while Rx <>= ES
      UART.tx(Rx)
      Rx := UART.rx

    repeat while UART.rxcheck == -1
      Rx := 0
      
    Rx := UART.rx
    
    if(Rx == "A")
      UART.str(string("UP"))
      UART.tx(CR)
      UART.tx(LF)

    if(Rx == "B")
      UART.str(string("DOWN"))
      UART.tx(CR)
      UART.tx(LF)
    
    if(Rx == "C")
      UART.str(string("RIGHT"))
      UART.tx(CR)
      UART.tx(LF)
    
    if(Rx == "D")
      UART.str(string("LEFT"))
      UART.tx(CR)
      UART.tx(LF)
    
    'repeat while Rx <>= "$"      ' wait for the $ to insure we are starting with
    '  Rx := UART.rx              '   a complete NMEA sentence
       
    'cptr := 0

    'repeat while Rx <>= CR       '  continue to collect data until the end of the NMEA sentence 
    '  Rx := UART.rx              '  get character from Rx Buffer
    '  UART.tx(Rx)
    '  serialbuff[cptr++] := Rx     '  else save the character

    'serialbuff[cptr] := 0
   
    'UART.str(string("<CR>"))
    'UART.str(@serialbuff)
    'UART.dec(cptr)
   
    if(strcomp(@serialbuff,@DRIVEcon)) ' Received Drive Command
      DRIVEvalue := UTIL.strntodec(@serialbuff[6], 0)
      UART.str(string("DRIVE command recieved"))
      UART.tx(CR)
      UART.tx(LF)
      UART.dec(DRIVEvalue)
     
    elseif(strcomp(@serialbuff,@STEERcon)) ' Received Steer Command
      STEERvalue := UTIL.strntodec(@serialbuff[6],0)
      UART.str(string("STEER command recieved"))
      UART.tx(CR)
      UART.tx(LF)
      UART.dec(STEERvalue)
      
    elseif(strcomp(@serialbuff,@CLAWcon)) ' Received Claw Command
      UART.str(string("CLAW command recieved"))
      UART.tx(CR)
      UART.tx(LF)
      CLAWvalue := UTIL.strntodec(@serialbuff[6],0)
      UART.dec(CLAWvalue)
      PWM.Set(ClawPin, CLAWvalue)
    
    elseif(strcomp(@serialbuff,@CONVcon)) ' Received Conveyor Command
      CONVvalue := UTIL.strntodec(@serialbuff[6], 0)
      PWM.Set(CONVPin, CONVValue)
      UART.str(string("CONV command recieved"))
      UART.tx(CR)
      UART.tx(LF)
      UART.dec(CONVvalue)

    elseif(strcomp(@serialbuff,@GATEcon)) ' Received Gate Command
      GATEvalue := UTIL.strntodec(@serialbuff[6], 0)  
      PWM.Set(GatePin, GATEvalue)
      UART.str(string("GATE command recieved"))
      UART.tx(CR)
      UART.tx(LF)
      UART.dec(GATEvalue)

    LDrive := 1000 #> (DRIVEvalue + STEERvalue - 1500) <# 2000
    RDrive := 1000 #> (DRIVEvalue - STEERvalue + 1500) <# 2000
    PWM.Set(LDrivePin, LDrive)
    PWM.Set(RDrivePin, RDrive)
    waitcnt(Delay + cnt)
                                                                                                                                                                                                                                                                                                                                                                                                             