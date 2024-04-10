dofile("$CONTENT_DATA/Scripts/Databases/ToolDatabase.lua")

local type_to_func_name =
{
	[1] = "anim_setup",
	[2] = "effect_handler",
	[3] = "delay_setup",
	[4] = "debris_handler",
	[5] = "particle_handler",
	[6] = "renderable_handler",
	[7] = "event_handler"
}

local AnimationUpdateFunctions = {}

AnimationUpdateFunctions.anim_selector = function(self, track, dt)
	track.step = track.step + 1
	if track.step < track.step_count then
		track.step_data = track.data[track.step]
		local func_name = type_to_func_name[track.step_data.type]

		track.func = AnimationUpdateFunctions[func_name]
		track.func(self, track, dt)
	else
		track.func = nil
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
	for k, anim_data in ipairs(cur_data.fp_anim) do
		local anim_val = _sm_util_lerp(anim_data.start_val, anim_data.end_val, normalized_val)
		s_tool:updateFpAnimation(anim_data.name, anim_val, 1.0)
	end
	for k, anim_data in pairs(cur_data.tp_anim) do
		local anim_val = _sm_util_lerp(anim_data.start_val, anim_data.end_val, normalized_val)
		s_tool:updateAnimation(anim_data.name, anim_val, 1.0)
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
		effect_dir = s_tool:getTpBoneDir(cur_bone)
		if s_tool:isInFirstPersonView() then
			cur_effect = self.cl_animator_effects[cur_data.name_fp]
			effect_pos = s_tool:getFpBonePos(cur_bone)
			effect_offset = cur_data.fp_offset
		else
			cur_effect = self.cl_animator_effects[cur_data.name_tp]
			effect_pos = s_tool:getTpBonePos(cur_bone)
			effect_offset = cur_data.tp_offset
		end

		if cur_effect then
			effect_offset = sm.camera.getRotation() * effect_offset

			cur_effect:setPosition(effect_pos + effect_offset)
			cur_effect:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, 1), effect_dir))
			if cur_data.apply_velocity then
				cur_effect:setVelocity(s_tool:getMovementVelocity())
			end

			cur_effect:start()
		end
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
---@field offsetAngle number

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
		if s_tool:isInFirstPersonView() then
			particle_pos = s_tool:getFpBonePos(bone_name)
			particle_offset = cur_data.fp_offset
			particle_name = cur_data.name_fp
		else
			particle_pos = s_tool:getTpBonePos(bone_name)
			particle_offset = cur_data.tp_offset
			particle_name = cur_data.name_tp
		end

		--Calculate rotation quaternion
		local camDir = sm.camera.getDirection()
		local particle_rot = sm.vec3.getRotation(camDir, sm.camera.getUp())
		local particle_rot_final = sm.quat.angleAxis(math.rad(90), sm.vec3.new(0, 0, 1)) * particle_rot

		if cur_data.offsetAngle then
			particle_rot_final = sm.quat.angleAxis(math.rad(cur_data.offsetAngle), camDir) * particle_rot_final
		end

		--Calculate final position
		local offset_final = sm.camera.getRotation() * particle_offset
		local particle_pos_final = particle_pos + offset_final

		sm.particle.createParticle(particle_name, particle_pos_final, particle_rot_final, debri_color)
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
			end
		else
			if rend_data.enabled then
				rend_data.enabled = false

				_table_remove(self.cl_animator_tp_renderables, rend_data.tp_id)
				_table_remove(self.cl_animator_fp_renderables, rend_data.fp_id)

				rend_data.tp_id = nil
				rend_data.fp_id = nil
			end
		end

		s_tool:setFpRenderables(self.cl_animator_fp_renderables)
		s_tool:setTpRenderables(self.cl_animator_tp_renderables)
	end

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end

---@class EventHandlerData
---@field callback string
---@field args? any
---@field server? boolean

---@class EventHandlerTrack
---@field step_data EventHandlerData
---@field func function

---@param self ToolClass
---@param track EventHandlerTrack
AnimationUpdateFunctions.event_handler = function(self, track, dt)
	local func_data = track.step_data
	if not func_data.server then
		self[func_data.callback](self, func_data.args)
	elseif self.cl_isLocal then
		self.network:sendToServer(func_data.callback, func_data.args)
	end

	track.func = AnimationUpdateFunctions.anim_selector
	track.func(self, track, dt)
end


