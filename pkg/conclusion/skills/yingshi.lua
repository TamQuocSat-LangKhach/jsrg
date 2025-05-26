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

    --直接用观星函数会把牌堆底牌默认填在“牌堆顶”一行，总有玩家报错……
    --room:askToGuanxing(player, {cards = room:getNCards(n, "bottom")})
    local cards = room:getNCards(n, "bottom")
    local dat = {
      prompt = yingshi.name,
      is_free = true,
      cards = { {}, cards },
      min_top_cards = 0,
      max_top_cards = n,
      min_bottom_cards = 0,
      max_bottom_cards = n,
      top_area_name = "Top",
      bottom_area_name = "Bottom",
    }

    local req = Request:new(player, "AskForGuanxing")
    req.focus_text = yingshi.name
    req:setData(player, dat)
    local result = req:getResult(player)
    local top, bottom
    if result ~= "" then
      local d = result
      top = d[1]
      bottom = d[2] or Util.DummyTable
    else
      bottom = cards
    end
    for i = #top, 1, -1 do
      table.removeOne(room.draw_pile, top[i])
      table.insert(room.draw_pile, 1, top[i])
    end
    for i = 1, #bottom, 1 do
      table.removeOne(room.draw_pile, bottom[i])
      table.insert(room.draw_pile, bottom[i])
    end

    room:syncDrawPile()
    room:sendLog{
      type = "#GuanxingResult",
      from = player.id,
      arg = #top,
      arg2 = #bottom,
    }
  end,
})

return yingshi
