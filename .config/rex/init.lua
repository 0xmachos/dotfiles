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
