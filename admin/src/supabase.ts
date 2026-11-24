import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const isSupabaseConfigured = Boolean(url && anonKey)
export const supabase = isSupabaseConfigured
  ? createClient(url!, anonKey!)
  : null

export type Book = {
  id: string
  title: string
  author: string
  price: number
  category: string | null
  description: string | null
  cover_url: string | null
  reading_path: string | null
}

export type Order = {
  id: string
  user_id: string
  total_price: number
  status: string
  created_at: string
}
