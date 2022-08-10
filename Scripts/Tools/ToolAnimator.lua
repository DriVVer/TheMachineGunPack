dofile("$CONTENT_DATA/Scripts/Databases/ToolDatabase.lua")

local type_to_func_name =
{
	[1] = "anim_setup",
	[2] = "effect_handler",
	[3] = "delay_setup",
	[4] = "debris_handler",
	[5] = "particle_handler",
	[6] = "renderable_handler"
}

local AnimationUpdateFunctions = {}
AnimationUpdateFunctions.no_animation = function(self, track, dt) end

AnimationUpdateFunctions.anim_selector = function(self, track, dt)
	track.step = track.step + 1
	if track.step < track.step_count then
		track.step_data = track.data[track.step]
		local func_name = type_to_func_name[track.step_data.type]

		track.func = AnimationUpdateFunctions[func_name]
		track.func(self, track, dt)
	end
end

AnimationUpdateFunctions.anim_setup = function(self, track, dt)
	track.time = track.step_data.time

	track.func = AnimationUpdateFunctions.anim_handler
	track.func(self, track, dt)
end

local _sm_util_clamp = sm.util.clamp
local _sm_util_lerp = sm.util.lerp
AnimationUpdateFunctions.anim_handler = function(self, track, dt)
	local cur_data = track.step_data
	local c_anim_time = cur_data.time

	local predict_time = (track.time - dt)
	
	local anim_prog = 0.0
	if c_anim_time > 0 then
		anim_prog = (c_anim_time - math.max(predict_time, 0)) / c_anim_time
	end

	local normalized_val = _sm_util_clamp(anim_prog, 0.0, 1.0)

	local s_tool = self.tool
	if s_tool:isInFirstPersonView() then
		for k, anim_data in ipairs(cur_data.fp_anim) do
			local anim_val = _sm_util_lerp(anim_data.start_val, anim_data.end_val, normalized_val)
			s_tool:updateFpAnimation(anim_data.name, anim_val, 1.0)
		end
	else
		for k, anim_data in pairs(cur_data.tp_anim) do
			local anim_val = _sm_util_lerp(anim_data.start_val, anim_data.end_val, normalized_val)
			s_tool:updateAnimation(anim_data.name, anim_val, 1.0)
		end
	end

	if track.time then
		track.time = predict_time

		if track.time <= 0 then
			track.time = nil

			track.func = AnimationUpdateFunctions.anim_selector
			track.func(self, track, dt)
		end
	end
end

AnimationUpdateFunctions.effect_handler = function(self, track, dt)
	local cur_data = track.step_data

	local s_tool = self.tool
	if s_tool:isEquipped() then
		local cur_effect
		local effect_pos
		local effect_dir
		local effect_offset

		local cur_bone = cur_data.bone
		if sm.localPlayer.isInFirstPersonView() and s_tool:isLocal() then
			cur_effect = self.cl_animator_effects[cur_data.name_fp]
			effect_pos = s_tool:getFpBonePos(cur_bone)
			effect_dir = s_tool:getTpBoneDir(cur_bone)
			effect_offset = cur_data.fp_offset
		else
			cur_effect = self.cl_animator_effects[cur_data.name_tp]
			effect_pos = s_tool:getTpBonePos(cur_bone)
			effect_dir = sm.localPlayer.getDirection()
			effect_offset = cur_data.tp_offset
		end

		effect_offset = sm.camera.getRotation() * effect_offset

		cur_effect:setPosition(effect_pos + effect_offset)
		cur_effect:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, 1), effect_dir))
		if cur_data.apply_velocity then
			cur_effect:setVelocity(s_tool:getMovementVelocity())
		end

		cur_effect:start()
	end

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end

AnimationUpdateFunctions.delay_setup = function(self, track, dt)
	track.time = track.step_data.time

	track.func = AnimationUpdateFunctions.delay_handler
	track.func(self, track, dt)
end

AnimationUpdateFunctions.delay_handler = function(self, track, dt)
	if track.time then
		track.time = track.time - dt

		if track.time <= 0 then
			track.time = nil

			track.func = AnimationUpdateFunctions.anim_selector
			track.func(self, track, dt)
		end
	end
end

local debri_color = sm.color.new(0x000000ff)
AnimationUpdateFunctions.debris_handler = function(self, track, dt)
	local cur_data = track.step_data

	local debri_pos = nil

	local s_tool = self.tool
	if s_tool:isInFirstPersonView() then
		debri_pos = s_tool:getFpBonePos(cur_data.bone_name)
	else
		debri_pos = s_tool:getTpBonePos(cur_data.bone_name)
	end

	sm.debris.createDebris(cur_data.uuid, debri_pos, sm.quat.identity())

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end

---@class ParticleHandlerTrack
---@field fp_offset Vec3
---@field tp_offset Vec3
---@field name_fp string
---@field name_tp string
---@field bone_name string

---@param self ToolClass
AnimationUpdateFunctions.particle_handler = function(self, track, dt)
	---@type ParticleHandlerTrack
	local cur_data = track.step_data

	local s_tool = self.tool
	if s_tool:isEquipped() then
		local particle_pos = nil
		local particle_offset = nil
		local particle_name = nil

		local bone_name = cur_data.bone_name
		if sm.localPlayer.isInFirstPersonView() and s_tool:isLocal() then
			particle_pos = s_tool:getFpBonePos(bone_name)
			particle_offset = cur_data.fp_offset
			particle_name = cur_data.name_fp
		else
			particle_pos = s_tool:getTpBonePos(bone_name)
			particle_offset = cur_data.tp_offset
			particle_name = cur_data.name_tp
		end

		--Calculate rotation quaternion
		local particle_rot = sm.vec3.getRotation(sm.camera.getDirection(), sm.camera.getUp())
		particle_rot = sm.quat.angleAxis(math.rad(90), sm.vec3.new(0, 0, 1)) * particle_rot

		--Calculate final position
		local offset_final = sm.camera.getRotation() * particle_offset
		local particle_pos_final = particle_pos + offset_final

		sm.particle.createParticle(particle_name, particle_pos_final, particle_rot, debri_color)
	end

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end

