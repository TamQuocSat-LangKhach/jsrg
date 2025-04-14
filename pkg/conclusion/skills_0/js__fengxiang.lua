local js__fengxiang = fk.CreateSkill {
  name = "js__fengxiang"
}

Fk:loadTranslationTable{
  ['js__fengxiang'] = '封乡',
  ['#js__fengxiang-choose'] = '封乡：与一名其他角色交换装备区内的所有牌',
  [':js__fengxiang'] = '锁定技，当你受到伤害后，你须与一名其他角色交换装备区内的所有牌，若你装备区内的牌数因此而减少，你摸等同于减少数的牌。',
}

js__fengxiang:addEffect(fk.Damaged, {
  frequency = Skill.Compulsory,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(skill.name) and #player.room.alive_players > 1
      and table.find(player.room.alive_players, function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#js__fengxiang-choose",
      skill_name = skill.name,
      cancelable = false
    })
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local num = 0
      local cards1 = player:getCardIds("e")
      local cards2 = to:getCardIds("e")
      local moveInfos = {}
      if #cards1 > 0 then
        table.insert(moveInfos, {
          from = player.id,
          ids = cards1,
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = skill.name,
        })
      end
      if #cards2 > 0 then
        table.insert(moveInfos, {
          from = to.id,
          ids = cards2,
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = skill.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end

      moveInfos = {}

      if not to.dead then
        local to_ex_cards1 = table.filter(cards1, function (id)
          return room:getCardArea(id) == Card.Processing and to:getEquipment(Fk:getCardById(id).sub_type) == nil
        end)
        if #to_ex_cards1 > 0 then
          table.insert(moveInfos, {
            ids = to_ex_cards1,
            fromArea = Card.Processing,
            to = to.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = skill.name,
          })
        end
      end
      if not player.dead then
        local to_ex_cards = table.filter(cards2, function (id)
          return room:getCardArea(id) == Card.Processing and player:getEquipment(Fk:getCardById(id).sub_type) == nil
        end)
        num = #cards1 - #to_ex_cards
        if #to_ex_cards > 0 then
          table.insert(moveInfos, {
            ids = to_ex_cards,
            fromArea = Card.Processing,
            to = player.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = skill.name,
          })
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end

      if not player.dead and num > 0 then
        player:drawCards(num, js__fengxiang.name)
      end
    end
  end,
})

return js__fengxiang
