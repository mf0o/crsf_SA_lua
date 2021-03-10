-- 2020-03-10	v0.9	www.github.com/mf0o

-- this lua script can be used to control a vtx via smartaudio 
-- which is connected to a TBS crossfire RX on CH1 or CH4
-- setup:
-- 1) connect the smartaudio port of your VTX to CH1 or CH4 of the TBS Crossfire RX
-- 2) set the output (of the wired channel) to "smartaudio" via the normal crossfire.lua or OLED screen
-- 3) save CRSFDEBUG.lua to your CROSSFIRE folder and execute it 
-- 4) navigate to your RX, a section VTX should be visible
-- 5) note the deviceID, address and value of the power setting
-- 6) place cfSA.lua into you SCRIPTS/MIXES folder
-- 7) enable the script on the models "CUSTOM SCRIPTS" page in openTX
-- 8.1) set "LEVEL" to a globalvar of your choice
-- 8.2) set "ADDR" to the address obtained in step #5
-- 8.3) set "DEVICEID" to the deviceID obtained in step #5
-- 8.4) optional, enable beep or sounds on script execution
-- 9) use SPECIAL FUNCTIONS to alter the GVAR and enter the powerlevel of choice

-- define inputs
local SAinputs = {
        { "LEVEL", SOURCE},                 -- GV1; 0,1,2,3 maps to TX power levels
        { "ADDRESS", VALUE, 0, 200, 7},                 -- GV1; 0,1,2,3 maps to TX power levels
        { "DEVICE", VALUE, 0, 500, 238 },	-- 238 seems to be the default
        { "playSounds", VALUE, 0, 1, 1 },		-- enable custom sounds
        { "playBeep", VALUE, 0, 1, 1 }			-- enable beeps 
    }

local exdelay = 50   	-- 1s
						-- was 2, delay between crossfireTelemetryPush, TX doesnt like to get fired too heavily
					  	-- crossfireTelemetryPush(0x28, { 0x00, 0xEA })

local firstrun = 1
local BeepFrequency = 4000 -- Hz
local BeemLengthMiliseconds = 20

local function SArun(LEVEL, ADDRESS, DEVICE, playSounds, playBeep )
    
	-- ignore any settings on first run of the script, send only further changes to vtx
	if firstrun == 1 then
		lastLEVEL = LEVEL
		firstrun = 0
		extime = getTime()
	end
	
	-- change power
	if (lastLEVEL ~= LEVEL) and (extime+exdelay < getTime()) then
		-- play beep or sound
		if (playBeep == 1) then
			playTone(BeepFrequency,BeemLengthMiliseconds,0)
		end
		if (LEVEL > lastLEVEL) and (playSounds == 1) then
			playFile("crsfPowerInc.wav")
		end
		
		-- write telemetry
		crossfireTelemetryPush(0x2D, { DEVICE, 0xEA, ADDRESS, LEVEL })

		-- save state and update execution time
		lastLEVEL = LEVEL
		extime = getTime()
	end
	
    return
end

return {input=SAinputs, run=SArun}
