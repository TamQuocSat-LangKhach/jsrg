local yingmen = fk.CreateSkill {
  name = "yingmen"
}

Fk:loadTranslationTable{
  ['yingmen'] = '盈门',
  ['@&js_fangke'] = '访客',
  ['js__pingjian'] = '评鉴',
  [':yingmen'] = '锁定技，游戏开始时，你在剩余武将牌堆中随机获得四张武将牌置于你的武将牌上，称为“访客”；回合开始前，若你的“访客”数少于四张，则你从剩余武将牌堆中将“访客”补至四张。',
  ['$yingmen1'] = '韩侯不顾？德高，门楣自盈。',
  ['$yingmen2'] = '贫而不阿，名广，胜友满座。',
}

yingmen:addEffect(fk.GameStart, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(yingmen.name)
  end,
  on_use = function (skill, event, target, player)
    local room = player.room
    local exclude_list = table.map(room.players, function(p)
      return p.general
    end)
    table.insertTable(exclude_list, banned_fangke)
    for _, p in ipairs(room.players) do
      local deputy = p.deputyGeneral
      if deputy and deputy ~= "" then
        table.insert(exclude_list, deputy)
      end
    end

    local m = player:getMark("@&js_fangke")
    local n = 4
    local generals = table.random(room.general_pile, n)
    for _, g in ipairs(generals) do
      addFangke(player, Fk.generals[g], player:hasSkill("js__pingjian", true))
    end
  end,
})

yingmen:addEffect(fk.TurnStart, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(yingmen.name) and #player:getTableMark("@&js_fangke") < 4
  end,
  on_use = function (skill, event, target, player)
    local room = player.room
    local exclude_list = table.map(room.players, function(p)
      return p.general
    end)
    table.insertTable(exclude_list, banned_fangke)
    for _, p in ipairs(room.players) do
      local deputy = p.deputyGeneral
      if deputy and deputy ~= "" then
        table.insert(exclude_list, deputy)
      end
    end

    local n = 4 - #player:getTableMark("@&js_fangke")
    local generals = table.random(room.general_pile, n)
    for _, g in ipairs(generals) do
      addFangke(player, Fk.generals[g], player:hasSkill("js__pingjian", true))
    end
  end,
})

yingmen:addEffect(fk.SkillEffect, {
  can_refresh = function (skill, event, target, player)
    return target == player and player:getMark("js_fangke_skills") ~= 0 and
      table.contains(player:getMark("js_fangke_skills"), data.name)
  end,
  on_refresh = function (skill, event, target, player, data)
    local room = player.room
    for _, s in ipairs(data.related_skills) do
      if s:isInstanceOf(StatusSkill) then
        room:addSkill(s)
      end
    end
  end,
})

return yingmen
