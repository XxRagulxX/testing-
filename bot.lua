util.require_natives("King")
is_loading = true
ls_debug = false
all_peds = {}
handle_ptr = memory.alloc(13*8)
local response = false
localVer = 1.4

--- Github Integration
async_http.init("raw.githubusercontent.com", "/XxRagulxX/testing-/main/version.lua", function(output)
    currentVer = tonumber(output)
    response = true
    if localVer ~= currentVer then
        util.toast("Auto NPC Kill version is available, update the lua to get the newest version.")
        menu.action(menu.my_root(), "Update Lua", {}, "", function()
            async_http.init('raw.githubusercontent.com','/XxRagulxX/testing-/main/bot.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("Successfully updated Auto NPC Kill, please restart the script :)")
                util.stop_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response
--end
-- debug mode is on
function ls_log(content)
    if ls_debug then
        util.toast(content)
        util.log("[KING RELOADED] " .. content)
    end
end

ls_log("Now setting up lists")
-- BEGIN SELF SUBSECTIONS
self_root = menu.list(menu.my_root(), "Peds", {}, "Ped Kill")
ped_uses = 0
function mod_uses(type, incr)
    if incr < 0 and is_loading then
        ls_log("Not incrementing use var of type " .. type .. " by " .. incr .. "- script is loading")
        return
    end
    ls_log("Incrementing use var of type " .. type .. " by " .. incr)
    if type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    end
end

function pid_to_handle(pid)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, handle_ptr, 13)
    return handle_ptr
end

--- Commands  

kill_aura = false
menu.toggle(self_root, "Kill", {"killp"}, "Auto Gun Killer", function(on)
    kill_aura = on
    mod_uses("ped", if on then 1 else -1)
end)
kill_aura_peds = false
menu.toggle(self_root, "Kill peds", {"killpeds"}, "Only Peds", function(on)
    kill_aura_peds = on
end)
kill_aura_dist = 100
menu.slider(self_root, "Kill radius", {"killradius"}, "", 1, 100, 100, 1, function(s)
    kill_aura_dist = s
end)

-- PEDS

peds_thread = util.create_thread(function (thr)
    while true do
        if ped_uses > 0 then
            ls_log("Ped pool is being updated")
            all_peds = entities.get_all_peds_as_handles()
            for k,ped in pairs(all_peds) do
                if kill_aura then
                    if (kill_aura_peds and not PED.IS_PED_A_PLAYER(ped)) or (kill_aura_players and PED.IS_PED_A_PLAYER(ped)) then
                        local pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(v)
                        local hdl = pid_to_handle(pid)
                        if (kill_aura_friends and not NETWORK.NETWORK_IS_FRIEND(hdl)) or not kill_aura_friends then
                            target = ENTITY.GET_ENTITY_COORDS(ped, false)
                            m_coords = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
                            if MISC.GET_DISTANCE_BETWEEN_COORDS(m_coords.x, m_coords.y, m_coords.z, target.x, target.y, target.z, true) < kill_aura_dist and ENTITY.GET_ENTITY_HEALTH(ped) > 0 then
                                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target['x'], target['y'], target['z']+0.1, 300.0, true, 100416529, players.user_ped(), true, false, 100.0)
                            end
                        end
                    end
                end
            end
        end
        util.yield()
    end
end)






