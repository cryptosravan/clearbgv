const ORIGIN = "https://raw.githubusercontent.com/cryptosravan/clearbgv/main";
addEventListener("fetch", event => { event.respondWith(handle(event.request)); });

async function handle(request) {
  const url = new URL(request.url);
  let path = url.pathname;
  if (path === "/" || path === "") path = "/index.html";

  const allowed = ["/index.html", "/supabase-config.js", "/app.html", "/auth.html", "/prod-ui.js"];
  if (allowed.indexOf(path) === -1) return new Response("Not found", { status: 404 });

  const upstream = await fetch(ORIGIN + path, {
    headers: { "User-Agent": "ClearBGV-live-worker" }
  });

  const headers = new Headers(upstream.headers);
  headers.set("cache-control", "no-store, no-cache, must-revalidate, max-age=0");
  headers.delete("content-encoding");

  if (path.endsWith(".html")) headers.set("content-type", "text/html; charset=UTF-8");
  if (path.endsWith(".js")) headers.set("content-type", "application/javascript; charset=UTF-8");

  if ((path === "/index.html" || path === "/app.html") && upstream.ok) {
    let html = await upstream.text();
    if (!html.includes("/prod-ui.js")) {
      html = html.replace("</body>", '<script src="/prod-ui.js" defer></script></body>');
    }
    return new Response(html, { status: upstream.status, headers });
  }

  return new Response(upstream.body, { status: upstream.status, headers });
}