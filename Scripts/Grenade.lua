---@type ShapeClass
Grenade = class()

function Grenade:server_onCreate()
	if self.interactable and self.interactable.publicData then
		self.timer = self.interactable.publicData.timer
	end
end

local mgp_sharpnel_uuid = sm.uuid.new("7a3887dd-0fd2-489c-ac04-7306a672ae35")
local _math_random = math.random
function Grenade:server_onFixedUpdate(dt)
	if self.timer then
		self.timer = self.timer - dt

		if self.timer <= 0.0 then
			local sharpnel_pos = sm.vec3.zero()
			local sharpnel_count = _math_random(150, 350)
			for i = 1, sharpnel_count do
				local s_speed = _math_random(100, 400)
				local shoot_dir = sm.vec3.new(_math_random(0, 100) / 100, _math_random(0, 100) / 100, _math_random(0, 100) / 100):normalize()
				local dir = sm.noise.gunSpread(shoot_dir, 360) * s_speed
				local s_damage = _math_random(10, 30)
				sm.projectile.shapeProjectileAttack(mgp_sharpnel_uuid, s_damage, sharpnel_pos, dir, self.shape)
			end

			sm.physics.explode(self.shape.worldPosition, 10, 1, 20, 50, "PropaneTank - ExplosionSmall", self.shape)
			self.shape:destroyShape(0)

			self.timer = nil
		end
	end
end