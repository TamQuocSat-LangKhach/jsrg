local guitu = fk.CreateSkill {
  name = "guitu"
}

Fk:loadTranslationTable{
  ['guitu'] = '诡图',
  ['#guitu-choose'] = '诡图：你可以交换场上两张武器牌，攻击范围减小的角色回复1点体力',
  ['#guitu-card'] = '诡图：选择 %dest 的一张武器牌',
  [':guitu'] = '准备阶段，你可以交换场上的两张武器牌，然后攻击范围因此以此法减少的角色回复1点体力。',
}

guitu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guitu.name) and player.phase == Player.Start and
      #table.filter(player.room.alive_players, function(p) return p:getEquipment(Card.SubtypeWeapon) end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getEquipments(Card.SubtypeWeapon) > 0 end), function (p) return p.id end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 2,
      max_num = 2,
      prompt = "#guitu-choose",
      skill_name = guitu.name,
      cancelable = true,
      targets = Util.Id2PlayerMapper(targets),
    })
    if #tos == 2 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(event:getCostData(self).tos, Util.Id2PlayerMapper)
    local n = {targets[1]:getAttackRange(), targets[2]:getAttackRange()}
    local cards = {}
    for _, p in ipairs(targets) do
      if #p:getEquipments(Card.SubtypeWeapon) == 1 then
        table.insert(cards, p:getEquipments(Card.SubtypeWeapon))
      else
        local card = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 1,
          max_card_num = 1,
          targets = p:getEquipments(Card.SubtypeWeapon),
          skill_name = guitu.name,
          prompt = "#guitu-card::" .. p.id
        })
        table.insert(cards, card)
      end
    end
    U.swapCards(room, player, targets[1], targets[2], cards[1], cards[2], guitu.name, Card.PlayerEquip)
    for i = 1, 2, 1 do
      if not targets[i].dead and targets[i]:isWounded() and targets[i]:getAttackRange() < n[i] then
        room:recover{
          who = targets[i],
          num = 1,
          recoverBy = player,
          skillName = guitu.name,
        }
      end
    end
  end,
})

return guitu
