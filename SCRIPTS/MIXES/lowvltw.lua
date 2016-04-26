----------------------------------------------------------------------------
-- Do some Init's
----------------------------------------------------------------------------
local trigger_is_active     = false
local volt_input_source     = "Cmin"
local volt_real             = 0
local volt_int_leftofpoint  = 0
local volt_int_rightofpoint = 0
local play_next_time        = 0
local play_delay            = 500
local wav_lwstcellvoltwarn  = "/SOUNDS/en/lwstcellvolt.wav"
local wav_lwstcell          = "/SOUNDS/en/lwstcell.wav"

----------------------------------------------------------------------------
-- Script input\output
--
--  input:  [1] Logical switch (i.e. L1)
--          [2] Physical switch (i.e. SH)
--
--  output: [1] Semaphore, indicating if switch is active (100) or not(0)
----------------------------------------------------------------------------
local inputs    = { { "Switch [L]", SOURCE }, { "Switch [S]", SOURCE } }
local outputs   = { "SwOn" }


----------------------------------------------------------------------------
-- NAME        : volt_real_to_int(volt_input_source)
--
-- DESCRIPTION : Splits the real voltage value into two integers (Int1.Int2)
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- INPUTS      : volt_input_source  (Voltage of input source)
--
-- PROCESS     : [1]  get real value of input source
--               [2]  Split real into two integer
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
--               2016-04-07 KS      An input of i.e. 3.5 (with a single digit
--                                  right of point) causes a value of 0.5.
--                                  The announcment then is "zero". Fixed
--                                  with "if value < 1 then value * 10"
----------------------------------------------------------------------------
local function volt_real_to_int(volt_input_source)

	volt_real             = getValue(getFieldInfo(volt_input_source).id)
	volt_int_leftofpoint  = tonumber(string.sub(volt_real, 1, 1))
	volt_int_rightofpoint = tonumber(string.sub(volt_real, -2))

  if volt_int_rightofpoint < 1 then

    volt_int_rightofpoint = volt_int_rightofpoint * 10

  end

end


----------------------------------------------------------------------------
-- NAME        : set_play_next_time()
--
-- DESCRIPTION : Defines the minimum time to next repeat of the warning
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- PROCESS     : [1]  get actual time and add a delay
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
----------------------------------------------------------------------------
local function set_play_next_time()

  play_next_time = getTime() + play_delay

end


----------------------------------------------------------------------------
-- NAME        : play_lowest_cell_voltage()	()
--
-- DESCRIPTION : Combines some sounds with actual voltage values
--               to announce the actual lowest cell voltage.
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- PROCESS     : [1]  play a intro
--               [2]  call function to play volt value
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
--               2016-04-07 KS      Define function input
----------------------------------------------------------------------------
local function play_lowest_cell_voltage(wav_file)

  -- Lowest cell X point Y volts
 	playFile(wav_file)
  playNumber(tonumber(volt_int_leftofpoint), 0)
  playFile("/SOUNDS/en/system/0112.wav")
	playNumber(tonumber(volt_int_rightofpoint), 1)

end


----------------------------------------------------------------------------
-- NAME        : run(trigger)
--
-- DESCRIPTION : If function is triggered (i.e. by logical switch to observe
--							 minimum cell value) it will play a personalized low voltage warning.
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- INPUTS      : trigger  (physical or logical switch)
--
-- PROCESS     : [1]  find out which trigger and check if not active
--               [2]    if next play time
--               [3]      set active
--               [4]      split real volt to integer
--               [5]      play warning by announcing the cell voltage
--               [6]      set next play time
--               [7]    else reset output and set to not active
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
--               2016-04-07 KS      Added logical AND physical switch as input
----------------------------------------------------------------------------
local function run(trigger_LogSw, trigger_PhySw)

  if (trigger_LogSw > 512) or (trigger_PhySw > 512) and not trigger_is_active then

    if getTime() >= play_next_time then

      trigger_is_active = true
      volt_real_to_int(volt_input_source)

      if trigger_LogSw > 512 then  -- if logical switch is active

        play_lowest_cell_voltage(wav_lwstcellvoltwarn)

      elseif trigger_PhySw > 512 then  -- if physical switch is active

        play_lowest_cell_voltage(wav_lwstcell)

      end

      set_play_next_time()

    end

  elseif trigger_LogSw and trigger_PhySw < 512 then

    trigger_is_active     = false
    volt_int_leftofpoint  = 0
    volt_int_rightofpoint = 0

  end

	-- return the trigger_is_active output (100 or 0)
	return (trigger_is_active and 1024 or 0)

end

return { run=run, input=inputs, output=outputs }

