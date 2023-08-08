dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

dofile("ToolSwimUtil.lua")

local Damage = 9

---@class Eoka : ToolClass
---@field fpAnimations table
---@field tpAnimations table
---@field aiming boolean
---@field mag_capacity integer
---@field normalFireMode table
---@field movementDispersion integer
---@field blendTime integer
---@field aimBlendSpeed integer
---@field sprintCooldown integer
---@field gun_used boolean|nil
Eoka = class()
Eoka.mag_capacity = 6

local renderables =
{
	"$CONTENT_DATA/Tools/Renderables/Eoka/Eoka_Model.rend"
}

local renderablesTp =
{
	"$CONTENT_DATA/Tools/Renderables/Eoka/char_male_tp_Eoka.rend",
	"$CONTENT_DATA/Tools/Renderables/Bazooka/Bazooka_offset.rend"
}

local renderablesFp =
{
	"$CONTENT_DATA/Tools/Renderables/Eoka/char_male_fp_Eoka.rend",
	"$CONTENT_DATA/Tools/Renderables/Bazooka/Bazooka_offset.rend"
}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Eoka:client_initAimVals()
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
end

function Eoka:client_onCreate()
	self.aimBlendSpeed = 8.0
	self:client_initAimVals()

	self.cl_shoot_tp = sm.effect.createEffect("Muzzle_Flash_SmallCal_tp")
	self.cl_shoot_fp = sm.effect.createEffect("Muzzle_Flash_SmallCal_fp")
end

function Eoka:client_onDestroy()
	local function destroy_effect(eff)
		if eff and sm.exists(eff) then
			eff:stopImmediate()
			eff:destroy()
		end
	end

	destroy_effect(self.cl_shoot_tp)
	destroy_effect(self.cl_shoot_fp)
end

function Eoka:client_onRefresh()
	self:loadAnimations()
end

function Eoka:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" },
		}
	)
	local movementAnimations = {
		idle = "spudgun_idle",
		idleRelaxed = "spudgun_relax",

		sprint = "spudgun_sprint",
		runFwd = "spudgun_run_fwd",
		runBwd = "spudgun_run_bwd",

		jump = "spudgun_jump",
		jumpUp = "spudgun_jump_up",
		jumpDown = "spudgun_jump_down",

		land = "spudgun_jump_land",
		landFwd = "spudgun_jump_land_fwd",
		landBwd = "spudgun_jump_land_bwd",

		crouchIdle = "spudgun_crouch_idle",
		crouchFwd = "spudgun_crouch_fwd",
		crouchBwd = "spudgun_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "Eoka_pickup", { nextAnimation = "idle" } },
				unequip = { "Eoka_putdown" },

				idle = { "Eoka_idle", { looping = true } },
				shoot = { "Eoka_shoot", { nextAnimation = "idle" } },

				sprintInto = { "Eoka_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "Eoka_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "Eoka_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.6,
		spreadCooldown = 1.2,
		spreadIncrement = 20,
		spreadMinAngle = 5,
		spreadMaxAngle = 15,
		fireVelocity = 60.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.movementDispersion = 0.0

	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0

	self:client_initAimVals()
end

function Eoka:client_updateAimWeights(dt)
	-- Camera update
	local bobbing = 1
	local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
	self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function Eoka:server_onFixedUpdate(dt)
	if self.sv_gun_timer then
		self.sv_gun_timer = self.sv_gun_timer - dt

		if self.sv_gun_timer <= 0.0 then
			self.sv_gun_timer = nil

			local v_tool_owner = self.tool:getOwner()
			if not (v_tool_owner and sm.exists(v_tool_owner)) then
				return
			end

			local v_pl_inventory = nil
			if sm.game.getLimitedInventory() then
				v_pl_inventory = v_tool_owner:getInventory()
			else
				v_pl_inventory = v_tool_owner:getHotbar()
			end

			if not (v_pl_inventory and sm.exists(v_pl_inventory)) then
				return
			end

			local v_eoka_uuid = "5a1ca305-513f-42db-ae71-52bd0a9247fc"
			for i = 0, v_pl_inventory:getSize() - 1 do
				local v_cur_item = v_pl_inventory:getItem(i)
				if tostring(v_cur_item.uuid) == v_eoka_uuid then
					if v_cur_item.instance == self.tool.id then
						sm.container.beginTransaction()
						sm.container.spendFromSlot(v_pl_inventory, i, v_cur_item.uuid, 1, true)
						sm.container.endTransaction()

						break
					end
				end
			end
		end
	end
end

function Eoka:client_onUpdate(dt)
	if not sm.exists(self.tool) then
		return
	end

	if self.cl_remove_timer then
		self.cl_remove_timer = self.cl_remove_timer - dt

		if self.cl_remove_timer <= 0.0 then
			self.cl_remove_timer = nil
			self.tool:setFpRenderables({})
		end
	end

	if self.cl_restore_timer then
		self.cl_restore_timer = self.cl_restore_timer - dt
		if self.cl_restore_timer <= 0.0 then
			self.cl_restore_timer = nil

			self.gun_used = nil
			if self.tool:isEquipped() then
				self:client_onEquip(true)
			end
		end
	end

	-- First person animation
	local isSprinting = self.tool:isSprinting()
	local isCrouching = self.tool:isCrouching()

	if self.tool:isLocal() then
		if self.equipped and not self.cl_restore_timer then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not isSprinting and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end
		end

		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	TSU_OnUpdate(self)

	self:client_updateAimWeights(dt)

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

	if self.tool:isLocal() then
		local dir = sm.localPlayer.getDirection()
		local fire_pos = self.tool:getFpBonePos("pejnt_barrel")

		local fp_eff = self.cl_shoot_fp
		fp_eff:setPosition(fire_pos + dir * 0.05)
		fp_eff:setVelocity(self.tool:getMovementVelocity())
		fp_eff:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, 1), dir))
	end

	local shoot_pos = self.tool:getTpBonePos("pejnt_barrel")
	local shoot_dir = self.tool:getTpBoneDir("pejnt_barrel")

	local tp_eff = self.cl_shoot_tp
	tp_eff:setPosition(shoot_pos)
	tp_eff:setVelocity(self.tool:getMovementVelocity())
	tp_eff:setRotation(sm.vec3.getRotation(sm.vec3.new(0, 0, 1), shoot_dir))

	if self.tool:isLocal() then
		local dispersion = 0.0
		local fireMode = self.normalFireMode

		if isCrouching then
			dispersion = fireMode.minDispersionCrouching
		else
			dispersion = fireMode.minDispersionStanding
		end

		if self.tool:getRelativeMoveDirection():length() > 0 then
			dispersion = dispersion + fireMode.maxMovementDispersion * self.tool:getMovementSpeedFraction()
		end

		if not self.tool:isOnGround() then
			dispersion = dispersion * fireMode.jumpDispersionMultiplier
		end

		self.movementDispersion = dispersion

		self.tool:setDispersionFraction( clamp( self.movementDispersion, 0.0, 1.0 ) )

		self.tool:setCrossHairAlpha( 1.0 )
		self.tool:setInteractionTextSuppressed( false )
	end

	-- Sprint block
	self.tool:setBlockSprint(self.cl_remove_timer ~= nil or self.cl_restore_timer ~= nil)

	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )

	down = clamp( -angle, 0.0, 1.0 )
	fwd = ( 1.0 - math.abs( angle ) )
	up = clamp( angle, 0.0, 1.0 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, "idle", 0.001 )
				elseif  name == "ammo_check" then
					setTpAnimation( self.tpAnimations, "idle", 3 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end

	-- Third Person joint lock
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local finalAngle = ( 0.5 + angle * 0.5 )
	self.tool:updateAnimation( "spudgun_spine_bend", finalAngle, self.spineWeight )

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )


	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )
