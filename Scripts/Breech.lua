--[[
	Copyright (c) 2022 Questionable Mark
]]

dofile("Databases/BreechDatabase.lua")

Breech = class()
Breech.maxParentCount = 1
Breech.maxChildCount  = 0
Breech.connectionInput  = sm.interactable.connectionType.logic
Breech.connectionOutput = sm.interactable.connectionType.none
Breech.colorNormal    = sm.color.new(0x000080ff)
Breech.colorHighlight = sm.color.new(0x0000edff)

local type_to_func_name =
{
	[1] = "anim_setup",
	[2] = "wait_handler",
	[3] = "effect_handler",
	[4] = "delay_setup"
}

local AnimationUpdateFunctions = {}
AnimationUpdateFunctions.no_animation = function(self, dt) end

AnimationUpdateFunctions.anim_selector = function(self, dt)
	self.anim_step = self.anim_step + 1
	if self.anim_step < self.anim_step_count then
		self.anim_step_data = self.anim_data[self.anim_step]
		local func_name = type_to_func_name[self.anim_step_data.type]

		self.anim_func = AnimationUpdateFunctions[func_name]
		self.anim_func(self, dt)
	else
		self.anim_func = AnimationUpdateFunctions.no_animation
		self.anim_step_data = nil
		self.anim_step = 0
	end
end

AnimationUpdateFunctions.anim_setup = function(self, dt)
	self.anim_time = self.anim_step_data.time

	self.anim_func = AnimationUpdateFunctions.anim_handler
	self.anim_func(self, dt)
end

AnimationUpdateFunctions.anim_handler = function(self, dt)
	local cur_data = self.anim_step_data

	local c_anim_time = cur_data.time

	local predict_time = (self.anim_time - dt)
	local anim_prog = (c_anim_time - math.max(predict_time, 0)) / c_anim_time
	local normalized_val = sm.util.clamp(anim_prog, 0.0, 1.0)
	local final_value = sm.util.lerp(cur_data.start_val, cur_data.end_val, normalized_val)

	local s_interactable = self.interactable
	for i, anim_name in pairs(cur_data.anim) do
		s_interactable:setAnimProgress(anim_name, final_value)
	end

	if self.anim_time then
		self.anim_time = predict_time

		if self.anim_time <= 0 then
			self.anim_time = nil

			self.anim_func = AnimationUpdateFunctions.anim_selector
			self.anim_func(self, dt)
		end
	end
end

AnimationUpdateFunctions.wait_handler = function(self, dt)
	if self.anim_wait_time then
		self.anim_wait_time = self.anim_wait_time - dt

		if self.anim_wait_time <= 0.0 then
			self.anim_wait_time = nil

			self.anim_func = AnimationUpdateFunctions.anim_selector
			self.anim_func(self, dt)
		end
	end
end

AnimationUpdateFunctions.effect_handler = function(self, dt)
	local cur_data = self.anim_step_data

	local s_anim_eff = self.anim_effects
	for k, eff_name in ipairs(cur_data.effects) do
		s_anim_eff[eff_name]:start()
	end

	self.anim_func = AnimationUpdateFunctions.anim_selector
	self.anim_func(self, dt)
end

AnimationUpdateFunctions.delay_setup = function(self, dt)
	self.anim_time = self.anim_step_data.time

	self.anim_func = AnimationUpdateFunctions.delay_handler
	self.anim_func(self, dt)
end

AnimationUpdateFunctions.delay_handler = function(self, dt)
	if self.anim_time then
		self.anim_time = self.anim_time - dt

		if self.anim_time <= 0 then
			self.anim_time = nil

			self.anim_func = AnimationUpdateFunctions.anim_selector
			self.anim_func(self, dt)
		end
	end
end



function Breech:client_onCreate()
	local anim_data = mgp_getBreechData(self)

	self.anim_effects = {}
	for effect_name, data in pairs(anim_data.required_effects) do
		local cur_eff = sm.effect.createEffect(data.name, self.interactable, data.bone)
		cur_eff:setOffsetPosition(data.offset)

		self.anim_effects[effect_name] = cur_eff
	end

	local s_interactable = self.interactable
	for k, anim_name in ipairs(anim_data.required_animations) do
		s_interactable:setAnimEnabled(anim_name, true)
	end

	self.anim_duration = 0.0
	for k, step_data in ipairs(anim_data.animation) do
		if step_data.type ~= mgp_anim_enum.wait_timer then
			self.anim_duration = self.anim_duration + (step_data.time or 0)
		end
	end

	self.anim_step = 0
	self.anim_data = anim_data.animation
	self.anim_step_count = #anim_data.animation + 1
	self.anim_func = AnimationUpdateFunctions.no_animation
end

function Breech:client_startAnimation(reloadTime)
	if self.anim_step == 0 then
		self.anim_func = AnimationUpdateFunctions.anim_selector
		self.anim_wait_time = reloadTime
	end
end

function Breech:client_onUpdate(dt)
	self.anim_func(self, dt)
end

function Breech:server_onCreate()
	self.interactable.publicData = {}
end

function Breech:server_checkParent(s_interactable)
	local cur_parent = s_interactable:getSingleParent()
	if cur_parent ~= self.sv_saved_parent then
		self.sv_saved_parent = cur_parent

		if cur_parent then
			if cur_parent.type == "scripted" then
				local p_pub_data = cur_parent.publicData
				if p_pub_data then
					local allowed_ports = p_pub_data.allowedPorts
					if allowed_ports and allowed_ports[tostring(self.shape.uuid)] == true then
						return
					end 
				end
			end

			cur_parent:disconnect(s_interactable)
			self.sv_saved_parent = nil
		end
	end	
end

function Breech:client_onReloadError(min_reload_time)
	sm.gui.displayAlertText(("Breech: Reload time should be at least %.2f seconds (%i ticks)"):format(min_reload_time, min_reload_time * 40))
end

function Breech:server_onFixedUpdate()
	local s_interactable = self.interactable
	local s_pub_data = s_interactable.publicData

	self:server_checkParent(s_interactable)

	if s_pub_data.canShoot then
		s_pub_data.canShoot = false

		local rld_time = s_pub_data.reloadTime or 40
		local final_duration = (rld_time / 40) - self.anim_duration
		if final_duration >= 0 then
			self.network:sendToClients("client_startAnimation", final_duration)
		else
			self.network:sendToClients("client_onReloadError", self.anim_duration)
		end
	end
end