--[[ Perf-O-Rate
     A performance rating device

 /perf:
 timer = {
 	elapsed = number,
	count = number,
	stamp = number,
	state = 'started' || 'stopped'
	}
 timer: report value and state of timer
 -a: show all
 -b expr: benchmark expr
 -d timer: delete timer expr
 -B count: benchmark count
 -n timer: create new timer (implicitly started)
 -s timer: start/stop timer
 -r timer: reset timer (implicitly stopped)

]]--

Library = Library or {}
local perf = {}
Library.LibPerfORate = perf
perf.timers = {}

function perf.printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

function perf.start(timer, verbose)
  if perf.timers[timer] then
    if perf.timers[timer].state == 'started' then
      perf.printf("Timer '%s' requested start when already started, ignoring.", timer)
    else
      perf.timers[timer].stamp = Inspect.Time.Real()
      perf.timers[timer].state = 'started'
      perf.timers[timer].count = perf.timers[timer].count + 1
      if verbose then
        perf.printf("Started timer '%s'.", timer)
      end
    end
  else
    perf.printf("No timer '%s' to start.", timer)
  end
end

function perf.stop(timer, verbose)
  if perf.timers[timer] then
    if perf.timers[timer].state == 'stopped' then
      perf.printf("Timer '%s' requested stop when already stopped, ignoring.", timer)
    else
      local new = Inspect.Time.Real()
      local elapsed = new - perf.timers[timer].stamp
      perf.timers[timer].elapsed = perf.timers[timer].elapsed + elapsed
      perf.timers[timer].state = 'stopped'
      if verbose then
        perf.printf("Stopped timer '%s' [%f sec, %f total].", timer, elapsed,
	      perf.timers[timer].elapsed)
      end
    end
  else
    perf.printf("No timer '%s' to stop.", timer)
  end
end

function perf.toggle(timer, verbose)
  if perf.timers[timer] then
    if perf.timers[timer].state == 'started' then
      perf.stop(timer, verbose)
    else
      perf.start(timer, verbose)
    end
  else
    perf.printf("No timer '%s' to toggle.", timer)
  end
end

function perf.reset(timer, verbose)
  local timer = args['r']
  if perf.timers[timer] then
    perf.timers[timer].elapsed = 0
    perf.timers[timer].count = 0
    perf.timers[timer].state = 'stopped'
    if verbose then
      perf.printf("Reset timer '%s'.", timer)
    end
  else
    perf.printf("No timer '%s' to reset.", timer)
  end
end

function perf.prettytime(elapsed)
  local secs = math.floor(elapsed)
  local subsecs = elapsed - secs
  local mins = math.floor(secs / 60)
  secs = secs % 60
  local hours = math.floor(mins / 60)
  mins = mins % 60
  local prettysubsecs = string.sub(string.format("%f", subsecs), 3)
  if hours > 0 then
    return string.format("%d:%02d:%02d.%s", hours, mins, secs, prettysubsecs)
  elseif mins > 0 then
    return string.format("%d:%02d.%s", mins, secs, prettysubsecs)
  elseif secs > 0 then
    return string.format("%d.%ss", secs, prettysubsecs)
  else
    local ms = subsecs * 1000
    return string.format("%fms", ms)
  end
end

function perf.new(timer, started, verbose)
  if not perf.timers[timer] then
    perf.timers[timer] = {
    	elapsed = 0,
	count = 0,
	stamp = Inspect.Time.Real(),
    	state = started and 'started' or 'stopped'
	}
    if verbose then
      perf.printf("Created new timer '%s'.", timer)
    end
  else
    if verbose then
      perf.printf("Can't recreate timer '%s', ignoring.", timer)
    end
  end
  return perf.timers[timer]
end

function perf.delete(timer, verbose)
  if perf.timers[timer] then
    perf.timers[timer] = nil
    if verbose then
      perf.printf("Deleted timer '%s'.", timer)
    end
  else
    perf.printf("No timer '%s' to delete.", timer)
  end
