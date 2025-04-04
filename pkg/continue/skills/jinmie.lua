local jinmie = fk.CreateSkill {
  name = "jinmie"
}

Fk:loadTranslationTable{
  ['jinmie'] = '烬灭',
  ['#jinmie'] = '烬灭：选择一名手牌数大于你的角色，视为对其使用火【杀】，若造成伤害弃置其手牌',
  [':jinmie'] = '魏势力技，出牌阶段限一次，你可以选择一名手牌数大于你的角色，视为对其使用一张无距离和次数限制的火【杀】。此牌造成伤害后，你将其手牌弃置至与你相同。',
}

jinmie:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#jinmie",
  can_use = function(self, player)
    return player:usedSkillTimes(jinmie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() > player:getHandcardNum() and not player:isProhibited(target, Fk:cloneCard("fire__slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("fire__slash"),
      extraUse = true,
    }
    use.card.skillName = jinmie.name
    room:useCard(use)
    if not player.dead and not target.dead and use.damageDealt and use.damageDealt[target.id] then
      local n = target:getHandcardNum() - player:getHandcardNum()
      if n <= 0 then return end
      room:doIndicate(player.id, {target.id})
      local cards = room:askToChooseCards(player, {
        min = n,
        max = n,
        flag = "h",
        target = target,
        skill_name = jinmie.name
      })
      room:throwCard(cards, jinmie.name, target, player)
    end
  end,
})

return jinmie
