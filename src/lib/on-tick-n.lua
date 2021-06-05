local on_tick_n = {}

on_tick_n.event_id = script.generate_event_name()

function on_tick_n.add_task(tick, payload)
  local tasks = global.tasks[tick]
  if not tasks then
    tasks = {}
    global.tasks[tick] = tasks
  end
  local id = #tasks + 1
  tasks[id] = payload
  return id
end

function on_tick_n.init()
  global.tasks = {}
end

function on_tick_n.iterate(e)
  local tasks = global.tasks[e.tick]
  if tasks then
    e.tasks = tasks
    global.tasks[e.tick] = nil
    script.raise_event(on_tick_n.event_id, e)
  end
end

return on_tick_n
