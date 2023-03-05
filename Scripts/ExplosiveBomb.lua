-- Explosive.lua --

---@class ExplosiveBomb : ShapeClass
---@field destructionLevel integer
---@field destructionRadius integer
---@field impulseRadius integer
---@field impulseMagnitude integer
---@field fireDelay integer
---@field fuseDelay integer
---@field singleHitEffect Effect
---@field counting boolean
---@field explosionEffectName string
---@field alive boolean
---@field client_counting boolean
---@field activateEffect Effect
ExplosiveBomb = class()
ExplosiveBomb.poseWeightCount = 1

ExplosiveBomb.maxChildCount = -1 -- ************** test on connection activation
ExplosiveBomb.maxParentCount = 1
ExplosiveBomb.connectionInput = sm.interactable.connectionType.logic + 2048
ExplosiveBomb.connectionOutput = 2048
ExplosiveBomb.colorNormal = sm.color.new( 0xcb0a00ff )
ExplosiveBomb.colorHighlight = sm.color.new( 0xee0a00ff ) -- ************** test on connection activation

ExplosiveBomb.BombData = {
	["db03da50-e7d6-4a42-8f07-4a296c64f2cd"] = { --Bomb 50kg
		destructionLevel = 5,
		destructionRadius = 3.0,
		impulseRadius = 10.0,
		impulseMagnitude = 40.0,
		effectExplosion = "BombSmall",
		effectActivate = "PropaneTank - ActivateBig",
		fireDelay = 240,
		fuseDelay = 0.0625
	},
	["2433e932-88bb-4c14-b9bb-76502e03a9c9"] = { --Bomb 100kg
		destructionLevel = 5,
		destructionRadius = 7.0,
		impulseRadius = 14.0,
		impulseMagnitude = 50.0,
		effectExplosion = "PropaneTank - ExplosionBig",
		effectActivate = "PropaneTank - ActivateBig",
		fireDelay = 240,
		fuseDelay = 0.0625
	},
	["fe2d4f4e-a2ba-42ba-a7a5-6b97b2c0fa48"] = { --Bomb 250kg
		destructionLevel = 5,
		destructionRadius = 12.0,
		impulseRadius = 22.0,
		impulseMagnitude = 60.0,
		effectExplosion = "PropaneTank - ExplosionBig",
		effectActivate = "PropaneTank - ActivateBig",
		fireDelay = 240,
		fuseDelay = 0.0625
	},
	["0352de84-5cc7-487a-ae15-f3d9d6a84f37"] = {
		destructionLevel = 5,
		destructionRadius = 8.0,
		impulseRadius = 20.0,
		impulseMagnitude = 40.0,
		effectExplosion = "PropaneTank - ExplosionBig",
		effectActivate = "PropaneTank - ActivateBig",
		fireDelay = 1,
		fuseDelay = 0.0625
	},
	["77a65230-9c33-490f-b24d-e80cd63f6802"] = { --S-Mine p1 exp.
		destructionLevel = 3,
		destructionRadius = 6.0,
		impulseRadius = 16.0,
		impulseMagnitude = 40.0,
		effectExplosion = "PropaneTank - ExplosionBig",
		effectActivate = "PropaneTank - ActivateBig",
		fireDelay = 1,
		fuseDelay = 0.0625
	}
}

--[[ Server ]]

-- (Event) Called upon creation on server
function ExplosiveBomb.server_onCreate( self )
	self:server_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function ExplosiveBomb.server_onRefresh( self )
	self:server_init()
end

-- Initialize explosive
function ExplosiveBomb.server_init( self )
	self.alive = true
	self.counting = false
	self.fireDelayProgress = 0

	local _CurBombData = self.BombData[tostring(self.shape.uuid)]

	self.destructionLevel = _CurBombData.destructionLevel
	self.destructionRadius = _CurBombData.destructionRadius
	self.impulseRadius = _CurBombData.impulseRadius
	self.impulseMagnitude = _CurBombData.impulseMagnitude
	self.fireDelay = _CurBombData.fireDelay
	self.fuseDelay = _CurBombData.fuseDelay
end

-- (Event) Called upon game tick. (40 times a second)
function ExplosiveBomb.server_onFixedUpdate( self, timeStep )
	if self.interactable then
		local parent = self.interactable:getSingleParent() -- ************** test on connection activation
		if ((parent and parent:isActive())) then
			self:server_tryExplode() -- ************** test on connection activation
		end
	end

	if self.counting then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self:server_tryExplode()
		end
	end
end

-- Attempt to create an explosion
function ExplosiveBomb.server_tryExplode( self )
	if self.alive then
		self.alive = false
		self.counting = false
		self.fireDelayProgress = 0

		-- Create explosion
		sm.physics.explode( self.shape.worldPosition, self.destructionLevel, self.destructionRadius, self.impulseRadius, self.impulseMagnitude, self.explosionEffectName, self.shape )
		sm.shape.destroyPart( self.shape )
	end
