{
********************************************
DS1620.spin                            V1.0
********************************************

This object provides essential interface methods to the DS1620

Hi resolution temperature readings
reading/writing High and Low alarm settings

Please refer to the following link for further documentation
http://pdfserv.maxim-ic.com/en/ds/DS1620.pdf

}
CON
  WrHi          = $01                                   ' write TH (high temp)
  WrLo          = $02                                   ' write TL (low temp)

  WrCfg         = $0C                                   ' write configuration register

  StopC         = $22                                   ' stop conversion
  
  RdCntr        = $A0                                   ' read counter
  RdHi          = $A1                                   ' read TH
  RdLo          = $A2                                   ' read TL
  
  RdSlope       = $A9                                   ' read slope
  RdTmp         = $AA                                   ' read temperature
  
  RdCfg         = $AC                                   ' read configuration register
  
  StartC        = $EE                                   ' start conversion

VAR
  byte  dpin, cpin, rst, started

PUB stop

PUB start(data_pin, clock_pin, rst_pin)

'' Initializes DS1620 for one-shot mode with host CPU
    dpin := data_pin
    cpin := clock_pin
    rst := rst_pin
    started~~                                           ' flag sensor as started
    setcfg(%00000011)                                   ' set for CPU, one-shot mode

PUB lowrestempc : tc
'' Returns temperature in 0.01° C units ; i.e. 25°C returns 2500
'' -- resolution is 0.5° C
    if started
       tc := ReadRegister(RdTmp,9)                      ' read temp in 0.5° C units
       if tc > 255
          tc -= 512
       Result := tc * 50

PUB lowrestempf : tc
'' Returns temperature in 0.01° F units ; i.e. 80°F returns 8000
'' -- resolution is 0.9° F
    result := C2D(lowrestempc)                          ' convert to Fahrenheit

PUB highrestempc : tc |cr,cpd
'' Returns temperature in 0.01° C units ; i.e. 25°C returns 2500
'' -- resolution is 0.0625° C
    if started
       tc := ReadRegister(RdTmp,9)                      ' read temp in 0.5° C units
       if tc > 255
          tc -= 512
       tc >>= 1                 'Strip LSB divide by 2  ' Scale 0.5° units to 1° units
       tc *= 100                                        ' Scale 1° units to 0.01° units
       tc -= 25                                         ' Offset adjustment for high resolution conversion
       cr := ReadRegister(RdCntr,9)                     ' read remaining counts
       cpd := ReadRegister(RdSlope,9)                   ' read counts per degree
       tc += ((cpd - cr)*100)/ cpd                      ' calculate high resolution temperature value
       Result := tc
CON
''       Note: In the New RevA DS1620 chips, the Slope register($A9) will always read a value of 16
''             so it would be unnecessary to read the slope.  Simply hard code the 'cpd' value in the
''             above code with a value of 16 instead.

PUB highrestempf
'' Returns temperature in 0.01° F units ; i.e. 80°F returns 8000
'' -- resolution is 0.1125° F
    result := C2D(highrestempc)                         ' convert to Fahrenheit       

PUB setlow(alarm)
'' Sets low-level alarm
'' -- alarm level is passed in 1° units
    if started
       WriteRegister(WrLo,(alarm/100)<<1,9)             ' write low-level alarm value

PUB readlow
'' Read low-level alarm
'' -- alarm level is passed in 1° units
    if started
       Result := ReadRegister(RdLo,8)*50                ' read low-level alarm value

PUB sethigh(alarm)
'' Sets high-level alarm
'' -- alarm level is passed in 1° units
    if started
       WriteRegister(WrHi,(alarm/100)<<1,9)             ' write high-level alarm value

PUB readhigh
'' Read high-level alarm
'' -- alarm level is passed in 1° units
    if started
       Result := ReadRegister(RdHi,8)*50                ' read high-level alarm value

PUB StartConversion
    if started
       high(rst)
       shiftout(StartC, 8)                              ' select register
       ConversionReady                                  ' Wait for conversion to complete

PUB setcfg(mask)
    writecfg((readcfg & !mask) + mask)
    
PUB clrcfg(mask)
    writecfg(readcfg & !mask)

PUB Done
    Result := (readcfg & %10000000) / %10000000         ' Read DONE bit of the CONFIGURATION/STATUS REGISTER
    
PUB THF
    Result := (readcfg & %1000000) / %1000000           ' Read THF bit of the CONFIGURATION/STATUS REGISTER

PUB TLF
    Result := (readcfg & %100000) / %100000             ' Read TLF bit of the CONFIGURATION/STATUS REGISTER

PUB NVB
    Result := (readcfg & %10000) / %10000               ' Read NVB bit of the CONFIGURATION/STATUS REGISTER

PUB CPU
    Result := (readcfg & %10) / %10                     ' Read CPU bit of the CONFIGURATION/STATUS REGISTER

PUB ONE_SHOT
    Result := (readcfg & %1) / %1                       ' Read 1SHOT bit of the CONFIGURATION/STATUS REGISTER

PUB Pause(Period)                                       ' Pause Period = uS
    waitcnt(clkfreq/1_000_000 * Period + cnt)

PRI readcfg
'' Read configuration register
    if started
       Result := ReadRegister(RdCfg,8)                  ' read configuration value

PRI writecfg(cfg)
'' Write configuration register
    if started
       WriteRegister(WrCfg,cfg,8)                       ' write configuration value

PRI WriteRegister(Cmd,Data,Bits)
    Command(Cmd)                                        ' send read counter command       
    shiftout(Data,Bits)                                 ' write register data   
    low(rst)                                            ' deactivate sensor
    pause(10_000)                                       ' allow EE write

PRI ReadRegister(Cmd,Bits)
    Command(Cmd)                                        ' send read counter command       
    Result := shiftin(Bits)                             ' read register data   
    low(rst)                                            ' deactivate sensor

PRI Command(cmd)
    high(rst)
    shiftout(cmd, 8)                                    ' select register

PRI high(pin)
    outa[pin]~~                                         ' write "1" to pin
    dira[pin]~~                                         ' make an output

PRI low(pin)
    outa[pin]~                                          ' write "0" to pin
    dira[pin]~~                                         ' make an output

PRI ConversionReady                                     ' In One-Shot mode wait for data
    low(rst)                                            ' deactivate sensor
    repeat
      Result := Done
      if Result == 1
         quit
    high(rst)                                           ' activate sensor

PRI C2D(C)
    result := ((C * 9) / 5) + 3200                      ' convert to Fahrenheit

PRI shiftin(bits)
    dira[dpin]~                                         ' make dpin input
    dira[cpin]~~                                        ' make cpin output
    Result~                                             ' clear output 
    repeat bits
      Result := (Result >> 1) | (ina[dpin] << 31)
      !outa[cpin]                                        
      pause(10)
      !outa[cpin]
      pause(10)
    Result >>= (32 - bits)

PRI shiftout(value, bits)
    dira[dpin]~~                                        ' make pins outputs
    dira[cpin]~~
    value <-= 1                                         ' pre-align lsb
    repeat bits
      outa[dpin] := (value ->= 1) & 1                   ' output data bit
      pause(10)                                         ' let it settle
      !outa[cpin]                                       ' clock the bit
      pause(10)
      !outa[cpin]
             
 
