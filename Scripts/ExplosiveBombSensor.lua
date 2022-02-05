-- Explosive.lua --

Explosive = class()
Explosive.poseWeightCount = 1

Explosive.maxChildCount = -1 -- ************** test on connection activation
Explosive.maxParentCount = 1
Explosive.connectionInput = sm.interactable.connectionType.logic + 2048
Explosive.connectionOutput = 2048
Explosive.colorNormal = sm.color.new( 0xcb0a00ff )
Explosive.colorHighlight = sm.color.new( 0xee0a00ff ) -- ************** test on connection activation

Explosive.BombData = {
    ["b660f72a-7640-4446-b8bb-2df3cad61bbb"] = { --Bomb Sensor
        destructionLevel = 5,
        destructionRadius = 5.0,
        impulseRadius = 8.0,
        impulseMagnitude = 20.0,
        effectExplosion = "PropaneTank - ExplosionBig",
        effectActivate = "PropaneTank - ActivateBig",
        fireDelay = 1,
        fuseDelay = 0.0625,
		range = 0.75
    }
}

--[[ Server ]]

-- (Event) Called upon creation on server
function Explosive.server_onCreate( self )
	self:server_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function Explosive.server_onRefresh( self )
	self:server_init()
end

-- Initialize explosive
function Explosive.server_init( self )
	self.alive = true
	self.counting = false
	self.activated = false
	self.fireDelayProgress = 0
	self.activationDelayProgress = 0

    local _CurBombData = self.BombData[tostring(self.shape.uuid)]

    self.destructionLevel = _CurBombData.destructionLevel
    self.destructionRadius = _CurBombData.destructionRadius
    self.impulseRadius = _CurBombData.impulseRadius
    self.impulseMagnitude = _CurBombData.impulseMagnitude
    self.fireDelay = _CurBombData.fireDelay
    self.fuseDelay = _CurBombData.fuseDelay
	self.range = _CurBombData.range
end

-- (Event) Called upon game tick. (40 times a second)
function Explosive.server_onFixedUpdate( self, timeStep )
	if self.interactable then
		local parent = self.interactable:getSingleParent() -- ************** test on connection activation
		if ((parent and parent:isActive())) then
				self.activated = true
		end
		if self.activated then
			if self.activationDelayProgress >= 60 then
				local position = self.shape.getWorldPosition(self.shape)
				local ray   = sm.physics.raycast(position, position + sm.vec3.new(0			 ,0			 , self.range))
				local ray2  = sm.physics.raycast(position, position + sm.vec3.new(0			 , self.range,0			 ))
				local ray3  = sm.physics.raycast(position, position + sm.vec3.new( self.range,0			 ,0			 ))
				local ray4  = sm.physics.raycast(position, position + sm.vec3.new(0			 ,0			 ,-self.range))
				local ray5  = sm.physics.raycast(position, position + sm.vec3.new(0			 ,-self.range,0			 ))
				local ray6  = sm.physics.raycast(position, position + sm.vec3.new(-self.range,0			 ,0			 ))
				local ray7  = sm.physics.raycast(position, position + sm.vec3.new(0			 , self.range, self.range))
				local ray8  = sm.physics.raycast(position, position + sm.vec3.new( self.range,0			 , self.range))
				local ray9  = sm.physics.raycast(position, position + sm.vec3.new( self.range, self.range,0			 ))
				local ray10 = sm.physics.raycast(position, position + sm.vec3.new(0			 ,-self.range, self.range))
				local ray11 = sm.physics.raycast(position, position + sm.vec3.new(-self.range,0			 , self.range))
				local ray12 = sm.physics.raycast(position, position + sm.vec3.new(-self.range, self.range,0			 ))
				local ray13 = sm.physics.raycast(position, position + sm.vec3.new(0			 , self.range,-self.range))
				local ray14 = sm.physics.raycast(position, position + sm.vec3.new( self.range,0			 ,-self.range))
				local ray15 = sm.physics.raycast(position, position + sm.vec3.new( self.range,-self.range,0			 ))
				local ray16 = sm.physics.raycast(position, position + sm.vec3.new(0			 ,-self.range,-self.range))
				local ray17 = sm.physics.raycast(position, position + sm.vec3.new(-self.range,0			 ,-self.range))
				local ray18 = sm.physics.raycast(position, position + sm.vec3.new(-self.range,-self.range,0			 ))
				local ray19 = sm.physics.raycast(position, position + sm.vec3.new( self.range, self.range, self.range))
				local ray20 = sm.physics.raycast(position, position + sm.vec3.new(-self.range, self.range, self.range)) 
				local ray21 = sm.physics.raycast(position, position + sm.vec3.new( self.range,-self.range, self.range))
				local ray22 = sm.physics.raycast(position, position + sm.vec3.new( self.range, self.range,-self.range))
				local ray23 = sm.physics.raycast(position, position + sm.vec3.new( self.range,-self.range,-self.range))
				local ray24 = sm.physics.raycast(position, position + sm.vec3.new(-self.range, self.range,-self.range))
				local ray25 = sm.physics.raycast(position, position + sm.vec3.new(-self.range,-self.range, self.range))
				local ray26 = sm.physics.raycast(position, position + sm.vec3.new(-self.range,-self.range,-self.range))
				if ray or ray2 or ray3 or ray4 or ray5 or ray6 or ray7 or ray8 or ray9 or ray10 or ray11 or ray12 or ray13 or ray14 or ray15 or ray16 or ray17 or ray18 or ray19 or ray20 or ray21 or ray22 or ray23 or ray24 or ray25 or ray26 then
					self:server_tryExplode() -- ************** test on connection activation
				end
			else			
				self.activationDelayProgress = self.activationDelayProgress + 1
			end
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
function Explosive.server_tryExplode( self )
	if self.alive then
		self.alive = false
		self.counting = false
		self.fireDelayProgress = 0

		-- Create explosion
		sm.physics.explode( self.shape.worldPosition, self.destructionLevel, self.destructionRadius, self.impulseRadius, self.impulseMagnitude, self.explosionEffectName, self.shape )
		sm.shape.destroyPart( self.shape )
	end
end

-- (Event) Called upon getting hit by a sledgehammer.
function Explosive.server_onSledgehammer( self, hitPos, player )
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
function Explosive.server_onExplosion( self, center, destructionLevel )
	-- Explode within a few ticks
	if self.alive then
		self.fireDelay = 1
		self.counting = true
	end
end

-- (Event) Called upon collision with another object
function Explosive.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
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
function Explosive.server_startCountdown( self )
	self.counting = true
	self.network:sendToClients( "client_startCountdown" )
end


--[[ Client ]]

-- (Event) Called upon creation on client
function Explosive.client_onCreate( self )
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
function Explosive.client_onUpdate( self, dt )
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
function Explosive.client_hitActivation( self, hitPos )
	local localPos = self.shape:transformPoint( hitPos )

	local smokeDirection = ( hitPos - self.shape.worldPosition ):normalize()
	local worldRot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), smokeDirection )
	local localRot = self.shape:transformRotation( worldRot )

	self.singleHitEffect:start()
	self.singleHitEffect:setOffsetRotation( localRot )
	self.singleHitEffect:setOffsetPosition( localPos )
end

-- Called from server upon countdown start
function Explosive.client_startCountdown( self )
	self.client_counting = true
	if self.activateEffect then
		self.activateEffect:start()
	end

	local offsetRotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 1, 0 ) )
	if self.activateEffect then
		self.activateEffect:setOffsetRotation( offsetRotation )
	end
end