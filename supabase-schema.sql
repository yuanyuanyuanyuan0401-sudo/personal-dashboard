-- ==========================================================================
-- luna 工作台 · 完整数据库初始化
-- 在 Supabase SQL Editor 中执行一次即可
-- ==========================================================================

-- 启用 UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================================================
-- 1. 待办 + 番茄钟
-- ==========================================================================
CREATE TABLE IF NOT EXISTS todos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  notes TEXT,
  category TEXT DEFAULT 'today',  -- today / week / none / checkin-daily / checkin-weekly
  checkin_pattern TEXT,            -- 仅打卡类使用：daily / weekly / specific-days
  checkin_days INTEGER[],          -- 打卡具体日期，1-7 表示周一到周日
  due_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS todo_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  todo_id UUID REFERENCES todos(id) ON DELETE SET NULL,
  duration INTEGER NOT NULL,         -- 秒
  mode TEXT DEFAULT 'countdown',     -- countdown / countup
  planned_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 2. 工作模块
-- ==========================================================================
CREATE TABLE IF NOT EXISTS work_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  category TEXT,                     -- 总结 / 计划 / 报告 / 其他
  file_url TEXT,                     -- Supabase Storage URL
  file_type TEXT,                    -- pdf / doc / image / etc
  file_size INTEGER,
  description TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS work_reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT,
  event TEXT,                        -- 事件
  reflection TEXT,                   -- 反思
  category TEXT,                     -- 教学反思 / 班级反思 / 个人反思
  mood INTEGER,                      -- 心情 1-5
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS work_communications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_name TEXT,
  student_name TEXT,
  method TEXT,                       -- 微信 / 电话 / 面谈
  topic TEXT,
  summary TEXT,
  follow_up TEXT,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 3. 运动模块
-- ==========================================================================
CREATE TABLE IF NOT EXISTS sports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL,
  date DATE NOT NULL,
  duration INTEGER NOT NULL,         -- 分钟
  distance DECIMAL,                  -- 公里
  calories INTEGER,
  intensity TEXT,                    -- 轻 / 中 / 高
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sports_videos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  source TEXT DEFAULT 'bilibili',
  url TEXT NOT NULL,
  category TEXT,                     -- 腹腹 / 瘦腿 / 瘦背 / 直角肩 / 体态 / 改善睡眠
  duration INTEGER,
  description TEXT,
  thumbnail TEXT,
  favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 4. 阅读模块
-- ==========================================================================
CREATE TABLE IF NOT EXISTS reading_books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  author TEXT,
  cover TEXT,
  status TEXT DEFAULT 'reading',     -- reading / finished / wishlist
  total_minutes INTEGER DEFAULT 0,
  notes_count INTEGER DEFAULT 0,
  source TEXT,                       -- manual / weread
  external_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reading_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES reading_books(id) ON DELETE SET NULL,
  duration INTEGER NOT NULL,
  pages INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reading_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES reading_books(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  page INTEGER,
  type TEXT DEFAULT 'quote',         -- quote / thought / summary
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reading_reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  book_id UUID REFERENCES reading_books(id) ON DELETE SET NULL,
  title TEXT,
  content TEXT NOT NULL,
  insights TEXT,                     -- 主要收获
  questions TEXT,                    -- 留下的疑问
  actions TEXT,                      -- 行动建议
  rating INTEGER,                    -- 评分 1-5
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 每日阅读思考（随时记录的短想法）
CREATE TABLE IF NOT EXISTS reading_daily_thoughts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  book_id UUID REFERENCES reading_books(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  start_page INTEGER,
  end_page INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 每日阅读时长统计（从微信读书同步）
CREATE TABLE IF NOT EXISTS reading_daily_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL UNIQUE,
  total_minutes INTEGER DEFAULT 0,
  sessions_count INTEGER DEFAULT 0,
  books JSONB,                        -- [{bookId, title, cover, minutes}]
  source TEXT DEFAULT 'manual',      -- manual / weread
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 5. 碎碎念模块
-- ==========================================================================
CREATE TABLE IF NOT EXISTS snippets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  type TEXT DEFAULT 'snippet',       -- snippet / mood / moment
  mood TEXT,                         -- 平和 / 充盈 / 感恩 / 焦虑 / 期待 / 疲惫
  tags TEXT[],
  location TEXT,
  weather TEXT,
  word_count INTEGER,
  images TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gratitudes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL UNIQUE,
  item1 TEXT,
  item2 TEXT,
  item3 TEXT,
  emotions TEXT,                     -- 逗号分隔
  extra TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 6. 设置
-- ==========================================================================
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================================
-- 索引
-- ==========================================================================
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);
CREATE INDEX IF NOT EXISTS idx_todo_sessions_todo ON todo_sessions(todo_id);
CREATE INDEX IF NOT EXISTS idx_sports_date ON sports(date);
CREATE INDEX IF NOT EXISTS idx_books_status ON reading_books(status);
CREATE INDEX IF NOT EXISTS idx_snippets_created ON snippets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gratitudes_date ON gratitudes(date);
CREATE INDEX IF NOT EXISTS idx_reading_thoughts_date ON reading_daily_thoughts(date DESC);
CREATE INDEX IF NOT EXISTS idx_reading_stats_date ON reading_daily_stats(date DESC);

-- ==========================================================================
-- RLS（行级安全 - 单用户场景，全部允许）
-- ==========================================================================
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE sports_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_daily_thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE snippets ENABLE ROW LEVEL SECURITY;
ALTER TABLE gratitudes ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 开放所有权限（单用户）
DROP POLICY IF EXISTS "Allow all" ON todos;
CREATE POLICY "Allow all" ON todos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON todo_sessions;
CREATE POLICY "Allow all" ON todo_sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON work_files;
CREATE POLICY "Allow all" ON work_files FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON work_reflections;
CREATE POLICY "Allow all" ON work_reflections FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON work_communications;
CREATE POLICY "Allow all" ON work_communications FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON sports;
CREATE POLICY "Allow all" ON sports FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON sports_videos;
CREATE POLICY "Allow all" ON sports_videos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_books;
CREATE POLICY "Allow all" ON reading_books FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_sessions;
CREATE POLICY "Allow all" ON reading_sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_notes;
CREATE POLICY "Allow all" ON reading_notes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_reflections;
CREATE POLICY "Allow all" ON reading_reflections FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_daily_thoughts;
CREATE POLICY "Allow all" ON reading_daily_thoughts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON reading_daily_stats;
CREATE POLICY "Allow all" ON reading_daily_stats FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON snippets;
CREATE POLICY "Allow all" ON snippets FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON gratitudes;
CREATE POLICY "Allow all" ON gratitudes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all" ON settings;
CREATE POLICY "Allow all" ON settings FOR ALL USING (true) WITH CHECK (true);

-- ==========================================================================
-- 完成
-- ==========================================================================
SELECT 'luna 工作台数据库初始化完成' AS status;
