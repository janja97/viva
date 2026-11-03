import { createClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database'

export default defineNuxtPlugin(() => {
  const { supabaseUrl, supabasePublishableKey } = useRuntimeConfig().public

  // Na serveru se sesija ne pamti kako se ne bi dijelila među posjetiteljima.
  const supabase = createClient<Database>(supabaseUrl, supabasePublishableKey, {
    auth: {
      persistSession: import.meta.client,
      autoRefreshToken: import.meta.client,
      detectSessionInUrl: import.meta.client,
    },
  })

  return { provide: { supabase } }
})
