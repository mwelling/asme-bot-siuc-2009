''DPG 26-Dec-07
CON

  CR = 13                                               ' ASCII <CR>
  LF = 10                                               ' ASCII <LF>
VAR  
   long gps_stack[10] 
   byte GPRMC[80]
   byte GPSLAT
   byte GPSLON
   

   byte gps_buff[80],Rx',cksum
   byte data[80]
   long cog,cptr,ptr,arg,j
   long Null[1]
   long flag[20]
   long count, i, strlen, strlenflag
OBJ
  uart :  "FullDuplexSerial_mini"
PUB Start : okay
  okay := uart.start(3,4,1,4800)
  return cog := cognew(readNEMA,@gps_stack) + 1
PUB readNEMA
  Null[0] := 0
  i := 0
  count := 0
  repeat
   longfill(gps_buff,20,0)
     strlen := strsize(@gps_buff)
     repeat i from 0 to strlen
      Rx := uart.rx
      if Rx == "$"
        flag[count] := i
        count++
      elseif Rx == ","
        flag[count] := i
        count++
      elseif Rx == CR
        flag[count] := i
        count++
     strlenflag := strsize(@flag) 
      
    
    repeat i from 1 to  strlenflag
      'data[i] :=         
    