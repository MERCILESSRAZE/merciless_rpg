-- 1st Skill: Flux (AoE Урон + 3 сек Замедление + Самоурон)

merciless_arc_warden_flux = class({})

LinkLuaModifier("modifier_merciless_arc_warden_flux_slow", "abilities/merciless_arc_warden_flux", LUA_MODIFIER_MOTION_NONE)

function merciless_arc_warden_flux:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function merciless_arc_warden_flux:OnSpellStart()
	local caster = self:GetCaster()
	local targetPos = self:GetCursorPosition()

	if not caster or caster:IsNull() then return end

	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local moveSlow = self:GetSpecialValueFor("move_slow")
	local selfDamagePerUnit = self:GetSpecialValueFor("self_damage_per_unit")
	local duration = self:GetSpecialValueFor("duration")

	EmitSoundOnLocationWithCaster(targetPos, "Hero_ArcWarden.Flux.Cast", caster)

	-- Ищем врагов в области применения
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		targetPos,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local unitsHitCount = #enemies

	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() and enemy:IsAlive() then
			-- Наносим магический урон врагу
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self
			})

			-- Замедление движения на 3 секунды
			enemy:AddNewModifier(caster, self, "modifier_merciless_arc_warden_flux_slow", {
				duration = duration,
				slow_pct = moveSlow
			})
		end
	end

	-- Если задет хотя бы один враг, наносим суммарный самоурон
	if unitsHitCount > 0 then
		local totalSelfDamage = unitsHitCount * selfDamagePerUnit

		ApplyDamage({
			victim = caster,
			attacker = caster,
			damage = totalSelfDamage,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			ability = self
		})
	end
end

--------------------------------------------------------------------------------
-- Модификатор замедления врагов
modifier_merciless_arc_warden_flux_slow = class({})

function modifier_merciless_arc_warden_flux_slow:IsHidden() return false end
function modifier_merciless_arc_warden_flux_slow:IsDebuff() return true end

function modifier_merciless_arc_warden_flux_slow:OnCreated(kv)
	if IsServer() then
		self.slowPct = kv.slow_pct or 30
	end
end

function modifier_merciless_arc_warden_flux_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_merciless_arc_warden_flux_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self.slowPct or 30)
end
