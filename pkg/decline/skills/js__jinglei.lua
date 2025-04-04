local js__jinglei = fk.CreateSkill {
  name = "js__jinglei"
}

Fk:loadTranslationTable{
  ['js__jinglei'] = '惊雷',
  ['#jinglei-choose'] = '惊雷：你可选择一名角色，然后令任意名手牌数之和小于其的角色各对其造成一点雷电伤害',
  ['jinglei_active'] = '惊雷',
  ['#jinglei-use'] = '惊雷：选择任意名手牌数之和不大于 %arg 的角色各对 %dest 造成一点雷电伤害。',
  [':js__jinglei'] = '准备阶段开始时，你可以选择一名手牌数不为最少的角色，然后你令任意名手牌数之和小于其的角色各对其造成1点雷电伤害。',
}

js__jinglei:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(js__jinglei.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local min_num = 999
    for _, p in ipairs(room.alive_players) do
      min_num = math.min(min_num, p:getHandcardNum())
    end
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = table.map(table.filter(room.alive_players, function(p) return p:getHandcardNum() > min_num end), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#jinglei-choose",
        skill_name = js__jinglei.name
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local n = to:getHandcardNum()
    room:setPlayerMark(player, js__jinglei.name, n)
    local success, dat = room:askToUseActiveSkill(
      player,
      {
        skill_name = "jinglei_active",
        prompt = "#jinglei-use::" .. to.id .. ":" .. n,
        cancelable = false
      }
    )
    if success then
      local tos = table.simpleClone(dat.targets)
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if p:isAlive() and to:isAlive() then
          room:doIndicate(p.id, { to.id })
          room:damage{
            from = p,
            to = to,
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = js__jinglei.name
          }
        end
      end
    end
  end,
})

return js__jinglei
