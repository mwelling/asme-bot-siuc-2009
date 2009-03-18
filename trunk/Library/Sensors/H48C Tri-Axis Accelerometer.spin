{{
File Documentation:

DPG 30-Apr-08:
  Added CON's for clock frequencies.
}}
{
                                ********************************************
                                        H48C Tri-Axis Accelerometer    V1.0
                                ********************************************
                                      coded by Beau Schwabe (Parallax) 
                                ********************************************

         ┌──────────┐
  P2 ──│1 ‣‣••6│── +5V       P0 = CS
         │  ┌°───┐  │               P1 = DIO
  P1 ──│2 │ /\ │ 5│── P0        P2 = CLK
         │  └────┘  │
 VSS ──│3  4│── Zero-G  
         └──────────┘


G = ((axis-vRef)/4095)x(3.3/0.3663)

        or

G = (axis-vRef)x0.0022

        or

G = (axis-vRef)/ 455
                               
}


CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

VAR
long    cog,CS,DIO,CLK,H48C_vref,H48C_x,H48C_y,H48C_z,H48C_YXtheta,H48C_ZXtheta,H48C_YZtheta


PUB stop                                                               
'' Stop driver - frees a cog
    if cog
       cogstop(cog~ -  1)

PUB start(CS_,DIO_,CLK_):okay
    CS  := CS_
    DIO := DIO_
    CLK := CLK_

'' Start driver - starts a cog
'' returns false if no cog available

    okay := cog := cognew(@H48C, @CS)
    return okay

PUB vref
    return H48C_vref
PUB x
    return H48C_x    
PUB y
    return H48C_y
PUB r
    return H48C_y     
PUB z
    return H48C_z
PUB thetaA
    return H48C_YXtheta    
PUB thetaB
    return H48C_ZXtheta    
PUB thetaC
    return H48C_YZtheta

DAT
H48C          org

              mov       t1,                     par                             'Setup CS pin mask
              rdlong    t2,                     t1
              mov       CSPin_mask,             #1
              shl       CSPin_mask,             t2

              add       t1,                     #4                              'Setup DIO pin mask
              rdlong    t2,                     t1
              mov       DIOPin_mask,            #1
              shl       DIOPin_mask,            t2

              add       t1,                     #4                              'Setup CLK pin mask
              rdlong    t2,                     t1
              mov       CLKPin_mask,            #1
              shl       CLKPin_mask,            t2

              add       t1,                     #4                              'Get variable Adress location for Vref
              mov       H48C_vref_,             t1

              add       t1,                     #4                              'Get variable Adress locations for X,Y,Z  g's
              mov       H48C_x_,                t1
              add       t1,                     #4
              mov       H48C_y_,                t1
              add       t1,                     #4
              mov       H48C_z_,                t1

              add       t1,                     #4                              'Get variable Adress locations for X,Y,Z Angle's                              
              mov       H48C_YXtheta_,          t1
              add       t1,                     #4
              mov       H48C_ZXtheta_,          t1
              add       t1,                     #4
              mov       H48C_YZtheta_,          t1

              or        outa,                   CSPin_mask                      'Pre-Set CS pin HIGH
              or        dira,                   CSPin_mask                      'Set CS pin as an OUTPUT

              mov       t3,                     VoltRef                         'Get vRef value
              call      #DataIO
              mov       vref_,                  t3

              mov       t3,                     Xselect                         'Get X value
              call      #DataIO
              mov       x_,                     t3
              subs      x_,                     vref_

              mov       t3,                     Yselect                         'Get Y value
              call      #DataIO
              mov       y_,                     t3
              subs      y_,                     vref_

              mov       t3,                     Zselect                         'Get Z value
              call      #DataIO
              mov       z_,                     t3
              subs      z_,                     vref_

              mov       cx,                     x_                              'Get theta of YX
              mov       cy,                     y_
              call      #cordic
              mov       YXtheta_,               ca

              mov       cx,                     x_                              'Get theta of ZX
              mov       cy,                     z_
              call      #cordic
              mov       ZXtheta_,               ca

              mov       cx,                     z_                              'Get theta of YZ
              mov       cy,                     y_
              call      #cordic
              mov       YZtheta_,               ca
              
              mov       t1,                     H48C_vref_                      'Write Vref data back
              wrlong    vref_,                  t1
              mov       t1,                     H48C_x_                         'Write x data back
              wrlong    x_,                     t1
              mov       t1,                     H48C_y_                         'Write y data back
              wrlong    y_,                     t1
              mov       t1,                     H48C_z_                         'Write z data back
              wrlong    z_,                     t1
              mov       t1,                     H48C_YXtheta_                   'Write YX theta back
              wrlong    YXtheta_,               t1
              mov       t1,                     H48C_ZXtheta_                   'Write ZX theta back
              wrlong    ZXtheta_,               t1
              mov       t1,                     H48C_YZtheta_                   'Write YZ theta back
              wrlong    YZtheta_,               t1

              jmp       #H48C                            
'------------------------------------------------------------------------------------------------------------------------------
DataIO                                                                          'Select DAC register and read data
              andn      outa,                   CSPin_mask                      '     Make CS pin LOW         (Select the device)
              mov       t4,                     #5                              '          Set Num of Bits
              call      #SHIFTOUT                                               '          Select DAC register
              mov       t4,                     #13                             '          Set Num of Bits
              call      #SHIFTIN                                                '          Read DAC register data
              or        outa,                   CSPin_mask                      '     Make CS pin HIGH       (Deselect the device)
              and       t3,                     DataMask
