''Demonstration of PWM version of NCO/PWM counter mode
CON _clkmode = xtal1 + pll16x
    _xinfreq = 6_000_000             ' CHECK THIS!!!
    led = 27
    max_duty = 100
    pwm1pin  = 1
    pwm2pin  = 2

VAR long parameter
  

OBJ
  pwm1  :  "pwmasm"
  'pwm2  :  "pwmasm"


PUB go | x
  dira[led] := 1
  pwm1.start(pwm1pin)
  'pwm2.start(pwm2pin) 
  'pwm2.SetPeriod( 300)
  pwm1.SetPeriod( 300)
  repeat
    !outa[led]
    repeat x from 0 to max_duty 'linearly advance parameter from 0 to 100
      pwm1.SetDuty(x)
      'pwm2.SetDuty(100-x)
      waitcnt(1_000_000 + cnt)   'wait a little while before next update