local cam = sm.camera
local camera_getPullBack = cam.getCameraPullback
local camera_getDefaultPos = cam.getDefaultPosition
local camera_getDefaultRotation = cam.getDefaultRotation
local camera_getDefaultFov = cam.getDefaultFov
local quat_angleAxis = sm.quat.angleAxis
local right = sm.vec3.new(1,0,0)
local util_lerp = sm.util.lerp
function mgp_toolAnimator_update(self, dt)
	if self.cl_animator_current_track_count > 0 then
		for id, track in pairs(self.cl_animator_tracks) do
			local track_func = track.func
			if track_func ~= nil then
				track_func(self, track, dt)
			else
				self.cl_animator_current_track_count = self.cl_animator_current_track_count - 1
				self.cl_animator_tracks[id] = nil
			end
		end

		if self.cl_animator_current_track_count == 0 then
			self.cl_animator_current_name = nil
		end
	end

	if not self.maxRecoil then return end

	self.cl_desiredRecoilAngle = math.max(self.cl_desiredRecoilAngle - dt * (self.recoilRecoverySpeed or 1), 0)
	self.cl_recoilAngle = util_lerp(self.cl_recoilAngle, self.cl_desiredRecoilAngle, dt * 10)
	--print(self.cl_desiredRecoilAngle, self.cl_recoilAngle, self.cl_isLocal, self.equipped)
	if self.cl_isLocal and self.equipped then
		local v_loc_pl = sm.localPlayer.getPlayer()
		local pullback = camera_getPullBack()
		if pullback == 0 then
			v_loc_pl.clientPublicData.customCameraData = {
				cameraState = 2,
				cameraPosition = camera_getDefaultPos(),
				cameraRotation = camera_getDefaultRotation() * quat_angleAxis(self.cl_recoilAngle, right),
				cameraFov = util_lerp(camera_getDefaultFov(), 30, self.aimWeight)
			}
		else
			local v_loc_char = v_loc_pl.character
			if not v_loc_char then return end

			local v_cam_dir = (sm.camera.getDefaultRotation() * sm.vec3.new(0, 1, 0)):normalize()
			local v_cam_pitch = math.asin(v_cam_dir.z)
			local v_cam_yaw = math.atan2(v_cam_dir.y, v_cam_dir.x) - math.pi / 2
			local v_cam_dist = 1.3659 + 0.325 * pullback
			local v_new_pos = sm.vec3.new(0, 1, 0)
				:rotateX(v_cam_pitch + self.cl_recoilAngle)
				:rotateZ(v_cam_yaw) * v_cam_dist

			-- Using jnt_root because it's smoother than char.worldPosition
			local v_char_real_pos = v_loc_char:getTpBonePos("jnt_root")
				+ sm.vec3.new(0, 0, v_loc_char:getHeight() * 0.5) + v_loc_char.velocity * dt
			local v_up_offset_coeff = math.abs(math.asin(v_cam_dir.z)) / math.pi * 2
			local v_final_up_offset = 0.575 * (1 - v_up_offset_coeff)
			local v_cam_final_offset = v_char_real_pos
				+ sm.localPlayer.getRight() * 0.375
				+ sm.localPlayer.getUp() * v_final_up_offset

			local v_cam_final_pos = v_cam_final_offset - v_new_pos
			local v_filter = sm.physics.filter
			local v_hit, v_result = sm.physics.raycast(v_cam_final_offset, v_cam_final_pos - v_new_pos * 0.2, nil,
				v_filter.staticBody + v_filter.terrainSurface + v_filter.terrainAsset)
			if v_hit then
				v_cam_final_pos = v_result.pointWorld + v_result.normalWorld * 0.2
			end

			v_loc_pl.clientPublicData.customCameraData = {
				cameraState = 3,
				cameraPosition = v_cam_final_pos,
				cameraRotation = camera_getDefaultRotation() * quat_angleAxis(self.cl_recoilAngle, right),
				cameraFov = util_lerp(camera_getDefaultFov(), 30, self.aimWeight)
			}
			-- old solution
			--[[local offset = sm.localPlayer.getRight() * 0.375 + sm.localPlayer.getUp() * 0.575 - sm.localPlayer.getDirection() * 1.6925 * pullback
			sm.localPlayer.getPlayer().clientPublicData.customCameraData = {
				cameraState = 3,
				cameraPosition = sm.localPlayer.getPlayer().character.worldPosition + sm.quat.angleAxis(self.cl_recoilAngle, sm.localPlayer.getRight()) * offset,
				cameraRotation = camera_getDefaultRotation() * sm.quat.angleAxis(self.cl_recoilAngle, right),
				cameraFov = util_lerp(camera_getDefaultFov(), 30, self.aimWeight)
			}]]
		end
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

