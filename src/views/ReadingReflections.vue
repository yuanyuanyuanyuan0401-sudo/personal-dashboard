<template>
  <div class="reflect-page">
    <div class="sub-header">
      <router-link to="/reading" class="back-btn">←</router-link>
      <span class="sub-title">💡 阅读思考输出</span>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">让阅读有所得，让思考有回响。</div>
    </div>

    <!-- 新增思考 -->
    <div class="card">
      <div class="card-title">✍️ 写下你的思考</div>
      <select v-model="form.book_id" class="select" style="margin-bottom:8px;">
        <option :value="null">不关联书目</option>
        <option v-for="b in books" :key="b.id" :value="b.id">{{ b.title }}</option>
      </select>
      <input v-model="form.title" class="input" placeholder="思考标题" style="margin-bottom:8px;" />
      <textarea v-model="form.content" class="textarea" placeholder="核心思考..." rows="4" style="margin-bottom:8px;"></textarea>
      <textarea v-model="form.insights" class="textarea" placeholder="我的收获..." rows="2" style="margin-bottom:8px;"></textarea>
      <textarea v-model="form.questions" class="textarea" placeholder="留下的疑问..." rows="2" style="margin-bottom:8px;"></textarea>
      <textarea v-model="form.actions" class="textarea" placeholder="行动建议..." rows="2" style="margin-bottom:8px;"></textarea>
      <div class="rating-row">
        <span class="rating-label">评分：</span>
        <button v-for="n in 5" :key="n" :class="['rating-btn', { active: form.rating >= n }]" @click="form.rating = n">⭐</button>
      </div>
      <button class="btn btn-primary btn-block" @click="saveReflect" :disabled="!form.content">保存思考</button>
    </div>

    <!-- 历史思考 -->
    <div class="card" v-if="reflections.length > 0">
      <div class="card-title">📚 我的思考</div>
      <div v-for="r in reflections" :key="r.id" class="reflect-item">
        <div class="reflect-header">
          <span class="reflect-title">{{ r.title || '思·考' }}</span>
          <span class="reflect-rating">{{ r.rating ? '⭐'.repeat(r.rating) : '' }}</span>
          <button class="btn-icon-small danger" @click="deleteReflect(r)">✕</button>
        </div>
        <div v-if="bookTitle(r.book_id)" class="reflect-book">📖 {{ bookTitle(r.book_id) }}</div>
        <div class="reflect-section">
          <div class="section-label">💡 思考</div>
          <div class="section-content">{{ r.content }}</div>
        </div>
        <div v-if="r.insights" class="reflect-section">
          <div class="section-label">🎯 收获</div>
          <div class="section-content">{{ r.insights }}</div>
        </div>
        <div v-if="r.questions" class="reflect-section">
          <div class="section-label">❓ 疑问</div>
          <div class="section-content">{{ r.questions }}</div>
        </div>
        <div v-if="r.actions" class="reflect-section">
          <div class="section-label">➡️ 行动</div>
          <div class="section-content">{{ r.actions }}</div>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <div class="icon">💡</div>
      <div class="text">还没有思考输出</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const books = ref([])
const reflections = ref([])

const form = ref({
  book_id: null,
  title: '',
  content: '',
  insights: '',
  questions: '',
  actions: '',
  rating: 4,
})

function bookTitle(id) {
  if (!id) return ''
  const b = books.value.find(x => x.id === id)
  return b ? b.title : ''
}

async function loadBooks() {
  try {
    const { data } = await supabase.from(TABLES.READING_BOOKS).select('*').order('title')
    books.value = data || []
  } catch (e) { console.warn(e) }
}

async function loadReflections() {
  try {
    const { data } = await supabase.from(TABLES.READING_REFLECTIONS).select('*').order('created_at', { ascending: false })
    reflections.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveReflect() {
  if (!form.value.content) return
  try {
    const { data } = await supabase.from(TABLES.READING_REFLECTIONS).insert(form.value).select()
    if (data) {
      reflections.value.unshift(data[0])
      form.value = { book_id: null, title: '', content: '', insights: '', questions: '', actions: '', rating: 4 }
    }
  } catch (e) { console.error('保存失败', e) }
}

async function deleteReflect(r) {
  if (!confirm('确定删除？')) return
  try {
    await supabase.from(TABLES.READING_REFLECTIONS).delete().eq('id', r.id)
    reflections.value = reflections.value.filter(x => x.id !== r.id)
  } catch (e) { console.error(e) }
}

onMounted(() => {
  loadBooks()
  loadReflections()
})
</script>

<style scoped>
.form-row {
  display: flex;
  gap: 8px;
}

.rating-row {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-bottom: 10px;
}

.rating-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-right: 4px;
}

.rating-btn {
  background: transparent;
  border: none;
  font-size: 18px;
  cursor: pointer;
  opacity: 0.3;
  transition: all 0.2s;
}

.rating-btn.active {
  opacity: 1;
}

.reflect-item {
  padding: 14px 0;
  border-bottom: 1px solid var(--border-soft);
}

.reflect-item:last-child {
  border-bottom: none;
}

.reflect-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.reflect-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  flex: 1;
}

.reflect-rating {
  font-size: 12px;
}

.reflect-book {
  font-size: 12px;
  color: var(--accent-blue);
  margin-bottom: 8px;
}

.reflect-section {
  margin-bottom: 8px;
}

.reflect-section:last-child {
  margin-bottom: 0;
}

.section-label {
  font-size: 12px;
  color: var(--primary-dark);
  margin-bottom: 4px;
  font-weight: 500;
}

.section-content {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
  text-indent: 2em;
  white-space: pre-wrap;
}

.btn-icon-small {
  width: 26px;
  height: 26px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-icon-small.danger {
  color: var(--danger-color);
}
</style>
