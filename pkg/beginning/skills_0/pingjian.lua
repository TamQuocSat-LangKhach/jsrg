local pingjian = fk.CreateSkill {
  name = "js__pingjian",
}

Fk:loadTranslationTable{
  ["js__pingjian"] = "评鉴",
  ["@&js_fangke"] = "访客",
  ["#js_lose_fangke"] = "评鉴：移除一张访客，若移除 %arg 则摸牌",
  [":js__pingjian"] = "当“访客”上的无类型标签或者只有锁定技标签的技能满足发动时机时，你可以发动该技能。此技能的效果结束后，你须移除一张“访客”，若移除的是含有该技能的“访客”，你摸一张牌。<br/><font color=>（注：由于判断发动技能的相关机制尚不完善，请不要汇报发动技能后某些情况下访客不丢的bug）</font>",
  ["$js__pingjian1"] = "太丘道广，广则不周。仲举性峻，峻则少通。",
  ["$js__pingjian2"] = "君生清平则为奸逆，处乱世当居豪雄。",
}

pingjian:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(pingjian.name) and #player:getTableMark("@&js_fangke") > 0
      and player:getMark("js_fangke_skills") ~= 0 and table.contains(player:getMark("js_fangke_skills"), data.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local choices = player:getMark("@&js_fangke")
    local owner = table.find(choices, function (name)
      local general = Fk.generals[name]
      return table.contains(general:getSkillNameList(), data.name)
    end) or "?"
    local choice = choices[1]
    if #choices > 1 then
      local result = player.room:askToCustomDialog(player, {
        skill_name = pingjian.name,
        qml_path = "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml",
        extra_data = { choices, {"OK"}, "#js_lose_fangke:::"..owner },
      })
      if result ~= "" then
        local reply = json.decode(result)
        choice = reply.cards[1]
      end
    end
    removeFangke(player, choice)
    if choice == owner and not player.dead then
      player:drawCards(1, pingjian.name)
    end
  end,
})

pingjian:addEffect("lose", {
  on_lose = function (self, player)
    if player:getMark("@&js_fangke") ~= 0 then
      for _, g in ipairs(player:getMark("@&js_fangke")) do
        removeFangke(player, g)
      end
    end
  end,
})

return pingjian