function mgp_toolAnimator_getAnimation(self)
	return self.cl_animator_current_name
end

local isAimShootAnim = {
	aimShoot = true,
	shoot_aim = true,
	shoot_bipod = true,
}
local isShootAnim = {
	shoot = true,
	last_shot = true
}

function mgp_toolAnimator_setAnimation(self, anim_name)
	if self.cl_animator_reset_data then
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
	end

	local anim_data = self.cl_animator_animations[anim_name]
	self.cl_animator_current_name = anim_name
	self.cl_animator_current_track_count = #anim_data
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

	local isAimShoot = isAimShootAnim[anim_name] == true
	if isAimShoot or isShootAnim[anim_name] == true then
		local recoilAmount = isAimShoot and self.aimRecoilAmount or self.recoilAmount
		self.cl_desiredRecoilAngle = math.min(self.cl_desiredRecoilAngle + math.rad(recoilAmount or 0), math.rad(self.maxRecoil or 0))
	end
end

local function cl_recoil_unlock(self)
	sm.localPlayer.setLockedControls(false)
end

local function sv_recoil_resetRecoil(self)
	self.network:sendToClients("cl_recoil_resetRecoil")
end

local function cl_recoil_resetRecoil(self)
	self.cl_recoilAngle = 0
	self.cl_desiredRecoilAngle = 0
end

function mgp_toolAnimator_initialize(self, tool_name)
	local anim_data = mgp_getToolData(tool_name)

	self.cl_animator_effects = {}
	if sm.cae_injected and anim_data.dlm_required_effects then
		for eff_id, eff_name in pairs(anim_data.dlm_required_effects) do
			self.cl_animator_effects[eff_id] = sm.effect.createEffect(eff_name)
		end

		for eff_id, eff_name in pairs(anim_data.required_effects) do
			if self.cl_animator_effects[eff_id] == nil then
				self.cl_animator_effects[eff_id] = sm.effect.createEffect(eff_name)
			end
		end
	else
		for eff_id, eff_name in pairs(anim_data.required_effects) do
			self.cl_animator_effects[eff_id] = sm.effect.createEffect(eff_name)
		end
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
	self.cl_animator_current_track_count = 0
	self.cl_animator_tracks = {}

	self.cl_recoilAngle = 0
	self.cl_desiredRecoilAngle = 0
	self.cl_isFiring = false

	self.cl_isLocal = self.tool:isLocal()

	self.cl_recoil_unlock = cl_recoil_unlock
	self.sv_recoil_resetRecoil = sv_recoil_resetRecoil
	self.cl_recoil_resetRecoil = cl_recoil_resetRecoil
end

function mgp_toolAnimator_reset(self)
	self.cl_animator_tracks = {}

	if self.cl_isLocal then
		sm.localPlayer.getPlayer().clientPublicData.customCameraData = nil
	end

	local cl_on_unequip = self.cl_animator_on_unequip
	if cl_on_unequip == nil then return end

	local effects_to_stop = cl_on_unequip.stop_effects
	if effects_to_stop == nil then return end

	for k, v in ipairs(effects_to_stop) do
		local cur_effect = self.cl_animator_effects[v]
		if cur_effect ~= nil then
			if cur_effect:isPlaying() then
				cur_effect:stopImmediate()
			end
		else
			print("[MGP] Reset: effect", v, "is invalid!")
		end
	end
end

function mgp_toolAnimator_checkForRecoil(self, state)
	--[[local isFiring = (state == 1 or state == 2) and self.ammo_in_mag > 0
	if isFiring ~= self.cl_isFiring then
		if not isFiring then
			sm.localPlayer.setLockedControls(true)
			sm.localPlayer.setDirection(sm.camera.getDefaultRotation() * sm.quat.angleAxis(self.cl_recoilAngle, sm.vec3.new(1,0,0)) * sm.vec3.new(0,1,0))
			self:cl_recoil_resetRecoil()
			self.network:sendToServer("sv_recoil_resetRecoil")
			sm.event.sendToTool(self.tool, "cl_recoil_unlock")
		end

		self.cl_isFiring = isFiring
	end]]
end

function mgp_toolAnimator_destroy(self)
	if self.cl_isLocal then
		sm.localPlayer.getPlayer().clientPublicData.customCameraData = nil
	end

	for k, cur_effect in pairs(self.cl_animator_effects) do
		if cur_effect:isPlaying() then
			cur_effect:stopImmediate()
		end

		cur_effect:destroy()
	end
end