end

-- (Event) Called upon getting hit by a projectile.
function ExplosiveBomb.server_onProjectile( self, hitPos, hitTime, hitVelocity, hitType )
	if self.alive then
		if self.counting then
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * 0.5
		else
			-- Trigger explosion countdown
			self:server_startCountdown()
			self.network:sendToClients( "client_hitActivation", hitPos )
		end
	end
end

-- (Event) Called upon getting hit by a sledgehammer.
function ExplosiveBomb.server_onSledgehammer( self, hitPos, player )
	if self.alive then
		if self.counting then
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * 0.5
		else
			-- Trigger explosion countdown
			self:server_startCountdown()
			self.network:sendToClients( "client_hitActivation", hitPos )
		end
	end
end

-- (Event) Called upon collision with an explosion nearby
function ExplosiveBomb.server_onExplosion( self, center, destructionLevel )
	-- Explode within a few ticks
	if self.alive then
		self.fireDelay = 1
		self.counting = true
	end
end

-- (Event) Called upon collision with another object
function ExplosiveBomb.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	local collisionDirection = (selfPointVelocity - otherPointVelocity):normalize()
	local diffVelocity = (selfPointVelocity - otherPointVelocity):length()
	local selfPointVelocityLength = selfPointVelocity:length()
	local otherPointVelocityLength = otherPointVelocity:length()
	local scaleFraction = 1.0 - ( self.fireDelayProgress / self.fireDelay )
	local dotFraction = math.abs( collisionDirection:dot( collisionNormal ) )

	local hardTrigger = diffVelocity * dotFraction >= 10 * scaleFraction
	local lightTrigger = diffVelocity * dotFraction >= 6 * scaleFraction

	if self.alive then
		if hardTrigger  then
			-- Trigger explosion immediately
			self.counting = true
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay
		elseif lightTrigger then
			-- Trigger explosion countdown
			if not self.counting then
				self:server_startCountdown()
				self.network:sendToClients( "client_hitActivation", collisionPosition )
			else
				self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * ( 1.0 - scaleFraction )
			end
		end
	end
end

-- Start countdown and update clients
function ExplosiveBomb.server_startCountdown( self )
	self.counting = true
	self.network:sendToClients( "client_startCountdown" )
end


--[[ Client ]]

-- (Event) Called upon creation on client
function ExplosiveBomb.client_onCreate( self )
	self.client_counting = false
	self.client_fuseDelayProgress = 0
	self.client_fireDelayProgress = 0
	self.client_poseScale = 0
	self.client_effect_doOnce = true

	local _CurBombData = self.BombData[tostring(self.shape.uuid)]

	self.explosionEffectName = _CurBombData.effectExplosion
	self.singleHitEffect = sm.effect.createEffect(_CurBombData.effectActivate, self.interactable)
end

-- (Event) Called upon every frame. (Same as fps)
function ExplosiveBomb.client_onUpdate( self, dt )
	if self.client_counting then
		if self.interactable then
			self.interactable:setPoseWeight( 0,(self.client_fuseDelayProgress*1.5) +self.client_poseScale )
		end
		self.client_fuseDelayProgress = self.client_fuseDelayProgress + dt
		self.client_poseScale = self.client_poseScale +(0.25*dt)

		if self.client_fuseDelayProgress >= self.fuseDelay then
			self.client_fuseDelayProgress = self.client_fuseDelayProgress - self.fuseDelay
		end

		self.client_fireDelayProgress = self.client_fireDelayProgress + dt
		if self.activateEffect then
			self.activateEffect:setParameter( "progress", self.client_fireDelayProgress / ( self.fireDelay * ( 1 / 40 ) ) )
		end
	end
end

-- Called from server upon getting triggered by a hit
function ExplosiveBomb.client_hitActivation( self, hitPos )
	local localPos = self.shape:transformPoint( hitPos )

	local smokeDirection = ( hitPos - self.shape.worldPosition ):normalize()
	local worldRot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), smokeDirection )
	local localRot = self.shape:transformRotation( worldRot )

	self.singleHitEffect:start()
	self.singleHitEffect:setOffsetRotation( localRot )
	self.singleHitEffect:setOffsetPosition( localPos )
end

-- Called from server upon countdown start
function ExplosiveBomb.client_startCountdown( self )
	self.client_counting = true
	if self.activateEffect then
		self.activateEffect:start()
	end

	local offsetRotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 1, 0 ) )
	if self.activateEffect then
		self.activateEffect:setOffsetRotation( offsetRotation )
	end
end