local guyin = fk.CreateSkill {
  name = "guyin"
}

Fk:loadTranslationTable{
  ['guyin'] = '孤吟',
  ['turnOver'] = '翻面',
  ['#guyin-choice'] = '%src发动了孤吟，是否将武将牌翻面',
  [':guyin'] = '准备阶段，你可以翻面，然后令所有其他男性角色各选择其是否翻面，然后你和所有翻面的角色轮流各摸一张牌直到以此法摸牌数达到X张（X为本局游戏男性角色数）。',
}

guyin:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guyin.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and p:isMale() and
        room:askToChoice(p, {
          choices = {"turnOver", "Cancel"},
          skill_name = guyin.name,
          prompt = "#guyin-choice:" .. player.id
        }) == "turnOver" then
        p:turnOver()
      end
    end
    local x = #table.filter(room.players, function (p)
      return p:isMale()
    end)
    local drawer = player
    for _ = 1, x, 1 do
      if drawer.dead then break end
      room:drawCards(drawer, 1, guyin.name)
      local all_player = room:getAllPlayers()
      local index = table.indexOf(all_player, drawer)
      local next_drawer = player
      if index < #all_player then
        for i = index+1, #all_player, 1 do
          local p = all_player[i]
          if not (p.dead or p.faceup) then
            next_drawer = p
            break
          end
        end
      end
      drawer = next_drawer
    end
  end,
})

return guyin
