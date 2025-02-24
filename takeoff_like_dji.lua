-- Command a Copter to takeoff to 1m and switch to Loiter mode
--
-- CAUTION: This script only works for Copter
-- This script waits for the vehicle to be armed and RC6 input > 1800 and then:
--    a) switches to Guided mode
--    b) takes off to 1m
--    c) switches to Loiter mode

local takeoff_alt_above_home = 1
local copter_guided_mode_num = 4
local copter_loiter_mode_num = 5
local stage = 0

-- Main update function
function update()
  if not arming:is_armed() then -- Reset state when disarmed
    stage = 0
  else
    pwm6 = rc:get_pwm(6)
    if pwm6 and pwm6 > 1800 then    -- Check if RC6 input has moved high
      if stage == 0 then            -- Stage 0: Change to Guided mode
        if vehicle:set_mode(copter_guided_mode_num) then
          stage = stage + 1
        end
      elseif stage == 1 then        -- Stage 1: Takeoff
        gcs:send_text(0, "Takeoff liek DJI using Lua-Script")
        if vehicle:start_takeoff(takeoff_alt_above_home) then
          stage = stage + 1
        end
      elseif stage == 2 then        -- Stage 2: Check if vehicle has reached target altitude
        local home = ahrs:get_home()
        local curr_loc = ahrs:get_location()
        if home and curr_loc then
          local vec_from_home = home:get_distance_NED(curr_loc)
          gcs:send_text(0, "alt above home: " .. tostring(math.floor(-vec_from_home:z())))
          if math.abs(takeoff_alt_above_home + vec_from_home:z()) < 1 then
            stage = stage + 1
          end
        end
      elseif stage == 3 then        -- Stage 3: Switch to Loiter mode
        if vehicle:set_mode(copter_loiter_mode_num) then
          gcs:send_text(0, "Reached target altitude, switching to Loiter mode")
          stage = stage + 1
        end
      end
    end
  end

  return update, 100
end

return update()