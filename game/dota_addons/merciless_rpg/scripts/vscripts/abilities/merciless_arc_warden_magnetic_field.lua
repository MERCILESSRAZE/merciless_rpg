-- 2nd Skill: Magnetic Field (Пассивная скорость атаки + Уклонение ТОЛЬКО от крипов)

merciless_arc_warden_magnetic_field = class({})

LinkLuaModifier("modifier_merciless_arc_warden_magnetic_field_passive", "abilities/merciless_arc_warden_magnetic_field", LUA_MODIFIER_MOTION_NONE)

function merciless_arc_warden_magnetic_field:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function merciless_arc_warden_magnetic_field:GetIntrinsicModifierName()
	return "modifier_merciless_arc_warden_magnetic_field_passive"
end

--------------------------------------------------------------------------------
modifier_merciless_arc_warden_magnetic_field_passive = class({})

function modifier_merciless_arc_warden_magnetic_field_passive:IsHidden() return false end
function modifier_merciless_arc_warden_magnetic_field_passive:IsDebuff() return false end
function modifier_merciless_arc_warden_magnetic_field_passive:IsPurgable() return false end

function modifier_merciless_arc_warden_magnetic_field_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

-- Бонус скорости атаки с поддержкой таланта 20 уровня
function modifier_merciless_arc_warden_magnetic_field_passive:GetModifierAttackSpeedBonus_Constant()
	local ability = self:GetAbility()
	if not ability or ability:GetLevel() == 0 then return 0 end
	return ability:GetSpecialValueFor("bonus_attack_speed")
end

-- Уклонение от атак крипов (срабатывает перед применением урона)
function modifier_merciless_arc_warden_magnetic_field_passive:OnTakeDamage(event)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()

	if not ability or ability:GetLevel() == 0 then return end
	if not parent or parent:IsNull() then return end
	if event.unit ~= parent then return end

	local attacker = event.attacker
	if not attacker or attacker:IsNull() or attacker == parent then return end

	-- Уклонение действует ТОЛЬКО против физического урона от автоатак крипов/нейтралов
	if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
	if attacker:IsHero() then return end
	if not (attacker:IsCreep() or attacker:IsNeutralUnitType()) then return end

	local evasionChance = ability:GetSpecialValueFor("creep_evasion")
	if RandomFloat(0, 100) <= evasionChance then
		event.damage = 0
		
		-- Частица доджа
		local pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_dodge.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(pfx)
		
		-- Звук доджа
		EmitSoundOn("Hero_ArcWarden.MagneticField.Dodge", parent)
	end
end
