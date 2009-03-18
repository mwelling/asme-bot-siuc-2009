{{
┌─────────────────────────────┬───────────────────┬──────────────────────┐
│ FPU_Matrix_Driver.spin v1.2 │ Author: I.Kövesdi │ Rel.:   25 08 2008   │
├─────────────────────────────┴───────────────────┴──────────────────────┤
│                    Copyright (c) 2008 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This driver object "expands" the matrix operation command set of the  │
│ uM-FPU v3.1 floating point coprocessor and provides the user a simple  │
│ interface for calculations with vectors and matrices in SPIN programs. │
│ Beside the basic matrix algebra, including copy, equality check,       │
│ transpose, add, subtract, multiply, maximum, minimum, the driver       │
│ implements inversion of square matrices, eigen-decomposition of square │
│ symmetric matrices and singular value decomposition of any rectangular │
│ matrices up to the size of 11-by-11. Beside this, a minimal set of     │
│ vector and float operations and float random number generation is      │
│ provided. This driver uses 2 COGs including the one for the SPIN       │
│ interpreter and the other for the PASM code SPI driver for the FPU.    │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  If your embedded application has anything to do with the physical     │
│ reality, e.g. it deals with position, speed, acceleration, rotation,   │
│ attitude or even with airplane navigation or UAV flight control then   │
│ you should use vectors and matrices in your calculations. A matrix can │
│ be a "storage" for a bunch of related numbers, e.g. a covariance matrix│
│ or can define a transform on a vector or on other matrices. The use of │
│ matrix algebra shines in many areas of computational mathematics as in │
│ coordinate transformations, rotational dynamics, control theory        │
│ including the Kalman filter. Matrix algebra can simplify complicated   │
│ problems and it's rules are not artificial mathematical constructions, │
│ but come from the nature of the problems and their solutions. A nice   │
│ summary that might give you some inspiration is as follows:            │
│                                                                        │
│ "In the worlds of math, engineering and physics, it's the matrix that  │ 
│ separates the men from the boys, the  women from the girls."           │
│                                                (Jack W. Crenshaw).     │
│                                                                        │
│  A matrix is an array of numbers organized in rows and columns. We     │
│ usually give the row number first, then the column. So a 3-by-4 matrix │
│ has 12 numbers arranged in three rows where each row has a length of   │
│ four                                                                   │
│                                                                        │
│                          ┌               ┐                             │
│                          │ 1  2  3   4   │                             │
│                          │ 2  3  4   5   │                             │
│                          │ 3  4  5  6.28 │                             │
│                          └               ┘                             │
│                                                                        │
│  Since computer RAM is not 2 dimensional, as we access it using only a │
│ single number that we call address, we have to find a way to map the   │
│ two dimensions of the matrix onto the one-dimensional, sequential      │
│ memory. In Propeller SPIN that's rather easy since we can use arrays.  │
│ For the previous matrix we declare an array of longs, e.g.             │
│                                                                        │
│ VAR   long mA[12]                                                      │
│                                                                        │
│ that is large enough to contain the "three times four" 32 bit IEEE 754 │
│ float numbers of the  matrix. In SPIN language the indexing starts with│
│ zero, so the first row, first column element of this matrix is placed  │
│ in mA[0]. The second row, fourth column element is placed in mA[7]. The│
│ general convention that I used with the "FPU_Matrix_Driver.spin" object│
│ is that the ith row, jth column element is accessed at the index       │
│                                                                        │ 
│                          "mA[i,j]" = mA[index]                         │
│                                                                        │
│ where                                                                  │
│                                                                        │
│                   index = (i-1)*(#columns) + (j-1)                     │
│                                                                        │
│ and #columns = 4 in this example. Matrices are passed to the driver    │
│ using their memory address. For example, after you declared mB and mC  │
│ matrices with the same size as mA, you can add mB to mC and store the  │
│ result in mA with the following procedure call                         │
│                                                                        │
│  OBJNAME.Matrix_Add(@mA, @mB, @mC, 3, 4)     (meaning mA := mB + mC)   │
│                                                                        │
│ You can't multiply mB with mC, of course, but you can multiply mB with │
│ the transpose of mC. To obtain this transpose use                      │
│                                                                        │
│  OBJNAME.Matrix_Transpose(@mCT, @mC, 3, 4)   (meaning mCT := Tr. of mC)│
│                                                                        │
│ mCT is a 4-by-3 matrix, which can be now multiplied from the left with │
│ mB as                                                                  │
│                                                                        │
│  OBJNAME.Matrix_Multiply(@mD,@mB,@mCT,3,4,3) (meaning mD := mB * mCT)  │
│                                                                        │
│ where the result mD is a 3-by-3 matrix. This matrix algebra coding     │
│ convention can yield compact and easy to debug code. The following 8   │      
│ lines of SPIN code were taken from the "FPU_ExtendedKF.spin"           │
│ application and calculate the Kalman gain matrix at a snap             │
│                                                                        │
│        (    Formula: K = A * P * CT * Inv[C * P * CT + Sz]   )         │
│                                                                        │
│      FPUMAT.Matrix_Transpose(@mCT, @mC, _R, _N)                        │
│      FPUMAT.Matrix_Multiply(@mAP, @mA, @mP, _N, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mAPCT, @mAP, @mCT, _N, _N, _R)            │
│      FPUMAT.Matrix_Multiply(@mCP, @mC, @mP, _R, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mCPCT, @mCP, @mCT, _R, _N, _R)            │
│      FPUMAT.Matrix_Add(@mCPCTSz, @mCPCT, @mSz, _R, _R)                 │
│      FPUMAT.Matrix_Invert(@mCPCTSzInv, @mCPCTSz, _R)                   │       
│      FPUMAT.Matrix_Multiply(@mK, @mAPCT, @mCPCTSzInv, _N, _R, _R)      │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│ -You can calculate with square or rectangular matrices with the driver.│
│ The only restriction is that the row*column product should be less than│
│ 128. So you can make algebra with, let's say 3-by-37 matrices or with  │
│ 91-by-1 vectors. However, both the inverse calculations and the eigen- │
│ -decompositions are for square matrices only, so here the maximum size │
│ is 11-by-11. Since the singular value decomposition is based here on   │
│ eigen-decomposition, the same size limit applies to the SVD. In other  │
│ words, neither row nor column can be larger than 11 for the rectangular│
│ (or even square) matrix that is submitted to SVD.                      │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

  _SMALL =  10
  _LARGE =  43
  _BIG   = 128

  #1,  _INIT, _RST, _WAIT                                           '1-3
  #4,  _WRTBYTE, _WRTCMDBYTE, _WRTCMD2BYTES, _WRTCMD3BYTES          '4-7
  #8,  _WRTCMD4BYTES, _WRTCMDREG, _WRTCMDRNREG                      '8-10
  #11, _WRTCMDCNTREGS, _WRTCMDSTRING                                '11-12
  #13, _RDBYTE, _RDREG, _RDREGS, _RDSTRING                          '13-16
  #17, _RANDOMIZE                                                   '17
'These are the enumerated PASM command No.s (_INIT=1, _RST=2,etc..)They
'should be in harmony with the Cmd_Table of the PASM program in the DAT
'section of this object

  _MAXSTRL   = 16        'Max string length
  _FTOAD     = 20_000    'FTOA delay max 250 us
  
'uM-FPU V3.1 opcodes and indexes------------------------------------------
  _NOP       = $00       'No Operation
  _SELECTA   = $01       'Select register A  
  _SELECTX   = $02       'Select register X

  _CLR       = $03       'Reg[nn] = 0
  _CLRA      = $04       'Reg[A] = 0
  _CLRX      = $05       'Reg[X] = 0, X = X + 1
  _CLR0      = $06       'Reg[0] = 0

  _COPY      = $07       'Reg[nn] = Reg[mm]
  _COPYA     = $08       'Reg[nn] = Reg[A]
  _COPYX     = $09       'Reg[nn] = Reg[X], X = X + 1
  _LOAD      = $0A       'Reg[0] = Reg[nn]
  _LOADA     = $0B       'Reg[0] = Reg[A]
  _LOADX     = $0C       'Reg[0] = Reg[X], X = X + 1
  _ALOADX    = $0D       'Reg[A] = Reg[X], X = X + 1
  _XSAVE     = $0E       'Reg[X] = Reg[nn], X = X + 1
  _XSAVEA    = $0F       'Reg[X] = Reg[A], X = X + 1
  _COPY0     = $10       'Reg[nn] = Reg[0]
  _COPYI     = $11       'Reg[nn] = long(unsigned bb)
  _SWAP      = $12       'Swap Reg[nn] and Reg[mm]
  _SWAPA     = $13       'Swap Reg[A] and Reg[nn]
  
  _LEFT      = $14       'Left parenthesis
  _RIGHT     = $15       'Right parenthesis
  
  _FWRITE    = $16       'Write 32-bit float to Reg[nn]
  _FWRITEA   = $17       'Write 32-bit float to Reg[A]
  _FWRITEX   = $18       'Write 32-bit float to Reg[X], X = X + 1
  _FWRITE0   = $19       'Write 32-bit float to Reg[0]

  _FREAD     = $1A       'Read 32-bit float from Reg[nn]
  _FREADA    = $1B       'Read 32-bit float from Reg[A]
  _FREADX    = $1C       'Read 32-bit float from Reg[X], X = X + 1
  _FREAD0    = $1D       'Read 32-bit float from Reg[0]

  _ATOF      = $1E       'Convert ASCII string to float, store in Reg[0]
  _FTOA      = $1F       'Convert float in Reg[A] to ASCII string.
  
  _FSET      = $20       'Reg[A] = Reg[nn] 

  _FADD      = $21       'Reg[A] = Reg[A] + Reg[nn]
  _FSUB      = $22       'Reg[A] = Reg[A] - Reg[nn]
  _FSUBR     = $23       'Reg[A] = Reg[nn] - Reg[A]
  _FMUL      = $24       'Reg[A] = Reg[A] * Reg[nn]
  _FDIV      = $25       'Reg[A] = Reg[A] / Reg[nn]
  _FDIVR     = $26       'Reg[A] = Reg[nn] / Reg[A]
  _FPOW      = $27       'Reg[A] = Reg[A] ** Reg[nn]
  _FCMP      = $28       'Float compare Reg[A] - Reg[nn]
  
  _FSET0     = $29       'Reg[A] = Reg[0]
  _FADD0     = $2A       'Reg[A] = Reg[A] + Reg[0]
  _FSUB0     = $2B       'Reg[A] = Reg[A] - Reg[0]
  _FSUBR0    = $2C       'Reg[A] = Reg[0] - Reg[A]
  _FMUL0     = $2D       'Reg[A] = Reg[A] * Reg[0]
  _FDIV0     = $2E       'Reg[A] = Reg[A] / Reg[0]
  _FDIVR0    = $2F       'Reg[A] = Reg[0] / Reg[A]
  _FPOW0     = $30       'Reg[A] = Reg[A] ** Reg[0]
  _FCMP0     = $31       'Float compare Reg[A] - Reg[0]  

  _FSETI     = $32       'Reg[A] = float(bb)
  _FADDI     = $33       'Reg[A] = Reg[A] + float(bb)
  _FSUBI     = $34       'Reg[A] = Reg[A] - float(bb)
  _FSUBRI    = $35       'Reg[A] = float(bb) - Reg[A]
  _FMULI     = $36       'Reg[A] = Reg[A] * float(bb)
  _FDIVI     = $37       'Reg[A] = Reg[A] / float(bb) 
  _FDIVRI    = $38       'Reg[A] = float(bb) / Reg[A]
  _FPOWI     = $39       'Reg[A] = Reg[A] ** bb
  _FCMPI     = $3A       'Float compare Reg[A] - float(bb)
  
  _FSTATUS   = $3B       'Float status of Reg[nn]
  _FSTATUSA  = $3C       'Float status of Reg[A]
  _FCMP2     = $3D       'Float compare Reg[nn] - Reg[mm]

  _FNEG      = $3E       'Reg[A] = -Reg[A]
  _FABS      = $3F       'Reg[A] = | Reg[A] |
  _FINV      = $40       'Reg[A] = 1 / Reg[A]
  _SQRT      = $41       'Reg[A] = sqrt(Reg[A])    
  _ROOT      = $42       'Reg[A] = root(Reg[A], Reg[nn])
  _LOG       = $43       'Reg[A] = log(Reg[A])
  _LOG10     = $44       'Reg[A] = log10(Reg[A])
  _EXP       = $45       'Reg[A] = exp(Reg[A])
  _EXP10     = $46       'Reg[A] = exp10(Reg[A])
  _SIN       = $47       'Reg[A] = sin(Reg[A])
  _COS       = $48       'Reg[A] = cos(Reg[A])
  _TAN       = $49       'Reg[A] = tan(Reg[A])
  _ASIN      = $4A       'Reg[A] = asin(Reg[A])
  _ACOS      = $4B       'Reg[A] = acos(Reg[A])
  _ATAN      = $4C       'Reg[A] = atan(Reg[A])
  _ATAN2     = $4D       'Reg[A] = atan2(Reg[A], Reg[nn])
  _DEGREES   = $4E       'Reg[A] = degrees(Reg[A])
  _RADIANS   = $4F       'Reg[A] = radians(Reg[A])
  _FMOD      = $50       'Reg[A] = Reg[A] MOD Reg[nn]
  _FLOOR     = $51       'Reg[A] = floor(Reg[A])
  _CEIL      = $52       'Reg[A] = ceil(Reg[A])
  _ROUND     = $53       'Reg[A] = round(Reg[A])
  _FMIN      = $54       'Reg[A] = min(Reg[A], Reg[nn])
  _FMAX      = $55       'Reg[A] = max(Reg[A], Reg[nn])
  
  _FCNV      = $56       'Reg[A] = conversion(nn, Reg[A])
    _F_C       = 0       '├─>F to C
    _C_F       = 1       '├─>C to F
    _IN_MM     = 2       '├─>in to mm
    _MM_IN     = 3       '├─>mm to in
    _IN_CM     = 4       '├─>in to cm
    _CM_IN     = 5       '├─>cm to in
    _IN_M      = 6       '├─>in to m
    _M_IN      = 7       '├─>m to in
    _FT_M      = 8       '├─>ft to m
    _M_FT      = 9       '├─>m to ft
    _YD_M      = 10      '├─>yd to m
    _M_YD      = 11      '├─>m to yd
    _MI_KM     = 12      '├─>mi to km
    _KM_MI     = 13      '├─>km to mi
    _NMI_M     = 14      '├─>nmi to m
    _M_NMI     = 15      '├─>m to nmi
    _ACR_M2    = 16      '├─>acre to m2
    _M2_ACR    = 17      '├─>m2 to acre
    _OZ_G      = 18      '├─>oz to g
    _G_OZ      = 19      '├─>g to oz
    _LB_KG     = 20      '├─>lb to kg
    _KG_LB     = 21      '├─>kg to lb
    _USGAL_L   = 22      '├─>USgal to l
    _L_USGAL   = 23      '├─>l to USgal
    _UKGAL_L   = 24      '├─>UKgal to l
    _L_UKGAL   = 25      '├─>l to UKgal
    _USOZFL_ML = 26      '├─>USozfl to ml
    _ML_USOZFL = 27      '├─>ml to USozfl
    _UKOZFL_ML = 28      '├─>UKozfl to ml
    _ML_UKOZFL = 29      '├─>ml to UKozfl
    _CAL_J     = 30      '├─>cal to J
    _J_CAL     = 31      '├─>J to cal
    _HP_W      = 32      '├─>hp to W
    _W_HP      = 33      '├─>W to hp
    _ATM_KP    = 34      '├─>atm to kPa
    _KP_ATM    = 35      '├─>kPa to atm
    _MMHG_KP   = 36      '├─>mmHg to kPa
    _KP_MMHG   = 37      '├─>kPa to mmHg
    _DEG_RAD   = 38      '├─>degrees to radians
    _RAD_DEG   = 39      '└─>radians to degrees    

  _FMAC      = $57       'Reg[A] = Reg[A] + (Reg[nn] * Reg[mm])
  _FMSC      = $58       'Reg[A] = Reg[A] - (Reg[nn] * Reg[mm])

  _LOADBYTE  = $59       'Reg[0] = float(signed bb)
  _LOADUBYTE = $5A       'Reg[0] = float(unsigned byte)
  _LOADWORD  = $5B       'Reg[0] = float(signed word)
  _LOADUWORD = $5C       'Reg[0] = float(unsigned word)
  
  _LOADE     = $5D       'Reg[0] = 2.7182818             
  _LOADPI    = $5E       'Reg[0] = 3.1415927
  
  _LOADCON   = $5F       'Reg[0] = float constant(nn)                        
    _ONE      = 0        '├─>1e0 one
    _1E1      = 1        '├─>1e1
    _1E2      = 2        '├─>1e2
    _KILO     = 3        '├─>1e3 kilo
    _1E4      = 4        '├─>1e4
    _1E5      = 5        '├─>1e5
    _MEGA     = 6        '├─>1e6 mega
    _1E7      = 7        '├─>1e7
    _1E8      = 8        '├─>1e8
    _GIGA     = 9        '├─>1e9 giga
    _MAXFLOAT = 10       '├─>3.4028235e38   :Largest 32-bit f.p. value                                   
    _MINFLOAT = 11       '├─>1.4012985e-45  :Smallest nonzero 32-bit f.p.
    _C        = 12       '├─>299792458.0    :Speed of light in vaccum[m/s]
    _GRAVCON  = 13       '├─>6.6742e-11     :Const. of grav. [m3/(kg*s2)]
    _MEANG    = 14       '├─>9.80665        :Mean accel. of gravity [m/s2]
    _EMASS    = 15       '├─>9.1093826e-31  :Electron mass [kg]
    _PMASS    = 16       '├─>1.67262171e-27 :Proton mass [kg]
    _NMASS    = 17       '├─>1.67492728e-27 :Neutron mass [kg]
    _A        = 18       '├─>6.0221415e23   :Avogadro constant [1/mol]
    _ELCHRG   = 19       '├─>1.60217653e-19 :Elementary charge [coulomb]
    _STDATM   = 20       '└─>101.325        :Standard atmosphere [kPa]

  _FLOAT     = $60       'Reg[A] = float(Reg[A])     :long to float  
  _FIX       = $61       'Reg[A] = fix(Reg[A])       :float to long
  _FIXR      = $62       'Reg[A] = fix(round(Reg[A])):rounded float to lng
  _FRAC      = $63       'Reg[A] = fraction(Reg[A])  
  _FSPLIT    = $64       'Reg[A] = int(Reg[A]), Reg[0] = frac(Reg[A])
  
  _SELECTMA  = $65       'Select matrix A
  _SELECTMB  = $66       'Select matrix B
  _SELECTMC  = $67       'Select matrix C
  _LOADMA    = $68       'Reg[0] = matrix A[bb, bb]
  _LOADMB    = $69       'Reg[0] = matrix B[bb, bb]
  _LOADMC    = $6A       'Reg[0] = matrix C[bb, bb]
  _SAVEMA    = $6B       'Matrix A[bb, bb] = Reg[0]                                         
  _SAVEMB    = $6C       'Matrix B[bb, bb] = Reg[0]                                             
  _SAVEMC    = $6D       'Matrix C[bb, bb] = Reg[0]                      

  _MOP       = $6E       'Matrix operation
    '-------------------------For each r(ow), c(olumn)--------------------
    _SCALAR_SET  = 0     '├─>MA[r, c] = Reg[0]
    _SCALAR_ADD  = 1     '├─>MA[r, c] = MA[r, c] + Reg[0]
    _SCALAR_SUB  = 2     '├─>MA[r, c] = MA[r, c] - Reg[0]
    _SCALAR_SUBR = 3     '├─>MA[r, c] = Reg[0] - MA[r, c] 
    _SCALAR_MUL  = 4     '├─>MA[r, c] = MA[r, c] * Reg[0]
    _SCALAR_DIV  = 5     '├─>MA[r, c] = MA[r, c] / Reg[0]
    _SCALAR_DIVR = 6     '├─>MA[r, c] = Reg[0] / MA[r, c]
    _SCALAR_POW  = 7     '├─>MA[r, c] = MA[r, c] ** Reg[0]
    _EWISE_SET   = 8     '├─>MA[r, c] = MB[r, c]
    _EWISE_ADD   = 9     '├─>MA[r, c] = MA[r, c] + MB[r, c]
    _EWISE_SUB   = 10    '├─>MA[r, c] = MA[r, c] - MB[r, c]                                 
    _EWISE_SUBR  = 11    '├─>MA[r, c] = MB[r, c] - MA[r, c]
    _EWISE_MUL   = 12    '├─>MA[r, c] = MA[r, c] * MB[r, c]
    _EWISE_DIV   = 13    '├─>MA[r, c] = MA[r, c] / MB[r, c]
    _EWISE_DIVR  = 14    '├─>MA[r, c] = MB[r, c] / MA[r, c]
    _EWISE_POW   = 15    '├─>MA[r, c] = MA[r, c] ** MB[r, c]
    '---------------------------------------------------------------------
    _MX_MULTIPLY = 16    '├─>MA = MB * MC 
    _MX_IDENTITY = 17    '├─>MA = I = Identity matrix (Diag. of ones)
    _MX_DIAGONAL = 18    '├─>MA = Reg[0] * I
    _MX_TRANSPOSE= 19    '├─>MA = Transpose of MB
    '---------------------------------------------------------------------
    _MX_COUNT    = 20    '├─>Reg[0] = Number of elements in MA 
    _MX_SUM      = 21    '├─>Reg[0] = Sum of elements in MA
    _MX_AVE      = 22    '├─>Reg[0] = Average of elements in MA
    _MX_MIN      = 23    '├─>Reg[0] = Minimum of elements in MA 
    _MX_MAX      = 24    '├─>Reg[0] = Maximum of elements in MA
   '----------------------------------------------------------------------
    _MX_COPYAB   = 25    '├─>MB = MA 
    _MX_COPYAC   = 26    '├─>MC = MA
    _MX_COPYBA   = 27    '├─>MA = MB 
    _MX_COPYBC   = 28    '├─>MC = MB
    _MX_COPYCA   = 29    '├─>MA = MC 
    _MX_COPYCB   = 30    '├─>MB = MC
    '---------------------------------------------------------------------
    _MX_DETERM   = 31    '├─>Reg[0]=Determinant of MA (for 2x2 or 3x3 MA)
    _MX_INVERSE  = 32    '├─>MA = Inverse of MB (for 2x2 or 3x3 MB)
    '---------------------------------------------------------------------
    _MX_ILOADRA  = 33    '├─>Indexed Load Registers to MA
    _MX_ILOADRB  = 34    '├─>Indexed Load Registers to MB
    _MX_ILOADRC  = 35    '├─>Indexed Load Registers to MC
    _MX_ILOADBA  = 36    '├─>Indexed Load MB to MA
    _MX_ILOADCA  = 37    '├─>Indexed Load MC to MA 
    _MX_ISAVEAR  = 38    '├─>Indexed Load MA to Registers
    _MX_ISAVEAB  = 39    '├─>Indexed Load MA to MB
    _MX_ISAVEAC  = 40    '└─>Indexed Load MA to MC

  _FFT       = $6F       'FFT operation
    _FIRST_STAGE = 0     '├─>Mode : First stage 
    _NEXT_STAGE  = 1     '├─>Mode : Next stage 
    _NEXT_LEVEL  = 2     '├─>Mode : Next level
    _NEXT_BLOCK  = 3     '├─>Mode : Next block
    '---------------------------------------------------------------------
    _BIT_REVERSE = 4     '├─>Mode : Pre-processing bit reverse sort 
    _PRE_ADJUST  = 8     '├─>Mode : Pre-processing for inverse FFT
    _POST_ADJUST = 16    '└─>Mode : Post-processing for inverse FFT
  
  _WRBLK     = $70       'Write register block
  _RDBLK     = $71       'Read register block

  _LOADIND   = $7A       'Reg[0] = Reg[Reg[nn]]
  _SAVEIND   = $7B       'Reg[Reg[nn]] = Reg[A]
  _INDA      = $7C       'Select A using Reg[nn]
  _INDX      = $7D       'Select X using Reg[nn]

  _FCALL     = $7E       'Call function in Flash memory
  _EECALL    = $7F       'Call function in EEPROM memory
  
  _RET       = $80       'Return from function
  _BRA       = $81       'Unconditional branch
  _BRACC     = $82       'Conditional branch
  _JMP       = $83       'Unconditional jump
  _JMPCC     = $84       'Conditional jump
  _TABLE     = $85       'Table lookup
  _FTABLE    = $86       'Floating point reverse table lookup
  _LTABLE    = $87       'Long integer reverse table lookup
  _POLY      = $88       'Reg[A] = nth order polynomial
  _GOTO      = $89       'Computed goto
  _RETCC     = $8A       'Conditional return from function
 
  _LWRITE    = $90       'Write 32-bit long integer to Reg[nn]
  _LWRITEA   = $91       'Write 32-bit long integer to Reg[A]
  _LWRITEX   = $92       'Write 32-bit long integer to Reg[X], X = X + 1
  _LWRITE0   = $93       'Write 32-bit long integer to Reg[0]

  _LREAD     = $94       'Read 32-bit long integer from Reg[nn] 
  _LREADA    = $95       'Read 32-bit long integer from Reg[A]
  _LREADX    = $96       'Read 32-bit long integer from Reg[X], X = X + 1   
  _LREAD0    = $97       'Read 32-bit long integer from Reg[0]

  _LREADBYTE = $98       'Read lower 8 bits of Reg[A]
  _LREADWORD = $99       'Read lower 16 bits Reg[A]
  
  _ATOL      = $9A       'Convert ASCII to long integer
  _LTOA      = $9B       'Convert long integer to ASCII

  _LSET      = $9C       'reg[A] = reg[nn]
  _LADD      = $9D       'reg[A] = reg[A] + reg[nn]
  _LSUB      = $9E       'reg[A] = reg[A] - reg[nn]
  _LMUL      = $9F       'reg[A] = reg[A] * reg[nn]
  _LDIV      = $A0       'reg[A] = reg[A] / reg[nn]
  _LCMP      = $A1       'Signed long compare reg[A] - reg[nn]
  _LUDIV     = $A2       'reg[A] = reg[A] / reg[nn]
  _LUCMP     = $A3       'Unsigned long compare of reg[A] - reg[nn]
  _LTST      = $A4       'Long integer status of reg[A] AND reg[nn] 
  _LSET0     = $A5       'reg[A] = reg[0]
  _LADD0     = $A6       'reg[A] = reg[A] + reg[0]
  _LSUB0     = $A7       'reg[A] = reg[A] - reg[0]
  _LMUL0     = $A8       'reg[A] = reg[A] * reg[0]
  _LDIV0     = $A9       'reg[A] = reg[A] / reg[0]
  _LCMP0     = $AA       'Signed long compare reg[A] - reg[0]
  _LUDIV0    = $AB       'reg[A] = reg[A] / reg[0]
  _LUCMP0    = $AC       'Unsigned long compare reg[A] - reg[0]
  _LTST0     = $AD       'Long integer status of reg[A] AND reg[0] 
  _LSETI     = $AE       'reg[A] = long(bb)
  _LADDI     = $AF       'reg[A] = reg[A] + long(bb)
  _LSUBI     = $B0       'reg[A] = reg[A] - long(bb)
  _LMULI     = $B1       'Reg[A] = Reg[A] * long(bb)
  _LDIVI     = $B2       'Reg[A] = Reg[A] / long(bb); Remainder in Reg0

  _LCMPI     = $B3       'Signed long compare Reg[A] - long(bb)
  _LUDIVI    = $B4       'Reg[A] = Reg[A] / unsigned long(bb)
  _LUCMPI    = $B5       'Unsigned long compare Reg[A] - ulong(bb)
  _LTSTI     = $B6       'Long integer status of Reg[A] AND ulong(bb)
  _LSTATUS   = $B7       'Long integer status of Reg[nn]
  _LSTATUSA  = $B8       'Long integer status of Reg[A]
  _LCMP2     = $B9       'Signed long compare Reg[nn] - Reg[mm]
  _LUCMP2    = $BA       'Unsigned long compare Reg[nn] - Reg[mm]
  
  _LNEG      = $BB       'Reg[A] = -Reg[A]
  _LABS      = $BC       'Reg[A] = | Reg[A] |
  _LINC      = $BD       'Reg[nn] = Reg[nn] + 1
  _LDEC      = $BE       'Reg[nn] = Reg[nn] - 1
  _LNOT      = $BF       'Reg[A] = NOT Reg[A]

  _LAND      = $C0       'reg[A] = reg[A] AND reg[nn]
  _LOR       = $C1       'reg[A] = reg[A] OR reg[nn]
  _LXOR      = $C2       'reg[A] = reg[A] XOR reg[nn]
  _LSHIFT    = $C3       'reg[A] = reg[A] shift reg[nn]
  _LMIN      = $C4       'reg[A] = min(reg[A], reg[nn])
  _LMAX      = $C5       'reg[A] = max(reg[A], reg[nn])
  _LONGBYTE  = $C6       'reg[0] = long(signed byte bb)
  _LONGUBYTE = $C7       'reg[0] = long(unsigned byte bb)
  _LONGWORD  = $C8       'reg[0] = long(signed word wwww)
  _LONGUWORD = $C9       'reg[0] = long(unsigned word wwww)
  _SETSTATUS = $CD       'Set status byte
  _SEROUT    = $CE       'Serial output
  _SERIN     = $CF       'Serial Input
  _SETOUT    = $D0       'Set OUT1 and OUT2 output pins
  _ADCMODE   = $D1       'Set A/D trigger mode
  _ADCTRIG   = $D2       'A/D manual trigger
  _ADCSCALE  = $D3       'ADCscale[ch] = B
  _ADCLONG   = $D4       'reg[0] = ADCvalue[ch]
  _ADCLOAD   = $D5       'reg[0] = float(ADCvalue[ch]) * ADCscale[ch]
  _ADCWAIT   = $D6       'wait for next A/D sample
  _TIMESET   = $D7       'time = reg[0]
  _TIMELONG  = $D8       'reg[0] = time (long)
  _TICKLONG  = $D9       'reg[0] = ticks (long)
  _EESAVE    = $DA       'EEPROM[nn] = reg[mm]
  _EESAVEA   = $DB       'EEPROM[nn] = reg[A]
  _EELOAD    = $DC       'reg[nn] = EEPROM[mm]
  _EELOADA   = $DD       'reg[A] = EEPROM[nn]
  _EEWRITE   = $DE       'Store bytes in EEPROM
  _EXTSET    = $E0       'external input count = reg[0]
  _EXTLONG   = $E1       'reg[0] = external input counter (long)
  _EXTWAIT   = $E2       'wait for next external input
  _STRSET    = $E3       'Copy string to string buffer
  _STRSEL    = $E4       'Set selection point
  _STRINS    = $E5       'Insert string at selection point
  _STRCMP    = $E6       'Compare string with string buffer
  _STRFIND   = $E7       'Find string and set selection point
  _STRFCHR   = $E8       'Set field separators
  _STRFIELD  = $E9       'Find field and set selection point
  _STRTOF    = $EA       'Convert string selection to float
  _STRTOL    = $EB       'Convert string selection to long
  _READSEL   = $EC       'Read string selection
  _STRBYTE   = $ED       'Insert 8-bit byte at selection point
  _STRINC    = $EE       'increment selection point
  _STRDEC    = $EF       'decrement selection point  
 
  _SYNC      = $F0       'Get synchronization character 
    _SYNC_CHAR = $5C     '└─>Synchronization character(Decimal 92)
    
  _READSTAT  = $F1       'Read status byte 
  _READSTR   = $F2       'Read string from string buffer    
  _VERSION   = $F3       'Copy version string to string buffer     
  _CHECKSUM  = $F6       'Calculate checksum for uM-FPU   

  _READVAR   = $FC       'Read internal variable, store in Reg[0]
    _A_REG    = 0        '├─>Reg[0] = A register
    _X_REG    = 1        '├─>Reg[0] = X register
    _MA_REG   = 2        '├─>Reg[0] = MA register
    _MA_ROWS  = 3        '├─>Reg[0] = MA rows
    _MA_COLS  = 4        '├─>Reg[0] = MA columns
    _MB_REG   = 5        '├─>Reg[0] = MB register
    _MB_ROWS  = 6        '├─>Reg[0] = MB rows
    _MB_COLS  = 7        '├─>Reg[0] = MB columns
    _MC_REG   = 8        '├─>Reg[0] = MC register
    _MC_ROWS  = 9        '├─>Reg[0] = MC rows
    _MC_COLS  = 10       '├─>Reg[0] = MC columns
    _INTMODE  = 11       '├─>Reg[0] = Internal mode word
    _STATBYTE = 12       '├─>Reg[0] = Last status byte
    _TICKS    = 13       '├─>Reg[0] = Clock ticks per milisecond
    _STRL     = 14       '├─>Reg[0] = Current length of string buffer
    _STR_SPTR = 15       '├─>Reg[0] = String selection starting point
    _STR_SLEN = 16       '├─>Reg[0] = String selection length
    _STR_SASC = 17       '├─>Reg[0] = ASCII char at string selection point
    _INSTBUF  = 18       '└─>Reg[0] = Number of bytes in instr. buffer

  _RESET      = $FF      'NOP (but 9 consecutive $FF bytes cause a reset
                         'in SPI protocol)

VAR

  long   cog, command, par1, par2, par3, par4, par5 
  byte   str[_MAXSTRL]   'The holder of strings. Star_COG passes its
                         'address to the PASM code.

  long   mU[121]   'Auxiliary arrays for matrix multiplication, inversion,
  long   mP[121]   'eigen-decomposition and singular value decomposition, 
  long   mV[121]   'index calculations, etc...


'Data Flow within FPU_Matrix_Driver object:
'==========================================
'Many procedures of this driver use heavily the FPU Read/Write procedures.
'These Read/Write procedures uses the SPIN variable "command" to call PASM.
'"command" will contain the command No. and par1, par2, etc..., will
'contain parameters. These par1, par2, etc..., HUB registers can be used
'as inputs or outputs for the PASM routines. These PASM routines can be
'selected by simply writing an appropriate command No. into the "command"
'register using the Driver's SPIN code after(!) writing the necessary
'parameters into the par1, par2, etc... SPIN code variables. The PASM code,
'which is continuously running in it's COG, will sense this and will
'switch to the corresponding PASM routine. This PASM routine then fetches
'it's parameters from the par1, par2, etc... variables in HUB and will do
'it's job. After this it will fill the resulting data in the par1, par2,
'etc...  HUB variables. Finally, the PASM code will write zero into
'HUB/command to signal back a "Command Processed" status for the SPIN code
'that called it.

'Data Flow between FPU_SPI_Driver object and a calling SPIN code object:
'========================================================================
'External SPIN code objects passes the addresses of the matrices to the
'available PUB routines of the driver object. In other words strings and
'register arrays are passed by reference. Anything else is passed by value
'in the standard way. 


PUB StartCOG(dio_Pin, clk_Pin) : okay
'-------------------------------------------------------------------------
'----------------------------------┌──────────┐---------------------------
'----------------------------------│ StartCOG │---------------------------
'----------------------------------└──────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Starts a COG to run uMFPU_Driver PASM code             
'' Parameters: dIO_Pin, cLK_Pin, @str (in HUB)
''    Results: okay (in HUB)
''+Reads/Uses: /command, cog, par1, par2, par3, @str, _INIT
''    +Writes: command, cog, par1, par2, par3
''      Calls: #Init (in COG)
'-------------------------------------------------------------------------
  StopCOG                              'Stop previous copy of this driver,
                                       'if any
  command := 0
  cog := cognew(@uMFPU, @command) + 1  'Try to start a COG with a running
                                       'PASM program that waits for a
                                       'nonzero "command"

  if cog                               'COG has been succcessfully started
    par1 := dio_Pin                    'Initialize PASM Driver with the 
    par2 := clk_Pin                    'DIO and CLK pins and with a
    par3 := @str                       'Pointer to HUB/str character array
    command := _INIT                   

    repeat while command       'Wait for _INIT command to be processed
    okay := par1               'Signal back error condition (from par1)
  else
    okay := false              'Signal back error if no COG available
 
  return okay 
'-------------------------------------------------------------------------

PUB StopCOG                                          
'-------------------------------------------------------------------------
'----------------------------------┌─────────┐----------------------------
'----------------------------------│ StopCOG │----------------------------
'----------------------------------└─────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Stops uMFPU_Driver PASM code by freeing a COG in which it
''             is running
'' Parameters: HUB/cog
''    Results: None 
''+Reads/Uses: /command, cog
''    +Writes: cog, command
''      Calls: None
'-------------------------------------------------------------------------
  command~                             'Clear "command" reister
                                       'Instead of this you can initiate a
                                       'shut off PASM routine if necessary 
  if cog
    cogstop(cog~ - 1)                  'Clears COG after usage
'-------------------------------------------------------------------------


PUB Matrix_LongToFloat(a_, r, c) | size, i, fV                                  
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Matrix_LongToFloat │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Converts Long valued matrix in place to Float valued one                                                 
'' Parameters: Row and Col of matrix {A}                     
''    Results: Float({A}) 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''       Note: Primarily for test and debug purposes, original {A} is
''             overwritten
'-------------------------------------------------------------------------
  size := r * c
  if (size < _BIG)                       'Check size of matrix  
    'Do conversion inside FPU
    WriteCmdByte(_SELECTX, 1)            'Load MA from HUB into FPU  
    WriteCmdCntLongs(_WRBLK, size, a_)

    repeat i from 2 to size              'Covert longs to floats in FPU
      WriteCmdByte(_SELECTA, i)
      WriteCmd(_FLOAT)
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FLOAT)  

    ReadRegs(2, size - 1, a_ + 4)       'Now reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV

  else
    abort   
'-------------------------------------------------------------------------


PUB Matrix_Copy(a_, b_, n, m) | size, fV                                  
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Matrix__Copy │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Copies {B} into {A}                                                  
'' Parameters: Address of HUB/{A}, {B}, N, M
''    Results: {A}={B} 
''+Reads/Uses: /_BIG, FPU CONs, 
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'------------------------------------------------------------------------- 
  size := n * n
  if (size < _BIG)                      'Check size of matrix
    'Do it inside FPU
    WriteCmd3Bytes(_SELECTMA, 1, n, m)  'Decleare matrix MA in FPU 
    WriteCmdCntFloats(_WRBLK, size, b_) 'Load HUB/{B} into FPU/MA
  
    ReadRegs(2, size - 1, a_ + 4)       'Now reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV
     
  else
    abort
'-------------------------------------------------------------------------


PUB Matrix_EQ(a_,b_,r,c,eps):okay|sz,sz1,i,maxV,minV,ok1,ok2,v1,v2                                 
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Matrix_EQ │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of {A} and {B} matrices within Epsilon                                               
'' Parameters: Pointer to matrices HUB/{A}, {B},
''             Row and Col of matrices
''             eps margin         
''    Results: True if each element of {A} is closer to the corresponding
''             element of {B} than eps 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''             Float_GT
'------------------------------------------------------------------------
  sz := r * c
  sz1 := sz - 1
  
  if (sz < _BIG)
    if ((2 * sz) < _BIG)                     'Check size of matrices 
      'Do it inside FPU
      'Decleare matrices in FPU 
      WriteCmd3Bytes(_SELECTMA, 1, r, c)
      WriteCmdCntFloats(_WRBLK, sz, a_)      'Load HUB/{A} into FPU/MA      
      WriteCmd3Bytes(_SELECTMB, 1 + sz, r, c)
      WriteCmdCntFloats(_WRBLK, sz, b_)      'Load HUB/{B} into FPU/MB 
      WriteCmdByte(_MOP, _EWISE_SUB)         'Do subraction MA=MA-MB
      Wait
      WriteCmdByte(_MOP, _MX_MAX)            'Reg[0]=Max. of MA's elements
      Wait
      WriteCmd(_FREAD0)
      maxV := ReadReg   
      WriteCmdByte(_MOP, _MX_MIN)            'Reg[0]=Min. of MA's elements
      Wait
      WriteCmd(_FREAD0)
      minV := ReadReg
      WriteCmdByte(_SELECTA, 127)
      WriteCmdFloat(_FWRITEA, maxV)
      WriteCmd(_FABS)
      Wait
      WriteCmd(_FREADA)
      maxV := ReadReg
      WriteCmdFloat(_FWRITEA, minV)
      WriteCmd(_FABS)
      Wait
      WriteCmd(_FREADA)
      minV := ReadReg        
      ok1 := Float_GT(eps, maxV, 0.0)
      ok2 := Float_GT(eps, minV, 0.0)
      okay := (ok1 AND ok2)
    else
      'Do it in HUB
      repeat i from 0 to sz1
        v1 := long[a_][i] 
        v2 := long[b_][i]
        okay := Float_EQ(v1, v2, eps)
        if (NOT okay)
          quit
  else
    abort
  
  return okay  
'-------------------------------------------------------------------------


PUB Matrix_Identity(a_, n) | size, fV                                  
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ Matrix__Identity │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Creates an [n-by-n] Identity matrix                                                  
'' Parameters: Address of HUB/{A}, n
''    Results: Diagonal matrix {A} with one-s in the diagonal 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'------------------------------------------------------------------------- 
  size := n * n
  if (size < _BIG)                      'Check size of matrix
    'Do it inside FPU
    WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare matrix MA in FPU 
    WriteCmdByte(_MOP, _MX_IDENTITY)    'Create NxN Identity matrix MA
      
    ReadRegs(2, size - 1, a_ + 4)       'Now reload matrix MA into HUB
    long [a_][0] := 1.0
      
  else
    abort
'-------------------------------------------------------------------------


PUB Matrix_Diagonal(a_, n, floatV) | size, d, i, fV
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ Matrix__Diagonal │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Creates an [n-by-n] diagonal matrix                                                  
'' Parameters: Address of HUB/{A}, n, floatV value for the diagonal
''    Results: Diagonal matrix MA with floatV in the diagonal 
''+Reads/Uses:/_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
  size := n * n
  if (size < _BIG)                       'Check size of matrix    
    'Do it inside FPU
    WriteCmdFloat(_FWRITE0, floatV) 
    WriteCmd3Bytes(_SELECTMA, 1, n, n)   'Decleare matrix MA in FPU 
    WriteCmdByte(_MOP, _MX_DIAGONAL)     'Create diagonal matrix MA
    
    ReadRegs(2, size - 1, a_ + 4)       'Now reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV
      
  else
    abort
'-------------------------------------------------------------------------


PUB Matrix_Transpose(a_, b_, n, m) | size, s2, fV, i, j                                 
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Matrix_Transpose │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Transposes {B} [n-by-m] matrix                                           
'' Parameters: Pointer to matrices HUB/{A}, {B}
''             n=Rows of {B}, m=Cols of {B}                      
''    Results: {A} = {BT} [m-by-n]
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
''       Note: {A} is a [m-by-n] matrix
'-------------------------------------------------------------------------  
  size := n * m
  if (size => _BIG)
    abort
  s2 := 2 * size
  if (s2 < _BIG)                             'Check total size of {A}, {B}
    'Do transpose within FPU
    'Declare MA [NxM], MB [NxM]  
    WriteCmd3Bytes(_SELECTMA, 1, m, n)        
    WriteCmd3Bytes(_SELECTMB, 1 + size, n, m) 
    WriteCmdCntFloats(_WRBLK, size, b_)       'Load HUB/{B} into FPU/MB
    WriteCmdByte(_MOP, _MX_TRANSPOSE)         'MA=MBT 

    ReadRegs(2, size - 1, a_ + 4)          'Reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV
  else
    'Do it in HUB
    repeat i from 0 to (n - 1)
      repeat j from 0 to (m - 1)
        'Get B(I,J)
        fV := long[b_][(i * m) + j]
        'Put A(J,I)
        long[a_][(j * n) + i] := fV
'-------------------------------------------------------------------------


PUB Matrix_Max(a_, r, c) : maxV | size                                 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_Max │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Finds the maximum element of {A} [NxM] matrix
'' Parameters: Pointer to matrix {A} in HUB,
''             N=r=Rows of {A}, M=c=Cols of {A}                     
''    Results: Max. of elements of {A} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------  
  size := r * c
  if (size < _BIG)                         'Check total size of MB, MA
    'Do within FPU
    'Declare MA
    WriteCmd3Bytes(_SELECTMA, 1, r, c) 
    WriteCmdCntFloats(_WRBLK, size, a_)    'Load HUB/{A} into FPU/MA

    WriteCmdByte(_MOP, _MX_MAX)            'Reg[0]=Max. of MA's elements
    Wait
    WriteCmd(_FREAD0)
    maxV := ReadReg   
   
  else
    abort

  return maxV     
'-------------------------------------------------------------------------


PUB Matrix_Min(a_, r, c) : minV | size                                 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_Min │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Finds the minimum element of {A} [NxM] matrix
'' Parameters: Pointer to matrix {A} in HUB,
''             N=r=Rows of {A}, M=c=Cols of {A}                     
''    Results: Min. of elements of {A} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: None        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------  
  size := r * c
  if (size < _BIG)                         'Check total size of MB, MA
    'Do within FPU
    'Declare MA
    WriteCmd3Bytes(_SELECTMA, 1, r, c) 
    WriteCmdCntFloats(_WRBLK, size, a_)    'Load HUB/{A} into FPU/MA

    WriteCmdByte(_MOP, _MX_MIN)            'Reg[0]=Max. of MA's elements
    Wait
    WriteCmd(_FREAD0)
    minV := ReadReg   
   
  else
    abort

  return minV     
'-------------------------------------------------------------------------


PUB Matrix_Add(a_, b_, c_, r, c) | size, s1, fV, fV1, i                                  
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Matrix_Add │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Adds {B} and {C} matrices and stores the result in {A}                                               
'' Parameters: Pointer to matrices {A}, {B} and {C} in HUB,
''             Row and Col of matrices                      
''    Results: {A} = {B} + {C} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg:127, 126        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
  size := r * c

  if (size => _BIG)
    abort

  s1 := size - 1
  if (((2 * size) < _BIG) AND (r > 1) AND (c > 1))
    'Decleare matrices in FPU
    WriteCmd3Bytes(_SELECTMA, 1, r, c)
    WriteCmdCntFloats(_WRBLK, size, b_)    'Load HUB/{B} into FPU/MA   
    WriteCmd3Bytes(_SELECTMB, 1 + size, r, c)  
    WriteCmdCntFloats(_WRBLK, size, c_)    'Load HUB/{C} into FPU/MB  
    WriteCmdByte(_MOP, _EWISE_ADD)         'MA=MA+MB 
    ReadRegs(2, size - 1, a_+ 4)           'Reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV   
  else
    'Do it in HUB 
    repeat i from 0 to s1
      fV := long[b_][i]
      fV1 := long[c_][i]
      WriteCmdByte(_SELECTA, 127)
      WriteCmdFloat(_FWRITEA, fV1)
      WriteCmdByte(_SELECTA, 126)
      WriteCmdFloat(_FWRITEA, fV)
      WriteCmdByte(_FADD, 127)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      long[a_][i] := fV   
'-------------------------------------------------------------------------


PUB Matrix_Subtract(a_, b_, c_, r, c) | size, s1, i, fV, fV1                                  
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Matrix_Subtract │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts {C} from {B} and writes the result into {A}                                                
'' Parameters: Pointer to matrices {A}, {B} and {C} in HUB,
''             Row and Col of matrices                      
''    Results: {A} = {B} - {C} 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg: 127, 126        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
  size := r * c

  if (size => _BIG)
    abort

  s1 := size - 1
  if (((2 * size) < _BIG) AND (r > 1) AND (c > 1))
    'Decleare matrices in FPU
    WriteCmd3Bytes(_SELECTMA, 1, r, c)
    WriteCmdCntFloats(_WRBLK, size, b_)    'Load HUB/{B} into FPU/MA   
    WriteCmd3Bytes(_SELECTMB, 1 + size, r, c)  
    WriteCmdCntFloats(_WRBLK, size, c_)    'Load HUB/{C} into FPU/MB  
    WriteCmdByte(_MOP, _EWISE_SUB)         'MA=MA-MB 
    ReadRegs(2, size - 1, a_+ 4)           'Reload FPU/MA into HUB/{A}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    long [a_][0] := fV   
  else
    'Do it in HUB
    repeat i from 0 to s1
      fV := long[b_][i]
      fV1 := long[c_][i]
      WriteCmdByte(_SELECTA, 127)
      WriteCmdFloat(_FWRITEA, fV1)
      WriteCmdByte(_SELECTA, 126)
      WriteCmdFloat(_FWRITEA, fV)
      WriteCmdByte(_FSUB, 127)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      long[a_][i] := fV   
'-------------------------------------------------------------------------


PUB Matrix_Multiply(a_,b_,c_,rB,cBrC,cC)|sA,sB,sC,fV,fV1,i,j,k,i1,a1,a2,a3                                  
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Matrix_Multiply │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies {B} and {C} matrices                                              
'' Parameters: Row and Col of matrices                      
''    Results: {MA} = {MB} * {MC} matrix product 
''+Reads/Uses: /_BIG, FPU CONs,
''    +Writes: FPU Reg:127, 126, 125        
''      Calls: FPU Read/Write procedures
''       Note: The columns of {B} should be equal with the rows of {C},
''             that's why they are specified with a single number cBrC
'-------------------------------------------------------------------------
  'Calculate size of matrices
  sA := rB * cC
  sB := rB * cBrC
  sC := cBrC * cC
  a3 := cBrC - 1
       
  if ((sA + sB + sC) < _BIG)             'Check total  size
    'Then do it within FPU
    'Check for dot product 
     if ((rB == 1) AND (cC == 1))
       WriteCmdByte(_CLR, 127)
       repeat i from 0 to a3
         fV := long[b_][i]
         fV1 := long[c_][i]
         WriteCmdByte(_SELECTA, 126)
         WriteCmdFloat(_FWRITEA, fV)
         WriteCmdByte(_SELECTA, 125)
         WriteCmdFloat(_FWRITEA, fV1)
         WriteCmdByte(_FMUL, 126)
         WriteCmdByte(_SELECTA, 127)
         WriteCmdByte(_FADD, 125)
       Wait  
       WriteCmd(_FREADA)
       fV := ReadReg
       long[a_][0] := fV       
     else
       'Decleare matrices in FPU
       WriteCmd3Bytes(_SELECTMA, 1, rB, cC)  
       WriteCmd3Bytes(_SELECTMB, 1 + sA, rB, cBrC)  
       WriteCmdCntFloats(_WRBLK, sB, b_)    'Load HUB/{B} into FPU/MB 
       WriteCmd3Bytes(_SELECTMC, 1 + sA + sB, cBrC, cC) 
       WriteCmdCntFloats(_WRBLK, sC, c_)    'Load HUB/{C} into FPU/MC  
       WriteCmdByte(_MOP, _MX_MULTIPLY)     'MA=MB*MC 

       ReadRegs(2, sA - 1, a_ + 4)          'Reload FPU/MA into HUB/{A}
       WriteCmdByte(_SELECTA, 1)
       WriteCmd(_FREADA)
       fV := ReadReg
       long [a_][0] := fV   
  else
    'Do it within HUB
    if ((sA + sB + sC) < (3 * _BIG))
       a1 := rB - 1
       a2 := cC - 1
       repeat i from 0 to a2
         mP[i] := i * cC
       repeat i from 0 to a3
         mV[i] := i * cBrC
       
      'Multiply HUB/{B} with HUB/{C}
      repeat i from 0 to a1
        i1 := mP[i]
        repeat j from 0 to a2
          WriteCmdByte(_CLR, 127)
          repeat k from 0 to a3
            'Use temp matrix U not to overwrite A in case of e.g. A=A*B
            'U(I,J)=U(I,J)+B(I,K)*C(K,J)        
            fV := long[b_][mV[i] + k]
            WriteCmdRnFloat(_FWRITE, 126, fV)
            fV := long[c_][mP[k] + j]
            WriteCmdRnFloat(_FWRITE, 125, fV)
            WriteCmdByte(_SELECTA, 126)    
            WriteCmdByte(_FMUL, 125)
            WriteCmdByte(_SELECTA, 127)
            WriteCmdByte(_FADD, 126)
          Wait    
          WriteCmd(_FREADA)
          fV := ReadReg
          mU[i1 + j] := fV

      'Now copy U within HUB to A
      repeat i from 0 to (sa - 1)
       long[a_][i] := mU[i]
    
    else   
      abort
'-------------------------------------------------------------------------


PUB Matrix_ScalarMultiply(a_, b_, r, c, floatV) | size, i, fV                                
'-------------------------------------------------------------------------
'------------------------┌───────────────────────┐------------------------
'------------------------│ Matrix_ScalarMultiply │------------------------
'------------------------└───────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies {B} with a scalar (float) value                                               
'' Parameters: Scalar, Row and Col of matrix  {A}, {B}                    
''    Results: {A} = Scalar * {B} 
''+Reads/Uses: /_BIG, FPU CONs
''    +Writes: FPU Reg:0        
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
  'Load float value into Reg[0]
  WriteCmdFloat(_FWRITE0, floatV)  
  size := r * c
  
  if (size) < _BIG                         'Check size of {B} 
    WriteCmd3Bytes(_SELECTMA, 1, r, c)
    WriteCmdCntFloats(_WRBLK, size, b_)    'Load HUB/{B} into FPU/MA
        
    Wait
    repeat i from 1 to size
      WriteCmdByte(_SELECTA, i)
      WriteCmd(_FMUL0)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      long [a_][i - 1] := fV
          
  else
    abort  
'-------------------------------------------------------------------------


PUB Matrix_InvertSmall(a_, b_, n) | size, fV                              
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Matrix_QuickInvert │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Inverts {B} [3 by 3], [2 by 2] or [1 by 1] matrix                                               
'' Parameters: Pointers to HUB/{A}, HUB/{B}, n                       
''    Results: {A}={1/B} 
''+Reads/Uses:  /_SMALL, FPU CONs  
''    +Writes: FPU Reg:127        
''      Calls: FPU Read/Write procedures
''       Note: Quick inversion within FPU. It just hangs up and lets you
''             down when {B} is singular (i.e. not invertible).
'-------------------------------------------------------------------------
  if (n > 1)
    size := n * n
    if size<_SMALL
      'Do inversion with one shot
      WriteCmd3Bytes(_SELECTMA, 1, n, n)        'Declare MA
      WriteCmd3Bytes(_SELECTMB, 1 + size, n, n) 'Declare MB 
      WriteCmdCntFloats(_WRBLK, size, b_)       'Load HUB/{B} into FPU/MB 
      WriteCmdByte(_MOP, _MX_INVERSE)           'MA=1/MB               

      ReadRegs(2, size - 1, a_ + 4)           'Reload FPU/MA into HUB/{A} 
      WriteCmdByte(_SELECTA, 1)
      WriteCmd(_FREADA)
      fV := ReadReg
      long [a_][0] := fV
    else
      abort  
  else
    fV := long[b_][0]
    WriteCmdByte(_SELECTA, 127)
    WriteCmdFloat(_FWRITEA, fV)
    WriteCmd(_FINV)
    Wait
    WriteCmd(_FREADA)
    fV := ReadReg
    long[a_][0] := fV                          
'-------------------------------------------------------------------------


PUB Matrix_Invert(a_, b_, n) | size, s1, st, fV, z, i, j, k, t, n1, i1, i2                              
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Matrix_Invert │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Inverts a square matrix by the method of Gauss-Jordan 
''             eliminations using a pivot technique.                                                
'' Parameters: Pointers to HUB/{A}, HUB/{B}, n                       
''    Results: {A}={1/B} 
''+Reads/Uses: /FPU CONs, mV, mP, mU
''    +Writes: FPU Reg: 127, 126, 125, 0        
''      Calls: FPU Read/Write procedures
''       Note: Original {A} matrix is overwritten in HUB.
''             The code here uses the memory very economically and because
''             of the pivoting it has excellent numerical stability. As
''             compared with naive Gaussian elimination pivoting avoids
''             division by zero and largely reduces (but not completely
''             eliminates) round off error.
'-------------------------------------------------------------------------
  if (n > 1)
  
    if (n > 11)
      abort
      
    size := n * n
    s1 := size - 1
    n1 := n - 1
    repeat  i from 0 to n1
      mV[i] := i * n
    
    'Load an identity matrix into the permutation matrix
    WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare FPU/MA 
    WriteCmdByte(_MOP, _MX_IDENTITY)    'Create nxn Identity matrix in it
    ReadRegs(2, s1, @mP + 4)            'Reload FPU/MA into HUB/{P}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    fV := ReadReg
    mP[0] := fV

    WriteCmdByte(_SELECTX, 1)              'Prepare Reg[X] for MA
    WriteCmdCntFloats(_WRBLK, size, b_)    'Load HUB/{B} into FPU/MA
    
    'Main loop
    repeat z from 0 to n1

      'Search for pivot element in z columnn inc. & below diag.
      WriteCmdByte(_SELECTA, 127)
      WriteCmd(_CLRA)
      repeat i from z to n1
        WriteCmd2Bytes(_LOADMA, i, z)
        WriteCmdByte(_SELECTA, 0)
        WriteCmd(_FABS)
        WriteCmdByte(_SELECTA, 127)
        WriteCmd(_FCMP0)
        WriteCmd(_READSTAT)
        st := ReadByte
        st := st & %0000_0010          'Mask Sign Bit
        if (st > 0)
          WriteCmd(_FSET0) 
          t := i

      'Check for singular matrix
      fV := 1E-24
      WriteCmdFloat(_FWRITE0, fV)
      WriteCmd(_FCMP0)
      WriteCmd(_READSTAT)
      st := ReadByte
      st := st & %0000_0010          'Mask Sign Bit
      if (st > 0)
        abort
      
      'Swap lines z, t    
      if (NOT (t == z))
        i1 := mV[z]
        i2 := mV[t] 
        repeat i from 0 to n1
          'Swap lines in MA
          WriteCmdByte(_SELECTA, 127)
          WriteCmd2Bytes(_LOADMA, z, i)
          WriteCmd(_FSET0)
          WriteCmd2Bytes(_LOADMA, t, i)
          WriteCmd2Bytes(_SAVEMA, z, i)
          WriteCmdByte(_SELECTA, 0)
          WriteCmdByte(_FSET, 127)
          WriteCmd2Bytes(_SAVEMA, t, i)
          'Swap lines in HUB/{P}
          j := i1 + i
          k := i2 + i
          fV := mP[j]
          mP[j] := mP[k]
          mP[k] := fV

      'Do Gauss-Jordan elimination
      'Calculate 1/A(Z,Z)    
      WriteCmd2Bytes(_LOADMA, z, z)
      WriteCmdByte(_SELECTA, 0) 
      WriteCmd(_FINV)
      WriteCmdByte(_COPY0, 127)
      i1 := mV[z] 
      repeat i from 0 to n1
        i2 := mV[i]
        repeat j from 0 to n1
          if (i == z)
            if (i == j)
              'U(Z,Z)=1/A(Z,Z)
              WriteCmdByte(_SELECTA, 127)
              Wait
              WriteCmd(_FREADA)
              fV := ReadReg
              mU[i1 + z] := fV
            else
              'U(I,J)=-A(I,J)/A(Z,Z)
              WriteCmd2Bytes(_LOADMA, i, j)
              WriteCmdByte(_SELECTA, 0)
              WriteCmdByte(_FMUL, 127)
              WriteCmd(_FNEG)
              Wait
              WriteCmd(_FREADA)
              fV := ReadReg
              mU[i2 + j] := fV
          else
            if (j == z)
              'U(I,Z)=A(I,Z)/A(Z,Z)
              WriteCmd2Bytes(_LOADMA, i, z)
              WriteCmdByte(_SELECTA, 0)
              WriteCmdByte(_FMUL, 127)
              Wait
              WriteCmd(_FREADA)
              fV := ReadReg
              mU[i2 + z] := fV
            else
              'U(I,J)=A(I,J)-A(Z,J)*A(I,Z)/A(Z,Z)
              WriteCmd2Bytes(_LOADMA, i, j)
              WriteCmdByte(_COPY0, 126)
              WriteCmd2Bytes(_LOADMA, z, j)
              WriteCmdByte(_COPY0, 125)
              WriteCmd2Bytes(_LOADMA, i, z)
              WriteCmdByte(_SELECTA, 0) 
              WriteCmdByte(_FMUL, 125)
              WriteCmdByte(_FMUL, 127)
              WriteCmd(_FNEG)
              WriteCmdByte(_FADD, 126)
              Wait
              WriteCmd(_FREADA)
              fV := ReadReg
              mU[i2 + j] := fV

      WriteCmdByte(_SELECTX, 1)            'Prepare Reg[X] for MA
      WriteCmdCntFloats(_WRBLK, size, @mU) 'Reload HUB/{U} to FPU/MA  

    'Main loop finished
    
    'Multiply FPU/MA with {P} to obtain final result
    repeat i from 0 to n1
      i1 := mV[i]
      repeat j from 0 to n1
        WriteCmdByte(_CLR, 127)
        repeat k from 0 to n1
          'U(I,J)=U(I,J)+A(I,K)*P(K,J)            
          fV := mP[mV[k] + j]
          WriteCmdRnFloat(_FWRITE, 126, fV)
          WriteCmd2Bytes(_LOADMA, i, k)
          WriteCmdByte(_SELECTA, 0)    
          WriteCmdByte(_FMUL, 126)
          WriteCmdByte(_SELECTA, 127)
          WriteCmd(_FADD0)
        Wait    
        WriteCmd(_FREADA)
        fV := ReadReg
        mU[i1 + j] := fV

    'Now copy {U} within HUB to {A}
    repeat i from 0 to s1
      long[a_][i] := mU[i]
          
  else
    'Take care of a [1-by-1] matrix
    fV := long[b_][0]
    WriteCmdByte(_SELECTA, 127)
    WriteCmdFloat(_FWRITEA, fV)
    WriteCmd(_FINV)
    Wait
    WriteCmd(_FREADA)
    fV := ReadReg
    long[a_][0] := fV                          
'-------------------------------------------------------------------------


PUB Matrix_Eigen(a_,u_,n)|sz,s1,n1,n2,i,i1,j,k1,k2,st,m1,m2,f1                                                                  
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ Matrix_Eigen │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the eigenvalues and the eigenvectors of a n-by-n      
''             symmetric matrix by Jacobi's method with pivoting. The
''             result is called eigen-decomposition. The result of the
''             process expresses the original matrix with three simple
''             matrices: a diagonal one {L} of the eigenvalues and an
''             orthogonal one {U} of the eigenvectors and its transpose
''             {UT}
''
''                            {A} = {U} * {L} * {UT} 
''
''             These three matrices have usefull algebraic properties.                            
'' Parameters: Pointers to HUB/{A}, HUB/{U}, n                    
''    Results: Eigenvalues in the diagonal of {L} in place of HUB/{A}
''             HUB/{U} : n-by-n array of eigenvectors, column wise
''                       stored, this matrix is orthogonal    
''+Reads/Uses: /FPU CONs, mV, mU
''    +Writes: FPU Reg:127, 126, 125, 124, 123, 122, 0        
''      Calls: FPU Read/Write procedures
''       Note: The Jacobi method consists of a sequence of transformations
''             (Jacobi rotations) designed to  zap one pair of the
''             off-diagonal matrix elements. Successive transformations
''             undo previously set zeros, but the off-diagonal elements
''             nevertheless get smaller and smaller, until the matrix is
''             diagonal to preset precision. Accumulating the product of
''             transformations as you go gives the matrix of eigenvectors,
''             while the elements of the final diagonal matrix are the
''             eigenvalues. I used here full pivoting (although it takes a
''             lot of time to search for the pivot element) to ensure a
''             numerically robust procedure since we are using here only
''             32 bit IEEE 754 floats. 
''             Original {A} matrix is overwritten in HUB with the diagonal
''             matrix of eigenvalues. This "matrix" form of the
''             eigevalues allows the user to work with the eigenvalues  in
''             matrix equations, e.g. in the restoration of {A},
''             immediately and conveniently. 
''             The {U} array of eigenvectors is an orthogonal matrix,
''             which means a lot of nice properties but especially that
''
''                                 {U} * {UT} = {I}
''
''             With other words, it's inverse is it's transpose. You can  
''             make algebra with {A} expressed in the form as
'' 
''                              {A} = {U} * {L} * {UT}
''
''             For example the inverse of {A} can be obtained quickly as
''
''                             {1/A} = {U} * {1/L} * {UT}
''
''             where {1/L} is just the reciprocals of the diagonal {L}.
''             Finally, you should not forget that {A} must be square and
''             symmetric to apply eigen-decomposition.
'-------------------------------------------------------------------------
  if (n > 1)
    if (n > 11)
      abort

    sz := n * n
    s1 := sz - 1
    n1 := n - 1
    n2 := n - 2
    repeat  i from 0 to n1
      mV[i] := i * n
    
    'Load an identity matrix into the HUB/{U} matrix of eigenvectors
    WriteCmd3Bytes(_SELECTMA, 1, n, n)  'Decleare FPU/MA 
    WriteCmdByte(_MOP, _MX_IDENTITY)    'Create nxn Identity matrix in it
    ReadRegs(2, s1, @mU + 4)            'Reload FPU/MA into HUB/{U}
    WriteCmdByte(_SELECTA, 1)
    WriteCmd(_FREADA)
    f1 := ReadReg
    mU[0] := f1

    'Read in HUB/{A} into FPU/MA
    WriteCmdByte(_SELECTX, 1)           'Prepare Reg[X] for MA
    WriteCmdCntFloats(_WRBLK, sz, a_)   'Load HUB/{A} into FPU/MA

    'Main loop for Jacobi rotations
    repeat 200
    
      'Search for pivot element in the lower triangular region
      WriteCmdByte(_SELECTA, 127)
      WriteCmd(_CLRA)
      repeat i from 0 to n2
        i1 := i + 1
        repeat j from i1 to n1
          WriteCmd2Bytes(_LOADMA, i, j)
          WriteCmdByte(_SELECTA, 0)
          WriteCmd(_FABS)
          WriteCmdByte(_SELECTA, 127)
          WriteCmd(_FCMP0)
          WriteCmd(_READSTAT)
          st := ReadByte
          st := st & %0000_0010          'Mask Sign Bit
          if (st > 0)
            WriteCmd(_FSET0) 
            m1 := i
            m2 := j

      'Check for job done, i.e. off-diagonal elements are small
      f1 := 0.0001                   '1E-4 
      WriteCmdFloat(_FWRITE0, f1)
      WriteCmd(_FCMP0)
      WriteCmd(_READSTAT)
      st := ReadByte
      st := st & %0000_0010          'Mask Sign Bit
      if (st > 0)
        quit                         'Quit main loop
        
      'Large off-diagonal element is found. We have to rotate  
      'f1 := A(M1,M1) 
      WriteCmd2Bytes(_LOADMA, m1, m1)
      WriteCmdByte(_SELECTA, 126)            'f1
      WriteCmd(_FSET0)

      'f2 := A(M2,M2)
      WriteCmd2Bytes(_LOADMA, m2, m2)
      WriteCmdByte(_SELECTA, 125)            'f2
      WriteCmd(_FSET0)

      'f3 := A(M1,M2)
      WriteCmd2Bytes(_LOADMA, m1, m2)
      WriteCmdByte(_SELECTA, 124)            'f3
      WriteCmd(_FSET0)
      
      'p := 2 * f3 /(f2 - f1)
      'p := ATN(p) / 2
      's := SIN(p)
      'c := COS(p)
      WriteCmdByte(_SELECTA, 127)
      WriteCmdByte(_FSET, 125)
      WriteCmdByte(_FSUB, 126)
      WriteCmd(_FINV)
      WriteCmdByte(_FMUL, 124)
      WriteCmdByte(_FMULI, 2)
      WriteCmd(_ATAN)
      WriteCmdByte(_FDIVI, 2)
      
      WriteCmdByte(_COPYA, 123)              's
      WriteCmdByte(_COPYA, 122)              'c

      WriteCmdByte(_SELECTA, 123)
      WriteCmd(_SIN)

      WriteCmdByte(_SELECTA, 122)
      WriteCmd(_COS)
      
      'We have the sine and cosine of the rotation angle.
      'Now we can modify the matrices
      'A = RT * A * R
      'U = U * R
      repeat i from 0 to n1
        if ((NOT (i == m1)) AND (NOT (i == m2)))
          'f1 := A(I,M1)
          WriteCmd2Bytes(_LOADMA, i, m1)
          WriteCmdByte(_SELECTA, 126)            'f1
          WriteCmd(_FSET0)

          'f2 := A(I,M2)
          WriteCmd2Bytes(_LOADMA, i, m2)
          WriteCmdByte(_SELECTA, 125)            'f2
          WriteCmd(_FSET0)
          
          'f3 := (f1 * c) - (f2 * s)
          WriteCmdByte(_SELECTA, 127)
          WriteCmdByte(_FSET, 125)
          WriteCmdByte(_FMUL, 123)
          WriteCmdByte(_SELECTA, 0)
          WriteCmdByte(_FSET, 126)
          WriteCmdByte(_FMUL, 122)
          WriteCmdByte(_FSUB, 127)

          'Store result 
          'A(I,M1) := f3
          'A(M1,I) := f3
          WriteCmd2Bytes(_SAVEMA, i, m1)
          WriteCmd2Bytes(_SAVEMA, m1, i)
          
          'f3 := (f1 * s) + (f2 * c)
          WriteCmdByte(_SELECTA, 127)
          WriteCmdByte(_FSET, 126)
          WriteCmdByte(_FMUL, 123)
          WriteCmdByte(_SELECTA, 0)
          WriteCmdByte(_FSET, 125)
          WriteCmdByte(_FMUL, 122)
          WriteCmdByte(_FADD, 127)

          'Store result
          'A(I,M2) := f3
          'A(M2,I) := f3
          WriteCmd2Bytes(_SAVEMA, i, m2)
          WriteCmd2Bytes(_SAVEMA, m2, i)

        'Now transform M1, M2 columns of the eigenvector matrix U
        'f1 := U(I,M1)
        k1 := mV[i] + m1
        f1 := mU[k1]
        WriteCmdByte(_SELECTA, 126)         'f1
        WriteCmdFloat(_FWRITEA, f1)

        'f2 := U(I,M2)
        k2 := mV[i] + m2
        f1 := mU[k2]
        WriteCmdByte(_SELECTA, 125)         'f2
        WriteCmdFloat(_FWRITEA, f1)

        'f3 := (f1 * c) - (f2 * s)
        WriteCmdByte(_SELECTA, 127)
        WriteCmdByte(_FSET, 125)
        WriteCmdByte(_FMUL, 123)
        WriteCmdByte(_SELECTA, 0)
        WriteCmdByte(_FSET, 126)
        WriteCmdByte(_FMUL, 122)
        WriteCmdByte(_FSUB, 127)

        'U(I,M1) := f3
        Wait
        WriteCmd(_FREADA)
        f1 := ReadReg
        mU[k1] := f1

        'f3 := (f1 * s) + (f2 * c)
        WriteCmdByte(_SELECTA, 127)
        WriteCmdByte(_FSET, 126)
        WriteCmdByte(_FMUL, 123)
        WriteCmdByte(_SELECTA, 0)
        WriteCmdByte(_FSET, 125)
        WriteCmdByte(_FMUL, 122)
        WriteCmdByte(_FADD, 127)
                    
        'U(I,M2) := f3
        Wait
        WriteCmd(_FREADA)
        f1 := ReadReg
        mU[k2] := f1
          
      'Now comes the transformation of the diagonals of A
      'f1 := A(M1,M1)
      WriteCmd2Bytes(_LOADMA, m1, m1)
      WriteCmdByte(_SELECTA, 126)            'f1
      WriteCmd(_FSET0)
      
      'f2 := A(M2,M2)
      WriteCmd2Bytes(_LOADMA, m2, m2)
      WriteCmdByte(_SELECTA, 125)            'f2
      WriteCmd(_FSET0)
      
      'f3 := A(M1,M2)
      WriteCmd2Bytes(_LOADMA, m1, m2)
      WriteCmdByte(_SELECTA, 124)            'f3  (s2)
      WriteCmd(_FSET0)

      's2 := 2*c*s*f3
      WriteCmdByte(_FMUL, 123)               
      WriteCmdByte(_FMUL, 122)
      WriteCmdByte(_FMULI, 2)
      
      's := s*s
      WriteCmdByte(_SELECTA, 123)
      WriteCmdByte(_FMUL, 123)
      
      'c := c*c
      WriteCmdByte(_SELECTA, 122)
      WriteCmdByte(_FMUL, 122)
      
      'f3 := f1*c - s2 + f2*s
      WriteCmdByte(_SELECTA, 127)
      WriteCmdByte(_FSET, 126)
      WriteCmdByte(_FMUL, 122)
      WriteCmdByte(_FSUB, 124)
      WriteCmdByte(_SELECTA, 0)
      WriteCmdByte(_FSET, 125)
      WriteCmdByte(_FMUL, 123)
      WriteCmdByte(_FADD, 127)
      
      'A(M1,M1) := f3
      WriteCmd2Bytes(_SAVEMA, m1, m1)
      
      'f3 := f1*s + s2 + f2*c
      WriteCmdByte(_SELECTA, 127)
      WriteCmdByte(_FSET, 126)
      WriteCmdByte(_FMUL, 123)
      WriteCmdByte(_FADD, 124)
      WriteCmdByte(_SELECTA, 0)
      WriteCmdByte(_FSET, 125)
      WriteCmdByte(_FMUL, 122)
      WriteCmdByte(_FADD, 127)
      
      'A(M2,M2) := f3
      WriteCmd2Bytes(_SAVEMA, m2, m2)
      
      'And clear the pivot, at last...
      WriteCmd(_CLR0)
      'A(M1,M2) := 0
      WriteCmd2Bytes(_SAVEMA, m1, m2)
      'A(M2,M1) := 0
      WriteCmd2Bytes(_SAVEMA, m2, m1)    
     
    'End of main loop here
    
    ReadRegs(2, s1, a_ + 4)        'Reload diagonalized matrix FPU/MA
    WriteCmdByte(_SELECTA, 1)      'to HUB/{A}
    WriteCmd(_FREADA)
    f1 := ReadReg
    long [a_][0] := f1

    'Copy HUB/{mU} to HUB/{U}
    repeat i from 0 to s1
      long[u_][i] := mU[i]

  else
    'Take care of a [1-by-1] matrix
    long[u_][0] := 1.0
'-------------------------------------------------------------------------


PUB Matrix_SVD(a_, u_, v_, n, m) | sz, s1, n1, m1, i, j, k, l, fV                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Matrix_SVD │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: It decomposes any(!) real rectangular {A} [n-by-m] matrix
''             into three simple and easy to invert matrices, two square
''             and orthogonal ones {U} [n-by-n], {VT} [m-by-m] and one
''             (semi) diagonal matrix {SV} which has the same size as {A}.
''             To decompose {A} means to represent {A} faithfully (100%)
''             with the product easy to manipulate matrices: 
'' 
''                               {A}={U}*{SV}*{VT}
''
''             It's worth mentioning here that {A} can be as simple as a
''             square matrix. The algorithm works perfectly in that case,
''             too.
'' Parameters: Pointers to HUB/{A}  [n-by-m] matrix (n<12, m<12)
''                         HUB/{U}  [n-by-n]
''                         HUB/{VT} [m-by-m]
''    Results: {SV} [n-by-m] diagonal matrix in place of HUB/{A}[n-by-m]
''                  It contains the singular values in the (sub)diagonal
''             {U}  [n-by-n] orthogonal matrix  
''             {VT}  [m-by-m] orthogonal matrix
''+Reads/Uses: /FPU CONs, mU, mP, mV
''    +Writes: FPU Reg: 0      
''      Calls: FPU Read/Write procedures
''             Matrix_Transpose
''             Matrix_Multiply
''             Matrix_Eigen
''       Note: The product of a matrix by its transpose is obviously
''             square and symmetric, but also (and this is less obvious)
''             its eigenvalues are all positive or null and the
''             eigenvectors corresponding to different eigenvalues are
''             pairwise orthogonal. The SVD algorithm here is based upon
''             the eigen-decomposition of such matrices, either {A}*{AT}
''             or {AT}*{A}, selecting the smaller.    
''             {SV} has the same size as {A}. The singular values or
''             'principle gains' of {A} lie on the diagonal of {SV} and
''             are the square root of the eigenvalues of both {A}*{AT}
''             and {AT}*{A}, that is, the eigenvectors in {U} and the
''             eigenvectors in {V} share the same eigenvalues. And that
''             means, too, that we have to calculate them only once. We
''             calculate either {U} or {V} (the smaller one) and the
''             corresponding pair is obtained with simple matrix algebra.  
''             The singular values are all positive or zero.
''             Algebra usually simplifies when using the SVD form of {A}.
''             E.g. you can calculate the (pseudo) inverses for any truly
''             rectangular matrix (where n is not equal with m), as well. 
''             The left pseudo inverse, for example, of an arbitrary {A}
''             is
''
''                             {1/AL}={V}*{SVRT}*{UT}
''
''             as you can confirm easily that
''
''                           {1/AL}*{A}={I}   [m-by-m].
'' 
''             where {SVRT} means the reciprocate and transpose of {SV}.
''             Pseudo inverses are also called Moore-Penrose inverses.
''              {U} and {V} are orthogonal matrices that can be obtained
''             for any(!) {A} matrix. Because of this it is worth to
''             summarize some useful properties of orthogonal {U}
''             matrices:
''
''                                  {U}*{UT}={I}
''
''                 {U}{x} vector has the same length as {x} vector
''
''             product of any number of orthogonal matrices is orthogonal
''
''                the {U}{S}{UT} transform preserves symmetry of {S}
''
''                     if {U} is symmetric then {U}*{U}={I}
''
''             The fact that orthogonal matrices don't change the length
''             of vectors makes them very desirable in numerical
''             applications since they will not increase rounding errors
''             significantly. They are therefore favored for stable
''             algorithm.
''              Finally, you should not forget that {A} has not to be
''             either square or symmetric to get it's SVD form to make
''             easy calculations with {U}, {SV} and {V} in your algorithm.  
'-------------------------------------------------------------------------
  if ((n == 1) AND (m == 1))
    long[u_][0] := 1.0
    long[v_][0] := 1.0
    
  if ((n > 11) OR (m > 11))
    abort
    
  sz := n * m
  s1 := sz - 1
  n1 := n - 1
  m1 := m - 1
  
  'Find smaller side
  if (n =< m)
    'Calculate {A}*{AT} which is [n-by-n]
    Matrix_Transpose(@mP, a_, n, m)
    Matrix_Multiply(@mP, a_, @mP, n, m, n)

    'Do the number crunching
    Matrix_Eigen(@mP, u_, n)

    'Construct {SV} [n-by-m] from [n-by-n] diagonal of eigenvalues
    'At the same sweep calculate essence INV({SV}) in {mU}, as well.
    'Prepare INV({SV}) [m-by-n], fill zeros
    repeat i from 0 to m1
      repeat j from 0 to n1
        k := (i * n) + j
        mU[k] := 0.0
    'Take square root (and reciprocal for INV({SV}) of the diagonals mP
    WriteCmdByte(_SELECTA, 0)
    repeat i from 0 to n1
      k := (i * n) + i
      fV := mP[k]
      WriteCmdFloat(_FWRITEA, fV)
      WriteCmd(_SQRT)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      mP[k] := fV
      WriteCmd(_FINV)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      mU[k] := fV

    'mU is ready made mP is not. Make it.
    'Augment mP with zeroes
    repeat i from (n * n) to ((n * m) - 1)
      mP[i] := 0.0
    'Shift the singular values to the new diagonal
    repeat i from 1 to n1
      'Original index of diagonal
      j := i * (n + 1)
      'New index of diagonal
      k := j + i * (m - n)
      mP[k] := mP[j]
      'Clear up
      mP[j] := 0.0
    
    'Up till now mP contains the singular values [n-by-m] and long[u_]
    'contains the {U} [n-by-n]
    
    'Now calculate {VT}=INV({SV})*{UT}*{A} directly
    'Calculate {UT}. Let us use mV since mU contains INV({SV})
    Matrix_Transpose(@mV, u_, n, n)
    'Calculate {UT}*{A} 
    Matrix_Multiply(@mV, @mV, a_, n, n, m)
    'Finally {VT}=INV({SV})*{UT}*{A}
    Matrix_Multiply(v_, @mU, @mV, m, n, m)

    'Copy {SV} into HUB/{A}
    repeat i from 0 to s1
      long[a_][i] := mP[i]
    
  else
    'm is smaller than n
    'Calculate {AT}*{A}  which is [m-by-m]
    Matrix_Transpose(@mP, a_, n, m)
    Matrix_Multiply(@mP, @mP, a_, m, n, m)

    Matrix_Eigen(@mP, v_, m)

    'Construct {SV} [n-by-m] from [m-by-m] diagonal of eigenvalues
    'At the same sweep construct INV({SV}) in {mU}, as well.
    'Prepare INV({SV}) [m-by-n], Fill the zeros  
    repeat i from 0 to m1
      repeat j from 0 to n1
        k := (i * n) + j
        mU[k] := 0.0
    'Take square root (and reciprocal for INV({SV}) of the diagonals mP
    WriteCmdByte(_SELECTA, 0)
    repeat i from 0 to m1
      k := (i * m) + i
      fV := mP[k]
      WriteCmdFloat(_FWRITEA, fV)
      WriteCmd(_SQRT)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      mP[k] := fV
      WriteCmd(_FINV)
      Wait
      WriteCmd(_FREADA)
      fV := ReadReg
      l := (i * n) + i
      mU[l] := fV
   
    'mU is ready made mP is not. Make it.
    'Augment mP with zeroes
    repeat i from (m * m) to ((n * m) - 1)
      mP[i] := 0.0
    
    'Now calculate {U}={A}*{V}*INV({SV}) directly
    'Calculate {A}*{V}, {V} is ready 
    Matrix_Multiply(@mV, a_, v_, n, m, m)
    'Finally {U}={A}*{V}*INV({SV})
    Matrix_Multiply(u_, @mV, @mU, n, m, n)

    'Since we have {V}, calculate {VT}, user assumes that. If we just give
    '{V} to her/him that would be a breach of contract.
    Matrix_Transpose(v_, v_, m, m)

    'Copy {SV} into HUB/{A}
    repeat i from 0 to s1
      long[a_][i] := mP[i]
'-------------------------------------------------------------------------


PUB Vector_CrossProduct(a_, b_, c_) | b1, b2, b3, c1, c2, c3                              
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│ Vector_CrossProduct │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the Cross product of {b}, {c} space vectors                                               
'' Parameters: Pointers to HUB/{a}, HUB/{b} and HUB/{c} [3x1] matrices                      
''    Results: {a}={b}x{c} 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126, 125, 124        
''      Calls: FPU Read/Write procedures
''       Note: This operation is specialized to 3D "space" vectors
''             Vector dot product can be done with Matrix_Multiply as
''             Matrix_Multiply(@dp, @v1, @v2, 1, n, 1) where n is the
''             dimension of the vectors. This means that the dot product
''             is not specialized for 3 dimensional vectors 
'-------------------------------------------------------------------------
  b1 := long[b_][0]
  b2 := long[b_][1]
  b3 := long[b_][2]
  c1 := long[c_][0]
  c2 := long[c_][1]
  c3 := long[c_][2]
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, b3)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, c2)
  WriteCmdByte(_FMUL, 127)
  WriteCmdByte(_SELECTA, 125)
  WriteCmdFloat(_FWRITEA, b2)
  WriteCmdByte(_SELECTA, 124)
  WriteCmdFloat(_FWRITEA, c3)
  WriteCmdByte(_FMUL, 125)
  WriteCmdByte(_FSUB, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][0] := ReadReg
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, b1)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, c3)
  WriteCmdByte(_FMUL, 127)
  WriteCmdByte(_SELECTA, 125)
  WriteCmdFloat(_FWRITEA, b3)
  WriteCmdByte(_SELECTA, 124)
  WriteCmdFloat(_FWRITEA, c1)
  WriteCmdByte(_FMUL, 125)
  WriteCmdByte(_FSUB, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][1] := ReadReg
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, b2)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, c1)
  WriteCmdByte(_FMUL, 127)
  WriteCmdByte(_SELECTA, 125)
  WriteCmdFloat(_FWRITEA, b1)
  WriteCmdByte(_SELECTA, 124)
  WriteCmdFloat(_FWRITEA, c2)
  WriteCmdByte(_FMUL, 125)
  WriteCmdByte(_FSUB, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][2] := ReadReg 
