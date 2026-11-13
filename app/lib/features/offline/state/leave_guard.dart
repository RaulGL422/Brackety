// While actions wait to be sent, the web asks before a reload or closing the tab. The queue is kept
// in the browser either way, but without network a reloaded page does not come back until the
// network does, and the referee is left without scoreboard (the hall is plain http: no service
// worker can keep the page).
export 'leave_guard_stub.dart'
    if (dart.library.js_interop) 'leave_guard_web.dart';
