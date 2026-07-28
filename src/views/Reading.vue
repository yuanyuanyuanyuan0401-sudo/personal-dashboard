<template>
  <div class="reading-page">
    <div class="page-header">
      <h1 class="page-title">阅读</h1>
      <div class="header-actions">
        <router-link to="/reading/reflections" class="btn btn-secondary btn-sm">💡 思考</router-link>
        <router-link to="/reading/stats" class="btn btn-secondary btn-sm">📊 统计</router-link>
      </div>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 微信读书连接 -->
    <div v-if="!wereadKey" class="card">
      <div class="card-title">🔗 微信读书</div>
      <p style="font-size:13px;color:var(--text-secondary);margin-bottom:10px;">
        配置微信读书 API Key 自动同步书架和阅读时长
      </p>
      <router-link to="/settings" class="btn btn-secondary">前往设置</router-link>
    </div>

    <div v-else>
      <div class="card">
        <div class="card-title">🔗 微信读书</div>
        <div class="stat-grid">
          <div class="stat-card">
            <div class="stat-value">{{ todayMinutes }}<span class="stat-unit">m</span></div>
            <div class="stat-label">今日阅读</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ weekMinutes }}<span class="stat-unit">m</span></div>
            <div class="stat-label">本周阅读</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ monthMinutes }}<span class="stat-unit">m</span></div>
            <div class="stat-label">本月阅读</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ streakDays }}</div>
            <div class="stat-label">连续天数</div>
          </div>
        </div>
        <button class="btn btn-secondary btn-block" @click="syncFromWeRead" :disabled="syncing" style="margin-top:12px;">
          {{ syncing ? '同步中...' : '🔄 同步微信读书' }}
        </button>
      </div>
    </div>

    <!-- 阅读计时 -->
    <div class="card" v-if="activeBook">
      <div class="card-title">📖 当前阅读：{{ activeBook.title }}</div>
      <div class="reading-timer">
        <div class="timer-display">{{ readingFormattedTime }}</div>
        <div class="timer-actions">
          <button v-if="!readingActive" class="btn btn-primary" @click="startReading">开始阅读</button>
          <button v-if="readingActive" class="btn btn-danger" @click="stopReading">结束阅读</button>
        </div>
      </div>
    </div>

    <!-- 今日阅读思考 -->
    <div class="card">
      <div class="card-title">✍️ 今日阅读思考</div>
      <div class="card-subtitle">记录一闪而过的想法</div>
      <select v-model="thoughtBookId" class="select" style="margin-bottom:8px;">
        <option :value="null">不关联书</option>
        <option v-for="b in readingBooks" :key="b.id" :value="b.id">{{ b.title }}</option>
      </select>
      <textarea v-model="thoughtContent" class="textarea" placeholder="刚刚想到的..." rows="2"></textarea>
      <button class="btn btn-primary btn-block" @click="saveThought" :disabled="!thoughtContent" style="margin-top:8px;">记下想法</button>

      <div v-if="todayThoughts.length > 0" class="thought-list">
        <div v-for="t in todayThoughts" :key="t.id" class="thought-item">
          <div class="thought-meta">
            <span class="thought-time">{{ formatTime(t.created_at) }}</span>
            <button class="btn-icon-small danger" @click="deleteThought(t)">✕</button>
          </div>
          <div v-if="thoughtBook(t.book_id)" class="thought-book">📖 {{ thoughtBook(t.book_id) }}</div>
          <div class="thought-content">{{ t.content }}</div>
        </div>
      </div>
    </div>

    <!-- 添加书目 -->
    <div class="card">
      <div class="card-title">➕ 添加书目</div>
      <div class="add-book-row">
        <input v-model="newBook.title" class="input" placeholder="书名" style="flex:2;" />
        <input v-model="newBook.author" class="input" placeholder="作者" style="flex:1;" />
      </div>
      <div class="add-book-row" style="margin-top:8px;">
        <select v-model="newBook.status" class="select" style="flex:1;">
          <option value="reading">在读</option>
          <option value="finished">已读完</option>
          <option value="wishlist">想读</option>
        </select>
        <button class="btn btn-primary" @click="addBook">添加</button>
      </div>
    </div>

    <!-- 选中当前阅读 -->
    <div class="card" v-if="readingBooks.length > 0">
      <div class="card-title">📚 选择当前阅读</div>
      <select v-model="activeBookId" class="select" @change="updateActiveBook">
        <option :value="null">不选择</option>
        <option v-for="b in readingBooks" :key="b.id" :value="b.id">{{ b.title }}</option>
      </select>
    </div>

    <!-- 在读 -->
    <div v-if="readingBooks.length > 0" class="card">
      <div class="card-title">📖 在读 ({{ readingBooks.length }})</div>
      <div v-for="book in readingBooks" :key="book.id" class="book-item">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
        <div class="book-stats">
          <span class="book-minutes">{{ getBookMinutes(book.id) }}分钟</span>
          <button class="btn-icon-small danger" @click="deleteBook(book)">✕</button>
        </div>
      </div>
    </div>

    <!-- 已读完 -->
    <div v-if="finishedBooks.length > 0" class="card">
      <div class="card-title">✅ 已读完 ({{ finishedBooks.length }})</div>
      <div v-for="book in finishedBooks" :key="book.id" class="book-item">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
        <div class="book-stats">
          <span class="book-minutes">{{ getBookMinutes(book.id) }}分钟</span>
          <button class="btn-icon-small danger" @click="deleteBook(book)">✕</button>
        </div>
      </div>
    </div>

    <!-- 想读 -->
    <div v-if="wishlistBooks.length > 0" class="card">
      <div class="card-title">⭐ 想读 ({{ wishlistBooks.length }})</div>
      <div v-for="book in wishlistBooks" :key="book.id" class="book-item">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
        <div class="book-stats">
          <button class="btn-icon-small danger" @click="deleteBook(book)">✕</button>
        </div>
      </div>
    </div>

    <div v-if="allBooks.length === 0" class="empty-state">
      <div class="icon">📚</div>
      <div class="text">还没有添加书目</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import { getShelf, getWeeklyStats } from '../utils/weread.js'

