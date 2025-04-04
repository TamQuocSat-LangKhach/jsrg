local qingxix = fk.CreateSkill {
  name = "qingxix"
}

Fk:loadTranslationTable{
  ['qingxix'] = '轻袭',
  ['#qingxix'] = '轻袭：选择一名手牌数小于你的角色，将手牌弃至与其相同，视为对其使用刺【杀】',
  [':qingxix'] = '群势力技，出牌阶段对每名角色限一次，你可以选择一名手牌数小于你的角色，你将手牌弃至与其相同，然后视为对其使用一张无距离和次数限制的刺【杀】。',
}

qingxix:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#qingxix",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() < player:getHandcardNum() and target:getMark("qingxix-phase") == 0 and
      not player:isProhibited(target, Fk:cloneCard("stab__slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "qingxix-phase", 1)
    local n = player:getHandcardNum() - target:getHandcardNum()
    if n <= 0 then return end
    local cards = room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = qingxix.name,
      cancelable = false,
      pattern = ".|.|.|hand",
    })
    if #cards < n then return end
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("stab__slash"),
      extraUse = true,
    }
    use.card.skillName = qingxix.name
    room:useCard(use)
  end,
})

return qingxix
