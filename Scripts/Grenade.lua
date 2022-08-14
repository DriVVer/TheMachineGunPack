---@type ShapeClass
Grenade = class()

function Grenade:server_onCreate()
	self.timer = 10
end

function Grenade:server_onFixedUpdate(dt)
	if self.timer then
		self.timer = self.timer - dt

		if self.timer <= 0.0 then
			sm.physics.explode(self.shape.worldPosition, 10, 1, 20, 50, "PropaneTank - ExplosionSmall", self.shape)
			self.shape:destroyShape(0)
			self.timer = nil
		end
	end
end