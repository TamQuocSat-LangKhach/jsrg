local yingshi = fk.CreateSkill {
  name = "js__yingshi",
}

Fk:loadTranslationTable{
  ["js__yingshi"] = "鹰视",
  [":js__yingshi"] = "当你翻面后，你可以观看牌堆底的三张牌（若场上阵亡角色数大于2则改为五张），以任意顺序置于牌堆顶或牌堆底。",

  ["$js__yingshi1"] = "亮志大而不见机，已堕吾画中。",
  ["$js__yingshi2"] = "贼偏执一端不能察变，破之必矣。",
}

yingshi:addEffect(fk.TurnedOver, {
  anim_type = "control",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.players, function(p)
      return p.dead
    end) > 2 and 5 or 3
    room:askToGuanxing(player, {cards = room:getNCards(n, "bottom")})
  end,
})

return yingshi