'-------------------------------------------------------------------------


PUB Vector_Norm(a_) : vnorm | a1, a2, a3                              
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Vector_Norm │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates the length of {a} space vector                                               
'' Parameters: Pointers to HUB/{a} [3-by-1] matrix                   
''    Results: Length of {a} 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126        
''      Calls: FPU Read/Write procedures
''       Note: Programmed for 3 dimensional vectors. You can easily code
''             it for the n dimensional case with n as a parameter
'-------------------------------------------------------------------------
  a1 := long[a_][0]
  a2 := long[a_][1]
  a3 := long[a_][2]
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, a1)
  WriteCmdByte(_FMUL, 127)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, a2)
  WriteCmdByte(_FMUL, 126)
  WriteCmdByte(_FADD, 127)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, a3)
  WriteCmdByte(_FMUL, 127)
  WriteCmdByte(_FADD, 126)
  WriteCmd(_SQRT)
  Wait
  WriteCmd(_FREADA)
  vnorm := ReadReg 

  return vnorm
'-------------------------------------------------------------------------


PUB Vector_Unitize(a_, b_) | l, b1, b2, b3                 
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Vector_Unitize │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a unit vector in direction of {b} space vector                                               
'' Parameters: Pointers to HUB/{a}, {b} [3-by-1] matrices                      
''    Results: {a}={b}/Norm({b}) 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126        
''      Calls: WFPU Read/Write procedures
''       Note: Programmed for 3 dimensional vectors. You can easily code
''             it for the n dimensional case with n as a parameter
'-------------------------------------------------------------------------
  l := Vector_Norm(b_)
  b1 := long[b_][0]
  b2 := long[b_][1]
  b3 := long[b_][2]
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, l)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, b1)
  WriteCmdByte(_FDIV, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][0] := ReadReg
  WriteCmdFloat(_FWRITEA, b2)
  WriteCmdByte(_FDIV, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][1] := ReadReg
  WriteCmdFloat(_FWRITEA, b3)
  WriteCmdByte(_FDIV, 126)
  Wait
  WriteCmd(_FREADA)
  long[a_][2] := ReadReg