local _table_remove = table.remove
local _table_insert = table.insert

---@class AnimatorClass : ToolClass
---@field cl_animator_renderables table
---@field cl_animator_tp_renderables table
---@field cl_animator_fp_renderables table
---@field cl_animator_reset_data table
---@field cl_animator_animations table

---@class RenderableHandlerData
---@field path string
---@field name string
---@field enabled boolean
---@field enabled_by_default boolean
---@field tp_id integer
---@field fp_id integer

---@class RenderableHandlerTrack
---@field step_data RenderableHandlerData
---@field func function

---@param self AnimatorClass
---@param track RenderableHandlerTrack
---@param dt integer
AnimationUpdateFunctions.renderable_handler = function(self, track, dt)
	local t_data = track.step_data

	local s_tool = self.tool
	if s_tool:isEquipped() then
		local rend_data = self.cl_animator_renderables[t_data.name]
		if t_data.enabled then
			if not rend_data.enabled then
				rend_data.enabled = true

				rend_data.fp_id = #self.cl_animator_fp_renderables + 1
				rend_data.tp_id = #self.cl_animator_tp_renderables + 1

				_table_insert(self.cl_animator_fp_renderables, rend_data.path)
				_table_insert(self.cl_animator_tp_renderables, rend_data.path)

				s_tool:setFpRenderables(self.cl_animator_fp_renderables)
				s_tool:setTpRenderables(self.cl_animator_tp_renderables)
			end
		else
			if rend_data.enabled then
				rend_data.enabled = false

				_table_remove(self.cl_animator_tp_renderables, rend_data.tp_id)
				_table_remove(self.cl_animator_fp_renderables, rend_data.fp_id)

				rend_data.tp_id = nil
				rend_data.fp_id = nil

				s_tool:setFpRenderables(self.cl_animator_fp_renderables)
				s_tool:setTpRenderables(self.cl_animator_tp_renderables)
			end
		end
	end

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end

function mgp_toolAnimator_update(self, dt)
	for id, track in ipairs(self.cl_animator_tracks) do
		track.func(self, track, dt)
	end
end

function mgp_toolAnimator_registerRenderables(self, fp_renderables, tp_renderables, fallback_renderables)
	if self.cl_animator_renderables then
		for k, v in pairs(self.cl_animator_renderables) do
			v.enabled = v.enabled_by_default
			if v.enabled then
				local fp_id = #fp_renderables + 1
				local tp_id = #tp_renderables + 1

				local v_path = v.path
				fp_renderables[fp_id] = v_path
				tp_renderables[tp_id] = v_path

				v.fp_id = fp_id
				v.tp_id = tp_id
			end
		end

		self.cl_animator_tp_renderables = tp_renderables
		self.cl_animator_fp_renderables = fp_renderables
	else
		for k, v in ipairs(fallback_renderables) do
			_table_insert(tp_renderables, v)
			_table_insert(fp_renderables, v)
		end
	end
end

---@param self AnimatorClass
function mgp_toolAnimator_setAnimation(self, anim_name)
	local reset_data = self.cl_animator_reset_data[anim_name]
	if reset_data ~= nil then
		local s_tool = self.tool
		for k, v in ipairs(reset_data.tp) do
			s_tool:updateAnimation(v[1], v[2], 1.0)
		end

		for k, v in ipairs(reset_data.fp) do
			s_tool:updateFpAnimation(v[1], v[2], 1.0)
		end
	end

	local anim_data = self.cl_animator_animations[anim_name]
	self.cl_animator_tracks = {}
	for k, v in ipairs(anim_data) do
		self.cl_animator_tracks[k] =
		{
			data = v,
			step = 0,
			step_count = #v + 1,
			func = AnimationUpdateFunctions.anim_selector
		}
	end
end

function mgp_toolAnimator_initialize(self, tool_name)
	local anim_data = mgp_getToolData(tool_name)

	self.cl_animator_effects = {}
	for eff_id, eff_name in pairs(anim_data.required_effects) do
		self.cl_animator_effects[eff_id] = sm.effect.createEffect(eff_name)
	end

	local anim_data_renderables = anim_data.renderables
	if anim_data_renderables ~= nil then
		self.cl_animator_renderables = {}
		for rend_name, data in pairs(anim_data_renderables) do
			self.cl_animator_renderables[rend_name] = data
		end
	end

	local anim_data_reset = anim_data.animation_reset
	if anim_data_reset ~= nil then
		self.cl_animator_reset_data = anim_data_reset
	end

	self.cl_animator_animations = anim_data.animation
	self.cl_animator_on_unequip = anim_data.on_unequip_action
	self.cl_animator_tracks = {}
end

function mgp_toolAnimator_reset(self)
	self.cl_animator_tracks = {}

	local effects_to_stop = self.cl_animator_on_unequip.stop_effects
	for k, v in ipairs(effects_to_stop) do
		local cur_effect = self.cl_animator_effects[v]
		if cur_effect:isPlaying() then
			cur_effect:stopImmediate()
		end
	end
end

function mgp_toolAnimator_destroy(self)
	for k, cur_effect in pairs(self.cl_animator_effects) do
		if cur_effect:isPlaying() then
			cur_effect:stopImmediate()
		end

		cur_effect:destroy()
	end
end