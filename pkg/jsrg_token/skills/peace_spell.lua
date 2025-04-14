local skill = fk.CreateSkill {
  name = "#js__peace_spell_skill",
  tags = { Skill.Compulsory },
  attached_equip = "js__peace_spell",
}

Fk:loadTranslationTable{
  ["#js__peace_spell_skill"] = "太平要术",
}

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).name == skill.attached_equip then
            return Fk.skills[skill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, skill.name)
    if player.hp > 1 then
      player.room:loseHp(player, 1, skill.name)
    end
  end,
})

skill:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

skill:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(skill.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    end
  end,
})

return skill