'-------------------------------------------------------------------------


PUB Rnd_Randomize : rndF | rndL                                   
'-------------------------------------------------------------------------
'-------------------------------┌───────────────┐-------------------------
'-------------------------------│ Rnd_Randomize │-------------------------
'-------------------------------└───────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Creates a truly random float int the interval [0, 1]                           
'' Parameters: None                      
''    Results: Random float value
''+Reads/Uses: /_RANDOMIZE, command, par1, FPU CONs    
''    +Writes: command, par1, FPU Reg:127, 126        
''      Calls: #Rndomize (in COG)
''             FPU Read/Write procedures
''       Note: Based upon the RealRandom object (v1.2) from the IDE lib
''             rndF will be usually different after each power up
'-------------------------------------------------------------------------
  command := _RANDOMIZE
  repeat while command         'Wait for _RANDOMIZE command to be
                               'processed

  rndL := par1                 'Get RealRandom rndL from par1

  WriteCmdByte(_SELECTA, 126)
  WriteCmdLong(_LWRITEA, 429496)
  WriteCmd(_FLOAT)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdLong(_LWRITEA, rndL)
  WriteCmd(_FLOAT)
  WriteCmdByte(_FDIV, 126)
  WriteCmd(_FRAC)
  Wait
  WriteCmd(_FREADA)
  rndF := ReadReg   

  return rndF
