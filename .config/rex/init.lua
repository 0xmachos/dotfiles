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
-- server and on every other server the app connects to (rex.servers()). A
-- pane counts when any of its status records (the program's own or a
-- sub-agent's) is blocked, or when its own record is error or done. Blocked
-- panes come first, oldest first; then error and done panes, newest first.
-- The server keeps a done record after you read it (the app tracks "seen"
-- itself), so pressing the key again moves on to the next pane in the list.
-- A call to another server fails with 409 until the action attaches to the
-- session, so the scan attaches first. A server that fails is skipped.
local terminal = "com.superlogical.terminal"
local rank = { blocked = 1, error = 2, done = 3 }

local function pane_need(srv, session_id, block_id)
  local st = srv.block.call(terminal, "program_status", { session_id = session_id, block_id = block_id })
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

local function scan(list, srv, remote)
  local sessions = srv.call("session.list", {})
  for _, s in ipairs(sessions and sessions.sessions or {}) do
    if remote then srv.call("session.attach", { session_id = s.session_id }) end
    local blocks = srv.call("session.list_blocks", { session_id = s.session_id })
    for _, b in ipairs(blocks and blocks.blocks or {}) do
      if b.creator_name == terminal and b.placement == "placed" then
        local state, at = pane_need(srv, s.session_id, b.block_id)
        if state then
          list[#list + 1] = {
            srv = srv, session_id = s.session_id, window_id = b.window_id,
            block_id = b.block_id, state = state, at = at or "",
          }
        end
      end
    end
  end
end

local function waiting_panes()
  local list = {}
  scan(list, rex, false)
  for _, label in ipairs(rex.servers()) do
    local ok, srv = pcall(rex.server, label)
    if ok then pcall(scan, list, srv, true) end
  end
  table.sort(list, function(a, b)
    if rank[a.state] ~= rank[b.state] then return rank[a.state] < rank[b.state] end
    if a.state == "blocked" then return a.at < b.at end
    return a.at > b.at
  end)
  return list
end

-- The client ID that this app has on another server: the app client there
-- with the same label as this client here, else the only app client there.
local function remote_app(srv, client_id)
  local mine
  local here = rex.call("client.list", {})
  for _, c in ipairs(here and here.clients or {}) do
    if c.client_id == client_id then mine = c.info and c.info.label end
  end
  local there = srv.call("client.list", {})
  local apps = {}
  for _, c in ipairs(there and there.clients or {}) do
    if c.info and c.info.kind == "app" then
      if mine and c.info.label == mine then return c.client_id end
      apps[#apps + 1] = c.client_id
    end
  end
  return #apps == 1 and apps[1] or nil
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
    pick.srv.call("session.focus_block", { session_id = pick.session_id, block_id = pick.block_id })
    local select = { session_id = pick.session_id, window_id = pick.window_id }
    if pick.srv ~= rex then
      -- The app resolves a queued session.select on this server only. Ask the
      -- app's own client on the other server instead.
      local app = remote_app(pick.srv, ctx.client_id)
      if not app then return { found = #list, error = "the app is not a client of that server" } end
      pick.srv.call("client.perform", { client_id = app, action = "session.select", args = select, timeout_ms = 5000 })
    elseif pick.session_id ~= ctx.session_id then
      rex.client.queue("session.select", select)
    end
    return { found = #list, state = pick.state, block_id = pick.block_id }
  end,
}

rex.bind("cmd+shift+j", "next_agent")

-- The remote Rex host, through the socket of the rex-remote-bridge LaunchAgent
-- (bin/rex-remote-bridge, 2026-10-30). A config host stays on this machine:
-- `rex hosts add` and `rex hosts edit` refuse a local socket path for the
-- shared home list, because other machines cannot reach it. The label comes
-- from the first line of the optional `label` file beside ssh-host (the host
-- name stays out of this tracked file, as the SSH alias does), else "remote".
-- Declared only where the bridge is set up (ssh-host exists): this file also
-- deploys to the remote Rex host itself, which has no bridge.
-- The endpoint is a percent-encoded unix:// URL: the Mac app cannot connect
-- to a bare socket path that contains a space (Preview 1696).
local bridge_dir = os.getenv("HOME") .. "/Library/Application Support/rex-remote-bridge"
local function first_line(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local line = f:read("*l")
  f:close()
  return line and line:match("^%s*(.-)%s*$") or nil
end
if first_line(bridge_dir .. "/ssh-host") then
  local remote_label = first_line(bridge_dir .. "/label")
  if remote_label == nil or remote_label == "" then remote_label = "remote" end
  rex.host{
    label = remote_label,
    endpoint = "unix://" .. (bridge_dir:gsub(" ", "%%20")) .. "/rex.sock",
    icon = "globe",
  }
end