end

function Eoka:client_onEquip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	if self.gun_used then
		self.tool:setTpRenderables({})
		return
	end

	self.wantEquipped = true
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	--Set the tp and fp renderables before actually loading animations
	self.tool:setTpRenderables(currentRenderablesTp)
	local is_tool_local = self.tool:isLocal()
	if is_tool_local then
		self.tool:setFpRenderables(currentRenderablesFp)
	end

	--Load animations before setting them
	self:loadAnimations()

	--Set tp and fp animations
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if is_tool_local then
		swapFpAnimation(self.fpAnimations, "unequip", "equip", 0.2)
	end
end

function Eoka:client_onUnequip(animate, is_custom)
	if not is_custom and TSU_IsOwnerSwimming(self) then
		return
	end

	self.wantEquipped = false
	self.equipped = false

	local s_tool = self.tool
	if sm.exists(s_tool) then
		if animate then
			sm.audio.play( "PotatoRifle - Unequip", s_tool:getPosition() )
		end

		if is_custom then
			s_tool:setTpRenderables({})
		else
			setTpAnimation( self.tpAnimations, "putdown" )
		end

		if s_tool:isLocal() then
			s_tool:setMovementSlowDown( false )
			s_tool:setBlockSprint( false )
			s_tool:setCrossHairAlpha( 1.0 )
			s_tool:setInteractionTextSuppressed( false )
			s_tool:setDispersionFraction(0.0)

			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

function Eoka:sv_n_onShoot(gun_slot)
	self.network:sendToClients("cl_n_onShoot")

	if sm.game.getEnableAmmoConsumption() and sm.game.getLimitedInventory() then
		self.sv_gun_timer = 3.0
	end
end

function Eoka:cl_n_onShoot()
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot()
	end
end

function Eoka:onShoot()
	self.tpAnimations.animations.idle.time  = 0
	self.tpAnimations.animations.shoot.time = 0

	setTpAnimation(self.tpAnimations, "shoot", 10.0)
	if self.tool:isInFirstPersonView() then
		self.cl_shoot_fp:start()
	else
		self.cl_shoot_tp:start()
	end
end

