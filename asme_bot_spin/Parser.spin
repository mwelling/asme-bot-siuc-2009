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

    repeat while Rx <>= "$"      ' wait for the $ to insure we are starting with
      Rx := UART.rx              '   a complete NMEA sentence
       
    cptr := 0

    repeat while Rx <>= CR       '  continue to collect data until the end of the NMEA sentence 
      Rx := UART.rx              '  get character from Rx Buffer
      serialbuff[cptr++] := Rx     '  else save the character

    serialbuff[cptr] := 0
    serialbuff[5] := 0
   
    if(strcomp(@serialbuff,@DRIVEcon)) ' Received Drive Command
      DRIVEvalue := UTIL.strntodec(@serialbuff[6], 0)
     
    elseif(strcomp(@serialbuff,@STEERcon)) ' Received Steer Command
      STEERvalue := UTIL.strntodec(@serialbuff[6],0)
      
    elseif(strcomp(@serialbuff,@CLAWcon)) ' Received Claw Command
      CLAWvalue := UTIL.strntodec(@serialbuff[6],0)
    
    elseif(strcomp(@serialbuff,@CONVcon)) ' Received Conveyor Command
      CONVvalue := UTIL.strntodec(@serialbuff[6], 0)

    elseif(strcomp(@serialbuff,@GATEcon)) ' Received Gate Command
      GATEvalue := UTIL.strntodec(@serialbuff[6], 0)  

    LDrive := 1000 #> (DRIVEvalue + STEERvalue - 1500) <# 2000
    RDrive := 1000 #> (DRIVEvalue - STEERvalue + 1500) <# 2000

    PWM.Set(ClawPin, CLAWvalue)
    PWM.Set(CONVPin, CONVValue)
    PWM.Set(GatePin, GATEvalue)
    PWM.Set(LDrivePin, LDrive)
    PWM.Set(RDrivePin, RDrive)

    waitcnt(Delay + cnt)
                                                                                                                                                                                                                                                                                                                                                                                                             