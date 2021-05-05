local devices = { }
local lineIndex = 1
local pageOffset = 0

local supportedRadios =
{
    ["128x64"]  =
    {
        --highRes         = false,
        textSize        = SMLSIZE,
        xOffset         = 60,
        yOffset         = 8,
        yOffset_val     = 3,
        topOffset       = 1,
        leftOffset      = 1,
    },
    ["128x96"]  =
    {
        --highRes         = false,
        textSize        = SMLSIZE,
        xOffset         = 60,
        yOffset         = 8,
        yOffset_val     = 3,
        topOffset       = 1,
        leftOffset      = 1,
    },
    ["212x64"]  =
    {
        --highRes         = false,
        textSize        = SMLSIZE,
        xOffset         = 60,
        yOffset         = 8,
        yOffset_val     = 3,
        topOffset       = 1,
        leftOffset      = 1,
    },
    ["480x272"] =
    {
        --highRes         = true,
        textSize        = 0,
        xOffset         = 100,
        yOffset         = 20,
        yOffset_val     = 5,
        topOffset       = 1,
        leftOffset      = 1,
    },
    ["320x480"] =
    {
        --highRes         = true,
        textSize        = 0,
        xOffset         = 120,
        yOffset         = 25,
        yOffset_val     = 5,
        topOffset       = 5,
        leftOffset      = 5,
    },
}

local radio_resolution = LCD_W.."x"..LCD_H
local radio_data = assert(supportedRadios[radio_resolution], radio_resolution.." not supported")


-- redraw the screen
local function refreshLCD()

    local yOffset = radio_data.topOffset;
    local lOffset = radio_data.leftOffset;

    lcd.clear()
	if #devices == 0 then
		lcd.drawText(lOffset, yOffset, "Waiting for Crossfire devices...")
	else
		yOffset = radio_data.yOffset_val
		for i=1, #devices do
		  local item_y = yOffset + radio_data.yOffset * i
		  local attr = (lineIndex == i and INVERS or 0)
		  local sel = (lineIndex == i and "-" or " ")

		  lcd.drawText(lOffset, item_y, sel..devices[i].name, attr+radio_data.textSize)
		end
	end
  
end


local function createDevice(id, name)
  local device = {
    id = id,
    name = name,
    timeout = 0
  }
  return device
end

local function getDevice(name)
  for i=1, #devices do
    if devices[i].name == name then
      return devices[i]
    end
  end
  return nil
end

local function parseDeviceInfoMessage(data)
  local id = data[2]
  local name = ""
  local i = 3
  while data[i] ~= 0 do
    name = name .. string.char(data[i])
    i = i + 1
  end
  local device = getDevice(name)
  if device == nil then
    device = createDevice(id, name)
    devices[#devices + 1] = device
  end
  local time = getTime()
  device.timeout = time + 3000 -- 30s
  if lineIndex == 0 then
    lineIndex = 1
  end
end

local devicesRefreshTimeout = 0
local function refreshNext()
  local command, data = crossfireTelemetryPop()
  if command == nil then
    local time = getTime()
    if time > devicesRefreshTimeout then
      devicesRefreshTimeout = time + 100 -- 1s
      crossfireTelemetryPush(0x28, { 0x00, 0xEA })
    end
  elseif command == 0x29 then
    parseDeviceInfoMessage(data)
  end
end

local function selectDevice(step)
  lineIndex = 1 + ((lineIndex + step - 1 + #devices) % #devices)
end

-- Init
local function init()
  lineIndex = 0
  pageOffset = 0
end

-- Main
local function run(event)
  if event == nil then
    error("Cannot be run as a model script!")
    return 2
  elseif event == EVT_VIRTUAL_EXIT or event == EVT_EXIT_BREAK or event == EVT_RTN_FIRST then
    return 2
  elseif event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_NEXT_REPT or event == EVT_ROT_RIGHT or event == EVT_SLIDE_RIGHT  then
    selectDevice(1)
  elseif event == EVT_VIRTUAL_PREV or event == EVT_VIRTUAL_PREV_REPT or event == EVT_ROT_LEFT or event == EVT_SLIDE_LEFT then
    selectDevice(-1)
  elseif event == EVT_VIRTUAL_ENTER or event == EVT_ENTER_BREAK then
	crossfireTelemetryPush(0x28, { devices[lineIndex].id, 0xEA })
	return "devaddr.lua"
  end

  refreshLCD()
  refreshNext()

  return 0
end

return { init=init, run=run }
