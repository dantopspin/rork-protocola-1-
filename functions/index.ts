// functions/index.ts — Ask Protocola AI proxy.
//
// Holds the Rork toolkit secret server-side so the iOS binary never carries
// it. The app POSTs an OpenAI-compatible chat payload to /ask; we validate
// it, force the model and generation caps, inject the upstream Authorization
// header, and forward to the Rork toolkit gateway. Upstream status codes are
// passed through so the app's 429 (busy) / 402 (credits) mapping still works.

const ALLOWED_MODELS = new Set(["openai/gpt-4.1-mini"]);
const MAX_TOKENS_CAP = 1500;
const MAX_MESSAGES = 12;
const MAX_MESSAGE_CHARS = 50_000;
const MAX_BODY_BYTES = 64 * 1024;
const RATE_LIMIT_WINDOW_MS = 5 * 60 * 1000;
const RATE_LIMIT_MAX = 30;

type ChatMessage = { role: string; content: string };

// Per-isolate sliding window. Isolates are recycled, so this is a deterrent
// against casual abuse, not hard protection — the toolkit key itself never
// leaves the Worker regardless.
const hitTimestamps = new Map<string, number[]>();

function rateLimited(ip: string): boolean {
  const now = Date.now();
  const hits = (hitTimestamps.get(ip) ?? []).filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  if (hits.length >= RATE_LIMIT_MAX) {
    hitTimestamps.set(ip, hits);
    return true;
  }
  hits.push(now);
  hitTimestamps.set(ip, hits);
  if (hitTimestamps.size > 10_000) hitTimestamps.clear();
  return false;
}

function sanitizeMessages(raw: unknown): ChatMessage[] | null {
  if (!Array.isArray(raw) || raw.length === 0 || raw.length > MAX_MESSAGES) return null;
  const messages: ChatMessage[] = [];
  for (const item of raw) {
    const role = (item as { role?: unknown })?.role;
    const content = (item as { content?: unknown })?.content;
    if (typeof role !== "string" || typeof content !== "string") return null;
    if (role !== "system" && role !== "user" && role !== "assistant") return null;
    if (content.length === 0 || content.length > MAX_MESSAGE_CHARS) return null;
    messages.push({ role, content });
  }
  return messages;
}

export default {
  async fetch(request: Request, env: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/ping") {
      return Response.json({ ok: true, now: new Date().toISOString() });
    }

    if (url.pathname === "/ask" && request.method === "POST") {
      const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
      if (rateLimited(ip)) {
        return Response.json({ error: "rate_limited" }, { status: 429 });
      }

      const bodyText = await request.text();
      if (bodyText.length > MAX_BODY_BYTES) {
        return Response.json({ error: "payload_too_large" }, { status: 413 });
      }

      let parsed: { model?: unknown; messages?: unknown; max_tokens?: unknown; temperature?: unknown };
      try {
        parsed = JSON.parse(bodyText);
      } catch {
        return Response.json({ error: "invalid_json" }, { status: 400 });
      }

      const messages = sanitizeMessages(parsed.messages);
      if (!messages) {
        return Response.json({ error: "invalid_messages" }, { status: 400 });
      }

      const model = typeof parsed.model === "string" && ALLOWED_MODELS.has(parsed.model)
        ? parsed.model
        : ALLOWED_MODELS.values().next().value as string;
      const maxTokens = typeof parsed.max_tokens === "number" && parsed.max_tokens > 0
        ? Math.min(Math.floor(parsed.max_tokens), MAX_TOKENS_CAP)
        : MAX_TOKENS_CAP;

      // The toolkit URL is public (not a secret); default covers Workers whose
      // env store does not spread it.
      const toolkitUrl = (env.EXPO_PUBLIC_TOOLKIT_URL || "https://toolkit.rork.com").replace(/\/+$/, "");
      const toolkitKey = env.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY ?? "";
      if (!toolkitUrl || !toolkitKey) {
        return Response.json({ error: "proxy_not_configured" }, { status: 503 });
      }

      const upstream = await fetch(`${toolkitUrl}/v2/vercel/v1/chat/completions`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${toolkitKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ model, messages, max_tokens: maxTokens, temperature: 0 }),
      });

      return new Response(upstream.body, {
        status: upstream.status,
        headers: { "Content-Type": upstream.headers.get("Content-Type") ?? "application/json" },
      });
    }

    return Response.json({ error: "not_found" }, { status: 404 });
  },
};