'-------------------------------------------------------------------------


PUB Rnd_FloatUD(seed) : rndF                                  
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Rnd_FloatUD │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a pseudo random float value from seed                                                 
'' Parameters: Seed                       
''    Results: Pseudo random float values are uniformmly distributed on 
''             [0, 1] intervall when the last value used as the seed for 
''             the next one.
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
''       Note: rndF=FRAC((PI+seed)^5)
'-------------------------------------------------------------------------
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, seed)
  WriteCmd(_LOADPI)
  WriteCmd(_FADD0)
  WriteCmdByte(_FPOWI, 5)
  WriteCmd(_FRAC)
  Wait
  WriteCmd(_FREADA)
  rndF := ReadReg 

  return rndF
'-------------------------------------------------------------------------


PUB Rnd_LongUD(rndF, minL, maxL) : rndL                                  
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Rnd_LongUD │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a pseudo random long value from a pseudo random
''             float                                                
'' Parameters: Random float value, Min and Max of long values                     
''    Results: Pseudo random long values will be drawn from the [Min, Max] 
''             interval according to rndF
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126, 125, 0       
''      Calls: None
'-------------------------------------------------------------------------
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_LWRITEA, minL)
  WriteCmd(_FLOAT)
  WriteCmdByte(_SELECTA, 125)
  WriteCmdByte(_FSET, 126)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_LWRITEA, maxL)
  WriteCmd(_FLOAT)
  WriteCmdByte(_FSUB, 126)
  WriteCmdByte(_FADDI, 1)
  WriteCmdRnFloat(_FWRITE, 126, rndF)
  WriteCmdByte(_FMUL, 126)
  WriteCmdByte(_FADD, 125)
  WriteCmd(_FLOOR)
  WriteCmd(_FIX)
  Wait
  WriteCmd(_LREADA)
  rndL := ReadReg 

  return rndL
