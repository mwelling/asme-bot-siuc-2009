{{
File Documentation:

DPG: 25-May-08
  Created Manual Driving Function ManualDrive
DPG: 26-May-08
  Fixed errors in distance calculations.
  Updated Documentation
  Added code to better support XBee Radio.
DPG: 25-Jun-08
  Added status indications for processor startup and runtime
  Added boot options
  Added calibration mode
  Added manual drive mode
DPG:  26-Jun-08
  Worked on the calibration mode
  Began Gyroscope Implementation
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000


 'Pin Definitions
  comrxpin      = 0
  comtxpin      = 1
  gpsrxpin      = 2
  gpstxpin      = 3
  drivepin      = 4
  steerpin      = 5
  ACCELcs       = 6
  ACCELdio      = 7
  CLK           = 8
  COMPen        = 9
  COMPdata      = 10
  statusled     = 11
  gyrocs        = 12
  gyrodio       = 13
  gyroclk       = 14
  

'GPS Definitions
{
mode bit 0 = invert rx
mode bit 1 = invert tx
mode bit 2 = open-drain/source tx
mode bit 3 = ignore tx echo on rx
}
  gpsmode       = 0
  gpsbaud       = 4800

'SERIAL Definitions
{
  To transmit a string: SERIAL.str((string(packet)))
  To recieve a string(that starts with a "$", delimited by ",", and is ended with a CR or "*": SERIAL.read
  Recieved string will be copied to readstr  
}
  commode       =  0
  combaud       =  115200
  
'Drive Definitions
  max_duty      = 100
  neutral       = (max_duty/2)

'Accelerometer Definitions

'Compass Definitions
  thetaN        = 0  'Compass Bias, set North to 0 Deg

DAT
        NXT byte "NEXT", 0          
VAR

  long stack[20]
  byte readstr[20]
  byte n,m
  long theta,thetarate
  byte cogerror
  byte cogerrorstatus
  byte cid[10]
  long cogver[10]
  long curLAT
  long curLONG
  long targetsetLAT
  long targetsetLONG
  long targetR
  long targettheta
  long targetdist
  long steermin,steerneutral,steermax,drivemin,driveneutral,drivemax
  'ASCII Definitions

OBJ
   GPS:                         "GPS_IO_mini"
   ACCEL:                       "H48C Tri-Axis Accelerometer"'Think is working
   COMPASS:                     "HM55B Compass Module Asm"'Think is working
   SERIALCOM:                   "Extended_FDSerial"
   DRIVEPWM:                    "pwmAsm"'Think is working
   STEER:                       "Servo32v3"'Think is working
   MATH:                        "Float32Full"
   XBEE:                        "XBee_Object"
   GYRO:                        "GyroXY"
  
PUB Main
   dira[comtxpin]~~
   AutoDrive
{PUB RunInit
'Set these pins as Outputs
  dira[comtxpin]~~
  dira[gpstxpin]~~
  dira[drivepin]~~
  dira[steerpin]~~
  dira[CLK]~~
  dira[COMPen]~~                                  '
  dira[ACCELdio]~~
'Set these pins as Inputs
  dira[comrxpin]~
  dira[gpsrxpin]~
  dira[ACCELcs]~
  dira[COMPdata]~
  Safemode
PUB Status ''Status Driver
  outa[statusled]:=1
  waitcnt(1_000000 + cnt)
  outa[statusled]:=0
PUB Safemode
  XBEE.Start(comrxpin,comtxpin,commode,combaud)
  
''Serial Port Tests
  'bytefill(@readstr, 0, 15)

   ' XBEE.str(String("Hello World"))
  '  waitcnt(1_000_000 + cnt)
    
    
DRIVEPWM.start(drivepin)

  AutoDrive
  {
  GPS.Start
  ACCEL.start(ACCELcs,ACCELdio,CLK)
  COMPASS.start(COMPen,CLK,COMPdata)
  MATH.start
  GYRO.start(gyrocs,gyrodio,gyroclk)
 }
''Test Cog Creation

{  if (cid[0] := SERIALCOM.start(comrxpin,comtxpin,commode,combaud)==-1)
    cogerror++
    SERIALCOM.str((string("SERIALCOM COG CREATION ERROR")))
    SERIALCOM.str(13)
  if (cid[1] := DRIVEPWM.start(drivepin)==-1)
    SERIALCOM.str((string("DRIVE COG CREATION ERROR")))
    SERIALCOM.str(13)
    cogerror++
  if (cid[2] := STEER.start==-1)
    SERIALCOM.str((string("STEER COG CREATION ERROR")))
    SERIALCOM.str(13)
    cogerror++
  if (cid[3] := GPS.Start == -1)
    SERIALCOM.str((string("GPS COG CREATION ERROR")))
    SERIALCOM.str(13)
    cogerror++
  if (cid[4] := ACCEL.start(ACCELcs,ACCELdio,CLK) == -1)
    cogerror++
    SERIALCOM.str((string("ACCELEROMETER COG CREATION ERROR")))
    SERIALCOM.str(13)
  if (cid[5] := COMPASS.start(COMPen,CLK,COMPdata) == -1)
    cogerror++
    SERIALCOM.str((string("COMPASS COG CREATION ERROR")))
    SERIALCOM.str(13)
  if (cogerror > 0)
    SERIALCOM.str((string("COG CREATION ERROR")))
    SERIALCOM.str(13)
    SERIALCOM.str(cogerror)
    SERIALCOM.str(13)
  else
    SERIALCOM.str((string("ALL PROCESSORS STARTED OK")))
    SERIALCOM.str(13)
    waitcnt(1_000_000 + cnt)
    SERIALCOM.str((string("BOOT OPTIONS:")))
    SERIALCOM.str(13)
    SERIALCOM.str((string("1-MANUAL CONTROL")))
    SERIALCOM.str(13)
    SERIALCOM.str((string("2-AUTOMATED DRIVING")))
    SERIALCOM.str(13)
    SERIALCOM.str((string("3-CALIBRATION MODE")))
    SERIALCOM.str(13)
    SERIALCOM.read
    SERIALCOM.str(readstr)
    CASE readstr
      1:  ManualDrive
      2:  AutoDrive
      3:  Calibrate
}
  }
PUB AutoDrive  |i,j,targetset,TransX,TransY,TransZ,Ar,Vr,Pr,Ax,Vx,Px,Ay,Vy,Py,Az,Vz,Pz,dist,dlat,dlong
''Right now, is just testing basic functionality
  m:= 0
  cogerror := 0
  Px := Py := Pr := Vx := Vy := Vz := Ax := Ay := Az := 0
  repeat

    ''repeat i from 0 to max_duty 'linearly advance parameter from 0 to 100
    i:=0
        DRIVEPWM.SetDuty(i)
        waitcnt(1_000_000 + cnt)   'wait a little while before next update
        {
''Test Compass Sensor

   theta := COMPASS.theta
   thetarate := COMPASS.thetarate
 

''Test Accelerometer

   TransX := ACCEL.x
   TransY := ACCEL.y
   TransZ := ACCEL.z

''Recieve Target Lat Long
   'targetset := SERIALCOM.gettarget
   'targetsetLAT := targetset[0]
   'targetsetLONG := targetset[1]
   'curLAT := GPS.latitude
   'curLONG := GPS.longitude
   'dlat:= targetsetLAT - curLAT              
   'dlong:= targetsetLONG - curLONG


   'dist:= (3963 - 13*MATH.Sin(targetsetLAT)) * MATH.Pow(2*MATH.Asin(Math.FMin(1, MATH.FSqr(MATH.Sin(dlat/2)) + Math.Cos(targetsetLAT)*Math.Cos(curLAT)* MATH.FSqr(MATH.Sin(dlong/2)) )),(1/2))
   

'Position Measurements, using Position Detection powerpoint
    repeat while 1
      Ay := AccelerationY
      Ax := AccelerationX

'Test XBee Communications
  XBEE.Start(comrxpin, comtxpin, commode, combaud)
  XBEE.AT_Init
  XBEE.str(String("Hello World"))
  XBEE.RxStr(readstr)

  status
PUB Calibrate|input

  SERIALCOM.str((string("CALIBRATION MODE:")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
            
  SERIALCOM.str((string("ADJUST FOR STEER HARD LEFT")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  steermin := SERIALCOM.read
  
  SERIALCOM.str((string("ADJUST FOR STEER NEUTRAL")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  steerneutral := SERIALCOM.read
   
  SERIALCOM.str((string("ADJUST FOR STEER HARD RIGHT")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  steermax := SERIALCOM.read
   
  SERIALCOM.str((string("ADJUST FOR DRIVE FULL REVERSE")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  drivemin := SERIALCOM.read
  
  SERIALCOM.str((string("ADJUST FOR STEER NEUTRAL")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  driveneutral := SERIALCOM.read
  
  SERIALCOM.str((string("ADJUST FOR STEER FULL FORWARD")))
  SERIALCOM.str(13)
  repeat while !strcomp(SERIALCOM.read,@NXT)
    waitcnt(1 + cnt)
  drivemax := SERIALCOM.read 

  SERIALCOM.str((string("CALIBRATION FINISHED.  OPTIONS:")))
  SERIALCOM.str(13)
  SERIALCOM.str((string("1-MANUAL CONTROL")))
  SERIALCOM.str(13)
  SERIALCOM.str((string("2-AUTOMATED DRIVING")))
  SERIALCOM.str(13)
  SERIALCOM.str((string("3-CALIBRATION MODE")))
  SERIALCOM.str(13)
  SERIALCOM.read
  SERIALCOM.str(readstr)
  CASE readstr
    1:  ManualDrive
    2:  AutoDrive
    3:  Calibrate
        
PUB ManualDrive|DriveX,SteerX ''Manual Drive Mode, using arrow keys

  repeat while 1 
    DRIVEPWM.SetDuty(DriveX)
    STEER.Set(steerpin,SteerX)

PUB AccelerationX|Ax ''Returns Acceleration in the x-axis
  Ax := 0
  theta := COMPASS.theta
  Ax := ACCEL.r * MATH.sin(thetaN - theta)
  return Ax
PUB AccelerationY|Ay ''Returns Acceleration in the y-axis
  Ay := 0 
  theta := COMPASS.theta 
  Ay := ACCEL.r * MATH.cos(thetaN - theta)
  return Ay

PUB VelocityX|i,Vx ''Returns Velocity in the x-axis
   Vx := 0
   repeat i from 1 to m
      theta := COMPASS.theta 
      Vx += (ACCEL.r * MATH.sin(thetaN - theta))/clkfreq
   return Vx
PUB VelocityY|i,Vy  ''Returns Velocity in the y-axis
   Vy := 0
   repeat i from 1 to m
      theta := COMPASS.theta 
      Vy += (ACCEL.r * MATH.cos(thetaN - theta))/clkfreq
   return Vy
PUB PositionX|i,Px  ''Returns Position in the x-axis
  Px := 0
  repeat i from 1 to m
    theta := COMPASS.theta 
    Px += VelocityX + (1/2)*(ACCEL.r * MATH.sin(thetaN - theta))/(clkfreq * clkfreq) 
  return Px
PUB PositionY|i,Py ''Returns Position in the y-axis 
  Py := 0
  repeat i from 1 to m
    theta := COMPASS.theta 
    Py += VelocityY + (1/2)*(ACCEL.r * MATH.cos(thetaN - theta))/(clkfreq * clkfreq) 
  return Py

        
                                                            }
      

      
      

   
  
      