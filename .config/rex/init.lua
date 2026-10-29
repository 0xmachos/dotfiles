-- Rex config. Deployed as a file symlink by `bittersweet dotfiles`, then
-- `rex config reload`.
--
-- Cmd+W asks before it closes a pane whose program still runs (an agent, an
-- editor, a build). Rex has no close confirmation or undo of its own yet
-- (accepted feature request, 2026-10-27). Remove this when Rex ships one.
-- Limits: the tab close button and the menu items still close at once.

local login_shells = { bash = true, fish = true, sh = true, zsh = true }

-- True only when closing the pane ends nothing: the program has exited, or a
-- login shell (argv0 starts with "-") sits at its prompt. A `zsh -c` pipeline
-- is not a login shell. A failed lookup returns false, so Rex asks.
local function pane_is_idle(info)
  if not info then return false end
  if info.last_exit ~= nil then return true end
  local fg = info.foreground
  if not fg or not login_shells[fg.name] then return false end
  return (fg.argv0 or ""):sub(1, 1) == "-"
end

-- osascript has no activation policy of its own: without Accessory the alert
-- opens behind Rex. The alert cancels itself after 20 s, inside the exec
-- timeout below, and gives focus back to Rex.
local confirm_script = [[
ObjC.import("AppKit")
function run(argv) {
  const app = $.NSApplication.sharedApplication
  const alert = $.NSAlert.alloc.init
  alert.messageText = "Close this pane?"
  alert.informativeText = argv[0] + " is still running. Closing the pane ends it."
  alert.addButtonWithTitle("Cancel")
  alert.addButtonWithTitle("Close Pane")
  app.setActivationPolicy($.NSApplicationActivationPolicyAccessory)
  app.activateIgnoringOtherApps(true)
  app.performSelectorWithObjectAfterDelayInModes("abortModal", $(), 20, $([$.NSModalPanelRunLoopMode]))
  const reply = alert.runModal
  const rex = $.NSRunningApplication.runningApplicationsWithBundleIdentifier("com.superlogical.rex").firstObject
  if (!rex.isNil()) rex.activateWithOptions(0)
  return reply == $.NSAlertSecondButtonReturn ? "close" : "cancel"
}
]]

local function confirmed(program)
  local r = rex.exec({ "/usr/bin/osascript", "-l", "JavaScript", "-e", confirm_script, program }, { timeout = 25 })
  return r ~= nil and r.ok and r.stdout:match("^close") ~= nil
end

rex.action{
  name = "confirm_close",
  title = "Close Pane, Ask if a Program Runs",
  run = function(ctx)
    -- No focused pane (for example the sidebar has focus): do nothing.
    if not ctx.block_id then return end
    local info = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    if not pane_is_idle(info) then
      local fg = info and info.foreground
      local program = fg and (fg.argv0 or fg.name):match("[^/]+$") or "A program"
      if not confirmed(program) then return end
    end
    -- Close by ID: the alert can move the app's focus to another pane, and a
    -- pane.close binding does not close the pane on recent builds.
    rex.call("block.close", { session_id = ctx.session_id, block_id = ctx.block_id })
  end,
}

rex.bind("cmd+w", "confirm_close")

-- Jump to the next pane whose agent needs you, in every session on this
-- server. A pane counts when any of its status records (the program's own or
-- a sub-agent's) is blocked, or when its own record is error or done. Blocked
-- panes come first, oldest first; then error and done panes, newest first.
-- The server keeps a done record after you read it (the app tracks "seen"
-- itself), so pressing the key again moves on to the next pane in the list.
local terminal = "com.superlogical.terminal"
local rank = { blocked = 1, error = 2, done = 3 }

local function pane_need(session_id, block_id)
  local st = rex.block.call(terminal, "program_status", { session_id = session_id, block_id = block_id })
  if not st or not st.records then return nil end
  local best, at
  for _, r in ipairs(st.records) do
    local counts = r.state == "blocked" or (r.id == nil and rank[r.state] ~= nil)
    if counts and (best == nil or rank[r.state] < rank[best]) then
      best, at = r.state, r.updated_at
    end
  end
  return best, at
end

local function waiting_panes()
  local list = {}
  local sessions = rex.call("session.list", {})
  for _, s in ipairs(sessions and sessions.sessions or {}) do
    local blocks = rex.call("session.list_blocks", { session_id = s.session_id })
    for _, b in ipairs(blocks and blocks.blocks or {}) do
      if b.creator_name == terminal and b.placement == "placed" then
        local state, at = pane_need(s.session_id, b.block_id)
        if state then
          list[#list + 1] = { session_id = s.session_id, block_id = b.block_id, state = state, at = at or "" }
        end
      end
    end
  end
  table.sort(list, function(a, b)
    if rank[a.state] ~= rank[b.state] then return rank[a.state] < rank[b.state] end
    if a.state == "blocked" then return a.at < b.at end
    return a.at > b.at
  end)
  return list
end

rex.action{
  name = "next_agent",
  title = "Go to Next Agent That Needs You",
  keywords = "blocked done waiting activity",
  run = function(ctx)
    local list = waiting_panes()
    if #list == 0 then return { found = 0 } end
    local pick = list[1]
    for i, p in ipairs(list) do
      if p.block_id == ctx.block_id then
        pick = list[i % #list + 1]
        break
      end
    end
    rex.call("session.focus_block", { session_id = pick.session_id, block_id = pick.block_id })
    if pick.session_id ~= ctx.session_id then
      rex.client.queue("session.select", { session_id = pick.session_id })
    end
    return { found = #list, state = pick.state, block_id = pick.block_id }
  end,
}

rex.bind("cmd+shift+j", "next_agent")
