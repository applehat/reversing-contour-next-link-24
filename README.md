# contour-next-link-24-teardown
Tear Down of the Contour Next Link 2.4 Blood Glucose Meter

## Front

Nothing super interesting up front. Mostly just the BG Meter bits.

**Unknown Chip**

F3796 018
1552pm402

**Most Likely Display Driver**

TOSHIBA
T5DBO0
1624 HUL
181961

![Front](https://github.com/applehat/contour-next-link-24-teardown/raw/master/front.jpg)

![Board Top/Front](https://github.com/applehat/contour-next-link-24-teardown/raw/master/board_top.jpg)



## Back

This is where the fun stuff is.

**Flash Memory**

http://www.zlgmcu.com/mxic/pdf/NOR_Flash_c/MX25L1606-8006E_DS_EN.pdf

**Ti SoC ZigBee Radio**

http://www.ti.com/lit/ds/symlink/cc2430.pdf

CC2430-F128
5CW01HG
1549

![Back](https://github.com/applehat/contour-next-link-24-teardown/raw/master/back.jpg)

![Back Naked](https://github.com/applehat/contour-next-link-24-teardown/raw/master/back-without-lipo-or-shielding.jpg)

![Board Bottom/Back](https://github.com/applehat/contour-next-link-24-teardown/raw/master/board_bottom.jpg)

![Debug Pins](https://github.com/applehat/contour-next-link-24-teardown/raw/master/debug-pins.jpg)

## Attempting to Dump the Firmware

The CC2430 is hooked up in-circuit to a nodeMCU devkit.  The CC2430's p2_1 is tied to the nodeMCU's D2, p2_2 to D1, reset_n to D5, and DVDD to 3v3.

![Debug Setup](https://github.com/applehat/contour-next-link-24-teardown/raw/master/debug_setup.jpg)

This Lua script was then used to determine whether the debug interface worked and whether the DBGLOCK bit was set:

```lua
-- Using GPIO from lua to bitbang
-- Debug data is driven when clock goes low->high
-- Debug data is sampled when clock goes high->low
-- minimum clock cycle is 128ns or 7.8125 MHz
-- Data is transferred MSB first

local pClock = 1 -- Clock pin is tied to D1
local pData = 2 -- Data pin is tied to D2
local pReset = 5 -- Reset pin is tied to D5

gpio.mode(pClock, gpio.OUTPUT)
gpio.mode(pData, gpio.OUTPUT)
gpio.mode(pReset, gpio.OUTPUT)

-- hold reset low and clock out twice
gpio.write(pReset, gpio.LOW)
for i = 1,2 do
  gpio.write(pClock, gpio.HIGH)
  tmr.delay(1)
  gpio.write(pClock, gpio.LOW)
  tmr.delay(1)
end
gpio.write(pReset, gpio.HIGH)

-- write the command byte for READ_STATUS
local cmd = 0x34
for i = 1,8 do
  local b = bit.band(1, bit.rshift(cmd, 8-i))
  local p = gpio.LOW
  if b == 1 then
    p = gpio.HIGH
  end
  gpio.write(pData, p)

  gpio.write(pClock, gpio.HIGH)
  tmr.delay(1)
  gpio.write(pClock, gpio.LOW)
  tmr.delay(1)
end

-- read back the result
local r_in = 0
for i = 1,8 do
  gpio.write(pData, gpio.LOW)
  gpio.write(pClock, gpio.HIGH)
  tmr.delay(1)
  gpio.mode(pData, gpio.INPUT)
  gpio.write(pClock, gpio.LOW)
  p = gpio.read(pData)
  r_in = bit.bor(r_in, bit.lshift(p, 8-i))
  tmr.delay(1)
  gpio.mode(pData, gpio.OUTPUT)
end

print(string.format("read 0x%x", r_in))

-- hold reset back at low since we're done
gpio.write(pReset, gpio.LOW)
```

This read back from the CC2430 `0xb6` (`0b10110110`), meaning DEBUG_LOCKED is 1.  This bit prevents the debug interface from executing all commands except READ_STATUS, GET_CHIP_ID, and CHIP_ERASE.  GET_CHIP_ID returned `0x8504`, indicating die revision E.  Trying other debug commands returned `0x00`.
