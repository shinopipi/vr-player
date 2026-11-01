// VR player — Cloudflare Worker for streaming videos from an R2 bucket.
// Setup: bind your R2 bucket as "BUCKET" and add a secret named "ACCESS_KEY" (your passphrase).
// GET /list?key=...            -> JSON list of videos in the bucket
// GET /<file name>?key=...     -> the video (supports Range requests for seeking)

const VIDEO = /\.(mp4|m4v|mov)$/i;
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Range',
  'Access-Control-Expose-Headers': 'Content-Range, Content-Length, Accept-Ranges',
};

export default {
  async fetch(req, env) {
    if (req.method === 'OPTIONS') return new Response(null, { headers: CORS });
    const url = new URL(req.url);
    if (!env.ACCESS_KEY || url.searchParams.get('key') !== env.ACCESS_KEY) {
      return new Response('forbidden', { status: 403, headers: CORS });
    }

    if (url.pathname === '/list') {
      const items = [];
      let cursor;
      do {
        const page = await env.BUCKET.list({ cursor, limit: 1000 });
        for (const o of page.objects) if (VIDEO.test(o.key)) items.push({ name: o.key, size: o.size });
        cursor = page.truncated ? page.cursor : undefined;
      } while (cursor);
      items.sort((a, b) => a.name.localeCompare(b.name, 'ja'));
      return new Response(JSON.stringify(items), {
        headers: { ...CORS, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
      });
    }

    const key = decodeURIComponent(url.pathname.slice(1));
    if (!key) return new Response('not found', { status: 404, headers: CORS });

    if (req.method === 'HEAD') {
      const head = await env.BUCKET.head(key);
      if (!head) return new Response(null, { status: 404, headers: CORS });
      const h = headersFor(head);
      h.set('Content-Length', String(head.size));
      return new Response(null, { headers: h });
    }

    const hasRange = req.headers.has('Range');
    const obj = await env.BUCKET.get(key, hasRange ? { range: req.headers } : {});
    if (!obj) return new Response('not found', { status: 404, headers: CORS });
    const h = headersFor(obj);

    if (hasRange && obj.range) {
      const r = obj.range;
      const start = 'suffix' in r ? obj.size - r.suffix : (r.offset || 0);
      const length = 'suffix' in r ? r.suffix : (r.length ?? obj.size - start);
      h.set('Content-Range', `bytes ${start}-${start + length - 1}/${obj.size}`);
      h.set('Content-Length', String(length));
      return new Response(obj.body, { status: 206, headers: h });
    }
    h.set('Content-Length', String(obj.size));
    return new Response(obj.body, { headers: h });
  },
};

function headersFor(obj) {
  const h = new Headers(CORS);
  obj.writeHttpMetadata(h);
  if (!h.get('Content-Type')) h.set('Content-Type', 'video/mp4');
  h.set('Accept-Ranges', 'bytes');
  h.set('ETag', obj.httpEtag);
  h.set('Cache-Control', 'private, max-age=3600');
  return h;
}
