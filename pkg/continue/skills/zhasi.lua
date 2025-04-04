local zhasi = fk.CreateSkill {
  name = "zhasi"
}

Fk:loadTranslationTable{
  ['zhasi'] = '诈死',
  ['#zhasi-invoke'] = '诈死：你可以防止受到的致命伤害，不计入距离和座次！',
  ['@@zhasi'] = '诈死',
  [':zhasi'] = '限定技，当你受到致命伤害时，你可以防止之，失去〖猘横〗并获得〖制衡〗，然后你不计入座次和距离计算，直到你对其他角色使用牌或当你受到伤害后。',
  ['$zhasi1'] = '内外大事悉付权弟，无需问我。',
  ['$zhasi2'] = '今遭小人暗算，不如将计就计。',
}

zhasi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhasi.name) and data.damage >= player.hp and
      player:usedSkillTimes(zhasi.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhasi.name,
      prompt = "#zhasi-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-zhihengs|ex__zhiheng", nil, true, false)
    room:setPlayerMark(player, "@@zhasi", 1)
    room:addPlayerMark(player, MarkEnum.PlayerRemoved, 1)
    return true
  end,

  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark("@@zhasi") > 0 then
      if event == fk.TargetSpecified then
        return data.firstTarget and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhasi", 0)
    player.room:removePlayerMark(player, MarkEnum.PlayerRemoved, 1)
  end,
})

return zhasi
