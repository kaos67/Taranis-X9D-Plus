----------------------------------------------------------------------------
-- Do some Init's
----------------------------------------------------------------------------
local trigger_is_active                   = false
local volt_input_source                   = "Cmin"
local volt_pre_delimiter                  = 0
local volt_post_delimiter                 = 0
local volt_post_delimiter_first_digit     = 0
local volt_post_delimiter_second_digit    = 0
local play_next_time                      = 0
local play_delay                          = 500
local wav_lwstcellvoltwarn                = "/SOUNDS/en/lwstcellvolt.wav"
local wav_lwstcell                        = "/SOUNDS/en/lwstcell.wav"
local wav_delimiter                       = "/SOUNDS/en/system/0112.wav"

----------------------------------------------------------------------------
-- Script input/output
--
--  input:  [1] Logical switch (i.e. L1)
--          [2] Physical switch (i.e. SH)
--
--  output: [1] Semaphore, indicating if switch is active (100) or not(0)
----------------------------------------------------------------------------
local inputs    = { { "Switch [L]", SOURCE }, { "Switch [S]", SOURCE } }
local outputs   = { "SwOn" }


----------------------------------------------------------------------------
-- NAME        : round(num, idp)
--
-- DESCRIPTION : Splits the float voltage value 
--               into three integers (= Int1.Int2Int3)
--
-- Author      : http://lua-users.org/wiki/SimpleRound
--
-- INPUTS      : round(number, number of digital places)
--
-- OUTPUT      : rounded number
--
-- PROCESS     : [1]  get float value of input source
--               [2]  Split float into three integer
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-21 KS      Original Code
----------------------------------------------------------------------------
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


----------------------------------------------------------------------------
-- NAME        : volt_float_to_single_int(volt_input_source)
--
-- DESCRIPTION : Splits the float voltage value 
--               into three integers (= Int1.Int2Int3)
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- INPUTS      : volt_input_source  (Voltage of input source)
--
-- PROCESS     : [1]  get float value of input source
--               [2]  Split float into three integer
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
--               2016-04-07 KS      An input of i.e. 3.5 (with a single digit
--                                  right of point) causes a value of 0.5.
--                                  The announcment then is "zero". Fixed
--                                  with "if value < 1 then value * 10"
--               2016-04-21 KS      Change calulation of values before and 
--                                  after delimiter to get the right values
--                                  i.e. at 3.05 Volts 
----------------------------------------------------------------------------
local function volt_float_to_single_int(volt_input_source)

  local int_a, int_b = math.modf(getValue(getFieldInfo(volt_input_source).id))

  volt_pre_delimiter = int_a
  print("*** int_b: " .. round(int_b, 2))
  volt_post_delimiter_first_digit = tonumber(string.sub(round(int_b, 2), 3, 3))
  volt_post_delimiter_second_digit = tonumber(string.sub(round(int_b, 2), 4, 4))
  print("*** volt_post_delimiter_first_digit: " .. volt_post_delimiter_first_digit)
  print("*** volt_post_delimiter_second_digit: " .. volt_post_delimiter_second_digit)
end


----------------------------------------------------------------------------
-- NAME        : volt_post_delimiter_has_2_digits()
--
-- DESCRIPTION : Checks if second digit after volt delimiter is nil
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- OUTPUT      : true/false
--
-- PROCESS     : [1]  checks if second digit after volt delimiter is nil
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-21 KS      Original Code
----------------------------------------------------------------------------
local function volt_post_delimiter_has_2_digits()

  if (volt_post_delimiter_second_digit == nil) then 
  
    return false
      
  else 
  
    return true

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
-- NAME        : announce_lowest_cell_voltage()	()
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
--               2016-04-07 KS      Create function input as path to wav file
--               2016-04-21 KS      Rename function, add announcement for 
--                                  first and second digit after delimiter
----------------------------------------------------------------------------
local function announce_lowest_cell_voltage(wav_warning)

  playFile(wav_warning)
  playNumber(volt_pre_delimiter, 0)
  playFile(wav_delimiter)
  
  if volt_post_delimiter_has_2_digits() then


	if (volt_post_delimiter_first_digit == 0) then
      
	  -- If the value after delimiter has 2 digits and the first number zero, 
	  -- the value should be announced divided into single numbers.
	  -- Example: 4.[05] Volts = announcing: zero, fife
      playNumber(volt_post_delimiter_first_digit, 0)
      playNumber(volt_post_delimiter_second_digit, 1)
	
	else
	
	  -- If the value after delimiter has 2 digits and the first number is not zero, 
	  -- the value should be announced as combined 2 digit number.
	  -- Example: 4.[18] Volts = announcing: eighteen
	  playNumber(volt_post_delimiter_first_digit .. volt_post_delimiter_second_digit, 1)
	
	end
  
  else

    -- If the value after delimiter has no second digit (=nil), 
	-- the value should be announced as combined 2 digit number. 
	-- Therefore it has to be filled up with zero at second digit. 
	-- Example: 4.[2] Volts = announcing: twenty ([2]&0)
    playNumber(volt_post_delimiter_first_digit .. 0, 1)
  
  end

end


----------------------------------------------------------------------------
-- NAME        : run(trigger)
--
-- DESCRIPTION : If function is triggered (i.e. by logical switch to observe
--               minimum cell value) it will play a personalized low voltage 
--               warning.
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
      volt_float_to_single_int(volt_input_source)

      if trigger_LogSw > 512 then  -- if logical switch is active

        announce_lowest_cell_voltage(wav_lwstcellvoltwarn)

      elseif trigger_PhySw > 512 then  -- if physical switch is active

        announce_lowest_cell_voltage(wav_lwstcell)

      end

      set_play_next_time()

    end

  elseif trigger_LogSw and trigger_PhySw < 512 then

    trigger_is_active                = false
    volt_pre_delimiter               = 0
    volt_post_delimiter              = 0
    volt_post_delimiter_first_digit  = 0
    volt_post_delimiter_second_digit = 0

  end

	-- return the trigger_is_active output (100 or 0)
	return (trigger_is_active and 1024 or 0)

end

return { run=run, input=inputs, output=outputs }

