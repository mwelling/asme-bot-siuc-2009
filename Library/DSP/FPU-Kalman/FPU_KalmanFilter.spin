{{
┌────────────────────────────┬─────────────────────┬─────────────────────┐
│ FPU_KalmanFilter.spin v1.2 │  Author: I.Kövesdi  │ Rel.:   25 08 2008  │
├────────────────────────────┴─────────────────────┴─────────────────────┤
│                    Copyright (c) 2008 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  Assuming that a discrete linear time-invariant system has n states, m │
│ inputs and r outputs, this application provides the user a general     │
│ coding framework of standard Time-Varying Kalman filter using the      │
│ following notations and definitions:                                   │
│                                                                        │
│         x(k+1) = A * x(k) + B * u(k) + w(k)    (State equation)        │
│                                                                        │
│           y(k) = C * x(k) + z(k)               (Measurement equation)  │
│                                                                        │
│ where                                                                  │
│                                                                        │
│     x is a n-by-1 vector    (estimated state vector)                   │
│     k is the time index                                                │   
│     A is a n-by-n matrix    (system model matrix)                      │ 
│     B is a n-by-m matrix    (state control matrix)                     │ 
│     u is a m-by-1 vector    (known control input to the system)        │
│     w                       (process noise, only it's statistics known.│
│                             It is "calculated" only during simulations.│
│                             In real applications it is just a notation │
│                             - we don't have to program it - to remind  │
│                             us that it might be there.)                │
│     y is a r-by-1 vector    (measured output, i.e. sensor readings)    │
│     C is a r-by-n vector    (measurement model matrix)                 │
│     z                       (measurement noise, only it's statistics   │
│                             known. It is "calculated" only during      │
│                             simulations. During real filtering we do   │
│                             not have to care about it. Nature will     │
│                             generate it for us.)                       │
│                                                                        │
│ The w and z noise vectors are described by their covariance matrices:  │
│                                                                        │ 
│    Sw is a n-by-n matrix    (process noise covariance matrix)          │
│    Sz is a r-by-r matrix    (measurement noise covariance matrix)      │
│                                                                        │
│ which are the expected values of the corresponding covariance products:│
│                                                                        │
│    Sw = E[w(k) * wT(k)]     (estimated and fixed before calculation)   │
│    Sz = E[z(k) * zT(k)]     (estimated and fixed before calculation)   │
│                                                                        │
│ From these we can setup the Kalman filter equations:                   │
│                                                                        │
│    K(k) = A * P(k) * CT * Inv[C * P(k) * CT + Sz]                      │
│                                                                        │
│  x(k+1) = [A * x(k) + B * u(k)] + K(k) * [y(k) - C * x(k)]             │
│           -------1st term------   ---------2nd term-------             │
│                                                                        │
│  P(k+1) = A * P(k) * AT + Sw - A * P(k) * CT * Inv(Sz) * C * P(k) * AT │
│                                                                        │
│ where                                                                  │
│                                                                        │
│           K(k)   (n-by-r Kalman gain matrix)                           │
│           P(k)   (n-by-n estimation error covariance matrix)           │
│                                                                        │
│  The second, so called "State Estimate Equation" is fairly intuitive.  │
│ The first                                                              │ 
│                                                                        │ 
│                    [system model predicted x(k+1)]                     │
│                                                                        │
│ term would be the state estimate if we didn't have a measurement. The  │
│ second                                                                 │
│                                                                        │
│        K(k)*[measured y(k) - measurement model defined y(k)]           │
│                                                                        │
│ term is called the correction term and it represents the amount by     │
│ which to correct the propagated state estimate due to measurement.     │
│  Inspection of the first "K" equation shows that if the measurement    │
│ noise is large, Sz is large, so K will be small since it is            │
│ proportional to                                                        │
│                                                                        │
│          Inv(C * P(k) * CT + Sz) = 1 / (C * P(k) * CT + Sz)            │
│                                                                        │
│ with Sz in the denominator. If K is small we won't give much credence  │
│ to the measurement y(k) when computing x(k+1). On the other hand, if   │
│ the measurement noise is small then Sz is small, so K will be larger.  │
│ We will give then a lot of credibility to the measurement.             │
│  The third "P" equation updates the estimation error covariance which's│
│ evolution in time is not influenced by the states and the measurements.│
│ This decoupled evolution applies to the K Kalman gain matrix, as well. │ 
│  During the computation of this so called time-varying Kalman filter we│
│ have to compute the inverse of an r-by-r matrix in the "K" equation. In│
│ the "P" equation CT * INV(Sz) * C is a constant matrix, so we have to  │
│ compute it only once for all later calculations. In each k step the    │
│ A * P(k) product can be used three times.  Even after all these tricks │
│ the calculation involves a lot of matrix algebra where the calls of the│
│ procedures of the "FPU_Matrix_Driver" came in very handy.              │
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  Perhaps the most famous application of Kalman filters to date was     │
│ guiding the Apollo spacecraft to the Moon. Rocket engineers have to    │
│ reconcile a spacecraft's current sensor readings with differential     │
│ equations that tell them where it ought to be, based on their knowledge│
│ of its past. When the designers of Apollo needed a way to blend these  │
│ two sources of information, they found it in Kalman filters which were │
│ actually developed for those missions. Since then, the Kalman filter   │
│ became a reliable computational workhorse of inertial guidance systems │
│ for airplanes and spacecrafts. During the last three decades it has    │
│ found other applications in hundreds of diverse areas, including all   │
│ forms of navigation, manufacturing, demographic modeling, nuclear plant│
│ instrumentation, robotics, weather prediction, just to mention a few.  │
│  The idea behind Kalman filters can be tracked back to least-squares   │
│ estimation theory by (K)arl (F)riedrich Gauss. With his words:         │
│                                                                        │
│ "...But since all our measurements and observations are nothing more   │
│ than approximations to the truth, the same must be true for all        │
│ calculations resting upon them, and the highest aim of all computations│
│ concerning concrete phenomena must be to approximate, as nearly as     │
│ practicable, to the truth. ... This problem can only be properly       │
│ undertaken when approximate knowledge has been already attained, which │
│ is afterwards to be corrected so as to satisfy all the observations in │
│ the most accurate manner possible."                                    │
│                                                                        │
│ These ideas, which captures the essential ingredients of all data      │
│ processing methods, were incarnated in modern form as Kalman filters   │
│ when, following similar work of Peter Swerling, Rudolph Kálmán         │
│ developed the algorithm. Sometimes the filter is referred to as the    │
│ Kalman-Bucy filter because of Richard Bucy's early work on the topic,  │
│ conducted jointly with Kálmán.                                         │
│  If you have two measurements x1, and x2 of an unknown variable x, what│
│ combination of x1 and x2 gives you the best estimate of x? The answer  │
│ depends on how much uncertainty you expect in each of the measurements.│
│ Statisticians usually measure uncertainty with the variances sigma1    │
│ squared and sigma2 squared. It can be shown, then, that the combination│
│ of x1 and x2 that gives the least variance is                          │
│                                                                        │
│   xhat = [(sigma2^2)*x1 + (sigma1^2)*x2] / [(sigma2^2) + (sigma1^2)]   │
│                                                                        │
│ This result can be figured out, or at least accepted, with common sense│
│ without algebra. The larger the variance of x2 the larger is the weight│
│ we give to x1 in the weighted average. In Kalman filters the first     │
│ measurement, x1, comes from sensor data, and the second "measurement"  │
│ is not really a measurement at all: It is your last forecast of the    │
│ spacecraft's trajectory. In real, e.g. life-saving situations these    │
│ measurements are usually not single numbers, but array of numbers, i.e.│
│ vectors. In the case of the Apollo spacecraft, the vectors had a few   │
│ tens of components. In our demo application here we will use a simpler │
│ device, a bicycle but with a modern GPS, to illustrate Kalman filtering│
│ with commanded acceleration and noisy sensor data fusion with state    │
│ prediction. The coding is based on the FPU_Matrix_Driver.spin object,  │
│ which allows us to construct Kalman filters that apply vectors up to 11│
│ components and can use [11-by-11] matrices. In the famous book of      │
│ Robert M. Rogers "Applied Mathematics in Integrated Navigation Systems,│
│ Second Edition" (AIAA) the largest matrix you can find is a [13-by-13] │                                          
│ one at a single occasion (as a theoretical summary of error state      │
│ dynamics of INU fine alignments including even time-correlated         │
│ accelerometer error states). But all of the worked out and in-practice │
│ demonstrated  algorithms in that book, before and after this matrix,   │
│ use smaller than [11-by-11] matrices and vectors.                      │                                                                   │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  There are many mathematically equivalent ways of writing the Kalman   │
│ filter equations. This can be a pretty effective source of confusion to│
│ novice and veteran alike. The coded version is a so called prediction  │
│ form of the Kalman filter equations where x(k+1) is estimated on the   │
│ basis of the measurements up to and including time k. It can be found  │
│ for example in Embedded System Programming June and in 2001, Embedded  │
│ Systems Design June 2006 by Dan Simon.                                 │ 
│  See that the "K" and "P" equations do not contain x or y values. In   │ 
│ other words they seem to be independent from the states of the system  │
│ and from the measurements. They are, of course, not totally independent│
│ since the value of deltaT influences the P(0), K(0) starting values of │
│ the matrices. Anyhow, we can compute the Kalman gain matrix K(k) off   │
│ line until we see it converges to a constant matrix. Then we can hard  │
│ code that constant matrix into the "State Estimate Equation". The      │
│ result is called the "Steady-State" Kalman filter. We then save a lot  │
│ of computational resources by using the steady-state version of the    │
│ filter. In many cases, the drop of performance will be negligible when │
│ compared to the Time-Varying Kalman filter. The Steady-State Kalman    │
│ filter algorithm is programmed in the "FPU_SteadyStateKF.spin"         │
│ application in this "FPU_Matrix_Driver" demonstration package release. │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘

Hardware:
 
                                           3.3V
                                            │
    │                               10K     │        
   P├A3─────────────────────────┳─────────┫  
   X│                           │           │
   3├A4─────────────────┐       │           │
   2│                   │       │           │ 
   A├A5────┳─────┐      │       │           │
    │      │     │      │       │           │
           │  ┌──┴──────┴───────┴──┐        │                               
         1K  │SIN12  SCLK16  /MCLR│        │                  
           │  │                    │        │
           │  │                AVDD├────────┫       
           └──┤SOUT11           VDD├────────┘
              │                    │         
              │     uM-FPU 3.1     │
              │                    │         
           ┌──┤CS                  │         
           ┣──┤SERIN9              │             
           ┣──┤AVSS                │         
           ┣──┤VSS                 │         
           ┴  └────────────────────┘
          GND

The CS pin of the FPU is tied to LOW to select SPI mode at Reset and must
remain LOW during operation. For this Demo the 2-wire SPI connection was
used, where the SOUT and SIN pins were connected through a 1K resistor and
the A5 pin(6) of the Propeller was connected to the SIN(12) of the FPU.
}}


CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

'Hardware
  '_FPU_MCLR    = 0                     'PROP pin to MCLR pin of FPU
  '_FPU_CLK     = 1                     'PROP pin to SCLK pin of FPU 
  '_FPU_DIO     = 2                     'PROP pin to SIN(-1K-SOUT) of FPU

  _FPU_MCLR    = 3                     'PROP pin to MCLR pin of FPU
  _FPU_CLK     = 4                     'PROP pin to SCLK pin of FPU 
  _FPU_DIO     = 5                     'PROP pin to SIN(-1K-SOUT) of FPU

 '_FLOAT_SEED  = 0.2718281    

'Debug
  _DBGDEL      = 80_000_000
  '_DBGDEL      = 20_000_000  
  '_DBGDEL      = 8_000_000

 
  'Dimensions of the linear system
  _N             = 2                   'States  (Max. 11)
  _M             = 1                   'Inputs  (Max. 11) 
  _R             = 1                   'Outputs (Max. 11) 

  
OBJ

  Debug   : "FullDuplexSerialPlus"   'From Parallax Inc.
                                     'Propeller Education Kit
                                     'Objects Lab v1.1
                                     
  FPUMAT  : "FPU_Matrix_Driver"      'v1.2
 
  
VAR

  long  fpu3

  long  debugLevel
  
  long  rnd                    'Global random variable 
  long  deltaT                 'Time step
  long  time                   'Time
  
  'I deliberatly will not be very parsimonious with HUB memory in the 
  'followings to make the coding more trackable and easier to debug. Most
  'of the next allocated matrices and vectors are recyclable but I leave
  'this memory optimization to the user when she/he tailors this general
  'coding framework to a given application
 
  'Constant matrices
  long         mA[_N * _N]     'System model matrix
  long         mB[_N * _M]     'State control matrix
  long         mC[_R * _N]     'Measurement model matrix
  long        mSw[_N * _N]     'Process noise covariance matrix
  long        mSz[_R * _R]     'Measurement noise covariance matrix

  'Pre-calculated constant matrices
  long        mAT[_N * _N]     'Transpose of mA
  long        mCT[_N * _R]     'Transpose of mC
  long     mSzInv[_R * _R]     'Inverse of Sz
  long    mSzInvC[_R * _N]     'SzInv * C
  long  mCTSzInvC[_N * _N]     'The factor of CT * INV(Sz) * C
  
  'Time varying vectors  
  long         vX[_N]          'Estimate of state vector
  long     vXtrue[_N]          'Hypotetic "true" state vector used only
                               'in simulations
  long         vU[_M]          'Input vector
  long         vY[_R]          'Measurement vector

  long vProcNoise[_N]          'Process noise vector for simulations
  long vMeasNoise[_R]          'Measurement noise vector for simulations 
  
  'Time varying matrices
  long         mK[_N * _R]     'Kalman gain matrix
  long        mKp[_N * _R]     'Previous step Kalman gain matrix
  long         mP[_N * _N]     'Estimation error covariance matrix


  'Matrices and vectors created during Kalman filtering algorithm  
  'In the calculation of the next Kalman gain matrix K(k+1)
  long        mAP[_N * _N]
  long      mAPCT[_N * _R]
  long        mCP[_R * _N]
  long      mCPCT[_R * _R]
  long    mCPCTSz[_R * _R]
  long mCPCTSzInv[_R * _R]
  
  'In the calculation of the next state estimate x(k+1)
  long        vCx[_R]
  long       vyCx[_R]
  long      vKyCx[_N]
  long        vAx[_N]
  long        vBu[_N]
  long      vAxBu[_N]
 
  
  'In the calculation of the new estimation error covariance matrix P(k+1) 
  long           mAPAT[_N * _N]
  long         mAPATSw[_N * _N]
  long     mAPCTSzINVC[_N * _N]
  long    mAPCTSzINVCP[_N * _N]
  long  mAPCTSzINVCPAT[_N * _N]          

  'User defined auxiliary variables to specify given model parameters
  long  dt2              '[(deltaT)^2]/2
  long  accAvr           'Average acceleration
  
  'Define model and environment dependent process noise parameters
  'These will be actuated in KF_Initialize procedure
  long  accProcNoise     'One standard deviation. In this example this
                         'will be the source of process noises
  
  long  posProcNoise     'One standard deviation
  long  posProcNoiseVar  'Variance of position process noise  
  long  velProcNoise     'One standard deviation
  long  velProcNoiseVar  'Variance of velocity process noise
  long  velPosPNCovar    'Covariance of velocity and position p. noises 

  'Define sensor dependent measurement noises and covar. matrix elements
  long  posMeasNoise     'One standard deviation  
  long  posMeasNoiseVar  'Variance of the position measurement noise

                 