'-------------------------------------------------------------------------


PUB Rnd_FloatND(seed, avr, sd) : rndF | rnd1, rnd2                                 
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Rnd_FloatND │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Calculates a normally distributed pseudo random float value                                                    
'' Parameters: Seed value from [0, 1] float interval,
''             Average avr,
''             Standard Deviation sd
''    Results: Pseudo random floats that are normaly distributed around
''             avr with a standard deviation sdev when this routine is
''             feeded with uniformly distributed (pseudo)random seed
''             values from the [0, 1] range.
''+Reads/Uses: /Some FPU constants from the DAT section
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: rndF=avr+sd*SQRT((-2*LOG(rnd1)))*COS(2*PI*rnd2)
''             This routine is handy to simulate gaussian noise.
'-------------------------------------------------------------------------
  rnd1 := Rnd_FloatUD(seed)
  rnd2 := Rnd_FloatUD(rnd1)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, rnd1)
  WriteCmd(_LOADPI)
  WriteCmd(_FMUL0)
  WriteCmdByte(_FMULI, 2)
  WriteCmd(_COS)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, rnd2)
  WriteCmd(_LOG)
  WriteCmdByte(_FMULI, -2)
  WriteCmd(_SQRT)
  WriteCmdByte(_FMUL, 126)
  WriteCmdFloat(_FWRITE0, sd)
  WriteCmd(_FMUL0)
  WriteCmdFloat(_FWRITE0, avr)
  WriteCmd(_FADD0)
  Wait
  WriteCmd(_FREADA)
  rndF := ReadReg

  return rndF
