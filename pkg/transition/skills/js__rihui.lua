local js__rihui = fk.CreateSkill {
  name = "js__rihui"
}

Fk:loadTranslationTable{
  ['js__rihui'] = '日彗',
  ['#js__rihui-invoke'] = '日彗：你可以令判定区内有牌的其他角色各摸一张牌',
  [':js__rihui'] = '当你使用【杀】对目标造成伤害后，你可以令判定区内有牌的其他角色各摸一张牌；你于出牌阶段对每名判定区内没有牌的角色使用的首张【杀】无次数限制。',
}

-- 主技能效果
js__rihui:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(js__rihui.name) and data.card and data.card.trueName == "slash" and not data.chain and
      table.find(player.room:getOtherPlayers(player, false), function(p) return #p:getCardIds("j") > 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = js__rihui.name,
      prompt = "#js__rihui-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p:getCardIds("j") > 0 and not p.dead then
        room:doIndicate(player.id, {p.id})
        p:drawCards(1, js__rihui.name)
      end
    end
  end,
})

-- 子技能效果
js__rihui:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(js__rihui.name) and data.card and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return to:getMark("js__rihui-phase") == 0 and #to:getCardIds("j") == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    room:addPlayerMark(room:getPlayerById(data.to), "js__rihui-phase", 1)
  end,
})

return js__rihui