const wereadKey = ref('')
const syncing = ref(false)
const allBooks = ref([])
const bookMinutes = ref({})
const activeBookId = ref(null)
const activeBook = ref(null)
const readingActive = ref(false)
const currentSession = ref(0)
const sessionStart = ref(null)
let bookTimer = null

const newBook = ref({ title: '', author: '', status: 'reading' })

// 今日阅读思考
const thoughts = ref([])
const todayThoughts = ref([])
const thoughtContent = ref('')
const thoughtBookId = ref(null)

const touchMoments = [
  '读书，是与灵魂的一次对话。',
  '书卷里，藏着更广阔的世界。',
  '读一本好书，交一个挚友。',
  '每读完一本书，就多了一种活法。',
  '给阅读时间，给思考空间。',
  '腹有诗书气自华。',
]
const touchMomentText = ref(touchMoments[0])

const readingBooks = computed(() => allBooks.value.filter(b => b.status === 'reading'))
const finishedBooks = computed(() => allBooks.value.filter(b => b.status === 'finished'))
const wishlistBooks = computed(() => allBooks.value.filter(b => b.status === 'wishlist'))

const todayMinutes = ref(0)
const weekMinutes = ref(0)
const monthMinutes = ref(0)
const streakDays = ref(0)

const readingFormattedTime = computed(() => {
  const total = currentSession.value
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  if (h > 0) return `${h}时${m}分${s}秒`
  return `${m}分${s}秒`
})

function getBookMinutes(bookId) {
  return Math.round((bookMinutes.value[bookId] || 0) / 60)
}

function thoughtBook(id) {
  if (!id) return ''
  const b = allBooks.value.find(x => x.id === id)
  return b ? b.title : ''
}

