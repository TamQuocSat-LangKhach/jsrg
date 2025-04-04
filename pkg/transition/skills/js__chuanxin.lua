local js__chuanxin = fk.CreateSkill {
  name = "js__chuanxin"
}

Fk:loadTranslationTable{
  ['js__chuanxin'] = '穿心',
  ['#js__chuanxin_viewas'] = '穿心',
  ['#js__chuanxin-invoke'] = '穿心：你可以将一张牌当【杀】使用，伤害值增加目标本回合回复的体力值',
  [':js__chuanxin'] = '一名角色结束阶段，你可以将一张牌当伤害值+X的【杀】使用（X为目标角色本回合回复过的体力值）。',
}

js__chuanxin:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(js__chuanxin.name) and target.phase == Player.Finish and not (player:isNude() and #player:getHandlyIds(false) == 0)
  end,
  on_cost = function(self, event, target, player)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "#js__chuanxin_viewas",
      prompt = "#js__chuanxin-invoke",
      cancelable = true
    })
    if success then
      event:setCostData(skill.name, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local card = Fk.skills["#js__chuanxin_viewas"]:viewAs(event:getCostData(skill.name).cards)
    local n = 0
    room.logic:getEventsOfScope(GameEvent.Recover, 999, function(e)
      local recover = e.data[1]
      for _, id in ipairs(event:getCostData(skill.name).targets) do
        if recover.who.id == id then
          n = n + recover.num
        end
      end
    end, Player.HistoryTurn)
    local use = {
      from = player.id,
      tos = table.map(event:getCostData(skill.name).targets, function(id) return {id} end),
      card = card,
      extraUse = true,
      additionalDamage = n,
    }
    room:useCard(use)
  end,
})

return js__chuanxin
