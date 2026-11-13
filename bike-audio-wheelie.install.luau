-- Run in the Studio Command Bar after installing EngineAudio and RiderPose.
local controller = game.StarterPlayer.StarterPlayerScripts.TwoStrokeClient.BikeController
local edits = {
    {[==[local Drivetrain = require(Shared.Sim.Drivetrain)]==], [==[local Drivetrain = require(Shared.Sim.Drivetrain)
local EngineAudio = require(script.Parent.EngineAudio)]==]},
    {[==[	hud.running = es.running]==], [==[	hud.running = es.running
	EngineAudio.update(dt, hud.rpm, input.throttle, es.running, st.gear)]==]},
    {[==[		Engine.kick(s.drivetrain.engine, st.engine)]==], [==[		Engine.kick(s.drivetrain.engine, st.engine)
		EngineAudio.kick()]==]},
    {[==[	Controller.active = true]==], [==[	EngineAudio.start(primary)
	Controller.active = true]==]},
    {[==[function Controller.stop()
]==], [==[function Controller.stop()
	EngineAudio.stop()
]==]},
    {[==[			local newRate = math.clamp((pitchRate + alpha * dt) * math.exp(-1.5 * dt), -2.2, 1.6)]==], [==[			-- Ease into the balance window under power. Above the window the
			-- rider must release throttle or use the rear brake to recover.
			local ceiling = if pitch < math.rad(49) then math.max(0.10, (math.rad(46) - pitch) * 3) else 1.6
			local newRate = math.clamp((pitchRate + alpha * dt) * math.exp(-1.5 * dt), -2.2, ceiling)]==]},
}
game:GetService("ScriptEditorService"):UpdateSourceAsync(controller, function(source)
    for _, edit in edits do
        if source:find(edit[2], 1, true) then continue end
        local first, last = source:find(edit[1], 1, true)
        assert(first and not source:find(edit[1], last + 1, true), "Unexpected BikeController source")
        source = source:sub(1, first - 1) .. edit[2] .. source:sub(last + 1)
    end
    return source
end)
