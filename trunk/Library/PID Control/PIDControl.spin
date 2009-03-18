'DPG 19-Dec-07
'PID Loop Controller
'Only Covers Translational and Spinning about the x-axis

VAR

long K                'PID Gain
long cur_error[6]     'Current Error
long pre_error[6]     'Previous Error

long outputindex     'Index for driving the appropriate output


long stack[30]        'Cog stack
byte cog              'cog number
long dt               'Integral Time


CON

OBJ

PUB Start(CP, SP, Gain, Integral_Time, Output)
''Starts PID Controller.  Starts a new cog to run in.
          ''Current_Addr: Address of Long Variable holding actual position
          ''Set_Addr:     Address of Long Variable holding set position
          ''Gain:         PID Algorithm Gain, i.e.: large gain = large changes faster, though less precise overall.
          ''Integral_Time: PID Algorithm Integral_Time
          ''Output_Addr:  Address of Long Variable which holds output of PID algorithm
{Fix initialization 
 dt := Integral_Time
 pre_error := 0
cur_error := 0
K := Gain}
'Start Evaluating Accelerometers to describe craft orientation, only describes pitching and rolling movement
   if (CP[1]<CP[2]) & (CP[4]<CP[5])
      'Pitching Forward
      outputindex := 0
   elseif (CP[1]>CP[2]) & (CP[4]>CP[5])
      'Pitching Backward
      outputindex := 0
   elseif (CP[0]<CP[5]) & (CP[3]<CP[5])
      'Rolling Left
      outputindex := 1
   elseif (CP[0]>CP[5]) & (CP[3]>CP[5])
      'Rolling Right
      outputindex := 1
   else
    'Indeterminate State
    outputindex := 0
    
    
  

cog := cognew(Loop(CP,SP,Output,outputindex), @stack)

PUB Stop
'Stops the Cog and the PID Controller
  cogstop(cog)
PRI Loop(CP,SP,Output,oindex) | e,P,I,D
repeat i from 0 to 5
  
  long[cur_error[i]] := long[SP[i]] - long[CP[i]]
  P[i] := K[i] * long[cur_error[i]]
  I[i] := I[i] + K[i]*long[cur_error[i]] * dt[i]
  e[i] := long[cur_error[i]] - long[pre_error[i]]
  D[i] := K[i] * e[i]/dt[i]
  long[Output[oindex]] := P[i] + I[i] + D[i]
  long[pre_error[i]] := long[cur_error[i]]
 