'-------------------------------------------------------------------------


PUB Float_EQ(fv1, fv2, eps) : okay | status                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ FloatEQ │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of two floats within epsilon                                                    
'' Parameters: Value1, Value2, Epsilon    
''    Results: True if ABS(Value1-Value2)<Epsilon else False
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: With Epsilon=0.0 you can test "true" equality, however that
''             is sometimes misleading in floating point calculations
'-------------------------------------------------------------------------
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, fv1)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, fv2)
  WriteCmdByte(_FSUB, 127)
  WriteCmd(_FABS)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, eps)
  WriteCmd(_FABS) 
  WriteCmdByte(_FCMP, 126) 
  WriteCmd(_READSTAT)
  status := ReadByte
  status := status & %0000_0010           'Sign bit in FPU's status byte 
  if (status > 0)
    okay := false
  else
    okay := true  

  return okay
'-------------------------------------------------------------------------


PUB Float_GT(fv1, fv2, eps) : okay | status                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ FloatGT │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Checks that Value1 is greater or not than Value2 with a
''             margin                                                    
'' Parameters: Value1, Value2, Epsilon    
''    Results: True if (Value1-Value2)>Epsilon else False
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: You can use eps=0.0, of course
'-------------------------------------------------------------------------
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, fv2)
  WriteCmdByte(_SELECTA, 126)
  WriteCmdFloat(_FWRITEA, fv1)
  WriteCmdByte(_FSUB, 127)
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, eps)
  WriteCmd(_FABS) 
  WriteCmdByte(_FCMP, 126) 
  WriteCmd(_READSTAT)
  status := ReadByte
  status := status & %0000_0010            'Sign bit in FPU's status byte
  if (status > 0)
    okay := true
  else
    okay := false  

  return okay
'-------------------------------------------------------------------------


PUB Float_INV(fV) : fVInv                                 
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Float_INV │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Takes reciprocal of a float value                           
'' Parameters: float Value fV
''    Results: 1/fV
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
  WriteCmdByte(_SELECTA, 127)
  WriteCmdFloat(_FWRITEA, fV)
  WriteCmd(_FINV)
  Wait
  WriteCmd(_FREADA)
  fVInv := ReadReg

  return fVInv
'-------------------------------------------------------------------------


PUB Reset : okay                                  
'-------------------------------------------------------------------------
'-----------------------------------┌───────┐-----------------------------
'-----------------------------------│ Reset │-----------------------------
'-----------------------------------└───────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Initiates a Software Reset of the FPU                                                 
'' Parameters: None                      
''    Results: Okay if reset was succesfull 
''+Reads/Uses: /command, _RST, par1
''    +Writes: command, par1        
''      Calls: #Rst (in COG)
'-------------------------------------------------------------------------
  command := _RST
  repeat while command         'Wait for _RST command to be processed

  okay := par1

  return okay
'-------------------------------------------------------------------------                                                                    


PUB Wait                                   
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Wait │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Waits for FPU ready                             
'' Parameters: None                      
''    Results: None 
''+Reads/Uses: /command, _WAIT    
''    +Writes: command        
''      Calls: #WaitForReady (in COG)
'-------------------------------------------------------------------------
  command := _WAIT
  repeat while command         'Wait for _WAIT command to be processed  
'-------------------------------------------------------------------------


PUB ReadSyncChar : syncChar                                   
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadSyncChar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads syncronization character from FPU                             
'' Parameters: None                      
''    Results: Sync Char response of FPU (should be $5C: dec 92) 
''+Reads/Uses: /_SYNC    
''    +Writes: None        
''      Calls: WriteCmd, ReadByte
''       Note: No Wait here berore the read operation
'-------------------------------------------------------------------------
  WriteCmd(_SYNC)  
  syncChar := ReadByte
                    
  return syncChar  
'-------------------------------------------------------------------------


PUB ReadInterVar(index) : intVar                                   
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ ReadInterVar │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads an Internal Variable from FPU                           
'' Parameters: Index of variable        
''    Results: interVar
''+Reads/Uses: /_READVAR, _LREAD0   
''    +Writes: None        
''      Calls: WriteCmdByte, Wait, WriteCmd
'-------------------------------------------------------------------------
  WriteCmdByte(_READVAR, index)
  Wait
  WriteCmd(_LREAD0)
  intVar := ReadReg 
  
  return intVar  
'-------------------------------------------------------------------------


PUB ReadRaFloatAsStr(format) : strPtr
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ ReadRaFloatAsStr │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Reads the float value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/str                           
'' Parameters: format of string in FPU convention        
''    Results: strPtr pointer to string HUB/str
''+Reads/Uses: /_FTOA, _FTOAD   
''    +Writes: None        
''      Calls: WriteCmdByte, Wait, ReadStr
'-------------------------------------------------------------------------
  WriteCmdByte(_FTOA, format)
  waitcnt(_FTOAD + cnt)
  Wait
  strPtr := ReadStr

  return strPtr
'-------------------------------------------------------------------------


PUB ReadRaLongAsStr(format) : strPtr
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ ReadRaLongAsStr │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads the long value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB                           
'' Parameters: Format of string in FPU convention        
''    Results: strPtr pointer to string HUB/str
''+Reads/Uses: /_LTOA, _FTOAD   
''    +Writes: None        
''      Calls: WriteCmdByte, Wait, ReadStr
'-------------------------------------------------------------------------
  WriteCmdByte(_LTOA, format)
  waitcnt(_FTOAD + cnt)
  Wait
  strPtr := ReadStr
  
  return strPtr
'-------------------------------------------------------------------------


PUB WriteCmd(cmd)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ WriteCmd │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte to FPU                           
'' Parameters: Command byte                       
''    Results: None
''+Reads/Uses: /par1, command, _WRTBYTE    
''    +Writes: par1, command        
''      Calls: #WrtByte (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  command := _WRTBYTE
  repeat while command         'Wait for _WRTBYTE command to be processed
'-------------------------------------------------------------------------


PUB WriteCmdByte(cmd, byt)                            
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WriteCmdByte │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus a Data byte to FPU          
'' Parameters: Command byte, Data byte
''    Results: None
''+Reads/Uses: /par1, par2, command, _WRTCMDBYTE  
''    +Writes: par1, par2, command        
''      Calls: #WrtCmdByte (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := byt
  command := _WRTCMDBYTE
  repeat while command         'Wait for _WRTCMDBYTE com. to be processed
'-------------------------------------------------------------------------


PUB WriteCmd2Bytes(cmd, b1, b2)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd2Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 2 Data bytes to FPU          
'' Parameters: Command byte, Data byte1, byte2
''    Results: None
''+Reads/Uses: /par1, par2, command, _WRTCMD2BYTES  
''    +Writes: par1, par2, par3, command        
''      Calls: #WrtCmd2Bytes (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := b1
  par3 := b2
  command := _WRTCMD2BYTES
  repeat while command        'Wait for _WRTCMD2BYTES com. to be processed
'-------------------------------------------------------------------------


PUB WriteCmd3Bytes(cmd, b1, b2, b3)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd3Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 3 Data bytes to FPU          
'' Parameters: Command byte, Data byte1, byte2, byte3
''    Results: None
''+Reads/Uses: /par1, par2, par3, par4, command, _WRTCMD3BYTES  
''    +Writes: par1, par2, par3, par4, command        
''      Calls: #WrtCmd3Bytes (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := b1
  par3 := b2
  par4 := b3
  command := _WRTCMD3BYTES
  repeat while command        'Wait for _WRTCMD3BYTES com. to be processed
'-------------------------------------------------------------------------


PUB WriteCmd4Bytes(cmd, b1, b2, b3, b4)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd4Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 4 Data bytes to FPU          
'' Parameters: Command byte, Data bytes 1,... ,4
''    Results: None
''+Reads/Uses: /par1, par2, par3, par4, par5, command, _WRTCMD4BYTES  
''    +Writes: par1, par2, par3, par4, par5, command        
''      Calls: #WrtCmd4Bytes (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := b1
  par3 := b2
  par4 := b3
  par5 := b4
  command := _WRTCMD4BYTES
  repeat while command        'Wait for _WRTCMD4BYTES com. to be processed
'-------------------------------------------------------------------------


PUB WriteCmdLong(cmd, longVal)                            
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WriteCmdLong │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 32 bit Long value to FPU          
'' Parameters: Command byte, 32 bit Long value
''    Results: None
''+Reads/Uses: /par1, par2, command, _WRTCMDREG  
''    +Writes: par1, par2, command        
''      Calls: #WrtCmdReg (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := longVal
  command := _WRTCMDREG
  repeat while command     'Wait for _WRTCMDREG command to be processed
