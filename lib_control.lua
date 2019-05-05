local floor = math.floor

local function set_trash(player)
    if player.character then
        local trash_filters = {}
        --TODO ensure trash >= requests
        for _, item_config in pairs(global.config_new[player.index].config) do
            if item_config.trash then
                trash_filters[item_config.name] = item_config.trash
            end
        end
        player.auto_trash_filters = trash_filters
    end
end

local function set_requests(player)
    if player.character then
        local character = player.character
        local storage = global.config_new[player.index].config
        local set_request_slot = character.set_request_slot
        local clear_request_slot = character.clear_request_slot
        local req

        for c = 1, character.request_slot_count do
            req = storage[c]
            if req then
                set_request_slot({name = req.name, count = req.request}, c)
            else
                clear_request_slot(c)
            end
        end
    end
end

local function get_requests(player)
    if not player.character then
        return {}
    end
    local requests = {}
    local get_request_slot = player.character.get_request_slot
    local t, max_slot
    for c = player.character.request_slot_count, 1, -1 do
        t = get_request_slot(c)
        if t then
            max_slot = not max_slot and c or max_slot
            requests[t.name] = {name = t.name, request = t.count, slot = c}
        end
    end
    return requests, max_slot
end

local function saveVar(var, name)
    var = var or global
    local n = name and "autotrash_" .. name or "autotrash"
    game.write_file(n..".lua", serpent.block(var, {name = "global", comment = false}))
end

local function debugDump(var, force)
    if false or force then
        for _, player in pairs(game.players) do
            local msg
            if type(var) == "string" then
                msg = var
            else
                msg = serpent.dump(var, {name = "var", comment = false, sparse = false, sortkeys = true})
            end
            player.print(msg)
        end
    end
end

local function display_message(player, message, sound)
    player.create_local_flying_text{position = player.position, text = message}
    if sound then
        if sound == "success" then
            player.play_sound{path = "utility/console_message", position = player.position}
        else
            player.play_sound{path = "utility/cannot_build", position = player.position}
        end
    end
end

local function format_number(n, append_suffix)
  local amount = tonumber(n)
    if not amount then
    return n
  end
  local suffix = ""
  if append_suffix then
    local suffix_list = {
        ["T"] = 1000000000000,
        ["B"] = 1000000000,
        ["M"] = 1000000,
        ["k"] = 1000
    }
    for letter, limit in pairs (suffix_list) do
      if math.abs(amount) >= limit then
        amount = floor(amount/(limit/10))/10
        suffix = letter
        break
      end
    end
  end
  local formatted, k = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k == 0) then
      break
    end
  end
  return formatted..suffix
end

local function format_request(item_config)
    return (item_config.request and item_config.request > 0) and item_config.request or (item_config.trash and 0) or " "
end

local function format_trash(item_config)
    return item_config.trash and item_config.trash or (item_config.request > 0 and "∞") or " "
end

local function convert_from_slider(n)
    if not n then
        return -1
    end
    n = floor(n)
    if n <= 10 then
        return n
    elseif n <= 19 then
        return (n-9)*10
    elseif n <= 28 then
        return (n-18)*100
    elseif n <= 37 then
        return (n-27)*1000
    else
        return (n-36)*10000
    end
end

local huge = math.huge
local function convert_to_slider(n)
    if n <= 10 then
        return n
    elseif n <= 100 then
        return n/10+9
    elseif n <= 1000 then
        return n/100+18
    elseif n <= 10000 then
        return n/1000+27
    elseif n < huge then
        return n/10000+36
    else
        return 42
    end
end

local M = {
    saveVar = saveVar,
    debugDump = debugDump,
    display_message = display_message,
    format_number = format_number,
    format_request = format_request,
    format_trash = format_trash,
    convert_to_slider = convert_to_slider,
    convert_from_slider = convert_from_slider,
    set_trash = set_trash,
    set_requests = set_requests,
    get_requests = get_requests
}

return M