-- ==========================================================================
-- 清理脚本：删除所有旧表（数据会丢失）
-- 执行完成后再跑完整的 supabase-schema.sql
-- ==========================================================================

DROP TABLE IF EXISTS gratitudes CASCADE;
DROP TABLE IF EXISTS snippets CASCADE;
DROP TABLE IF EXISTS reading_reflections CASCADE;
DROP TABLE IF EXISTS reading_notes CASCADE;
DROP TABLE IF EXISTS reading_sessions CASCADE;
DROP TABLE IF EXISTS reading_books CASCADE;
DROP TABLE IF EXISTS sports_videos CASCADE;
DROP TABLE IF EXISTS sports CASCADE;
DROP TABLE IF EXISTS work_communications CASCADE;
DROP TABLE IF EXISTS work_reflections CASCADE;
DROP TABLE IF EXISTS work_files CASCADE;
DROP TABLE IF EXISTS todo_sessions CASCADE;
DROP TABLE IF EXISTS todos CASCADE;
DROP TABLE IF EXISTS settings CASCADE;

SELECT '已清空所有表，现在可以重新跑 supabase-schema.sql' AS status;
