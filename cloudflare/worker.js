const ORIGIN = "https://raw.githubusercontent.com/cryptosravan/clearbgv/043004cfef7d159e6ed0913c64430c5e0f5a1a80";
addEventListener("fetch", event => { event.respondWith(handle(event.request)); });
async function handle(request) {
  const url = new URL(request.url);
  let path = url.pathname;
  if (path === "/" || path === "") path = "/index.html";
  const allowed=["/index.html","/supabase-config.js","/app.html","/auth.html"];
  if (allowed.indexOf(path)===-1) return new Response("Not found",{status:404});
  const upstream=await fetch(ORIGIN+path,{headers:{"User-Agent":"ClearBGV-live-worker"}});
  const headers=new Headers(upstream.headers);
  headers.set("cache-control","no-store, no-cache, must-revalidate, max-age=0");
  headers.delete("content-encoding");
  if (path.indexOf(".html")!==-1) headers.set("content-type","text/html; charset=UTF-8");
  if (path.indexOf(".js")!==-1) headers.set("content-type","application/javascript; charset=UTF-8");
  headers.set("x-clearbgv-release","043004cfef7d159e6ed0913c64430c5e0f5a1a80");
  return new Response(upstream.body,{status:upstream.status,headers});
}