function formatTime(dateStr) {
  const d = new Date(dateStr)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

async function loadBooks() {
  try {
    const { data } = await supabase.from(TABLES.READING_BOOKS).select('*').order('created_at', { ascending: false })
    allBooks.value = data || []
  } catch (e) { console.warn(e) }
}

async function loadReadingMinutes() {
  try {
    const { data } = await supabase.from(TABLES.READING_SESSIONS).select('book_id, duration, created_at')
    if (data) {
      const map = {}
      const todayStr = new Date().toISOString().split('T')[0]
      const weekStart = new Date()
      weekStart.setDate(weekStart.getDate() - 6)
      weekStart.setHours(0, 0, 0, 0)
      const monthStart = new Date()
      monthStart.setDate(1)
      monthStart.setHours(0, 0, 0, 0)

      let todayTotal = 0, weekTotal = 0, monthTotal = 0
      const days = new Set()

      data.forEach(s => {
        const d = new Date(s.created_at)
        const dateStr = s.created_at.split('T')[0]
        map[s.book_id] = (map[s.book_id] || 0) + (s.duration || 0)
        if (dateStr === todayStr) todayTotal += s.duration
        if (d >= weekStart) weekTotal += s.duration
        if (d >= monthStart) {
          monthTotal += s.duration
          days.add(dateStr)
        }
      })

      bookMinutes.value = map
      todayMinutes.value = Math.round(todayTotal / 60)
      weekMinutes.value = Math.round(weekTotal / 60)
      monthMinutes.value = Math.round(monthTotal / 60)
      streakDays.value = computeStreak(days)
    }
  } catch (e) { console.warn(e) }
}

function computeStreak(days) {
  if (days.size === 0) return 0
  const sorted = [...days].sort().reverse()
  let streak = 0
  const today = new Date()
  for (let i = 0; i < sorted.length; i++) {
    const expected = new Date(today)
    expected.setDate(today.getDate() - i)
    if (sorted[i] === expected.toISOString().split('T')[0]) streak++
    else break
  }
  return streak
}

async function loadSettings() {
  try {
    const { data } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key').single()
    if (data) wereadKey.value = data.value
  } catch (e) { /* not set */ }
}

async function loadThoughts() {
  try {
    const todayStr = new Date().toISOString().split('T')[0]
    const { data } = await supabase
      .from(TABLES.READING_DAILY_THOUGHTS)
      .select('*')
      .eq('date', todayStr)
      .order('created_at', { ascending: false })
    todayThoughts.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveThought() {
  if (!thoughtContent.value.trim()) return
  try {
    const todayStr = new Date().toISOString().split('T')[0]
    const { data } = await supabase.from(TABLES.READING_DAILY_THOUGHTS).insert({
      date: todayStr,
      book_id: thoughtBookId.value,
      content: thoughtContent.value,
    }).select()
    if (data) {
      todayThoughts.value.unshift(data[0])
      thoughtContent.value = ''
    }
  } catch (e) { console.error('保存失败', e) }
}

async function deleteThought(t) {
  if (!confirm('删除这条想法？')) return
  try {
    await supabase.from(TABLES.READING_DAILY_THOUGHTS).delete().eq('id', t.id)
    todayThoughts.value = todayThoughts.value.filter(x => x.id !== t.id)
  } catch (e) { console.error(e) }
}

async function addBook() {
  if (!newBook.value.title.trim()) return
  try {
    const { data } = await supabase.from(TABLES.READING_BOOKS).insert({
      title: newBook.value.title,
      author: newBook.value.author,
      status: newBook.value.status,
    }).select()
    if (data) allBooks.value.unshift(data[0])
    newBook.value = { title: '', author: '', status: 'reading' }
  } catch (e) { console.error(e) }
}

async function deleteBook(book) {
  if (!confirm(`删除《${book.title}》？`)) return
  try {
    await supabase.from(TABLES.READING_BOOKS).delete().eq('id', book.id)
    allBooks.value = allBooks.value.filter(b => b.id !== book.id)
  } catch (e) { console.error(e) }
}

function updateActiveBook() {
  activeBook.value = allBooks.value.find(b => b.id === activeBookId.value) || null
}

function startReading() {
  if (!activeBook.value) {
    alert('请先选一本书')
    return
  }
  readingActive.value = true
  sessionStart.value = Date.now()
  currentSession.value = 0
  bookTimer = setInterval(() => {
    currentSession.value = Math.floor((Date.now() - sessionStart.value) / 1000)
  }, 1000)
}

async function stopReading() {
  if (bookTimer) clearInterval(bookTimer)
  readingActive.value = false
  const elapsed = currentSession.value

  if (elapsed > 10 && activeBook.value) {
    const todayStr = new Date().toISOString().split('T')[0]
    try {
      await supabase.from(TABLES.READING_SESSIONS).insert({
        book_id: activeBook.value.id,
        duration: elapsed,
      })
      loadReadingMinutes()
    } catch (e) { console.error(e) }
  }

  currentSession.value = 0
}

async function syncFromWeRead() {
  syncing.value = true
  try {
    const shelf = await getShelf(wereadKey.value)
    if (shelf && (shelf.books || shelf)) {
      const books = Array.isArray(shelf) ? shelf : shelf.books
      for (const book of books) {
        if (!book.title) continue
        const exists = allBooks.value.find(b => b.title === book.title)
        if (!exists) {
          await supabase.from(TABLES.READING_BOOKS).insert({
            title: book.title,
            author: book.author || '',
            cover: book.cover || '',
            status: book.finishReading ? 'finished' : 'reading',
            source: 'weread',
            external_id: book.bookId,
          })
        } else if (book.cover && !exists.cover) {
          await supabase.from(TABLES.READING_BOOKS)
            .update({ cover: book.cover })
            .eq('id', exists.id)
        }
      }
      loadBooks()
      alert('同步成功！')
    }
  } catch (e) {
    alert('同步失败，请检查 API Key')
    console.error(e)
  }
  syncing.value = false
}

onMounted(() => {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
  loadBooks()
  loadReadingMinutes()
  loadSettings()
  loadThoughts()
})

onUnmounted(() => {
  if (bookTimer) clearInterval(bookTimer)
})
</script>

<style scoped>
.header-actions {
  display: flex;
  gap: 6px;
}

.card-subtitle {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 12px;
  margin-top: -8px;
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
}

.stat-card {
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  padding: 12px;
  text-align: center;
}

.stat-value {
  font-size: 22px;
  font-weight: 700;
  color: var(--primary-dark);
}

.stat-unit {
  font-size: 11px;
  font-weight: 400;
  color: var(--text-muted);
  margin-left: 2px;
}

.stat-label {
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 2px;
}

/* 阅读计时 */
.reading-timer {
  text-align: center;
  padding: 12px 0;
}

.timer-display {
  font-size: 36px;
  font-weight: 700;
  color: var(--primary-dark);
  font-variant-numeric: tabular-nums;
  letter-spacing: 2px;
  margin-bottom: 12px;
  font-family: var(--font-serif);
}

.timer-actions {
  display: flex;
  justify-content: center;
  gap: 10px;
}

/* 今日思考 */
.thought-list {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.thought-item {
  padding: 10px 12px;
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  border-left: 3px solid var(--accent-yellow);
}

.thought-meta {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
}

.thought-time {
  font-size: 11px;
  color: var(--text-muted);
  flex: 1;
}

.thought-book {
  font-size: 11px;
  color: var(--accent-blue);
  margin-bottom: 4px;
}

.thought-content {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.6;
  text-indent: 0;
  white-space: pre-wrap;
}

.btn-icon-small {
  width: 22px;
  height: 22px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
}

.btn-icon-small.danger {
  color: var(--danger-color);
}

.add-book-row {
  display: flex;
  gap: 8px;
}

.book-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid var(--border-soft);
}

.book-item:last-child {
  border-bottom: none;
}

.book-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 0;
}

.book-title {
  font-size: 14px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.book-author {
  font-size: 12px;
  color: var(--text-muted);
}

.book-stats {
  display: flex;
  align-items: center;
  gap: 8px;
}

.book-minutes {
  font-size: 12px;
  color: var(--text-secondary);
  white-space: nowrap;
}
</style>
