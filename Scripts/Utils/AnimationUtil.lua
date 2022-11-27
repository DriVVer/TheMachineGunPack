--[[
	Copyright (c) 2022 Questionable Mark
]]

local g_type_to_func_name =
{
	[1] = "setup_bone_anim",
	[2] = "setup_pose_anim",
	[3] = "particle",
	[4] = "debris",
	[5] = "delay_setup"
}

local AnimUtil_AnimationTypes = {}
function AnimUtil_AnimationTypes.anim_selector(self, track, dt)
	track.step = track.step + 1

	if track.step < track.step_count then
		track.step_data = track.data[track.step]
		local func_name = g_type_to_func_name[track.step_data.type]

		track.func = AnimUtil_AnimationTypes[func_name]
		track.func(self, track, dt)
	else
		track.func = nil
	end
end

function AnimUtil_AnimationTypes.setup_bone_anim(self, track, dt)
	track.time = track.step_data.time

	track.func = AnimUtil_AnimationTypes.bone_animation
	track.func(self, track, dt)
end

function AnimUtil_AnimationTypes.bone_animation(self, track, dt)
	local v_anim_data = track.step_data
	local v_predict_time = (track.time - dt)

	local v_anim_prog = (v_anim_data.time - math.max(v_predict_time, 0)) / v_anim_data.time
	local v_norm_value = math.min(math.max(v_anim_prog, 0), 1)
	local v_final_val = sm.util.lerp(v_anim_data.start_value, v_anim_data.end_value, v_norm_value)

	local s_inter = self.interactable
	for i, anim in pairs(v_anim_data.anims) do
		s_inter:setAnimProgress(anim, v_final_val)
	end

	BoneTracker_clientOnUpdate(self, dt)

	if track.time then
		track.time = v_predict_time

		if track.time <= 0 then
			track.time = nil

			track.func = AnimUtil_AnimationTypes.anim_selector
			track.func(self, track, dt)
		end
	end
end

function AnimUtil_AnimationTypes.setup_pose_anim(self, track, dt)
	track.time = track.step_data.time

	track.func = AnimUtil_AnimationTypes.pose_animation
	track.func(self, track, dt)
end

function AnimUtil_AnimationTypes.pose_animation(self, track, dt)
	local v_anim_data = track.step_data
	local v_predict_time = track.time - dt

	local v_anim_prog = (v_anim_data.time - math.max(v_predict_time, 0)) / v_anim_data.time
	local v_norm_value = math.min(math.max(v_anim_prog, 0), 1)
	local v_final_val = sm.util.lerp(v_anim_data.start_value, v_anim_data.end_value, v_norm_value)

	self.interactable:setPoseWeight(v_anim_data.pose, v_final_val)

	if track.time then
		track.time = v_predict_time

		if track.time <= 0 then
			track.time = nil

			track.func = AnimUtil_AnimationTypes.anim_selector
			track.func(self, track, dt)
		end
	end
end

function AnimUtil_AnimationTypes.particle(self, track, dt)
	local v_effect_table = track.step_data.particles
	local s_effects = self.effects

	for k, particle in pairs(v_effect_table) do
		s_effects[particle]:start()
	end

	track.func = AnimUtil_AnimationTypes.anim_selector
	track.func(self, track, dt)
end

local debri_color = sm.color.new(0x000000ff)
function AnimUtil_AnimationTypes.debris(self, track, dt)
	local v_debri_data = track.step_data
	local s_inter = self.interactable

	local bone_name = v_debri_data.bone
	local tracked_bone = self.cl_bone_tracker[bone_name] --[[@as BoneData]]
	local debri_pos = s_inter:getWorldBonePosition(bone_name)
	local v_dir = (s_inter:getLocalBonePosition(bone_name) - s_inter:getLocalBonePosition(bone_name.."_end")):normalize()

	local debri_rot_local = sm.vec3.getRotation(v_dir, sm.vec3.new(1, 0, 0))
	local debri_rot = self.shape.worldRotation * debri_rot_local --[[@as Quat]]

	--Calculate other things
	local debri_time = math.random(2, 15)
	local debri_offset = debri_rot * v_debri_data.offset
	local debri_pos_final = debri_pos + debri_offset --[[@as Vec3]]
	local world_vel = (self.shape.worldRotation * tracked_bone.vel) + self.shape.velocity --[[@as Vec3]]
	local world_ang_vel = self.shape.worldRotation * -tracked_bone.angular_vel --[[@as Vec3]]

	sm.debris.createDebris(v_debri_data.uuid, debri_pos_final, debri_rot, world_vel, world_ang_vel, debri_color, debri_time)

	track.func = AnimUtil_AnimationTypes.anim_selector
	track.func(self, track, dt)
end

function AnimUtil_AnimationTypes.delay_setup(self, track, dt)
	track.time = track.step_data.time

	track.func = AnimUtil_AnimationTypes.delay_handler
	track.func(self, track, dt)
end

function AnimUtil_AnimationTypes.delay_handler(self, track, dt)
	track.time = track.time - dt

	if track.time <= 0.0 then
		track.time = nil

		track.func = AnimUtil_AnimationTypes.anim_selector
		track.func(self, track, dt)
	end
end

function AnimUtil_SendAnimationData(self, player)
	self.network:sendToClient(player, "client_receiveAnimData", self.cl_cannon_heat)
end

function AnimUtil_ReceiveAnimationData(self, cannon_heat)
	self.cl_cannon_heat = cannon_heat

	self.cl_animator_reset(self)

	if self.anim.method == 2 then --has bone animation
		self.anim.state_queue = {}
		self.anim.cur_state = nil
	end