'-------------------------------------------------------------------------


PUB WriteCmdFloat(cmd, floatVal)                            
'-------------------------------------------------------------------------
'----------------------------┌───────────────┐----------------------------
'----------------------------│ WriteCmdFloat │----------------------------
'----------------------------└───────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus a 32 bit Float value to FPU          
'' Parameters: Command byte, 32 bit Float value
''    Results: None
''+Reads/Uses: /par1, par2, command, _WRTCMDREG  
''    +Writes: par1, par2, command        
''      Calls: #WrtCmdReg (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := floatVal
  command := _WRTCMDREG
  repeat while command     'Wait for _WRTCMDREG command to be processed
'-------------------------------------------------------------------------


PUB WriteCmdRnLong(cmd, regN, longVal)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmdRnLong │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + Long data to FPU                          
'' Parameters: Command byte, RegNo byte, Long (32 bit) data                      
''    Results: None
''+Reads/Uses: /par1, par2, par3, command, _WRTCMDRNREG   
''    +Writes: par1, par2, par3, command        
''      Calls: #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := regN
  par3 := longVal
  command := _WRTCMDRNREG
  repeat while command     'Wait for _WRTCMDRNREG command to be processed  
'-------------------------------------------------------------------------


PUB WriteCmdRnFloat(cmd, regN, floatVal)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ WriteCmdRnFloat │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + Float data to FPU                          
'' Parameters: Command byte, RegNo byte, Float (32 bit) Data                      
''    Results: None
''+Reads/Uses: /par1, par2, par3, command, _WRTCMDRNREG   
''    +Writes: par1, par2, par3, command        
''      Calls: #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := regN
  par3 := floatVal
  command := _WRTCMDRNREG
  repeat while command     'Wait for _WRTCMDRNREG command to be processed  
'-------------------------------------------------------------------------


PUB WriteCmdCntLongs(cmd, cntr, longPtr) 
'-------------------------------------------------------------------------
'--------------------------┌──────────────────┐---------------------------
'--------------------------│ WriteCmdCntLongs │---------------------------
'--------------------------└──────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command + Counter byte + Long Data array into FPU                          
'' Parameters: Command byte, Counter, Pointer to Long (32 bit) Data array                      
''    Results: None
'' Reads/Uses: /par1, par2, par3, command, _WRTCMDCNTREGS     
''    +Writes: par1, par2, par3, command         
''      Calls: #WrtCmdCntRegs (in COG)
''       Note: Cntr byte is (should be) the size of the Long data array
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := cntr
  par3 := longPtr
  command := _WRTCMDCNTREGS
  repeat while command    'Wait for _WRTCMDCNTREGS command to be processed 
'-------------------------------------------------------------------------


PUB WriteCmdCntFloats(cmd, cntr, floatPtr)
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ WriteCmdCntFloats │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command + Counter byte + Float Data array into FPU                          
'' Parameters: Command byte, Counter, Pointer to Float (32 bit) Data array                      
''    Results: None
''+Reads/Uses: /par1, par2, par3, command, _WRTCMDCNTREGS     
''    +Writes: par1, par2, par3, command         
''      Calls: #WrtCmdCntRegs (in COG)
''       Note: Cntr byte is (should be) the size of the Float data array
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := cntr
  par3 := floatPtr
  command := _WRTCMDCNTREGS
  repeat while command    'Wait for _WRTCMDCNTREGS command to be processed 
'-------------------------------------------------------------------------


PUB WriteCmdStr(cmd, strPtr)
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ WriteCmdStr │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + a String into FPU                          
'' Parameters: Command byte, Pointer to HUB/String                      
''    Results: None
''+Reads/Uses: /par1, par2, command, _WRTCMDSTRING     
''    +Writes: par1, par2, command       
''      Calls: #WrtCmdString (in COG)
''       Note: No need for counter byte, zero terminates string
'-------------------------------------------------------------------------
  par1 := cmd
  par2 := strPtr
  command := _WRTCMDSTRING
  repeat while command    'Wait for_WRTCMDSTRING command to be processed 
'-------------------------------------------------------------------------


PUB ReadByte : fpuByte                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadByte │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a byte from FPU                           
'' Parameters: None                      
''    Results: Entry in fpuByte
''+Reads/Uses: /command, _RDBYTE, par1    
''    +Writes: command, par1        
''      Calls: #RByte (in COG)
'-------------------------------------------------------------------------
  command := _RDBYTE
  repeat while command         'Wait for _RDBYTE command to be processed

  fpuByte := par1              'Get fpuByte from par1

  return fpuByte
'-------------------------------------------------------------------------


PUB ReadReg : fpuReg                                    
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadReg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32 bit Register from FPU                           
'' Parameters: None                      
''    Results: Entry in fpuReg
''+Reads/Uses: /command, _RDBYTE, par1    
''    +Writes: command, par1        
''      Calls: #RdReg (in COG)
'-------------------------------------------------------------------------
  command := _RDREG
  repeat while command         'Wait for _RDREG command to be processed

  fpuReg := par1               'Get fpuReg from par1

  return fpuReg
'-------------------------------------------------------------------------


PUB ReadRegs(regX, cntr, floatPtr)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadRegs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads 32 bit Registers from FPU starting from Reg[X]                           
'' Parameters: Reg[X], Number of registers to read, pointer to HUB address
''             of register array                      
''    Results: FPU registers from Reg[X] stored in HUB sequentially
''+Reads/Uses: /par1, par2, par3, command, _RDREGS    
''    +Writes: par1, par2, par3, command        
''      Calls: #RdRegs (in COG)
'-------------------------------------------------------------------------
  Wait
  par1 := regX
  par2 := cntr
  par3 := floatPtr
  command := _RDREGS
  repeat while command         'Wait for _RDREGS command to be processed
'-------------------------------------------------------------------------


PUB ReadStr : strPtr                                    
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadStr │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a String from FPU                           
'' Parameters: None                      
''    Results: Pointer to HUB/str
''+Reads/Uses: /command, _RDSTRING, @str    
''    +Writes: command        
''      Calls: #RdString (in COG)
''       Note: _READSTR FPU command is issued by the PASM routine
'-------------------------------------------------------------------------
  command := _RDSTRING
  repeat while command         'Wait for _RDSTRING command to be processed

  strPtr := @str               'Set strPtr to point HUB/str

  return strPtr
'-------------------------------------------------------------------------


DAT

'-------------------------------------------------------------------------
'-------------DAT section for PASM program and COG registers--------------
'------------------------------------------------------------------------- 
uMFPU      org           0             'Start of PASM program

Get_Command
  rdlong   r1,           par wz        'Read "command" register from HUB
  if_z     jmp           #Get_Command  'Wait for a nonzero value

  shl      r1,           #1            'Multiply command No. with 2
  add      r1,           #Cmd_Table-2  'Add it to the value of
                                       '#Cmd_Table-2

'Note that command numbers are 1, 2, 3, etc..., but the entry routines
'are the 0th, 2rd, 4th, etc... entries in the Cmd_Table (measured in 32
'bit registers)

  jmp      r1                      'Jump to command in Cmd_Table
                                     
Cmd_Table                          'Command dispatch table
  call     #Init                   '(Init=command No.1)
  jmp      #Done                   'Nothing else to do for Init
  call     #Rst                    '(Reset=command No.2)
  jmp      #Done                   'Nothing else to do for Rst
  call     #WaitForReady           '(Wait=command No.3)
  jmp      #Done                   'Nothing to do for WaitForReady
  call     #WrtByte                '(WrtByte=command No. 4)
  jmp      #Done                   'Nothing else to do for WrtByte
  call     #WrtCmdByte             '(WrtCmdByte=command No. 5)
  jmp      #Done                   'Nothing else to do for WrtCmdByte
  call     #WrtCmd2Bytes           '(WrtCmd2Bytes=command No. 6)
  jmp      #Done                   'Nothing else to do for WrtCmd2Bytes
  call     #WrtCmd3Bytes           '(WrtCmd3Bytes=command No. 7)
  jmp      #Done                   'Nothing else to do for WrtCmd3Bytes
  call     #WrtCmd4Bytes           '(WrtCmd4Bytes=command No. 8)
  jmp      #Done                   'Nothing else to do for WrtCmd4Bytes
  call     #WrtCmdReg              '(WrtCmdReg=command No. 9)
  jmp      #Done                   'Nothing else to do for WrtCmdReg
  call     #WrtCmdRnReg            '(WrtCmdRnReg=command No. 10)
  jmp      #Done                   'Nothing else to do for WrtCmdRnReg
  call     #WrtCmdCntRegs          '(WrtCmdCntRegs=command No. 11)
  jmp      #Done                   'Nothing else to do for WrtCmdCntRegs
  call     #WrtCmdString           '(WrtCmdString=command No. 12)
  jmp      #Done                   'Nothing else to do for WrtCmdCntRegs
  call     #RByte                  '(RdByte=command No. 13)
  jmp      #Done                   'Nothing else to do for RdByte 
  call     #RdReg                  '(RdReg=command No. 14)
  jmp      #Done                   'Nothing else to do for RdReg
  call     #RdRegs                 '(RdReg=command No. 15)
  jmp      #Done                   'Nothing else to do for RdRegs
  call     #RdString               '(RdString=command No. 16)
  jmp      #Done                   'Nothing else to do for RdString
  call     #Rndomize               '(Rndomize=command No. 17)  
  'jmp      #Done                  'Take care of comment line if 
                                   'you expand this driver
                                       
'Command has been processed. Signal this to the SPIN code of this driver
'by zeroing the "command" register, then jump back to the entry point of
'this PASM code and fetch the next command

Done
  wrlong   _Zero,        par           'Write 0 to command(in HUB)    
  jmp      #Get_Command                'Get next command

  
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Init │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Initializes DIO and CLK Pin Masks
'             Stores HUB addresses of parameters.
'             Prepares real random routine
'             Preforms a simple FPU ready? test
' Parameters: HUB/dio, clk, @str
'             COG/par
'    Results: COG/dio_Mask, clk_Mask
'             COG/par1_Addr_, par2_Addr_, par3_Addr_, str_Addr_
'             HUB/par1 (Flag of success)  
'+Reads/Uses: /r1, r2
'    +Writes: r1, r2
'      Calls: None
'-------------------------------------------------------------------------
Init

  mov      r1,           par     'Get HUB memory address of "command"

  add      r1,           #4      'r1 now points to "par1" in HUB memory 
  mov      par1_Addr_,   r1      'Store this address
  rdlong   r2,           r1      'Load DIO pin No. from HUB memory into r2
  mov      dio_Mask, #1          'Setup DIO pin mask 
  shl      dio_Mask, r2
  andn     outa,         dio_Mask      'Pre-Set Data pin LOW
  andn     dira,         dio_Mask      'Set Data pin as INPUT 

  add      r1,           #4      'r1 now points to "par2" in HUB memory
  mov      par2_Addr_,   r1      'Store this address
  rdlong   r2,           r1      'Load CLK pin No. from HUB memory into r2
  mov      clk_Mask, #1          'Setup CLK pin mask
  shl      clk_Mask, r2
  andn     outa,         clk_Mask      'Pre-Set Clock pin LOW (Idle)
  or       dira,         clk_Mask      'Set Clock pin as an OUTPUT

  add      r1,           #4      'r1 now points to "par3" in HUB memory
  mov      par3_Addr_,   r1      'Store this address
  rdlong   str_Addr_,    r1      'Read pointer to str char array

  add      r1,           #4      'r1 now points to "par4" in HUB memory
  mov      par4_Addr_,   r1      'Store this address
  add      r1,           #4      'r1 now points to "par5" in HUB memory
  mov      par5_Addr_,   r1      'Store this address

   '**********************************************************************
  'Prepare COG to randomize (copied from RealRandom v1.2)
  movi     ctra,         #%00001_111   'set ctra to internal pll mode,
                                       'select x16 tap
  movi     frqa,         #$020         'set frqa to system
                                       'clock frequency / 16
  movi     vcfg,         #$040         'set vcfg to discrete output,
                                       'but without pins
  mov      vscl,         #70           'set vscl to 70 pixel clocks
                                       'per waitvid
  '***********************************************************************                                     
  
  'Check DIO for FPU ready
  test     dio_Mask,     ina wc        'Read DIO state into 'C' flag
  if_nc    jmp           #:Ready       'Should be LOW

  mov      r1,           #0            'Not LOW not ready, make "false" 
  jmp      #:Signal                    'and signal it
  
:Ready
  neg      r1,           #1            'Make"true"  and signal it back

:Signal  
  wrlong   r1,           par1_Addr_
  
Init_Ret
  ret           
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ Rst │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Does a Software Reset of FPU
' Parameters: None
'    Results: "Okay" in HUB/par1
'+Reads/Uses: /r1, r4, time, _RESET, _Data_Period, _Reset_Delay
'             dio_Mask, par1_Addr_
'    +Writes: r1, r4, time
'      Calls: #Write_Byte
'       Note: #Write_Byte and descendants use r2,r3
'-------------------------------------------------------------------------
Rst

  mov      r1,           #_RESET       'Byte to send
  mov      r4,           #10           '10 times

:Loop
  call     #Write_Byte                 'Write byte to FPU 
  djnz     r4,           #:Loop        'Repeat Loop 10 times 

  mov      r1,           #0            'Write a 0 byte to enforce DIO LOW
  call     #Write_Byte

  'Wait for a  Reset Delay of 10 msec
  mov      time,         cnt           'Find the current time
  add      time,         _Reset_Delay  'Prepare a 10 msec Reset Delay
  waitcnt  time,         #0            'Wait for 10 msec

  'Check DIO for FPU ready
  test     dio_Mask,     ina wc        'Read DIO state into 'C' flag
  if_nc    jmp           #:Ready       'Should be LOW

  mov      r1,           #0            'Not ready, signal "false" back
  jmp      #:Signal
  
:Ready
  neg      r1,           #1            'Ready, signal "true" back

:Signal  
  wrlong   r1,           par1_Addr_  

Rst_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WaitForReady │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU
'  Parameter: None
'     Result: None 
'+Reads/Uses: /time, dio_Mask
'    +Writes: time, CARRY flag
'      Calls: None
'       Note: Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise DIO line in response to a received command.
'             That's why a Data Period Delay is inserted before the check.
'-------------------------------------------------------------------------
WaitForReady

  andn     dira,         dio_Mask  'Set DIO pin as an INPUT

'Insert Data Period Delay 
  mov      time,         cnt           'Find the current time
  add      time,         _Data_Period  '1.6 us Data Period Delay
  waitcnt  time,         #0            'Wait for 1.6 usec  

:Loop
  test     dio_Mask,     ina wc    'Read SOUT state into 'C' flag
  if_c     jmp           #:Loop    'Wait until DIO LOW

WaitForReady_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'----------------------------------┌─────────┐----------------------------
'----------------------------------│ WrtByte │----------------------------
'----------------------------------└─────────┘----------------------------
'-------------------------------------------------------------------------
'      Action: Sends a byte to FPU 
'  Parameters: Byte to send in HUB/par1 (LS byte)
'     Results: None 
' +Reads/Uses: /r1, par1_Addr_
'     +Writes: r1
'       Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtByte

  rdlong   r1,           par1_Addr_    'Load byte from HUB
  call     #Write_Byte                 'Write it to FPU
   
WrtByte_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ WrtCmdByte │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus Data byte sequence to FPU
' Parameters: Command byte in HUB/par1
'             Data byte in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /r1, par1_Addr_, par2_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdByte

  'Send an 8 bit Command + 8 bit data sequence to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par2_Addr_    'Load Data byte from par2
  call     #Write_Byte                 'and write it to FPU
  
WrtCmdByte_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd2Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 2 Data bytes to FPU
' Parameters: Command byte in HUB/par1
'             Data bytes in HUB/par2, par3
'    Results: None                                                                                             
'+Reads/Uses: /r1, par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd2Bytes

  'Send an 8 bit Command + 2 x 8 bit data sequence to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par2_Addr_    'Load 1st Data byte from par2
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par3_Addr_    'Load 2nd Data byte from par3
  call     #Write_Byte                 'and write it to FPU
  
WrtCmd2Bytes_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd3Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 3 Data bytes to FPU
' Parameters: Command byte in HUB/par1
'             Data bytes in HUB/par2, par3, par4
'    Results: None                                                                                             
'+Reads/Uses: /r1, par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd3Bytes

  'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par2_Addr_    'Load 1st Data byte from par2
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par3_Addr_    'Load 2nd Data byte from par3
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par4_Addr_    'Load 3nd Data byte from par4
  call     #Write_Byte                 'and write it to FPU
  
