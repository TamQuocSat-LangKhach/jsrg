local zhenfeng = fk.CreateSkill {
  name = "zhenfeng"
}

Fk:loadTranslationTable{
  ['zhenfeng'] = '针锋',
  ['#zhenfeng'] = '针锋：你可以视为使用一种场上角色技能描述中包含的牌',
  [':zhenfeng'] = '出牌阶段每种类别的牌限一次，你可以视为使用一张存活角色技能描述中包含的牌（无次数距离限制且须为基本牌或普通锦囊牌），当此牌对该角色生效后，你对其造成1点伤害。',
}

-- ViewAsSkill
zhenfeng:addEffect('viewas', {
  prompt = "#zhenfeng",
  interaction = function(skill)
    local names = {}
    for _, card in pairs(Fk.all_card_types) do
      if ((card.type == Card.TypeBasic and skill.player:getMark("zhenfeng_basic-phase") == 0) or
        (card:isCommonTrick() and skill.player:getMark("zhenfeng_trick-phase") == 0)) and
        not card.is_derived and not table.contains(names, card.name) then
        local c = Fk:cloneCard(card.name)
        c.skillName = zhenfeng.name
        if skill.player:canUse(c) and not skill.player:prohibitUse(c) then
          local p = skill.player
          repeat
            for _, s in ipairs(p.player_skills) do
              if s:isPlayerSkill(p) and s.visible then
                if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(c.name, "zh_CN").."】") or
                  string.find(Fk:translate(":"..s.name, "zh_CN"), Fk:translate(c.name, "zh_CN")[1].."【"..Fk:translate(c.trueName, "zh_CN").."】") then
                  table.insertIfNeed(names, c.name)
                end
              end
            end
            p = p:getNextAlive()
          until p.id == skill.player.id
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = zhenfeng.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:setPlayerMark(player, "zhenfeng_"..use.card:getTypeString().."-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("zhenfeng_basic-phase") == 0 or player:getMark("zhenfeng_trick-phase") == 0
  end,
})

-- TargetModSkill
zhenfeng:addEffect('targetmod', {
  bypass_distances = function(self, player, skill2, card)
    return card and table.contains(card.skillNames, "zhenfeng")
  end,
  bypass_times = function(self, player, skill2, scope, card)
    return card and table.contains(card.skillNames, "zhenfeng")
  end,
})

-- TriggerSkill
zhenfeng:addEffect(fk.CardEffectFinished, {
  can_trigger = function(self, event, target, player, data)
    if player.id == data.from and table.contains(data.card.skillNames, "zhenfeng") and data.to then
      local to = player.room:getPlayerById(data.to)
      if to.dead then return end
      for _, s in ipairs(to.player_skills) do
        if s:isPlayerSkill(to) and s.visible then
          if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(data.card.name, "zh_CN").."】") or
            string.find(Fk:translate(":"..s.name, "zh_CN"), Fk:translate(data.card.name, "zh_CN")[1].."【"..Fk:translate(data.card.trueName, "zh_CN").."】") then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhenfeng")
    player.room:notifySkillInvoked(player, "zhenfeng", "offensive")
    room:doIndicate(player.id, {data.to})
    room:damage{
      from = player,
      to = room:getPlayerById(data.to),
      damage = 1,
      skillName = zhenfeng.name,
    }
  end,
})

return zhenfeng