end

function perf.showstate(timer)
  if perf.timers[timer] then
    local elapsed = perf.timers[timer].elapsed
    if perf.timers[timer].state == 'started' then
      elapsed = elapsed + (Inspect.Time.Real() - perf.timers[timer].stamp)
    end
    local prettytime = perf.prettytime(elapsed)
    local prettyavg = perf.prettytime(elapsed / perf.timers[timer].count)
    perf.printf("%s*%d: %s (average %s) [%s]", timer, perf.timers[timer].count, prettytime, prettyavg, perf.timers[timer].state)
  else
    perf.printf("No timer '%s'.", timer)
  end
end

function perf.hook(func, timer)
  perf.new(timer)
  return function(...)
    perf.start(timer)
    func(...)
    perf.stop(timer)
  end
end

function perf.benchmark(expr, run_this_many, ...)
  local func, error
  if perf.benchmarking then
    perf.printf("Already benchmarking something, request for new benchmark ignored.")
    return false
  end
  if type(expr) == 'function' then
    func = expr
    expr = "<function>"
  else
    func, error = loadstring("return { " .. expr .. " }")
  end
  if func then
    local do_expr = perf.hook(func, expr)
    perf.benchmarking = do_expr
    perf.benchmark_name = expr
    perf.benchmark_args = { ... }
    perf.benchmark_count = run_this_many or 100
    perf.printf("Evaluating '%s' %d times...", expr, run_this_many)
    return true
  else
    perf.printf("Failed to parse '%s': %s", expr, error)
    return false
  end
end

function perf.update(args)
  if perf.benchmarking then
    perf.benchmarking(unpack(perf.benchmark_args))
    perf.benchmark_count = perf.benchmark_count - 1
    if perf.benchmark_count < 1 then
      perf.benchmarking = nil
      perf.showstate(perf.benchmark_name)
    elseif perf.benchmark_count % 25 == 0 then
      perf.printf("%d cycles left on benchmark.", perf.benchmark_count)
    end
  end
end

function perf.slashcommand(args)
  local didsomething = false
  local run_this_many = 100
  if not args then
    perf.printf("Usage error.  /perf for usage.")
    return
  end
  if args['B'] then
    run_this_many = args['B'] 
    -- don't set didsomething, because we didn't didsomething.
  end
  if args['b'] then
    if perf.benchmarking then
      perf.printf("Cancelling benchmark.")
      perf.benchmarking = nil
    else
      expr = args['b']
      perf.benchmark(expr, run_this_many)
      didsomething = true
    end
  end
  if args['d'] then
    local timer = args['d']
    perf.delete(timer, true)
    didsomething = true
  end
  if args['n'] then
    local timer = args['n']
    perf.new(timer, true, true)
    didsomething = true
  end
  if args['r'] then
    perf.reset(args['r'], true)
    didsomething = true
  end
  if args['s'] then
    perf.toggle(args['s'], true)
    didsomething = true
  end
  if args['a'] then
    for k, v in pairs(perf.timers) do
      perf.showstate(k)
      didsomething = true
    end
    if not didsomething then
      perf.printf("No timers to display.")
      didsomething = true
    end
  end
  if table.getn(args['leftover_args']) > 0 then
    for i, v in ipairs(args['leftover_args']) do
      perf.showstate(v)
    end
  else
    if not didsomething then
      perf.printf('Usage: /perf [-a] [-B count] [-b "expr"] [-[dnrs] timer] [timer ...]')
      perf.printf('Default count is 100.')
    end
  end
end

function perf.wastetime()
  for i = 1,100 do
    local a = {}
    for k, v in pairs(_G) do
      a[k] = v
    end
  end
end

-- perf.benchmark(perf.wastetime, 300)

table.insert(Event.System.Update.Begin, { perf.update, "PerfORate", "update hook" })

Library.LibGetOpt.makeslash("ab:B#d:n:r:s:", "PerfORate", "perf", perf.slashcommand)
