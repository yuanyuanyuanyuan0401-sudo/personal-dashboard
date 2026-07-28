/**
 * Supabase 客户端配置
 */
import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://zifxneisxvqarlnlvhca.supabase.co'
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InppZnhuZWlzeHZxYXJsbmx2aGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxNDk2MTcsImV4cCI6MjEwMDcyNTYxN30._fBcOGPxIM5DeC6CpYHhaUiD8o254EWnplp0hgkcDeA'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

/**
 * 数据表名常量
 */
export const TABLES = {
  // 待办
  TODOS: 'todos',
  TODO_SESSIONS: 'todo_sessions',
  TODO_SUMMARIES: 'todo_summaries',
  // 工作
  WORK_FILES: 'work_files',
  WORK_REFLECTIONS: 'work_reflections',
  WORK_COMMUNICATIONS: 'work_communications',
  // 运动
  SPORTS: 'sports',
  SPORTS_VIDEOS: 'sports_videos',
  // 阅读
  READING_BOOKS: 'reading_books',
  READING_SESSIONS: 'reading_sessions',
  READING_NOTES: 'reading_notes',
  READING_REFLECTIONS: 'reading_reflections',
  // 碎碎念
  SNIPPETS: 'snippets',
  GRATITUDES: 'gratitudes',
  // 设置
  SETTINGS: 'settings',
}
