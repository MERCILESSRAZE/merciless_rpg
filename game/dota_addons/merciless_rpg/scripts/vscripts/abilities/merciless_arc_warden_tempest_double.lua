-- 4th Skill (Ultimate): Tempest Double (Пассивная вторая тичка 40%/60%/100%)
-- БЕЗ ТАЛАНТА 25: вторая атака наносит обычный урон (с Divine Rapier, но без критов/вампиризма)
-- С ТАЛАНТОМ 25: вторая атака - полноценный PerformAttack (критует, вампирит, баши работают)

merciless_arc_warden_tempest_double = class({})

LinkLuaModifier("modifier_merciless_arc_warden_tempest_double_passive", "abilities/merciless_arc_warden_tempest_double", LUA_MODIFIER_MOTION_NONE)

function merciless_arc_warden_tempest_double:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function merciless_arc_warden_tempest_double:GetIntrinsicModifierName()
	return "modifier_merciless_arc_warden_tempest_double_passive"
end

--------------------------------------------------------------------------------
modifier_merciless_arc_warden_tempest_double_passive = class({})

function modifier_merciless_arc_warden_tempest_double_passive:IsHidden() return false end
function modifier_merciless_arc_warden_tempest_double_passive:IsDebuff() return false end

function modifier_merciless_arc_warden_tempest_double_passive:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_merciless_arc_warden_tempest_double_passive:OnAttackLanded(event)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()

	-- Проверки валидности
	if not ability or ability:GetLevel() == 0 then return end
	if event.attacker ~= parent then return end
	if not event.target or event.target:IsNull() or not event.target:IsAlive() then return end

	-- Защита от бесконечного цикла
	if self.processingSecondAttack then return end

	local pct = ability:GetSpecialValueFor("second_attack_damage_pct") / 100.0
	
	-- Проверяем талант 25
	local talent25 = parent:FindAbilityByName("special_bonus_merciless_arc_warden_4")
	local hasTalent25 = (talent25 and talent25:GetLevel() > 0)

	self.processingSecondAttack = true

	if hasTalent25 then
		-- С ТАЛАНТОМ 25: Полноценный attack pipeline
		parent:PerformAttack(
			event.target,
			true,  -- bUseMods - критит, вампирит, бачит!
			true,  -- bUseOrbs
			true,  -- bUseProjectile
			false, -- bUseRangeCheck
			false, -- bIsWholeAttack
			false, -- bAllowIllusions
			true   -- bAttachModifier
		)
	else
		-- БЕЗ ТАЛАНТА 25: Урон включает Divine Rapier, но НЕ критует/не вампирит
		local baseDamage = parent:GetAverageTrueAttackDamage(event.target)
		local secondHitDamage = baseDamage * pct

		ApplyDamage({
			victim = event.target,
			attacker = parent,
			damage = secondHitDamage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
			ability = ability
		})

		EmitSoundOn("Hero_ArcWarden.Attack", event.target)
	end

	self.processingSecondAttack = false
end
