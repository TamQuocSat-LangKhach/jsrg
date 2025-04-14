local zuozhan = fk.CreateSkill {
  name = "zuozhan"
}

Fk:loadTranslationTable{
  ['zuozhan'] = '坐瞻',
  ['#zuozhan-choose'] = '坐瞻：请选择至多两名“坐瞻”角色，你的攻击范围增加你和这些角色中最大的体力值',
  ['@@zuozhan'] = '坐瞻',
  ['#zuozhan-prey'] = '坐瞻：令一名“坐瞻”角色从弃牌堆获得至多%arg张牌名各不相同的基本牌',
  [':zuozhan'] = '游戏开始时，你选择你与至多两名其他角色，你的攻击范围+X（X为你选择角色中最大的体力值，至多为5）。当“坐瞻”角色死亡后，你令一名存活的“坐瞻”角色从弃牌堆中获得至多X张牌名各不相同的基本牌。',
}

zuozhan:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zuozhan) then
      return #player.room.alive_players > 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 2,
      prompt = "#zuozhan-choose",
      skill_name = zuozhan.name,
      cancelable = false
    })
    table.insert(tos, player.id)
    room:setPlayerMark(player, zuozhan.name, tos)
    for _, id in ipairs(tos) do
      local p = room:getPlayerById(id)
      room:setPlayerMark(p, "@@zuozhan", 1)
    end
  end,
})

zuozhan:addEffect(fk.Deathed, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zuozhan) then
      return table.contains(player:getTableMark(zuozhan.name), target.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = {0}
    for _, id in ipairs(player:getTableMark(zuozhan.name)) do
      local p = room:getPlayerById(id)
      table.insert(nums, p.hp)
    end
    local n = math.max(table.unpack(nums))
    if n == 0 then return end
    local cards = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        cards[card.trueName] = cards[card.trueName] or {}
        table.insert(cards[card.trueName], id)
      end
    end
    if next(cards) == nil then return end
    local to = room:askToChoosePlayers(player, {
      targets = player:getTableMark(zuozhan.name),
      min_num = 1,
      max_num = 1,
      prompt = "#zuozhan-prey:::"..n,
      skill_name = zuozhan.name,
      cancelable = false
    })
    to = room:getPlayerById(to[1])
    local card_data = {}
    for _, name in ipairs({"slash", "jink", "peach", "analeptic"}) do
      if cards[name] then
        table.insert(card_data, {name, cards[name]})
      end
    end
    for name, ids in pairs(cards) do
      if not table.contains({"slash", "jink", "peach", "analeptic"}, name) and #ids > 0 then
        table.insert(card_data, {name, ids})
      end
    end
    local ret = room:askToPoxi(to, {
      poxi_type = zuozhan.name,
      data = card_data,
      extra_data = {num = n},
      cancelable = false
    })
    room:moveCardTo(ret, Card.PlayerHand, to, fk.ReasonJustMove, zuozhan.name, nil, true, to.id)
  end,
})

zuozhan:addEffect('atkrange', {
  name = "#zuozhan_attackrange",
  correct_func = function (self, from, to)
    if from:getMark("zuozhan") ~= 0 then
      local nums = {0}
      for _, id in ipairs(from:getTableMark("zuozhan")) do
        local p = Fk:currentRoom():getPlayerById(id)
        table.insert(nums, p.hp)
      end
      return math.max(table.unpack(nums))
    end
  end,
})

return zuozhan
