-- Picom animation script for GNOME-like workspace switching
-- Place this in ~/.config/picom/animations.lua or reference it in picom.conf

local workspace_direction = 0  -- -1 for left, 1 for right, 0 for no animation

-- Track current desktop to determine direction
local current_desktop = 0

-- Animation settings
local animation_duration = 0.3  -- Duration in seconds
local animation_curve = "ease-out-cubic"

-- Handle desktop change events
function on_desktop_change(old_desktop, new_desktop)
    if new_desktop > old_desktop then
        workspace_direction = 1  -- Moving to higher desktop (slide right to left)
    elseif new_desktop < old_desktop then
        workspace_direction = -1  -- Moving to lower desktop (slide left to right)
    else
        workspace_direction = 0
    end
    current_desktop = new_desktop
end

-- Window show animation (new workspace coming in)
function window_show_anim(win)
    if workspace_direction == 0 then
        return nil
    end
    
    -- New windows slide in from the direction we're moving toward
    local start_offset = workspace_direction * win.width
    
    return {
        duration = animation_duration,
        curve = animation_curve,
        props = {
            {
                property = "offset-x",
                from = start_offset,
                to = 0
            },
            {
                property = "opacity",
                from = 1.0,
                to = 1.0
            }
        }
    }
end

-- Window hide animation (old workspace going out)
function window_hide_anim(win)
    if workspace_direction == 0 then
        return nil
    end
    
    -- Old windows slide out in the direction we're moving
    local end_offset = workspace_direction * win.width
    
    return {
        duration = animation_duration,
        curve = animation_curve,
        props = {
            {
                property = "offset-x",
                from = 0,
                to = end_offset
            },
            {
                property = "opacity",
                from = 1.0,
                to = 1.0
            }
        }
    }
end

-- Optional: Add smooth transitions for other events
function window_open_anim(win)
    return {
        duration = 0.2,
        curve = "ease-out-cubic",
        props = {
            {
                property = "opacity",
                from = 0.0,
                to = 1.0
            },
            {
                property = "scale-x",
                from = 0.9,
                to = 1.0
            },
            {
                property = "scale-y",
                from = 0.9,
                to = 1.0
            }
        }
    }
end

function window_close_anim(win)
    return {
        duration = 0.2,
        curve = "ease-in-cubic",
        props = {
            {
                property = "opacity",
                from = 1.0,
                to = 0.0
            },
            {
                property = "scale-x",
                from = 1.0,
                to = 0.9
            },
            {
                property = "scale-y",
                from = 1.0,
                to = 0.9
            }
        }
    }
end

-- Reset direction after animation completes
function on_animation_complete()
    workspace_direction = 0
end
