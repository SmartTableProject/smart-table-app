/* Smart Table OS — config condivisa
   Chiave anon pubblica (già in produzione sul progetto).
   NON mettere service_role qui. */
window.ST_CONFIG = {
  supabaseUrl: "https://izmppsvnxghfeitktldh.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6bXBwc3ZueGdoZmVpdGt0bGRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMzA3NTIsImV4cCI6MjA5OTYwNjc1Mn0.-LQQC11p6d25EG67J1YCTp2QpYc2WlMW3nmg-z-VK_0",
  venueId: "ardea",
  sla: {
    greenSec: 60,
    yellowSec: 180
  },
  labels: {
    water: "Acqua",
    bread: "Pane",
    cutlery: "Posate",
    clean: "Pulizia",
    bill: "Conto",
    generic: "Cameriere"
  }
};

window.stClient = function () {
  if (!window.supabase) throw new Error("Supabase SDK non caricato");
  return window.supabase.createClient(
    window.ST_CONFIG.supabaseUrl,
    window.ST_CONFIG.supabaseAnonKey
  );
};

/** Coda offline locale (IndexedDB-lite via localStorage) */
window.ST_OFFLINE = {
  key: "st_offline_queue_v1",
  push(event) {
    const q = JSON.parse(localStorage.getItem(this.key) || "[]");
    q.push({ ...event, id: crypto.randomUUID(), ts: Date.now() });
    localStorage.setItem(this.key, JSON.stringify(q));
  },
  list() {
    return JSON.parse(localStorage.getItem(this.key) || "[]");
  },
  clear() {
    localStorage.removeItem(this.key);
  },
  async flush(client) {
    const q = this.list();
    if (!q.length) return { ok: 0, fail: 0 };
    let ok = 0;
    let fail = 0;
    const rest = [];
    for (const ev of q) {
      try {
        if (ev.type === "call") {
          const { error } = await client.from("calls").insert([ev.payload]);
          if (error) throw error;
        } else if (ev.type === "audit") {
          await client.from("audit_events").insert([ev.payload]);
        }
        ok++;
      } catch (e) {
        fail++;
        rest.push(ev);
      }
    }
    localStorage.setItem(this.key, JSON.stringify(rest));
    return { ok, fail };
  }
};

window.stSlaClass = function (createdAt) {
  const sec = (Date.now() - new Date(createdAt).getTime()) / 1000;
  if (sec < window.ST_CONFIG.sla.greenSec) return "sla-green";
  if (sec < window.ST_CONFIG.sla.yellowSec) return "sla-yellow";
  return "sla-red";
};

window.stSelfCheck = async function (client) {
  const out = { hub: true, cloud: false, queue: 0, message: "" };
  out.queue = window.ST_OFFLINE.list().length;
  try {
    const { error } = await client.from("config_buttons").select("id").limit(1);
    out.cloud = !error;
  } catch (e) {
    out.cloud = false;
  }
  if (out.cloud && out.queue === 0) out.message = "Tutto collegato e funzionante";
  else if (!out.cloud && out.queue > 0)
    out.message = "Lavoro in locale — " + out.queue + " eventi in coda";
  else if (!out.cloud) out.message = "Attenzione: manca la connessione al cloud";
  else out.message = "Cloud ok — sincronizzo coda (" + out.queue + ")";
  return out;
};
