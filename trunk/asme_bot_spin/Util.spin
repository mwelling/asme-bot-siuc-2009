{{
  Object:       Util.spin
  Purpose:      This program contains some utility methods for use in other SPIN programs.
  Author:       Steve Warren
  Contents:
        strntofloat(str,n) : float
        strntodec(str,n) : integer
}}
obj
  fmath:        "FloatMath.spin"



  
pub strntofloat(str,n) : number | i, cbyte, fpt, fi
' converts str starting at n, ending at the first non numeric character to floating point
  i := n
  fpt := false 
  repeat until ((cbyte := byte[str][i]) > 48 OR cbyte < 58 ) AND cbyte <> "." AND cbyte <> "#"
    if cbyte == "#"
      n := i++
      next
    elseif cbyte == "."
      fpt := true
      fi := i-n
    cbyte -= 48
    cbyte := fmath.FFloat(cbyte)
    if NOT fpt                                               
      number := fmath.FAdd(fmath.FMul(number,10.0),cbyte)
    else
      repeat i-fi
        cbyte := fmath.FMul(cbyte,0.1)
      number := fmath.FAdd(number,cbyte)
    i++
    
pub strntodec(str,n) : number | i,j, cbyte
' converts str starting at n, ending at the first non numeric character to decimal
  i := n
  j := strsize(str)
  number := 0                                                                   
  repeat until ((cbyte := byte[str][i]) > "9" OR cbyte < "0" OR i > j ) ''AND cbyte <> ","
    if cbyte == ","
      i++
      next
    cbyte -= "0"                 
    number := number*10 + cbyte 
    i++     
    
pub strncomp(str1,str2,n) : tf | k,c
' checks str1 starting at n to see if a substring str2 exists there

  c := strsize(str2)
  k := 0
  
  repeat c
    if byte[str1][n+k] <> byte[str2][k]
      return false
    k++ 
  return true
   
pub strbytefind(str1,sbyte,n) : i
' searches str1 starting at index n for the character sbtye

  i := n
  
  repeat until i>(strsize(str1)-1)
    if byte[str1][i] == sbyte
      return i 
    i++    