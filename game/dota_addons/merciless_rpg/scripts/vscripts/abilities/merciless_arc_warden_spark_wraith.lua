-- 3rd Skill: Spark Wraith (Атакует до 3/5 целей одновременно, потом исчезает)

merciless_arc_warden_spark_wraith = class({})

LinkLuaModifier("modifier_merciless_arc_warden_spark_wraith_thinker", "abilities/merciless_arc_warden_spark_wraith", LUA_MODIFIER_MOTION_NONE)

function merciless_arc_warden_spark_wraith:GetAOERadius()
	return self:GetSpecialValueFor("search_radius")
end

function merciless_arc_warden_spark_wraith:OnSpellStart()
	local caster = self:GetCaster()
	local targetPos = self:GetCursorPosition()

	local radius = self:GetSpecialValueFor("search_radius")
	local damage = self:GetSpecialValueFor("damage")
	local targetsCount = self:GetSpecialValueFor("targets_count")

	-- Создаём тинкер, который СРАЗУ атакует врагов и исчезает
	CreateModifierThinker(
		caster,
		self,
		"modifier_merciless_arc_warden_spark_wraith_thinker",
		{
			duration = 0.1, -- Очень короткая длительность
			radius = radius,
			damage = damage,
			targets_count = targetsCount
		},
		targetPos,
		caster:GetTeamNumber(),
		false
	)

	EmitSoundOnLocationWithCaster(targetPos, "Hero_ArcWarden.SparkWraith.Cast", caster)
end

--------------------------------------------------------------------------------
modifier_merciless_arc_warden_spark_wraith_thinker = class({})

function modifier_merciless_arc_warden_spark_wraith_thinker:IsHidden() return true end

function modifier_merciless_arc_warden_spark_wraith_thinker:OnCreated(kv)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	local caster = self:GetCaster()

	if not caster or caster:IsNull() then
		self:Destroy()
		return
	end

	self.radius = kv.radius or (ability and ability:GetSpecialValueFor("search_radius")) or 375
	self.damage = kv.damage or (ability and ability:GetSpecialValueFor("damage")) or 100
	self.targetsCount = kv.targets_count or (ability and ability:GetSpecialValueFor("targets_count")) or 3

	-- Отображаем частицы области действия
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_spark_wraith_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(self.radius, self.radius, self.radius))
	self:AddParticle(pfx, false, false, -1, false, false)

	-- СРАЗУ ЖЕ ищем и атакуем врагов
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	if #enemies > 0 then
		EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_ArcWarden.SparkWraith.Activate", caster)

		local hitCount = 0
		for _, enemy in pairs(enemies) do
			if hitCount < self.targetsCount and enemy and not enemy:IsNull() and enemy:IsAlive() then
				hitCount = hitCount + 1

				-- Частица полёта
				local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_spark_wraith_projectile.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
				ParticleManager:SetParticleControlEnt(pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(pfx)

				-- Наносим магический урон
				ApplyDamage({
					victim = enemy,
					attacker = caster,
					damage = self.damage,
					damage_type = DAMAGE_TYPE_MAGICAL,
					ability = ability
				})

				EmitSoundOn("Hero_ArcWarden.SparkWraith.Damage", enemy)
			end
		end
	end

	-- Модификатор исчезает сразу
	self:Destroy()
end
