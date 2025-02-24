-- Dynamic Altitude Control: Switch between Rangefinder and Barometer based on RC input
-- Uses barometer during RC movement and rangefinder when stationary

local rangefinder_threshold = 10   -- Max reliable range of rangefinder in meters
local rc_input_threshold = 100     -- RC input threshold to detect movement
local baro_mode = 0
local rangefinder_mode = 1
local active_mode = baro_mode

-- Function to check RC stick movement
function is_rc_moving()
    local roll = rc:get_pwm(1)
    local pitch = rc:get_pwm(2)
    local throttle = rc:get_pwm(3)
    local yaw = rc:get_pwm(4)

    -- Check if any stick input is beyond the neutral zone
    return (math.abs(roll - 1500) > rc_input_threshold) or
           (math.abs(pitch - 1500) > rc_input_threshold) or
           -- (math.abs(throttle - 1500) > rc_input_threshold) or
           (math.abs(yaw - 1500) > rc_input_threshold)
end

function update()
    local rangefinder_dist = rangefinder:distance_cm() / 100  -- Convert to meters
    local baro_alt = ahrs:get_relative_altitude()             -- Altitude from barometer

    if is_rc_moving() then
        -- Use barometer when RC input is detected
        if active_mode ~= baro_mode then
            gcs:send_text(0, "RC input detected, switching to Barometer mode")
            active_mode = baro_mode
        end
        vehicle:set_target_altitude(baro_alt)
    else
        -- Use rangefinder when stationary
        if rangefinder_dist > 0 and rangefinder_dist < rangefinder_threshold then
            if active_mode ~= rangefinder_mode then
                gcs:send_text(0, "No RC input, switching to Rangefinder mode")
                active_mode = rangefinder_mode
            end
            vehicle:set_target_altitude(rangefinder_dist)
        else
            -- Fallback to barometer if rangefinder is out of range
            vehicle:set_target_altitude(baro_alt)
        end
    end

    return update, 100  -- Run every 100ms
end

return update()