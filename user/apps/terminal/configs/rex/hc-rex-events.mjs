// The event stream `rex events --json` prints is one JSON object per line.
// Every `rex api call` this script makes opens a client for the length of the
// call, so its own reads arrive as client_connected and client_disconnected.
// Those carry no layout change, and reconciling on them schedules the next
// reconcile, so they are dropped here.
const OWN_CLIENT = new Set(["client_connected", "client_disconnected"]);

export const isOwnClientEvent = (ev) => OWN_CLIENT.has(ev?.payload?.event?.type);

// A chunk does not end on an event boundary, so the tail is carried over.
export function eventLines() {
  let rest = "";
  return (chunk) => {
    rest += chunk;
    const events = [];
    let i;
    while ((i = rest.indexOf("\n")) >= 0) {
      const line = rest.slice(0, i);
      rest = rest.slice(i + 1);
      let ev;
      try {
        ev = JSON.parse(line);
      } catch {
        continue;
      }
      if (!isOwnClientEvent(ev)) events.push(ev);
    }
    return events;
  };
}
