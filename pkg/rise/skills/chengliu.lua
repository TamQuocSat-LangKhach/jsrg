local chengliu = fk.CreateSkill {
  name = "chengliu"
}

Fk:loadTranslationTable{
  ['chengliu'] = '乘流',
  ['#chengliu-invoke'] = '乘流：对一名装备数小于你的角色造成1点伤害，然后你可以弃置一张装备重复此流程',
  ['#chengliu-discard'] = '乘流：是否弃置一张装备，继续造成伤害？',
  [':chengliu'] = '准备阶段，你可以对一名装备区内牌数小于你的角色造成1点伤害，然后你可以弃置装备区内的一张牌，对一名本回合未以此法选择过的角色重复此流程。',
}

chengliu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(chengliu.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return #player:getCardIds("e") > #p:getCardIds("e")
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return #player:getCardIds("e") > #p:getCardIds("e")
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = chengliu.name,
      prompt = "#chengliu-invoke",
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = event:getCostData(self)
    local to = room:getPlayerById(data.tos[1])
    room:addTableMark(player, "chengliu-turn", to.id)
    room:damage({
      from = player,
      to = to,
      damage = 1,
      skillName = chengliu.name,
    })
    while not player.dead and #player:getCardIds("e") > 0 do
      local targets = table.filter(room.alive_players, function (p)
        return #player:getCardIds("e") > #p:getCardIds("e") and not table.contains(player:getTableMark("chengliu-turn"), p.id)
      end)
      if #targets == 0 then return end
      local cards = table.filter(player:getCardIds("e"), function (id)
        return not player:prohibitDiscard(id)
      end)
      local success, dat = room:askToUseActiveSkill(player, "ex__choose_skill", {
        prompt = "#chengliu-discard",
        cancelable = true,
        extra_data = {
          targets = table.map(targets, Util.IdMapper),
          min_c_num = 1,
          max_c_num = 1,
          min_t_num = 1,
          max_t_num = 1,
          pattern = tostring(Exppattern{ id = cards }),
          skillName = chengliu.name
        },
        no_indicate = false
      })
      if success then
        to = room:getPlayerById(dat.targets[1])
        room:addTableMark(player, "chengliu-turn", to.id)
        room:throwCard(dat.cards, chengliu.name, player, player)
        if not to.dead then
          room:damage({
            from = player,
            to = to,
            damage = 1,
            skillName = chengliu.name,
          })
        end
      else
        return
      end
    end
  end,
})

return chengliu