end

local function AnimUtil_SetAnimationInternal(self, anim_name)
	local anim_data = self.cl_animator_animations[anim_name]

	self.cl_animator_active_tracks = #anim_data
	self.cl_animator_tracks = {}

	for k, v in ipairs(anim_data) do
		self.cl_animator_tracks[k] =
		{
			data = v,
			step = 0,
			step_count = #v + 1,
			func = AnimUtil_AnimationTypes.anim_selector
		}
	end
end

local function AnimUtil_LoadAnimFromQueue(self)
	if self.anim.state_q_sz > 0 then
		local v_cur_anim = self.anim.state_queue[1]
		if v_cur_anim == "overheat" then
			self.cl_cannon_heat = 0
		end

		AnimUtil_SetAnimationInternal(self, v_cur_anim)

		table.remove(self.anim.state_queue, 1)
		self.anim.state_q_sz = self.anim.state_q_sz - 1

		return true
	end

	return false
end

function AnimUtil_SetAnimation(self, anim_name)
	if type(anim_name) == "table" then
		self.anim.state_queue = anim_name
		self.anim.state_q_sz = #anim_name

		self.cl_animator_reset(self)
	else
		AnimUtil_SetAnimationInternal(self, anim_name)

		if anim_name == "shoot" and self.cl_heat_per_shot then
			self.cl_cannon_heat = (self.cl_cannon_heat or 0.0) + self.cl_heat_per_shot
		end
	end
end

function AnimUtil_InitializeEffects(self, effect_data)
	self.effects = {}
	for k, eData in pairs(effect_data) do
		local new_effect = sm.effect.createEffect(eData.name, self.interactable, eData.bone_name)
		new_effect:setOffsetPosition(eData.offset)

		self.effects[k] = new_effect
	end
end

function AnimUtil_InitializeAnimationUtil(self)
	local _data = DatabaseLoader.getClientSettings(self.shape.uuid)

	local overheat_eff = _data.overheat_effect
	if overheat_eff then
		self.cl_heat_per_shot = overheat_eff.heat_per_shot
		self.cl_cooling_speed = overheat_eff.cooling_speed

		self.cl_overheat_anim_max = overheat_eff.uv_overheat_anim_max
	end

	AnimUtil_InitializeEffects(self, _data.effects)

	self.anim = {}
	self.anim.state_queue = {}
	self.anim.state_q_sz = 0
	self.cl_animator_tracks = {}
	self.cl_animator_active_tracks = 0

	local d_anim = _data.animation
	local d_pose_anim = _data.pose_animation
	if d_anim then
		self.cl_animator_reset = function(self)
			local s_inter = self.interactable
			for k, v in pairs(self.anim.required_animations) do
				s_inter:setAnimProgress(v, 0)
			end
		end

		self.anim.required_animations = d_anim.required_animations or {}
		if d_anim.required_animations then
			local s_inter = self.interactable

			for i, anim in pairs(d_anim.required_animations) do
				s_inter:setAnimEnabled(anim, true)
			end
		end

		self.cl_animator_animations = d_anim.animation_states
	elseif d_pose_anim then
		self.cl_animator_reset = function(self)
			local s_inter = self.interactable

			s_inter:setPoseWeight(0, 0)
			s_inter:setPoseWeight(1, 0)
			s_inter:setPoseWeight(2, 0)
		end

		self.cl_animator_animations = d_pose_anim.animation_states
	end
end




function AnimUtil_server_performDataCheck(self, callback_name)
	if self.sv_anim_wait then return end

	local is_overheating = (self.cl_cannon_heat and self.cl_cannon_heat >= 1.0)
	local is_reloading   = (self.cannon_ammo and self.cannon_ammo == 0)

	if is_overheating or is_reloading then
		local data_table = {}

		if is_overheating then
			table.insert(data_table, "overheat")
		end

		if is_reloading then
			self.cannon_ammo = self.cannon_settings.magazine_capacity
			table.insert(data_table, "reload")
		end

		self.network:sendToClients(callback_name, data_table)
		self.sv_anim_wait = true
	end
end

function AnimUtil_UpdateAnimations(self, dt)
	if self.cl_animator_active_tracks > 0 then
		for id, track in ipairs(self.cl_animator_tracks) do
			local track_func = track.func
			if track_func ~= nil then
				track_func(self, track, dt)
			else
				self.cl_animator_active_tracks = self.cl_animator_active_tracks - 1
				self.cl_animator_tracks[id] = nil
			end
		end

		if self.cl_animator_active_tracks == 0 then
			if not AnimUtil_LoadAnimFromQueue(self) then
				self.sv_anim_wait = false
			end
		end
	else
		AnimUtil_LoadAnimFromQueue(self)
	end

	if self.cl_cannon_heat then
		if self.cl_cannon_heat > 0 then
			self.cl_cannon_heat = self.cl_cannon_heat - (self.cl_cooling_speed * dt)
		else
			self.cl_cannon_heat = nil
		end
	end

	if self.cl_overheat_anim_max then
		local clamped_heat = math.min(math.max(self.cl_cannon_heat or 0, 0), 1)
		self.cl_uv_heat_value = sm.util.lerp(self.cl_uv_heat_value or 0, clamped_heat, dt)

		self.interactable:setUvFrameIndex(self.cl_uv_heat_value * self.cl_overheat_anim_max)
	end
end

function AnimUtil_DestroyEffects(self)
	for k, mEffect in pairs(self.effects) do
		if mEffect and sm.exists(mEffect) then
			mEffect:stop()
			mEffect:destroy()
		end
	end
end