local jinglei = fk.CreateSkill {
  name = "jinglei"
}

Fk:loadTranslationTable{
  ['jinglei_active'] = '惊雷',
  ['js__jinglei'] = '惊雷',
}

jinglei:addEffect('active', {
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  target_filter = function(self, player, to_select, selected)
    local n = Fk:currentRoom():getPlayerById(to_select):getHandcardNum()
    for _, p in ipairs(selected) do
      n = n + Fk:currentRoom():getPlayerById(p):getHandcardNum()
    end
    return n < player:getMark("js__jinglei")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "jinglei", 0)
  end,
})

return jinglei
