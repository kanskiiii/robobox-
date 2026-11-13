-- Run in the Studio Command Bar in Edit mode to apply the riding controls.
local client = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient
local scriptEditor = game:GetService("ScriptEditorService")
local changes = {
    [client.BikeController] = {
        {[==[	input.clutch = approach(input.clutch, math.max(if down(Enum.KeyCode.LeftControl) then 1 else 0, padClutch), 10, 1.6)]==],
         [==[	input.clutch = approach(input.clutch, math.max(if down(Enum.KeyCode.LeftShift) or down(Enum.KeyCode.RightShift) then 1 else 0, padClutch), 10, 1.6)]==]},
        {[==[	-- Shift: rider throws his weight back and pulls on the bars (wheelies)]==],
         [==[	-- Ctrl: rider throws his weight back and pulls on the bars (wheelies)]==]},
        {[==[	local wantBack = math.max(if down(Enum.KeyCode.LeftShift) then 1 else 0, padWheelie)]==],
         [==[	local wantBack = math.max(if down(Enum.KeyCode.LeftControl) or down(Enum.KeyCode.RightControl) then 1 else 0, padWheelie)]==]},
        {[==[	-- Wheelies (Shift = lean back). One smooth model, pivoting on the rear tyre:]==],
         [==[	-- Wheelies (Ctrl = lean back). One smooth model, pivoting on the rear tyre:]==]},
        {[==[	--           (first gear near peak revs or a clutch pop: yes; fourth gear: no), more with Shift held]==],
         [==[	--           (first gear near peak revs or a clutch pop: yes; fourth gear: no), more with Ctrl held]==]},
        {[==[	Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl, Enum.KeyCode.X,]==],
         [==[	Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.X,]==]},
        {[==[			st.engine.lastFault = "in gear: pull the clutch (Ctrl) or find neutral (Q)"]==],
         [==[			st.engine.lastFault = "in gear: pull the clutch (Shift) or find neutral (Q)"]==]},
    },
    [client.Hud] = {
        {[==[	local help = Ui.label("W throttle  S brakes  X rear brake  A/D lean  Ctrl clutch  Shift weight back (wheelie)  E/Q gear  I ignition  C choke  K kick  Space get off",]==],
         [==[	local help = Ui.label("W throttle  S brakes  X rear brake  A/D lean  Shift clutch  Ctrl wheelie  E/Q gear  I ignition  C choke  K kick  Space get off",]==]},
    },
    [client.Main] = {
        {[==[		toast("Ignition I, choke C (cold engine), kickstart K. Pull the clutch (Ctrl), click into first (E) and ease it out. Shift throws your weight back.", "info")]==],
         [==[		toast("Ignition I, choke C (cold engine), kickstart K. Pull the clutch (Shift), click into first (E) and ease it out. Ctrl throws your weight back.", "info")]==]},
    },
}

local updated = {}
for target, edits in changes do
    local source = scriptEditor:GetEditorSource(target)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected source in " .. target:GetFullName())
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    updated[target] = source
end

for target, source in updated do
    scriptEditor:UpdateSourceAsync(target, function()
        return source
    end)
end
