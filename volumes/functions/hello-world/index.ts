// Follow this setup guide to integrate the Deno runtime with your Supabase Edge Functions:
// https://supabase.com/docs/guides/functions/auth

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

console.log("Hello from Functions!")

serve(async (req) => {
  const { name } = await req.json()
  const data = {
    message: `Hello ${name || 'World'}!`,
  }

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})