PUB DoIt                               
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ DoIt │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Starts driver objects
''             Makes a MASTER CLEAR of the FPU and
''             Calls standard Time-Variable Kalman filter demo
'' Parameters: None
''    Results: None
''+Reads/Uses: /FPU pin CONs
''    +Writes: fpu3
''      Calls: FullDuplexSerialPlus---->Debug.Start
''             FPU_Matrix_Driver ------>FPUMAT.StartCOG
''                                      FPUMAT.StopCOG
''             Kalman_Filter_Demo  
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus Debug terminal
Debug.Start(31, 30, 0, 57600)
  
waitcnt(6 * clkfreq + cnt)
Debug.Str(string(10, 13))
Debug.Str(string("Kalman filter with uM-FPU Matrix v1.2", 10, 10, 13))

waitcnt(clkfreq + cnt)

fpu3 := false

'FPU Master Clear...
Debug.Str(string(10, "FPU MASTER CLEAR...", 10, 10, 13))
outa[_FPU_MCLR]~~ 
dira[_FPU_MCLR]~~
outa[_FPU_MCLR]~
waitcnt(clkfreq + cnt)
outa[_FPU_MCLR]~~
dira[_FPU_MCLR]~

'Start FPU_Matrix_Driver
fpu3 := FPUMAT.StartCOG(_FPU_DIO, _FPU_CLK)

