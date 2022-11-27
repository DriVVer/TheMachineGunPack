---@class BoneData
---@field pos Vec3
---@field vel Vec3
---@field angular_vel Vec3
---@field angles integer[]
---@field b_end string

---@class BoneTrackerData : ShapeClass
---@field cl_bone_tracker BoneData[]

function BoneTracker_Initialize(self, bone_data)
	local bone_tracker_tmp = {}
	for k, v in ipairs(bone_data or {}) do
		bone_tracker_tmp[v] =
		{
			pos = self.interactable:getLocalBonePosition(v),
			vel = sm.vec3.zero(),
			angular_vel = sm.vec3.zero(),
			angles = {0, 0},
			b_end = v.."_end"
		}
	end

	self.cl_bone_tracker = bone_tracker_tmp
end

---@param self BoneTrackerData
function BoneTracker_Reset(self)
	local s_inter = self.interactable
	for k, v in pairs(self.cl_bone_tracker) do
		v.pos = s_inter:getLocalBonePosition(k --[[@as string]])
		v.vel = sm.vec3.zero()
		v.angular_vel = sm.vec3.zero()
		v.angles = { 0, 0 }
	end
end

local g_pidiv2 = math.pi / 2
---@param self BoneTrackerData
---@param dt integer
function BoneTracker_clientOnUpdate(self, dt)
	local s_inter = self.interactable
	for k, b_data in pairs(self.cl_bone_tracker) do
		local prev_pos = b_data.pos
		local new_pos = s_inter:getLocalBonePosition(k --[[@as string]])
		local b_end_pos = s_inter:getLocalBonePosition(b_data.b_end)
		local b_dir = (new_pos - b_end_pos):normalize()

		local prev_angles = b_data.angles
		local new_pitch = math.asin(b_dir.z)
		local new_yaw = math.atan2(b_dir.y, b_dir.x) - g_pidiv2

		local new_ang_vel = sm.vec3.new(
			(prev_angles[1] - new_pitch) / dt,
			0,
			(prev_angles[2] - new_yaw) / dt
		)

		b_data.pos = new_pos
		b_data.vel = (new_pos - prev_pos) / dt
		b_data.angular_vel = new_ang_vel
		b_data.angles = { new_pitch, new_yaw }
	end
end