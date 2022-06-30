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
	[4] = "delay_setup",
	[5] = "debris_handler"
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
	
	local anim_prog = 0.0
	if c_anim_time > 0 then
		anim_prog = (c_anim_time - math.max(predict_time, 0)) / c_anim_time
	end

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

AnimationUpdateFunctions.debris_handler = function(self, dt)
	local cur_data = self.anim_step_data

	--self.bone_tracker
	local tracked_bone = self.bone_tracker[cur_data.bone]
	local debri_pos = self.interactable:getWorldBonePosition(cur_data.bone)
	local dir_calc  = self.interactable:getWorldBonePosition(cur_data.bone_end)

	local direction = (debri_pos - dir_calc):normalize()

	local debri_rot_local = sm.vec3.getRotation(-self.shape.at, direction)
	local debri_rot = debri_rot_local * self.shape.worldRotation
	local debri_offset = debri_rot * cur_data.offset

	local debri_time = math.random(2, 15)
	sm.debris.createDebris(cur_data.uuid, debri_pos + debri_offset, debri_rot, tracked_bone.vel, sm.vec3.zero(), sm.color.new(0x000000ff), debri_time)

	self.anim_func = AnimationUpdateFunctions.anim_selector
	self.anim_func(self, dt)
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

	--Create bone tracker
	local bone_tracker_tmp = {}
	for k, v in ipairs(anim_data.bone_tracker or {}) do
		bone_tracker_tmp[v] =
		{
			pos = self.interactable:getWorldBonePosition(v),
			vel = sm.vec3.zero(),
			angular_vel = sm.vec3.zero(),
			angles = {0, 0},
			b_end = v.."_end"
		}
	end

	self.bone_tracker = bone_tracker_tmp
end

function Breech:client_startAnimation(reloadTime)
	if self.anim_step == 0 then
		self.anim_func = AnimationUpdateFunctions.anim_selector
		self.anim_wait_time = reloadTime
	end
end

function Breech:client_onUpdate(dt)
	--Trach bone velocity and angular velocity
	local s_interactable = self.interactable
	for k, b_data in pairs(self.bone_tracker) do
		local prev_pos = b_data.pos
		local new_pos = s_interactable:getWorldBonePosition(k)
		local b_end_pos = s_interactable:getWorldBonePosition(b_data.b_end)
		local b_dir = (new_pos - b_end_pos):normalize()

		local prev_angles = b_data.angles
		local new_pitch = math.asin(b_dir.z)
		local new_yaw = math.atan2(b_dir.y, b_dir.x) - math.pi / 2

		local new_ang_vel = sm.vec3.new(
			(new_pitch - prev_angles[1]) / dt,
			0,
			(new_yaw - prev_angles[2]) / dt
		)

		self.bone_tracker[k] =
		{
			pos = new_pos,
			vel = (new_pos - prev_pos) / dt,
			angular_vel = new_ang_vel,
			angles = { new_pitch, new_yaw },
			b_end = b_data.b_end
		}
	end

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