-----------------------------------------------------------------------------
-- This script is build for the Taranis X9D PLUS. It offers the ability to
-- play the lowest cell value of the battery attached to the receiver.
-- To get the the precise value of the lowest cell an additional telemetry
-- module named "FrSky FLVSS LiPo Voltage Sensor With Smart Port" is needed.
-- This module offers the sensor "lowest" which should be used as voltage
-- input sensor for this script.
--
-- To activate the voltage announcement either a logical or a hardware switch
-- can be used and selected as switch input for this script.
--
-- Depending on which switch is used the voltage announcement includes an
-- additional warning text or not.
--
-- Version: 1.01
--
-- (c) 2016 Kai Schmitz, Velbert, Germany (schmitz.kai@me.com)
--
-- License: MIT, see http://choosealicense.com/licenses/mit/
-----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Do some Init's
----------------------------------------------------------------------------
local switch_status                     = false
local logical_switch_is_active          = false
local physical_switch_is_active         = true
local switch_logic_on_position          = 1024 -- (off 0 | on 1024)
local switch_2pos_on_position           = 1024 -- (SW↑ 0 | SW↓ 1024)
local switch_3pos_on_position           = 1024 -- (SW↑ -1024 | SW- 0 | SW↓ 1024)
local volt_pre_delimiter                = 0
local volt_post_delimiter_digits_count  = 0
local volt_post_delimiter_first_digit   = 0
local volt_post_delimiter_second_digit  = 0
local play_next_time                    = 0
local play_delay                        = 1500
local wav_lwstcellvoltzero              = "/SOUNDS/en/batfault.wav"
local wav_lwstcellvoltcritical          = "/SOUNDS/en/lwstcvcrit.wav"
local wav_lwstcellwarn                  = "/SOUNDS/en/lwstcellwrn.wav"
local wav_lwstcell                      = "/SOUNDS/en/lwstcell.wav"
local wav_delimiter                     = "/SOUNDS/en/system/0112.wav"

----------------------------------------------------------------------------
-- Script input/output
--
--  input:  [1] Telemetry sensor (i.e. Cmin)
--          [2] Logical switch (i.e. L1)
--          [3] Physical 2 way switch (i.e. SH)
--              or
--          [4] Physical 3 way switch (i.e. SC)
----------------------------------------------------------------------------
local inputs    = { { "Sensor"   , SOURCE },
                    { "SW_logic" , SOURCE },
                    { "SW_2pos"  , SOURCE },
                    { "SW_3pos"  , SOURCE } }


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
-- NAME        : change_volt_float_to_single_digits(sensor_voltage)
--
-- DESCRIPTION : Splits the float voltage value
--               into three integers (= Int1.Int2Int3)
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- INPUTS      : sensor_voltage  (Voltage of input source)
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
local function change_volt_float_to_single_digits(sensor)

  local int_a, int_b = math.modf(sensor)

  volt_pre_delimiter = int_a

  volt_post_delimiter_first_digit  = tonumber(string.sub(round(int_b, 2), 3, 3))
  volt_post_delimiter_second_digit = tonumber(string.sub(round(int_b, 2), 4, 4))

end


----------------------------------------------------------------------------
-- NAME        : get_volt_post_delimiter_digits()
--
-- DESCRIPTION : Checks if digits after volt delimiter are nil
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- OUTPUT      : true/false
--
-- PROCESS     : [1]  checks if second digit after volt delimiter is not nil
--               [2]  checks if first digit after volt delimiter is not nil
--               [3]  returns zero if both digit after volt delimiter are nil
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-21 KS      Original Code
--               2016-05-11 KS      Improve check and return behavior
----------------------------------------------------------------------------
local function get_volt_post_delimiter_digits()

  if (volt_post_delimiter_second_digit ~= nil) then

    return 2

  elseif (volt_post_delimiter_first_digit ~= nil) then

    return 1

  else

    return 0

  end

end


