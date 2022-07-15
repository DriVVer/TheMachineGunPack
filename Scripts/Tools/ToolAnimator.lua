dofile("$CONTENT_DATA/Scripts/Databases/ToolDatabase.lua")

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
	self.cl_animator_step = self.cl_animator_step + 1
	if self.cl_animator_step < self.cl_animator_step_count then
		self.cl_animator_step_data = self.cl_animator_data[self.cl_animator_step]
		local func_name = type_to_func_name[self.cl_animator_step_data.type]

		self.cl_animator_func = AnimationUpdateFunctions[func_name]
		self.cl_animator_func(self, dt)
	end
end

AnimationUpdateFunctions.anim_setup = function(self, dt)
	self.cl_animator_time = self.cl_animator_step_data.time

	self.cl_animator_func = AnimationUpdateFunctions.anim_handler
	self.cl_animator_func(self, dt)
end

AnimationUpdateFunctions.anim_handler = function(self, dt)
	local cur_data = self.cl_animator_step_data
	local c_anim_time = cur_data.time

	local predict_time = (self.cl_animator_time - dt)
	
	local anim_prog = 0.0
	if c_anim_time > 0 then
		anim_prog = (c_anim_time - math.max(predict_time, 0)) / c_anim_time
	end

	local normalized_val = sm.util.clamp(anim_prog, 0.0, 1.0)
	local final_value = sm.util.lerp(cur_data.start_val, cur_data.end_val, normalized_val)

	local s_tool = self.tool
	if s_tool:isInFirstPersonView() then
		for k, anim_name in ipairs(cur_data.fp_anim) do
			s_tool:updateFpAnimation(anim_name, final_value, 1.0)
		end
	else
		for k, anim_name in pairs(cur_data.tp_anim) do
			s_tool:updateAnimation(anim_name, final_value, 1.0)
		end
	end

	if self.cl_animator_time then
		self.cl_animator_time = predict_time

		if self.cl_animator_time <= 0 then
			self.cl_animator_time = nil

			self.cl_animator_func = AnimationUpdateFunctions.anim_selector
			self.cl_animator_func(self, dt)
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

local debri_color = sm.color.new(0x000000ff)
AnimationUpdateFunctions.debris_handler = function(self, dt)
	local cur_data = self.anim_step_data

	--Calculate direction
	local bone_name = cur_data.bone
	local tracked_bone = self.bone_tracker[bone_name]
	local debri_pos = self.interactable:getWorldBonePosition(bone_name)
	local dir_calc  = self.interactable:getWorldBonePosition(bone_name.."_end")
	local direction = (debri_pos - dir_calc):normalize()

	--Calculate rotation
	local debri_rot_local = sm.vec3.getRotation(-self.shape.at, direction)
	local debri_rot = debri_rot_local * self.shape.worldRotation

	--Calculate other things
	local debri_time = math.random(2, 15)
	local debri_offset = debri_rot * cur_data.offset
	local debri_pos_final = debri_pos + debri_offset
	local world_vel = (debri_rot * tracked_bone.vel) + self.shape.velocity
	local world_ang_vel = debri_rot * tracked_bone.angular_vel

	sm.debris.createDebris(cur_data.uuid, debri_pos_final, debri_rot, world_vel, world_ang_vel, debri_color, debri_time)

	self.anim_func = AnimationUpdateFunctions.anim_selector
	self.anim_func(self, dt)
end

function mgp_toolAnimator_update(self, dt)
	self.cl_animator_func(self, dt)
end

function mgp_toolAnimator_setAnimation(self, anim_name)
	local anim_data = self.cl_animator_animations[anim_name]

	self.cl_animator_data = anim_data
	self.cl_animator_step = 0
	self.cl_animator_step_count = #anim_data + 1

	self.cl_animator_func = AnimationUpdateFunctions.anim_selector
end

function mgp_toolAnimator_initialize(self, tool_name)
	local anim_data = mgp_getToolData(tool_name)

	self.cl_animator_step = 0
	self.cl_animator_animations = anim_data.animation

	self.cl_animator_func = AnimationUpdateFunctions.no_animation
end