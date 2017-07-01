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

local function write_cmd(cmd)
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
end

local function read_byte()
  local res = 0
  for i = 1,8 do
    gpio.write(pData, gpio.LOW)
    gpio.write(pClock, gpio.HIGH)
    tmr.delay(1)
    gpio.mode(pData, gpio.INPUT)
    gpio.write(pClock, gpio.LOW)
    p = gpio.read(pData)
    res = bit.bor(res, bit.lshift(p, 8-i))
    tmr.delay(1)
    gpio.mode(pData, gpio.OUTPUT)
  end
  return res
end

-- write the command byte for READ_STATUS
write_cmd(0x34)

-- read back the result
print(string.format("read: 0x%x", read_byte()))

write_cmd(0x48)
print(string.format("read: 0x%x", read_byte()))
print(string.format("read: 0x%x", read_byte()))
write_cmd(0x5c)
print(string.format("read: 0x%x", read_byte()))
write_cmd(0x48)
print(string.format("read: 0x%x", read_byte()))
print(string.format("read: 0x%x", read_byte()))


-- hold reset back at low since we're done
gpio.write(pReset, gpio.LOW)