---@return Vec3
function Eoka:calculateFirePosition()
	local crouching = self.tool:isCrouching()
	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()

	local fireOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	if crouching then
		fireOffset.z = 0.15
	else
		fireOffset.z = 0.45
	end

	if firstPerson then
		fireOffset = fireOffset + right * 0.05
	else
		fireOffset = fireOffset + right * 0.25
		fireOffset = fireOffset:rotate( math.rad( pitch ), right )
	end

	return GetOwnerPosition(self.tool) + fireOffset
end

function Eoka:calculateTpMuzzlePos()
	local crouching = self.tool:isCrouching()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()
	local up = right:cross(dir)

	local fakeOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	--General offset
	fakeOffset = fakeOffset + right * 0.25
	fakeOffset = fakeOffset + dir * 0.5
	fakeOffset = fakeOffset + up * 0.25

	--Action offset
	local pitchFraction = pitch / ( math.pi * 0.5 )
	if crouching then
		fakeOffset = fakeOffset + dir * 0.2
		fakeOffset = fakeOffset + up * 0.1 --[[@as Vec3]]
		fakeOffset = fakeOffset - right * 0.05

		if pitchFraction > 0.0 then
			fakeOffset = fakeOffset - up * 0.2 * pitchFraction
		else
			fakeOffset = fakeOffset + up * 0.1 * math.abs( pitchFraction )
		end
	else
		fakeOffset = fakeOffset + up * 0.1 *  math.abs( pitchFraction )
	end

	local fakePosition = fakeOffset + GetOwnerPosition( self.tool )
	return fakePosition
end

function Eoka:calculateFpMuzzlePos()
	local fovScale = ( sm.camera.getFov() - 45 ) / 45

	local up = sm.localPlayer.getUp()
	local dir = sm.localPlayer.getDirection()
	local right = sm.localPlayer.getRight()

	local muzzlePos45 = sm.vec3.new( 0.0, 0.0, 0.0 )
	local muzzlePos90 = sm.vec3.new( 0.0, 0.0, 0.0 )

	muzzlePos45 = muzzlePos45 - up * 0.15
	muzzlePos45 = muzzlePos45 + right * 0.2
	muzzlePos45 = muzzlePos45 + dir * 1.25

	muzzlePos90 = muzzlePos90 - up * 0.15
	muzzlePos90 = muzzlePos90 + right * 0.2
	muzzlePos90 = muzzlePos90 + dir * 0.25

	return self.tool:getFpBonePos( "pejnt_barrel" ) + sm.vec3.lerp( muzzlePos45, muzzlePos90, fovScale )
end

local mgp_projectile_potato = sm.uuid.new("35588452-1e08-46e8-aaf1-e8abb0cf7692")
function Eoka:cl_onPrimaryUse(state)
	if state ~= sm.tool.interactState.start or not self.equipped then return end

	if self.gun_used then return end

	local v_toolOwner = self.tool:getOwner()
	if not (v_toolOwner and sm.exists(v_toolOwner)) then
		return
	end

	if self.tool:isSprinting() then
		return
	end

	local v_ownerChar = v_toolOwner.character
	if not (v_ownerChar and sm.exists(v_ownerChar)) then
		return
	end

	self.gun_used = true
	if sm.game.getEnableAmmoConsumption() and sm.game.getLimitedInventory() then
		self.cl_remove_timer = 2.5
	else
		self.cl_restore_timer = 2.5
	end

	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()

	local firePos = self:calculateFirePosition()
	local fakePosition = self:calculateTpMuzzlePos()
	local fakePositionSelf = fakePosition
	if firstPerson then
		fakePositionSelf = self:calculateFpMuzzlePos()
	end

	-- Aim assist
	if not firstPerson then
		local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
		local hit, result = sm.localPlayer.getRaycast( 250, raycastPos, sm.camera.getDirection() )
		if hit then
			local norDir = sm.vec3.normalize( result.pointWorld - firePos )
			local dirDot = norDir:dot( dir )

			if dirDot > 0.96592583 then -- max 15 degrees off
				dir = norDir
			else
				local radsOff = math.asin( dirDot )
				dir = sm.vec3.lerp( dir, norDir, math.tan( radsOff ) / 3.7320508 ) -- if more than 15, make it 15
			end
		end
	end

	dir = dir:rotate( math.rad( 0.6 ), sm.camera.getRight() ) -- 25 m sight calibration

	-- Spread
	local fireMode = self.normalFireMode
	local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

	local spreadFactor = clamp( self.movementDispersion * recoilDispersion, 0.0, 1.0 )
	local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

	dir = sm.noise.gunSpread( dir, spreadDeg )
	sm.projectile.projectileAttack( mgp_projectile_potato, Damage, firePos, dir * fireMode.fireVelocity, v_toolOwner, fakePosition, fakePositionSelf )

	-- Send TP shoot over network and dircly to self
	self:onShoot()
	self.network:sendToServer("sv_n_onShoot")

	-- Play FP shoot animation
	setFpAnimation( self.fpAnimations, "shoot", 0.0 )
end

function Eoka:client_onReload() return true end

function Eoka:client_onEquippedUpdate(primaryState, secondaryState)
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse(primaryState)
		self.prevPrimaryState = primaryState
	end

	return true, true
end