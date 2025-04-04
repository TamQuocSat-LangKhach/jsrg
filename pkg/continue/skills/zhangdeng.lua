local zhangdeng = fk.CreateSkill {
  name = "zhangdeng"
}

Fk:loadTranslationTable{
  ['zhangdeng'] = '帐灯',
  ['#zhangdeng-active'] = '发动帐灯，视为使用一张【酒】',
  ['zhangdeng&'] = '帐灯',
  ['#zhangdeng_trigger'] = '帐灯',
  [':zhangdeng'] = '当一名武将牌背面朝上的角色需要使用【酒】时，若你的武将牌背面朝上，其可以视为使用之。当本技能于一回合内第二次及以上发动时，你翻面至正面朝上。',
}

zhangdeng:addEffect("viewas", {
  prompt = "#zhangdeng-active",
  attached_skill_name = "zhangdeng&",
  pattern = "analeptic",
  card_filter = function(self, player, to_select, selected) return false end,
  before_use = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "zhangdeng_used-turn")
    end
  end,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = zhangdeng.name
    return c
  end,
  enabled_at_play = function (self, player)
    return not player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return not response and not player.faceup
  end,
})

zhangdeng:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhangdeng.name) and not player.faceup and table.contains(data.card.skillNames, zhangdeng.name) and
      player:getMark("zhangdeng_used-turn") > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,
})

return zhangdeng