WrtCmd3Bytes_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd4Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 4 Data bytes to FPU
' Parameters: Command byte in HUB/par1
'             Data bytes in HUB/par2, par3, par4, par5
'    Results: None                                                                                             
'+Reads/Uses: /r1, par1_Addr_,par2_Addr_,par3_Addr_,par4_Addr_ ,par5_Addr
'    +Writes: r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd4Bytes

  'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par2_Addr_    'Load 1st Data byte from par2
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par3_Addr_    'Load 2nd Data byte from par3
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par4_Addr_    'Load 3nd Data byte from par4
  call     #Write_Byte                 'and write it to FPU
  rdlong   r1,           par5_Addr_    'Load 4th Data byte from par4
  call     #Write_Byte                 'and write it to FPU
  
WrtCmd4Bytes_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ WrtCmdReg │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 32 bit Register sequence to FPU
' Parameters: Command byte in HUB/par1
'             32 bit Register value in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /r1, r4, par1_Addr_, par2_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdReg

  'Send an 8 bit Command + 32 bit Register sequence to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r4,           par2_Addr_    'Load 32 bit Reg. value from par2
  call     #Write_Reg                  'and write it to FPU
  
WrtCmdReg_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ WrtCmdRnReg │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 32 bit data to FPU
' Parameters: Command byte in HUB/par1
'             Reg[n] byte in HUB/par2
'             32 bit data in HUB/par3
'    Results: None                                                                                             
'+Reads/Uses: /r1,r4,par1,par2,par3,par1_Addr_,par2_Addr_,par3_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnReg

  'Send Command byte + Reg[n] byte + 32 bit data to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par2_Addr_    'Load Reg[n] from par2
  call     #Write_Byte                 'Write it to FPU
  rdlong   r4,           par3_Addr_    'Load 32 bit Reg. value from par3
  call     #Write_Reg                  'and write it to FPU
  
WrtCmdRnReg_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ WrtCmdCntRegs │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Cntr byte + 32 bit data array to FPU
' Parameters: Command byte in HUB/par1
'             Cntr byte in HUB/par2
'             Pointer to 32 bit data array in HUB/par3
'    Results: None                                                                                             
'+Reads/Uses: /r1, r4, r5, r6, par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdCntRegs

  'Send Command byte + Reg[n] byte + 32 bit data array to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r5,           par2_Addr_    'Load Counter from par2
  mov      r1,           r5
  call     #Write_Byte                 'Write it to FPU 
  rdlong   r6,           par3_Addr_    'Load pointer to float array in HUB

:Loop
  rdlong   r4,           r6            'Load next 32 bit value from HUB
  call     #Write_Reg                  'and write it to FPU 
  add      r6,           #4            'Increment pointer to HUB memory
  djnz     r5,           #:Loop        'Decrement r5; jump if not zero 
  
WrtCmdCntRegs_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WrtCmdString │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + String to FPU
' Parameters: Command byte in HUB/par1
'             Pointer to String in HUB/par2
'    Results: None                                                                                             
'+Reads/Uses: /r1, r4, par1_Addr_, par2_Addr_
'    +Writes: r1, r4          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdString

  'Send Command byte + String (array of Chars then 0) to FPU
  rdlong   r1,           par1_Addr_    'Load FPU Command from par1
  call     #Write_Byte                 'Write it to FPU
  rdlong   r4,           par2_Addr_    'Load pointer to HUB/Str from par2

'Write String from HUB to FPU
:Loop
  rdbyte   r1,           r4 wz         'Read character from HUB
  call     #Write_Byte                 'Write char to FPU
  if_z     jmp           #:Done        'Char=0 String terminated, job done
  add      r4,           #1            'Increment pointer to HUB memory
  jmp      #:Loop                      'Next character 

:Done  
WrtCmdString_Ret
  ret
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'----------------------------------┌────────┐-----------------------------
'----------------------------------│ RdByte │-----------------------------
'----------------------------------└────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU 
' Parameters: None
'    Results: Byte entry in HUB/par1 (LSB of) 
'+Reads/Uses: /r1, par1_Addr_
'    +Writes: r1
'      Calls: #Read_Setup_Delay , #Read_Byte
'-------------------------------------------------------------------------
RByte

  call     #Read_Setup_Delay           'Insert Read Setup Delay
  call     #Read_Byte
  wrlong   r1,           par1_Addr_    'Write r1 into HUB/par1
   
RByte_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ RdReg │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32 bit register from FPU 
' Parameters: None
'    Results: Register Entry in HUB/par1 
'+Reads/Uses: /r1, par1_Addr_
'    +Writes: r1
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdReg

  call     #Read_Setup_Delay           'Insert Read Setup Delay
  call     #Read_Register
  wrlong   r1,           par1_Addr_    'Write r1 into par1(in HUB)
   
RdReg_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdRegs │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads 32 bit registers from FPU 
' Parameters: Reg X, No.  of Regs
'    Results: None 
'+Reads/Uses: /r1, r5, r6, par1_Addr_, par2_Addr_, par3_Addr_
'             _SELECTX, _RDBLK
'    +Writes: r1, r5, r6
'      Calls: #WaitForReady, #Write_Byte, #Read_Setup_Delay,
'             #Read_Register 
'-------------------------------------------------------------------------
RdRegs

  'Set Reg[X] 
  mov      r1,           #_SELECTX     'Select Reg[X] command
  call     #Write_Byte                 'Write it to FPU
  rdlong   r1,           par1_Addr_    'Load X from par1
  call     #Write_Byte                 'Write it to FPU

  rdlong   r5,           par2_Addr_    'Load cntr from par2
  rdlong   r6,           par3_Addr_    'Load pointer to HUB/floats from p3 

  call     #WaitForReady               'Before a read operation

  'Send the RDBLK command
  mov      r1,           #_RDBLK
  call     #Write_Byte
  mov      r1,           r5            'Send No. of registers to read
  call     #Write_Byte

  call     #Read_Setup_Delay           'Insert Read Setup Delay

:Loop
  call     #Read_Register              'Read register from FPU
  wrlong   r1,          r6             'Write register into HUB
  add      r6,          #4  
  djnz     r5,          #:Loop         'Get next register 
   
RdRegs_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ RdString │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads String from the String Buffer of FPU 
' Parameters: None
'    Results: String in HUB/str 
'+Reads/Uses: /r1, _READSTR
'    +Writes: r1
'      Calls: #Write_Byte, #Read_Setup_Delay, #Read_String  
'-------------------------------------------------------------------------
RdString

  'Send a _READSTR command to read the String Buffer from FPU
  call     #WaitForReady 
  mov      r1,           #_READSTR     'Send _READSTR          
  call     #Write_Byte
  call     #Read_Setup_Delay           'Insert Read Setup Delay
  call     #Read_String                'Now read String Buffer of FPU
                                       'into HUB RAM   
RdString_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'---------------------------------┌──────────┐----------------------------
'---------------------------------│ Rndomize │----------------------------
'---------------------------------└──────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Generates a  random long value
' Parameters: None
'    Returns: random_value into par1 
'+Reads/Uses: /r1 
'    +Writes: None
'      Calls: None
'       Note: Copied from RealRandom (v1.2) of Chip Gracey and modified 
'             not to run continuosly, just when we need it.
'-------------------------------------------------------------------------
Rndomize
  mov      r1,           #45
  mov      random_value, #0

:twobits
  waitvid  0,            0                'wait for next 70-pixel mark
                                          '± jitter time
  test     phsa,         #%10111 wc       'pseudo-randomly sequence phase
                                           'to induce jitter
  rcr      phsa,         #1               '(c holds random bit #1)
  add      phsa,         cnt              'mix PLL jitter back into phase 

  rcl      par,          #1 wz, nr        'transfer c into nz (par shadow
                                          'register = 0)
  'wrlong   random_value, par             'write random value back to spin
                                          ' variable
  
  waitvid  0,            0                'wait for next 70-pixel mark
                                          ' ± jitter time           
  test     phsa,         #%10111 wc       'pseudo-randomly sequence phase
                                          ' to induce jitter        
  rcr      phsa,         #1               '(c holds random bit #2)                                                        
  add      phsa,         cnt              'mix PLL jitter back into phase                    

  if_z_eq_c rcl          random_value, #1 'only allow different bits
                                          ' (removes bias)
  'jmp      #:twobits                     'get next two bits    

  djnz     r1,           #:twobits

  wrlong   random_value, par1_Addr_       'Write random_value into
                                          'HUB/par1              

Rndomize_Ret         
  ret
'------------------------------------------------------------------------- 



'Now come the "PRIVATE" PASM routines of this Driver. They are "PRI" in the
'sense that they do not have "command No." and they do not use par1, par2,
'etc... 

'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Write_Byte │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a byte to FPU 
' Parameters: Byte to send in r1
'    Results: None 
'+Reads/Uses: /time, _Data_Period, dio_Mask
'    +Writes: time
'      Calls: #Shift_Out_Byte
'-------------------------------------------------------------------------
Write_Byte

  'Wait for the Minimum Data Period
  mov      time,         cnt           'Find the current time
  add      time,         _Data_Period  '1.6 us minimum data period
  waitcnt  time,         #0            'Wait for  1.6 us

  or       dira,         dio_Mask      'Set DIO pin as an OUTPUT
  call     #Shift_Out_Byte             'Write byte to FPU
   
Write_Byte_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'---------------------------------┌───────────┐---------------------------
'---------------------------------│ Write_Reg │---------------------------
'---------------------------------└───────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32 bit value to FPU
' Parameters: 32 bit value in r4 to send (MSB first)
'    Results: None 
'+Reads/Uses: /r1, _Byte_Mask
'    +Writes: r1
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
Write_Reg

  'Send MS byte of r4
  mov      r1,           r4
  ror      r1,           #24
  and      r1,           _Byte_Mask
  call     #Write_Byte

  'Send 2nd byte of r4
  mov      r1,           r4
  ror      r1,           #16
  and      r1,           _Byte_Mask
  call     #Write_Byte

  'Send 3rd byte of r4
  mov      r1,           r4
  ror      r1,           #8
  and      r1,           _Byte_Mask
  call     #Write_Byte

  'Send LS byte of r4
  mov      r1,           r4
  and      r1,           _Byte_Mask
  call     #Write_Byte
  
Write_Reg_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Read_Setup_Delay │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Inserts 15 us Read Setup Delay
' Parameters: None
'    Results: None
'+Reads/Uses: /time, _Read_Setup_Delay 
'    +Writes: time
'      Calls: None
'-------------------------------------------------------------------------
Read_Setup_Delay

  mov      time,         cnt                 'Find the current time
  add      time,         _Read_Setup_Delay   '15 usec Read Setup Delay
  waitcnt  time,         #0                  'Wait for 15 usec
  
Read_Setup_Delay_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Read_Byte │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU
' Parameters: None
'    Results: Entry in r1
'+Reads/Uses: /time, dio_Mask, _Read_Byte_Delay
'    +Writes: time
'      Calls: #Shift_In_Byte
'-------------------------------------------------------------------------
Read_Byte

  andn     dira,         dio_Mask          'Set DIO pin as an INPUT

  'Insert a 1 us Read Byte Delay
  mov      time,         cnt               'Find the current time
  add      time,         _Read_Byte_Delay  '1 us Read Byte Delay
  waitcnt  time,         #0                'Wait for 1 usec       
  
  call     #Shift_In_Byte                  'Read a byte from FPU
  
Read_Byte_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Read_Register │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32 bit register form FPU
' Parameters: None
'    Results: Entry in r1
'+Reads/Uses: /r3
'    +Writes: r3
'      Calls: #Read_Byte
'       note: #Read_Byte's descendant uses r2
'-------------------------------------------------------------------------
Read_Register

  'Collect FPU register in r3 
  call     #Read_Byte
  mov      r3,           r1
  call     #Read_Byte
  shl      r3,           #8
  add      r3,           r1
  call     #Read_Byte
  shl      r3,           #8
  add      r3,           r1
  call     #Read_Byte
  shl      r3,           #8
  add      r3,           r1

  mov      r1,           r3            'Done. Copy summ from r3 into r1
  
Read_Register_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Read_String │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a string from FPU into HUB memory
' Parameters: Address of str[] byte array in HUB
'    Results: Sring in HUB/str
'+Reads/Uses: /r1, r3, str_Addr_
'    +Writes: r1, r3
'      Calls: #Read_Byte
'-------------------------------------------------------------------------
Read_String

  'Prepare read string from FPU to HUB loop
  mov      r3,           str_Addr_
 
:Loop
  call     #Read_Byte
  wrbyte   r1,           r3            'Write character to HUB memory
  cmp      r1,           #0 wz            
  if_z     jmp           #:Continue    'String terminated if char is 0
  add      r3,           #1            'Increment pointer to HUB memory
  jmp      #:Loop                      'Fetch next character from FPU                                 

:Continue  
Read_String_Ret
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Shift_Out_Byte │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Shifts out a byte to FPU  (MSBFIRST)
' Parameters: Byte to send in r1
'    Results: None
'+Reads/Uses: /r2, r3, dio_Mask 
'    +Writes: r2, r3
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_Out_Byte                               

  mov      r2,           #8            'Set length of byte         
  mov      r3,           #%1000_0000   'Set bit mask (MSBFIRST)
                                                               
:Loop
  test     r1,           r3 wc         'Test a bit of data byte
  muxc     outa,         dio_Mask      'Set DIO HIGH or LOW
  shr      r3,           #1            'Prepare for next data bit  
  call     #Clock_Pulse                'Send a clock pulse
  djnz     r2,           #:Loop        'Decrement r2; jump if not zero
         
Shift_Out_Byte_Ret
  ret
'-------------------------------------------------------------------------

  
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Shift_In_Byte │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Shifts in a byte from FPU (MSBPRE)
' Parameters: None
'    Results: Entry byte in r1
'+Reads/Uses: /r2, dio_Mask, _Byte_Mask 
'    +Writes: r2
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_In_Byte
  andn     dira,         dio_Mask      'Set DIO pin as an INPUT
  mov      r2,           #8            'Set length of byte 
          
:Loop
  test     dio_Mask,     ina wc        'Read Data Bit into 'C' flag
  rcl      r1,           #1            'Left rotate 'C' flag into r1  
  call     #Clock_Pulse                'Send a clock pulse   
  djnz     r2,           #:Loop        'Decrement r2; jump if not zero

  and      r1,           _Byte_Mask    'Clean up bit mess in r1  

Shift_In_Byte_Ret        
  ret              
'-------------------------------------------------------------------------


'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Clock_Pulse │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a 50 us pulse to CLK pin of FPU
' Parameters: None
'    Returns: None 
'+Reads/Uses: /clk_Mask 
'    +Writes: None
'      Calls: None
'       Note: At 80_000_000 Hz the CLK pulse width is about 50 ns(4 ticks)
'             and the CLK pin is pulsed at the rate about 2.5 MHz. This
'             rate is determined by the cycle time of the loop containing
'             the "call #Clock_Pulse" instruction. You can make the rate a
'             bit faster using inline code instead of djnz in the shift
'             in/out routines. However, the overal data burst speed will
'             not increase that much since the necessary delays affect it,
'             as well. They should remain in the time sequence, of course.
'-------------------------------------------------------------------------
Clock_Pulse

  or       outa,         clk_Mask  'Set CLK Pin HIGH
  andn     outa,         clk_Mask  'Set CLK Pin LOW

Clock_Pulse_Ret         
  ret
'------------------------------------------------------------------------- 



'-------------------------------------------------------------------------
'--------Allocate COG memory for registers defined by PASM symbols--------
'-------------------------------------------------------------------------
  
'-------------------------------------------------------------------------
'------------------------------ Initialized data -------------------------
'-------------------------------------------------------------------------
_Zero                long    0

'---------------------------Delays at 80_000_000 MHz----------------------
_Data_Period         long    128       '1.6 us Minimum Data Period  
_Reset_Delay         long    800_000   '10 ms Reset Delay
_Read_Setup_Delay    long    1_200     '15 us Read Setup Delay
_Read_Byte_Delay     long    80        '1 us Read Byte Delay

 
'----------------------------------Data Masks-----------------------------
_Byte_Mask           long    $FF       '8-Bit mask for LS byte


'-------------------------------------------------------------------------
'-----------------------------Uninitialized data -------------------------
'-------------------------------------------------------------------------

'----------------------------------Pin Masks------------------------------
dio_Mask       res     1     'Pin mask in Propeller for DIO
clk_Mask       res     1     'Pin mask in Propeller for CLK

'------------------------------HUB memory addresses-----------------------
par1_Addr_     res     1
par2_Addr_     res     1
par3_Addr_     res     1
par4_Addr_     res     1
par5_Addr_     res     1
str_Addr_      res     1
time           res     1
random_value   res     1              'After Realrandom of Chip Gracey

'-------------------------Recycled Temporary Registers--------------------
r1             res     1         
r2             res     1         
r3             res     1
r4             res     1
r5             res     1
r6             res     1          

fit            496


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