if fpu3
  Debug.Str(string("FPU Matrix Driver started...", 10, 13))
else
  Debug.Str(string("FPU Matrix Driver Start failed!", 10, 13))

if fpu3
  Kalman_Filter_Demo

if fpu3
  Debug.Str(string(10, 10, 13, "Kalman filter with uM-FPU Matrix v1.2 "))
  Debug.Str(string("terminated normally...", 10, 13))
else
  Debug.Str(string(10, 10, 13))
  Debug.Str(string("No FPU found! Check board and try again...", 10, 13))

if fpu3
  FPUMAT.StopCOG
'-------------------------------------------------------------------------    


PRI Kalman_Filter_Demo | okay, char, row, col
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Kalman_Filter_Demo │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates Kalman filter with the FPU_Matrix_Driver
''             procedures
'' Parameters: None
''    Results: None
''+Reads/Uses: None
''    +Writes: None
''      Calls: FullDuplexSerialPlus-------------->Debug.Str
''                                                Debug.Dec
''             FloatToString
''             KF_Initialize
''             KF_Prepare_Next_TimeStep
''             KF_Next_K
''             KF_Next_X
''             KF_Next_P
'-------------------------------------------------------------------------
  Debug.Str(string(10, 13))
  Debug.Str(string("----------Kalman Filter Demo---------", 10, 13))
  'Debug.Str(string(10, 13))

  waitcnt(clkfreq + cnt)

  okay := false
  okay := FPUMAT.Reset
  Debug.Str(string(10, 13))   
  if okay
    Debug.Str(string("FPU Software Reset done...", 10, 13))
  else
    Debug.Str(string("FPU Software Reset failed...", 10, 13))
    Debug.Str(string("Please check hardware and restart...", 10, 13))
    repeat                             'Untill restart or switch off

  waitcnt(clkfreq + cnt)

  char := FPUMAT.ReadSyncChar
  Debug.Str(string(10, 13, "Response to _SYNC: "))
  Debug.Dec(char)
  if (char == FPUMAT#_SYNC_CHAR)
    Debug.Str(string("    (OK)", 10, 13))  
  else
    Debug.Str(string("   Not OK!", 10, 13))
    Debug.Str(string("Please check hardware and restart...", 10, 13))
    repeat                             'Untill restart or switch off
  
  waitcnt(clkfreq + cnt)
  
  rnd := FPUMAT.Rnd_Randomize            'Use real random values

  'Initialise pseudorandom rnd
  'rnd := FPUMAT.Rnd_FloatUD(_FLOAT_SEED) 'Use this code for pseudorandom
                                          'run

  'debugLevel := 1  'Shows Setup, K and V evolution
  debuglevel := 2   'Shows Setup, Time, Measurement, State est., K and V
  'debuglevel := 3  'Shows allmost every details of the calculation


  Debug.Str(string(10, 10, 13))
  Debug.Str(string("*****************Bicycle with GPS*****************"))
  Debug.Str(string(10, 10, 13))
  Debug.Str(string("We try to speed up a bicycle with 1 m/s2 commanded"))
  Debug.Str(string(10, 13))
  Debug.Str(string("acceleration. But the road is very bumpy and"))
  Debug.Str(string(10, 13))
  Debug.Str(string("the actual acceleration has large 0.5 m/(s*s)"))
  Debug.Str(string(10, 13))
  Debug.Str(string("standard deviation due to potholes. For position"))
  Debug.Str(string(10, 13))
  Debug.Str(string("determination we have only GPS data with 5 m"))
  Debug.Str(string(10, 13))
  Debug.Str(string("standard deviation 4 times a second. In spite of"))
  Debug.Str(string(10, 13))
  Debug.Str(string("all these odds and large randomness can we keep our"))
  Debug.Str(string(10, 13))
  Debug.Str(string("average position estimate error less than 2 m for"))
  Debug.Str(string(10, 13))
  Debug.Str(string("the 12 seconds of the run? The filter only 'knows'"))
  Debug.Str(string(10, 13))
  Debug.Str(string("the average acceleration and uses only the very "))     
  Debug.Str(string(10, 13))
  Debug.Str(string("noisy GPS position data. As a bonus from the system"))
  Debug.Str(string(10, 13))
  Debug.Str(string("model of the  Kalman filter we will obtain velocity"))
  Debug.Str(string(10, 13))
  Debug.Str(string("estimate, beside the primarily wanted position"))
  Debug.Str(string(10, 13))
  Debug.Str(string("estimate."))
  Debug.Str(string(10, 10, 13)) 
    
  waitcnt(16*_DBGDEL + cnt) 

  'Initialize Kalman filter***********************************************
  KF_Initialize
  '***********************************************************************

  Debug.Str(string(10, 10, 13))
  Debug.Str(string("---------------------------------------")) 
  Debug.Str(string(10, 13))
  Debug.Str(string("Parameters of the linear system:"))
  Debug.Str(string(10, 10, 13))
  Debug.Str(string(" Number of states n :"))  
  Debug.Dec(_N) 
  Debug.Str(string(10, 13, " Number of inputs m :"))
  Debug.Dec(_M) 
  Debug.Str(string(10, 13, "Number of outputs r :"))
  Debug.Dec(_R) 
  Debug.Str(string(10, 13))

  waitcnt(4*_DBGDEL + cnt) 
  
  Debug.Str(string(10, 13, "{A} [n-by-n]:", 10, 10, 13))
  repeat row from 1 to _N
    repeat col from 1 to _N
      Debug.Str(FloatToString(mA[((row-1)*_N)+(col-1)], 96))
    Debug.Str(string(10, 13))
    waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)  
  
  Debug.Str(string(10, 13, "{B} [n-by-m]:", 10, 10, 13))
  repeat row from 1 to _N
    repeat col from 1 to _M
      Debug.Str(FloatToString(mB[((row-1)*_M)+(col-1)], 96))
    Debug.Str(string(10, 13))
    waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)

  Debug.Str(string(10, 13, "{C} [r-by-n]:", 10, 10, 13))
  repeat row from 1 to _R
    repeat col from 1 to _N
      Debug.Str(FloatToString(mC[((row-1)*_N)+(col-1)], 96))
    Debug.Str(string(10, 13))
    waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)

  Debug.Str(string(10, 13, "{Sw} [n-by-n]:", 10, 10, 13))
  repeat row from 1 to _N
    repeat col from 1 to _N
      Debug.Str(FloatToString(mSw[((row-1)*_N)+(col-1)], 96))
    Debug.Str(string(10, 13))
    waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)

  Debug.Str(string(10, 13, "{Sz} [r-by-r]:", 10, 10, 13))
  repeat row from 1 to _R
    repeat col from 1 to _R
      Debug.Str(FloatToString(mSz[((row-1)*_R)+(col-1)], 94))
    Debug.Str(string(10, 13))
    waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)
  
  Debug.Str(string(10, 13, "{X(0)} [n-by-1]:",10,10,13)) 
    repeat row from 1 to _N
      repeat col from 1 to 1
        Debug.Str(FloatToString(vX[(row-1)+(col-1)], 95))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)

  Debug.Str(string(10, 13, "{P(0)} [n-by-n]:", 10, 10, 13))
    repeat row from 1 to _N
      repeat col from 1 to _N
        Debug.Str(FloatToString(mP[((row-1)*_N)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

  waitcnt(4*_DBGDEL + cnt)

  if debugLevel > 2
  
    Debug.Str(string(10, 13, "{AT} [n-by-n]:", 10, 10, 13))
    repeat row from 1 to _N
      repeat col from 1 to _N
        Debug.Str(FloatToString(mAT[((row-1)*_N)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

    waitcnt(4*_DBGDEL + cnt)

    Debug.Str(string(10, 13, "{CT} [n-by-r]:", 10, 10, 13))
    repeat row from 1 to _N
      repeat col from 1 to _R
        Debug.Str(FloatToString(mCT[((row-1)*_R)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

    waitcnt(4*_DBGDEL + cnt)

    Debug.Str(string(10, 13, "{SzInv} [r-by-r]:", 10, 10, 13))
    repeat row from 1 to _R
      repeat col from 1 to _R
        Debug.Str(FloatToString(mSzInv[((row-1)*_R)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

    waitcnt(4*_DBGDEL + cnt)

    Debug.Str(string(10, 13, "{SzInvC} [r-by-n]:", 10, 10, 13))
    repeat row from 1 to _R
      repeat col from 1 to _N
        Debug.Str(FloatToString(mSzInvC[((row-1)*_N)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

    waitcnt(4*_DBGDEL + cnt)

    Debug.Str(string(10, 13, "{CTSzInvC} [n-by-n]:", 10, 10, 13))
    repeat row from 1 to _N
      repeat col from 1 to _N
        Debug.Str(FloatToString(mCTSzInvC[((row-1)*_N)+(col-1)], 96))
      Debug.Str(string(10, 13))
      waitcnt((_DBGDEL/25) + cnt)

    waitcnt(4*_DBGDEL + cnt)


  repeat 48
    'Prepare next time step***********************************************
    KF_Prepare_Next_TimeStep
    '*********************************************************************

    if debugLevel > 2
        
      Debug.Str(string(10,13,"Measurement {Y} [r-by-1]:"))
      Debug.Str(string(10, 10, 13)) 
      repeat row from 1 to _R
        repeat col from 1 to 1
          Debug.Str(FloatToString(vY[(row-1)+(col-1)], 95))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13, "MeasNoise [r-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _R
          repeat col from 1 to 1
            Debug.Str(FloatToString(vMeasNoise[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)
  
      Debug.Str(string(10, 13, "Input {U} [r-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _R
          repeat col from 1 to 1
            Debug.Str(FloatToString(vU[(row-1)+(col-1)], 93))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13, "ProcNoise [n-by-1]:",10,10,13)) 
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vProcNoise[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)
  

    'Calculate next Kalman gain matrix************************************
    KF_Next_K
    '*********************************************************************

    
    if debugLevel > 2
      Debug.Str(string(10,13,"{AP} [n-by-n]:",10,10,13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAP[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10,13,"{APCT} [n-by-r]:",10,10,13))
      repeat row from 1 to _N
        repeat col from 1 to _R
          Debug.Str(FloatToString(mAPCT[((row-1)*_R)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10,13,"{CP} [r-by-n]:",10,10,13))
      repeat row from 1 to _R
        repeat col from 1 to _N
          Debug.Str(FloatToString(mCP[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10,13,"{CPCT} [r-by-r]:",10,10,13))
      repeat row from 1 to _R
        repeat col from 1 to _R
          Debug.Str(FloatToString(mCPCT[((row-1)*_R)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10,13,"{CPCTSz} [r-by-r]:",10,10,13))
      repeat row from 1 to _R
        repeat col from 1 to _R
          Debug.Str(FloatToString(mCPCTSz[((row-1)*_R)+(col-1)], 93))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10,13,"{CPCTSzInv} [r-by-r]:",10,10,13))
      repeat row from 1 to _R
        repeat col from 1 to _R
          Debug.Str(FloatToString(mCPCTSzInv[((row-1)*_R)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

        waitcnt(4*_DBGDEL + cnt)

    if (debugLevel > 1)  
      Debug.Str(string(10,13,"{K} [n-by-r]:",10,10,13))
      repeat row from 1 to _N
        repeat col from 1 to _R
          Debug.Str(FloatToString(mK[((row-1)*_R)+(col-1)], 95))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)
 
      waitcnt(_DBGDEL + cnt)
    
    
    'Calculate next State estimate****************************************
    KF_Next_X
    '*********************************************************************
    if (debugLevel > 3)
    
      Debug.Str(string(10, 13, "{vCx} [r-by-1]:", 10, 10, 13)) 
      repeat row from 1 to _R
        repeat col from 1 to 1
          Debug.Str(FloatToString(vCx[(row-1)+(col-1)], 95))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)
   
      Debug.Str(string(10, 13, "{vyCx} [n-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _R
          repeat col from 1 to 1
            Debug.Str(FloatToString(vyCx[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13, "{vKyCx} [n-by-1]:", 10, 10, 13)) 

      repeat row from 1 to _N
        repeat col from 1 to 1
          Debug.Str(FloatToString(vKyCx[(row-1)+(col-1)], 95))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)
  
      Debug.Str(string(10, 13, "{vAx} [n-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vAx[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13, "{vBu} [n-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vBu[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)
    
      Debug.Str(string(10, 13, "{vAxBu} [n-by-1]:", 10, 10, 13)) 
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vAxBu[(row-1)+(col-1)], 95))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

    if (debugLevel > 1)
    
      Debug.Str(string(10, 10, 13))
      Debug.Str(string("---------------------------------------")) 
      Debug.Str(string(10, 13, "Time: "))
      Debug.Str(FloatToString(time , 93)) 
      Debug.Str(string(10, 13))

      Debug.Str(string(10, 13, "GPS position data [r-by-1]:"))
      Debug.Str(string(10, 10, 13))  
        repeat row from 1 to _R
          repeat col from 1 to 1
            Debug.Str(FloatToString(vY[(row-1)+(col-1)], 71))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)
      waitcnt(1*_DBGDEL + cnt)
      
      Debug.Str(string(10, 13, "State estimate (pos. vel.) [n-by-1]:"))
      Debug.Str(string(10, 10, 13))  
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vX[(row-1)+(col-1)], 93))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)
      waitcnt(_DBGDEL + cnt)

      Debug.Str(string(10, 13, "'True' state (pos. vel.) [n-by-1]:"))
      Debug.Str(string(10, 10, 13))  
        repeat row from 1 to _N
          repeat col from 1 to 1
            Debug.Str(FloatToString(vXtrue[(row-1)+(col-1)], 93))
          Debug.Str(string(10, 13))
          waitcnt((_DBGDEL/25) + cnt)
      waitcnt(6*_DBGDEL + cnt)    
    
    
    'Calculate next estimation error covariance matrix********************
    KF_Next_P
    '*********************************************************************

    if (debugLevel > 2)
    
      Debug.Str(string(10, 13, "{APAT} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAPAT[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13, "{APATSw} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAPATSw[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13))
      Debug.Str(string("{APCTSzInvC} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAPCTSzInvC[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13))
      Debug.Str(string("{APCTSzInvCP} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAPCTSzInvCP[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

      Debug.Str(string(10, 13))
      Debug.Str(string("{APCTSzInvCPAT} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mAPCTSzInvCPAT[((row-1)*_N)+(col-1)],96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(4*_DBGDEL + cnt)

    if (debugLevel > 1)  
      Debug.Str(string(10, 13))
      Debug.Str(string("{P} [n-by-n]:", 10, 10, 13))
      repeat row from 1 to _N
        repeat col from 1 to _N
          Debug.Str(FloatToString(mP[((row-1)*_N)+(col-1)], 96))
        Debug.Str(string(10, 13))
        waitcnt((_DBGDEL/25) + cnt)

      waitcnt(2*_DBGDEL + cnt)

'-------------------------------------------------------------------------


PRI KF_Initialize | row, col
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ KF_Initialize │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Initializes KF calculations
' Parameters: Timestep deltaT, process noise and measurement noise data
'             System parameters
'    Results: A, B, C, Sw, Sz matrices
'             Starting valu of vX, vXtrue vectors
'+Reads/Uses: /FPUMAT CONs 
'    +Writes: FPU Reg:127, 126
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Read/Write procedures
'                                            FPUMAT.Matrix_Copy
'                                            FPUMAT.Matrix_Transpose
'                                            FPUMAT.Matrix_InvertSmall
'                                            FPUMAT.Matrix_Multiply    
'-------------------------------------------------------------------------
  'Setup time step
  deltaT := 0.25                     's
  time := 0.0                        's

  'Setup average acceleration
  accAvr := 1.0                      'm/s2
  'Setup acceleration noise 
  accProcNoise := 0.5                '(one standard deviation)
  'In this example this uncerteinity is the only source of process noises     
   
  'Calculate user defined variables---------------------------------------
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      'Calculate (deltaT^2)/2
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, 2)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  dt2 := FPUMAT.ReadReg

  'One Standard deviation of the position process noise is
  '      (dt2)*(accProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, dt2)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, accProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  posProcNoise := FPUMAT.ReadReg

  'One Standard deviation of the velocity process noise is
  '      (deltaT)*(accProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, accProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  velProcNoise := FPUMAT.ReadReg

  'Variance of the position proc. noise is
  '    (sdev of pos. p. noise)^2
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, posProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  posProcNoiseVar := FPUMAT.ReadReg

  'Variance of the velocity proc. noise is
  '    (sdev of vel. p. noise)^2
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, velProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  velProcNoiseVar := FPUMAT.ReadReg

  'Covariance of the position and velocity process noises
  '   (sdev of pos. p. noise)*(sdev of vel. p. noise)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, posProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, velProcNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  velPosPNCovar := FPUMAT.ReadReg

  'Define Sw[n-by-n] matrix 
  row := 1
  col := 1
  mSw[((row-1)*_N)+(col-1)] := posProcNoiseVar
  row := 1
  col := 2
  mSw[((row-1)*_N)+(col-1)] := velPosPNCovar
  row := 2
  col := 1
  mSw[((row-1)*_N)+(col-1)] := velPosPNCovar
  row := 2
  col := 2
  mSw[((row-1)*_N)+(col-1)] := velProcNoiseVar
  
  'Define sensor dependent measurement noise parameters
  posMeasNoise := 5.0                'One standard deviation
  'Variance of the position meas. noise is
  '       (sdev of pos. m. noise)^2
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)      
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, posMeasNoise)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  posMeasNoiseVar := FPUMAT.ReadReg

  'Define Sz[r-by-r] matrix
  row := 1
  col := 1
  mSz[((row-1)*_R)+(col-1)] := posMeasNoisevar
   

  'Define linear system and measurement matrices--------------------------
  'Define A[n-by-n] matrix
  row := 1
  col := 1
  mA[((row-1)*_N)+(col-1)] := 1.0
  row := 1
  col := 2
  mA[((row-1)*_N)+(col-1)] := deltaT
  row := 2
  col := 1
  mA[((row-1)*_N)+(col-1)] := 0.0
  row := 2
  col := 2
  mA[((row-1)*_N)+(col-1)] := 1.0

  'Define B[n-by-m] matrix
  row := 1
  col := 1
  mB[((row-1)*_M)+(col-1)] := dt2
  row := 2
  col := 1
  mB[((row-1)*_M)+(col-1)] := deltaT

  'Define C[r-by-n] matrix
  row := 1
  col := 1
  mC[((row-1)*_N)+(col-1)] := 1.0
  row := 1
  col := 2
  mC[((row-1)*_N)+(col-1)] := 0.0


 'Initialize the P estimation error covariance matrix as Sw
  FPUMAT.Matrix_Copy(@mP, @mSw, _N, _N)


 'Specify starting value of state vector
  row := 1
  vX[row - 1] := 0.0       'Estimated position 
  row := 2
  vX[row - 1] := 0.0       'Estimated speed

  'Specify starting value of the simulated "true" system state
  row := 1
  vXtrue[row - 1] := 0.0   '"true" position
  row := 2
  vXtrue[row - 1] := 0.0   '"true" speed
   
   
  'Calculate permanently used constant matrices (*)-----------------------
  FPUMAT.Matrix_Transpose(@mAT, @mA, _N, _N)                       '(*)
  FPUMAT.Matrix_Transpose(@mCT, @mC, _R, _N)                       '(*)
  FPUMAT.Matrix_InvertSmall(@mSzInv, @mSz, _R)
  FPUMAT.Matrix_Multiply(@mSzInvC, @mSzInv, @mC, _R, _R, _N)
  FPUMAT.Matrix_Multiply(@mCTSzInvC, @mCT, @mSzInvC, _N, _R, _N)   '(*)
'-------------------------------------------------------------------------


PRI KF_Prepare_Next_TimeStep | fV, row, col
'-------------------------------------------------------------------------
'----------------------┌──────────────────────────┐-----------------------
'----------------------│ KF_Prepare_Next_TimeStep │-----------------------
'----------------------└──────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: Prepares data to calculate X(k+1), i.e.
'             generates process noise and   (for tests and filter tuning)
'             measurement noise             (for tests and filter tuning)
'             calculates input vector vU(k) for timestep k 
' Parameters: Noise parameters
'    Results: Y(k) "noisy" measurement values
'             Xtrue(k+1)
'+Reads/Uses: /FPUMAT CONs 
'    +Writes: FPU Reg:127, 126, 125
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Read/Write procedures
'                                            FPUMAT.Matrix_Add
'                                            FPUMAT.Matrix_Multiply
'                                            FPUMAT.RND_FloatUD
'                                            FPUMAT.RND_FloatND
'       Note: This procedure now serves for testing and tuning but this is
'             the right place to enter actuator (input) data and sensor
'             (measurement) data in real applications. In that case Mother
'             Nature will do us the favour to generate all the noises.
'-------------------------------------------------------------------------

  'Measurement data came here from real sensors in real applications.
  'Now we are running a simulation, so we calculate the measurement
  'vector from the hypothetical "true" state vector and then we perturb
  'that vector delibaretly with the measurement error.
  'First calculate measurement vector (or enter sensor values here!)
  FPUMAT.Matrix_Multiply(@vY, @mC, @vXtrue, _R, _N, 1)
  'Comment out next lines in real application. 
  'Calculate Measurement Noise vector from posMeasNoise
  rnd := FPUMAT.Rnd_FloatUD(rnd)           
  fV := FPUMAT.Rnd_FloatND(rnd, 0.0, posMeasNoise)
  row := 1
  vMeasNoise[row - 1] := fV  
  FPUMAT.Matrix_Add(@vY,@vY,@vMeasNoise,_R,1) 'Add simulated meas. noise

  'Calculate new time
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, time)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
  FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  time := FPUMAT.ReadReg
  
  'Generate Process Noise [directly from acceleration noise]
  rnd := FPUMAT.Rnd_FloatUD(rnd)
  fV := FPUMAT.Rnd_FloatND(rnd, accAvr, accProcNoise)

  'Calculate the perturbed acceleration for the simulation 
  row := 1
  vU[row - 1] := fV

  'Calculate hypothetical "true" state vector from the acceleration     
  'Next section for "true" state is for simulation purposes only
  'Calculat "true" state vector from the input acceleration
  'Integrate position first
  'vXtrue[0](k+1) = vXtrue[0](k) + vXtrue[1](k)*deltaT + a*(deltaT2)/2
  fV := vXtrue[0]     'Previous "true" Position
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
  fV := vXtrue[1]     'Previous "true" Speed
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
  FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
  fV := vU[0]         'We simulate to know the acceleration
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, dt2)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
  FPUMAT.WriteCmdByte(FPUMAT#_FADD, 125)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  fV := FPUMAT.ReadReg
  vXtrue[0] := fV      'Integrated "true" position
  'Now integrate speed
  'vXtrue[1](k+1) = vXtrue[1](k) + a*deltaT  
  fV := vXtrue[1]      'Previous "true" speed 
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
  fV := vU[0]          'We simulate to know the acceleration
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
  FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
  FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
  FPUMAT.Wait
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  fV := FPUMAT.ReadReg
  vXtrue[1] := fV      'Integrated "true" velocity

  'Now set back the nominal value of the acceleration that we really
  'assume and  take into account in the filter calculation 
  row := 1
  vU[row - 1] := accAvr    

  'Use next lines if you want to generate other process noises
  'in simulations
  'row := 1
  'vProcNoise[row - 1] := something1  
  'row := 2
  'vProcNoise[row - 1] := something2
'-------------------------------------------------------------------------


PRI KF_Next_K
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ KF_Next_K │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of FPU_Matrix procedure calls computes the
'             K(k) matrix
' Parameters: A, C, Sz, P
'    Results: Kalman gain matrix
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply 
'                                            FPUMAT.Matrix_Add
'                                            FPUMAT.Matrix_InvertSmall
'-------------------------------------------------------------------------
  FPUMAT.Matrix_Multiply(@mAP, @mA, @mP, _N, _N, _N)
  FPUMAT.Matrix_Multiply(@mAPCT, @mAP, @mCT, _N, _N, _R)
  FPUMAT.Matrix_Multiply(@mCP, @mC, @mP, _R, _N, _N)
  FPUMAT.Matrix_Multiply(@mCPCT, @mCP, @mCT, _R, _N, _R)
  FPUMAT.Matrix_Add(@mCPCTSz, @mCPCT, @mSz, _R, _R)
  FPUMAT.Matrix_InvertSmall(@mCPCTSzInv, @mCPCTSz, _R)
  'Use here Matrix_Invert if necessary, i.e. _R>3 
  FPUMAT.Matrix_Multiply(@mK, @mAPCT, @mCPCTSzInv, _N, _R, _R)  
'-------------------------------------------------------------------------


PRI KF_Next_X
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ KF_Next_X │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of procedure calls computes X(k+1)
' Parameters: Previous state estimate X(k)
'             Measurement values Y(k)
'             Kalman gain matrix K(k)
'    Results: New state estimate vector X(k+1)
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply
'                                            FPUMAT.Matrix_Subtract         
'                                            FPUMAT.Matrix_Add
'-------------------------------------------------------------------------
  FPUMAT.Matrix_Multiply(@vCx, @mC, @vX, _R, _N, 1)
  FPUMAT.Matrix_Subtract(@vyCx, @vY, @vCx, _R, 1) 
  FPUMAT.Matrix_Multiply(@vKyCx, @mK, @vyCx, _N, _R, 1)
  FPUMAT.Matrix_Multiply(@vAx, @mA, @vX, _N, _N, 1)  
  FPUMAT.Matrix_Multiply(@vBu, @mB, @vU, _N, _M, 1)
  FPUMAT.Matrix_Add(@vAxBu, @vAx, @vBu, _N, 1)
  FPUMAT.Matrix_Add(@vX, @vAxBu, @vKyCx, _N, 1)
  
  'Here you can add process noise if you do such simulation
  'FPUMAT.Matrix_Add(@vX,@vX,@vProcNoise,_N,1)    
'-------------------------------------------------------------------------


PRI KF_Next_P
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ KF_Next_P │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of procedure calls computes the P(k+1) matrix
' Parameters: A, C, Sz, Sw
'    Results: P(k+1)
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply
'                                            FPUMAT.Matrix_Add         
'                                            FPUMAT.Matrix_Subtract
'-------------------------------------------------------------------------
  FPUMAT.Matrix_Multiply(@mAPAT, @mAP, @mAT, _N, _N, _N)
  FPUMAT.Matrix_Add(@mAPATSw, @mAPAT, @mSw, _N, _N) 
  FPUMAT.Matrix_Multiply(@mAPCTSzInvC, @mAP, @mCTSzInvC, _N, _N, _N)
  FPUMAT.Matrix_Multiply(@mAPCTSzInvCP,@mAPCTSzInvC,@mP,_N,_N,_N)
  FPUMAT.Matrix_Multiply(@mAPCTSzInvCPAT,@mAPCTSzInvCP,@mAT,_N,_N,_N)
  FPUMAT.Matrix_Subtract(@mP, @mAPATSw, @mAPCTSzInvCPAT, _N, _N)
'-------------------------------------------------------------------------


PRI FloatToString(floatV, format) : strPtr
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ FloatToString │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Converts a HUB/floatV into string within FPU then loads it
'             back into HUB
' Parameters: Float value, Format code in FPU convention
'    Results: Pointer to string in HUB
'+Reads/Uses: FPUMAT#_FWRITE, FPUMAT#_SELECTA 
'    +Writes: FPU Reg: 127
'      Calls: FPU_Matrix_Driver------->FPUMAT.WriteCmdRnFloat
'                                      FPUMAT.WriteCmdByte
'                                      FPUMAT.ReadRaFloatAsStr
'       Note: For debug and test purposes
'-------------------------------------------------------------------------
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, floatV) 
  strPtr := FPUMAT.ReadRaFloatAsStr(format) 

  return strPtr
'-------------------------------------------------------------------------


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  