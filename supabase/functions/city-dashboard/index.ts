import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { html } from "./html.ts";

Deno.serve((_req: Request) => new Response(html, {
  headers: {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store",
  },
}));