----------------------------------------------------------------------------
-- NAME        : play_voltage()
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
--               2016-04-26 KS      Remove the combined value announcement
--                                  after delimiter
--               2016-04-15 KS      Value announcement now even when logical
--                                  and physical switch is active
----------------------------------------------------------------------------
local function play_voltage()

  volt_post_delimiter_digits_count = get_volt_post_delimiter_digits()

  if (volt_pre_delimiter == 0) or (volt_pre_delimiter == nil) then

    playFile(wav_lwstcellvoltzero)

  elseif (volt_pre_delimiter > 0) then

    if logical_switch_is_active and not physical_switch_is_active then

      playFile(wav_lwstcellvoltcritical)

    elseif logical_switch_is_active and physical_switch_is_active then

      playFile(wav_lwstcellwarn)

    elseif not logical_switch_is_active and physical_switch_is_active then

      playFile(wav_lwstcell)

    end

    if (volt_post_delimiter_digits_count == 0) then

      playNumber(volt_pre_delimiter, 1)

    else

      playNumber(volt_pre_delimiter, 0)

    end

    if (volt_post_delimiter_digits_count ~= 0) then

      playFile(wav_delimiter)

      if (volt_post_delimiter_digits_count == 2) then

        -- If the value after delimiter has 2 digits and the first number zero,
        -- the value should be announced divided into single numbers.
        -- Example: 4.[05] Volts = announcing: zero, fife
        playNumber(volt_post_delimiter_first_digit, 0)
        playNumber(volt_post_delimiter_second_digit, 1)

      elseif (volt_post_delimiter_digits_count == 1) then

        -- If the value after delimiter has no second digit (=nil),
        -- the value should be announced as single digit number.
        playNumber(volt_post_delimiter_first_digit, 1)

      end

    end

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
-- NAME        : time_to_play()
--
-- DESCRIPTION : Checks if the delay time between to announces is still
--               active or not
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- PROCESS     : [1]  checks if delay is over
--               [2]  initiates setup of next playtime
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-30 KS      Original Code
----------------------------------------------------------------------------
local function time_to_play()

  if getTime() >= play_next_time then

    set_play_next_time()
    return true

  else

    return false

  end

end


----------------------------------------------------------------------------
-- NAME        : switch_is_active(switch_logic, switch_2pos, switch_3pos)
--
-- DESCRIPTION : Checks if one of the possible input switches is active
--
-- Author      : Kai Schmitz (KS), Velbert, Germany
--
-- INPUTS      : switch_logic (Voltage of logical input switch)
--               switch_2pos  (Voltage of 2 way input switch)
--               switch_3pos  (Voltage of 3 way input switch)
--
-- PROCESS     : [1]  checks if one switch is active
--               [2]  set semaphore if the logic switch is active
--               [3]  returns if a switch is active or not
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-30 KS      Original Code
--               2016-05-15 KS      Correction of return statements, now
--                                  switches always stay on
----------------------------------------------------------------------------
local function switch_is_active(switch_logic, switch_2pos, switch_3pos)

  if (switch_logic == switch_logic_on_position) then

    logical_switch_is_active  = true

  else

    logical_switch_is_active  = false

  end

  if (switch_2pos  == switch_2pos_on_position) or
     (switch_3pos  == switch_3pos_on_position) then

    physical_switch_is_active = true

  else

    physical_switch_is_active = false

  end

  if not (logical_switch_is_active or physical_switch_is_active) then

    return false

  else

    return true

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
-- PROCESS     : [1]  checks if switch is active and the play delay is over
--               [2]  processing the sensor voltage into pronounceable values
--               [3]  announce t the sensor value
--
-- CHANGES     : DATE       AUTHOR  DETAIL
--               2016-04-06 KS      Original Code
--               2016-04-07 KS      Added logical AND physical switch as input
--               2016-04-30 KS      Complete redesign of this script
----------------------------------------------------------------------------
local function run(sensor, switch_logic, switch_2pos, switch_3pos)

  if switch_is_active(switch_logic, switch_2pos, switch_3pos) and time_to_play() then

    change_volt_float_to_single_digits(sensor)
    play_voltage()

  end

end

return { run=run, input=inputs }

