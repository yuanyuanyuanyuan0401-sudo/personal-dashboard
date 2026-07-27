import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// 数据库表名常量
export const TABLES = {
  TODOS: 'todos',
  TODO_SESSIONS: 'todo_sessions',
  DIARY: 'diaries',
  DIARY_IMAGES: 'diary_images',
  READING_BOOKS: 'reading_books',
  READING_SESSIONS: 'reading_sessions',
  READING_NOTES: 'reading_notes',
  SPORTS: 'sports',
  SETTINGS: 'settings'
}
