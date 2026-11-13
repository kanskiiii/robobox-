-- Client-side sound for the currently controlled bike.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = {}
local bands = {1500, 5000, 8000, 10500}
local clips = {}
local motor
local lastGear = 0
local wasRunning = false

function Audio.stop()
    if motor then motor:Destroy() end
    motor = nil
    table.clear(clips)
end

function Audio.start(chassis)
    Audio.stop()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local source = assets and assets:FindFirstChild("Audio")
    if not source then return end
    motor = Instance.new("Attachment")
    motor.Name = "TwoStrokeEngineAudio"
    motor.Parent = chassis
    lastGear, wasRunning = 0, false
    for _, item in source:GetChildren() do
        if item:IsA("Sound") and item.Name:sub(1, 6) == "zefir_" then
            local sound = item:Clone()
            sound.RollOffMinDistance = 4
            sound.RollOffMaxDistance = 70
            if sound.Looped then sound.Volume = 0 end
            sound.Parent = motor
            clips[sound.Name:sub(7)] = sound
        end
    end
end

local function oneShot(name)
    local sound = clips[name]
    if sound then sound.TimePosition = 0 sound:Play() end
end

function Audio.kick()
    oneShot("kickstart")
end

function Audio.update(dt, rpm, load, running, gear)
    if not motor then return end
    if lastGear ~= gear then oneShot("gear_clunk") end
    if wasRunning and not running then oneShot("stall") end
    lastGear, wasRunning = gear, running
    local low, high = 1, 1
    for i = 2, #bands do
        high = i
        if rpm <= bands[i] then break end
        low = i
    end
    local mix = low == high and 0 or math.clamp((rpm-bands[low])/(bands[high]-bands[low]), 0, 1)
    local blend = 1-math.exp(-dt*18)
    load = math.clamp(load, 0, 1)
    for i, band in bands do
        local weight = (i == low and 1-mix or 0) + (i == high and mix or 0)
        for _, suffix in {"off", "on"} do
            local sound = clips[tostring(band) .. "_" .. suffix]
            if sound then
                local target = running and .42*weight*(suffix == "on" and load or 1-load) or 0
                sound.PlaybackSpeed = math.clamp(rpm/band, .65, 1.45)
                sound.Volume += (target-sound.Volume)*blend
                if target > .002 and not sound.IsPlaying then sound:Play() end
                if target == 0 and sound.Volume < .001 and sound.IsPlaying then sound:Stop() end
            end
        end
    end
end

return Audio
