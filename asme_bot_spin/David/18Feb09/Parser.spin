{
 ************************************************************************************************************
 *                                                                                                          *
 *  AUTO-RECOVER NOTICE: This file was automatically recovered from an earlier Propeller Tool session.      *
 *                                                                                                          *
 *  ORIGINAL FOLDER:     C:\David.Gitz\Robots\ASME Design\Controller\Program\18Feb09\                       *
 *  TIME AUTO-SAVED:     over 1 day ago (2/18/2009 4:40:59 PM)                                              *
 *                                                                                                          *
 *  OPTIONS:             1)  RESTORE THIS FILE by deleting these comments and selecting File -> Save.       *
 *                           The existing file in the original folder will be replaced by this one.         *
 *                                                                                                          *
 *                           -- OR --                                                                       *
 *                                                                                                          *
 *                       2)  IGNORE THIS FILE by closing it without saving.                                 *
 *                           This file will be discarded and the original will be left intact.              *
 *                                                                                                          *
 ************************************************************************************************************
.}
CON

  CR = 13                                               ' ASCII <CR>
  LF = 10                                               ' ASCII <LF>
  comlen = 5
  
VAR  
   long serialstack[10] 
   byte GPRMCb[68],GPGGAb[80],PGRMZb[40]   
   long GPRMCa[20],GPGGAa[20],PGRMZa[20]

   long DRIVEvalue
   long STEERvalue
   long CLAWvalue
   long CONVvalue
   long GATEvalue
   
  
   byte DRIVEstr[5]
   byte STEERstr[5]
   byte CLAWstr[5]
   byte CONVstr[5]
   byte GATEstr[5]
   
   byte serialbuff[80],Rx',cksum
   long cog,cptr,ptr,arg
   long Null[1]
OBJ

  UART :  "FullDuplexSerial"
  UTIL :  "Util"

DAT

  DRIVEcon  byte  "DRIVE", 0
  STEERcon  byte  "STEER", 0
  CLAWcon   byte  "CLAW_", 0
  CONVcon  byte  "CONV_", 0
  GATEcon  byte  "GATE_", 0

PUB start(serialRxPin, serialTxPin, serialMode, serialBaud) : okay

'' Starts uart object (at baud specified) in a cog
'' -- returns false if no cog available

  okay := UART.start(serialRxPin,serialTxPin,serialMode,serialBaud)
  return cog := cognew(readserialport,@serialstack) + 1 

PUB  readserialport | i, j, teststr, strvalue


  Null[0] := 0
  repeat
   longfill(serialbuff,14,0)
   repeat while Rx <>= "$"      ' wait for the $ to insure we are starting with
     Rx := UART.rx              '   a complete NMEA sentence 
   cptr := 0

   repeat while Rx <>= CR       '  continue to collect data until the end of the NMEA sentence 
     Rx := UART.rx              '  get character from Rx Buffer
     if Rx == ","
       serialbuff[cptr++] := 0    '  If "," replace the character with 0
     else
       serialbuff[cptr++] := Rx   '  else save the character
   repeat i from 0 to comlen
     teststr[i] := serialbuff[i]
    
   if(strcomp(teststr,@DRIVEcon)) ' Received Drive Command
     j := 0
     repeat i from (comlen + 1) to strsize(serialbuff)
       DRIVEstr[j] := serialbuff[i]
       j++    

   elseif(strcomp(teststr,@STEERcon)) ' Received Steer Command
     j := 0
     repeat i from (comlen + 1) to strsize(serialbuff)
       STEERstr[j] := serialbuff[i]
       j++

   elseif(strcomp(teststr,@CLAWcon)) ' Received Claw Command
     j := 0
     repeat i from (comlen + 1) to strsize(serialbuff)
       CLAWstr[j] := serialbuff[i]
       j++

   elseif(strcomp(teststr,@CONVcon)) ' Received Conveyor Command
     j := 0
     repeat i from (comlen + 1) to strsize(serialbuff)
       CONVstr[j] := serialbuff[i]
       j++

   elseif(strcomp(teststr,@GATEcon)) ' Received Gate Command
     j := 0
     repeat i from (comlen + 1) to strsize(serialbuff)
       GATEstr[j] := serialbuff[i]
       j++  
PUB DRIVE
  return UTIL.strntodec(@DRIVEstr,0)

PUB STEER
  return UTIL.strntodec(@STEERstr,0) 
   
PUB CLAW
  return UTIL.strntodec(@CLAWstr,0) 

PUB CONV
  return UTIL.strntodec(@CONVstr,0) 

PUB GATE
  return UTIL.strntodec(@GATEstr,0)          