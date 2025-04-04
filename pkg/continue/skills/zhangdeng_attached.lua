local zhangdeng_attached = fk.CreateSkill {
  name = "zhangdeng&"
}

Fk:loadTranslationTable{
  ['zhangdeng&'] = '帐灯',
  ['#zhangdeng-active'] = '发动帐灯，视为使用一张【酒】',
  [':zhangdeng&'] = '当你需要使用【酒】时，若你与邹氏的武将牌均为背面朝上，你可以视为使用之。',
}

zhangdeng_attached:addEffect('viewas', {
  prompt = "#zhangdeng-active",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "zhangdeng_used-turn")
    end
  end,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = skill.name
    return c
  end,
  enabled_at_play = function (skill, player)
    return not player.faceup and not table.every(Fk:currentRoom().alive_players, function (p)
      return not p:hasSkill(zhangdeng_attached) or p.faceup
    end)
  end,
  enabled_at_response = function (skill, player, response)
    return not response and not player.faceup and  not table.every(Fk:currentRoom().alive_players, function (p)
      return not p:hasSkill(zhangdeng_attached) or p.faceup
    end)
  end,
})

return zhangdeng_attached
