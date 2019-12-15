
--[[
	When whooting a weapon the camera falls back to the starting angle. This original angle is stored
	in AimingSimulation.AimAssist, so in order to get rid of the reset we add the recoil increase in each
	GunSway:UpdateRecoil call to the AimAssist and set the recoil to 0 after. This makes the starting
	angle the same as the final one, removing the fallback.
--]]


Events:Subscribe('GunSway:UpdateRecoil', function(gunSway, soldierWeapon, weaponFiring, deltaTime)
	-- Only update if we have a weapon.
	if soldierWeapon == nil then
		return
	end

	-- soldierWeapon is an entity, we cast it to its type (SoldierWeapon) so we can access its fields. 
	local weapon = SoldierWeapon(soldierWeapon)

	-- Get the aiming simulation.
	local simulation = weapon.aimingSimulation

	if simulation == nil or gunSway == nil then
		return
	end

	-- Get the aim assist handler and the recoil deviation produced since the previous OnGunSwayUpdateRecoil call.
	local aimAssist = simulation.aimAssist
	local recoilDeviation = gunSway.currentRecoilDeviation

	-- We add the recoil increse to the AimAssist current angle.
	aimAssist.yaw = aimAssist.yaw - recoilDeviation.yaw
	aimAssist.pitch = aimAssist.pitch - recoilDeviation.pitch

	-- We now set the recoil to 0, so it doesn't fall back to the starting angle when the weapon stops firing.
	recoilDeviation.yaw = 0
	recoilDeviation.pitch = 0
end)