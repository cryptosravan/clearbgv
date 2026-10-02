const ORIGIN = "https://raw.githubusercontent.com/cryptosravan/clearbgv/main";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    let path = url.pathname;
    if (path === "/" || path === "") path = "/index.html";

    if (path !== "/index.html" && path !== "/supabase-config.js") {
      return new Response("Not found", { status: 404 });
    }

    const upstream = await fetch(ORIGIN + path, {
      headers: { "User-Agent": "ClearBGV-Pages" }
    });

    const headers = new Headers(upstream.headers);
    headers.set("cache-control", "no-store");

    return new Response(upstream.body, {
      status: upstream.status,
      headers
    });
  }
};
