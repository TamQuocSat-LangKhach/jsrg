local js__xianzhu = fk.CreateSkill {
  name = "js__xianzhu"
}

Fk:loadTranslationTable{
  ['js__xianzhu'] = '先著',
  ['#js__xianzhu'] = '先著：你可以将一张普通锦囊牌当无次数限制的【杀】使用，若对唯一目标造成伤害，视为对其使用此锦囊',
  ['#js__xianzhu_trigger'] = '先著',
  ['#js__xianzhu-choose'] = '先著：选择对%dest使用的【%arg】的副目标',
  [':js__xianzhu'] = '魏势力技，你可以将一张普通锦囊牌当无次数限制的【杀】使用，此【杀】对唯一目标造成伤害后，你视为对目标额外执行该锦囊牌的效果。',
}

js__xianzhu:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#js__xianzhu",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):isCommonTrick()
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = js__xianzhu.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

js__xianzhu:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "js__xianzhu")
  end,
})

js__xianzhu:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, "js__xianzhu") and not player.dead and not data.to.dead then
      local card = Fk:getCardById(data.card.subcards[1])
      local to_use = Fk:cloneCard(card.name)
      if card:isCommonTrick() and not player:prohibitUse(to_use) and not player:isProhibited(data.to, to_use) and
        card.skill:modTargetFilter(player.id, data.to.id, {}, to_use, true) then
        local room = player.room
        local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if e then
          local use = e.data[1]
          return #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(use.tos)[1] == data.to.id
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(data.card.subcards[1])
    local tos = {data.to.id}
    local to_use = Fk:cloneCard(card.name)
    to_use.skillName = js__xianzhu.name
    if not card:isCommonTrick() or card.skill:getMinTargetNum() > 2 then
      return false
    elseif card.skill:getMinTargetNum() == 2 then
      local targets = table.filter(room.alive_players, function (p)
        return not table.contains(tos, p.id) and card.skill:targetFilter(player.id, data.to.id, {}, to_use, nil, player)
      end)
      if #targets > 0 then
        local to_slash = room:askToChoosePlayers(player, {
          targets = table.map(targets, Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#js__xianzhu-choose::" .. data.to.id .. ":" .. card.name,
          skill_name = js__xianzhu.name,
          cancelable = false
        })
        if #to_slash > 0 then
          table.insert(tos, to_slash[1])
        end
      else
        return false
      end
    end
    room:useCard({
      from = player.id,
      tos = table.map(tos, function(pid) return { pid } end),
      card = to_use,
      extraUse = true,
    })
  end,
})

return js__xianzhu