DataIO_ret    ret              
'------------------------------------------------------------------------------------------------------------------------------
SHIFTOUT                                                                        'SHIFTOUT Entry
              andn      outa,                   DIOPin_mask                     'Pre-Set Data pin LOW
              or        dira,                   DIOPin_mask                     'Set Data pin as an OUTPUT

              andn      outa,                   CLKPin_mask                     'Pre-Set Clock pin LOW
              or        dira,                   CLKPin_mask                     'Set Clock pin as an OUTPUT
MSBFIRST_                                                                       '     Send Data MSBFIRST
              mov       t5,                     #%1                             '          Create MSB mask     ;     load t5 with "1"
              shl       t5,                     t4                              '          Shift "1" N number of bits to the left.
              shr       t5,                     #1                              '          Shifting the number of bits left actually puts
                                                                                '          us one more place to the left than we want. To
                                                                                '          compensate we'll shift one position right.              
MSB_Sout      test      t3,                     t5      wc                      '          Test MSB of DataValue
              muxc      outa,                   DIOPin_mask                     '          Set DataBit HIGH or LOW
              shr       t5,                     #1                              '          Prepare for next DataBit
              call      #Clock                                                  '          Send clock pulse
              djnz      t4,                     #MSB_Sout                       '          Decrement t4 ; jump if not Zero
              andn      outa,                   DIOPin_mask                     '          Force DataBit LOW
SHIFTOUT_ret  ret
'------------------------------------------------------------------------------------------------------------------------------
SHIFTIN                                                                         'SHIFTIN Entry
              andn      dira,                   DIOPin_mask                     'Set Data pin as an INPUT

              andn      outa,                   CLKPin_mask                     'Pre-Set Clock pin LOW
              or        dira,                   CLKPin_mask                     'Set Clock pin as an OUTPUT
MSBPOST_                                                                        '     Receive Data MSBPOST
MSBPOST_Sin   call      #Clock                                                  '          Send clock pulse
              test      DIOPin_mask,            ina     wc                      '          Read Data Bit into 'C' flag
              rcl       t3,                     #1                              '          rotate "C" flag into return value
              djnz      t4,                     #MSBPOST_Sin                    '          Decrement t4 ; jump if not Zero
SHIFTIN_ret   ret              
'------------------------------------------------------------------------------------------------------------------------------
Clock         or        outa,                   CLKPin_mask                     'Set ClockPin HIGH
              andn      outa,                   CLKPin_mask                     'Set ClockPin LOW
Clock_ret     ret
'------------------------------------------------------------------------------------------------------------------------------
' Perform CORDIC cartesian-to-polar conversion

'Input = cx(x) and cy(x)
'Output = cx(ro) and ca(theta)

cordic        abs       cx,cx           wc 
        if_c  neg       cy,cy             
              mov       ca,#0             
              rcr       ca,#1

              movs      :lookup,#table
              mov       t1,#0
              mov       t2,#20

:loop         mov       dx,cy           wc
              sar       dx,t1
              mov       dy,cx
              sar       dy,t1
              sumc      cx,dx
              sumnc     cy,dy
:lookup       sumc      ca,table

              add       :lookup,#1
              add       t1,#1
              djnz      t2,#:loop

              shr       ca,                     #19
              
cordic_ret    ret

table         long    $20000000
              long    $12E4051E
              long    $09FB385B
              long    $051111D4
              long    $028B0D43
              long    $0145D7E1
              long    $00A2F61E
              long    $00517C55
              long    $0028BE53
              long    $00145F2F
              long    $000A2F98
              long    $000517CC
              long    $00028BE6
              long    $000145F3
              long    $0000A2FA
              long    $0000517D
              long    $000028BE
              long    $0000145F
              long    $00000A30
              long    $00000518
'------------------------------------------------------------------------------------------------------------------------------
' Initialized data

                 '     ┌───── Start Bit              
                 '     │┌──── Single/Differential Bit
                 '     ││┌┳┳─ Channel Select         
                 '     
Xselect       long    %11000    'DAC Control Code
Yselect       long    %11001    'DAC Control Code
Zselect       long    %11010    'DAC Control Code
VoltRef       long    %11011    'DAC Control Code

DataMask      long    $1FFF     '13-Bit data mask

' Uninitialized data
x_            long    0                  
y_            long    0
z_            long    0
YXtheta_      long    0
ZXtheta_      long    0
YZtheta_      long    0
vref_         long    0

t1            res     1         'temp
t2            res     1         'temp
t3            res     1         'temp
t4            res     1         'temp
t5            res     1         'temp

CSPin_mask    res     1         'IO pin mask
DIOPin_mask   res     1         'IO pin mask 
CLKPin_mask   res     1         'IO pin mask 

H48C_vref_    res     1         'variable address location                      Arg3 

H48C_x_       res     1         'variable address location                      Arg4
H48C_y_       res     1         'variable address location                      Arg5
H48C_z_       res     1         'variable address location                      Arg6

H48C_YXtheta_ res     1         'variable address location                      Arg7
H48C_ZXtheta_ res     1         'variable address location                      Arg8
H48C_YZtheta_ res     1         'variable address location                      Arg9

dx            res     1         'cordic temp variable
dy            res     1         'cordic temp variable
cx            res     1         'cordic temp variable
cy            res     1         'cordic temp variable
ca            res     1         'cordic temp variable