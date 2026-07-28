<template>
  <div class="reading-page">
    <div class="page-header">
      <h1 class="page-title">阅读</h1>
      <router-link to="/reading/reflections" class="btn btn-secondary btn-sm">💡 思考</router-link>
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
        <div class="weread-stats">
          <div class="ws-item">
            <div class="ws-value">{{ weeklyMinutes }}</div>
            <div class="ws-label">本周阅读(分钟)</div>
          </div>
          <div class="ws-item">
            <div class="ws-value">{{ streakDays }}</div>
            <div class="ws-label">连续天数</div>
          </div>
        </div>
        <button class="btn btn-secondary btn-block" @click="syncFromWeRead" :disabled="syncing">
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

const weeklyMinutes = ref(0)
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

async function loadBooks() {
  try {
    const { data } = await supabase.from(TABLES.READING_BOOKS).select('*').order('created_at', { ascending: false })
    allBooks.value = data || []
  } catch (e) { console.warn(e) }
}

async function loadReadingMinutes() {
  try {
    const { data } = await supabase.from(TABLES.READING_SESSIONS).select('book_id, duration')
    if (data) {
      const map = {}
      data.forEach(s => {
        map[s.book_id] = (map[s.book_id] || 0) + (s.duration || 0)
      })
      bookMinutes.value = map
    }
  } catch (e) { console.warn(e) }
}

async function loadSettings() {
  try {
    const { data } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key').single()
    if (data) wereadKey.value = data.value
  } catch (e) { /* not set */ }
}

async function loadWeeklyStats() {
  try {
    const weekStart = new Date()
    weekStart.setDate(weekStart.getDate() - 6)
    weekStart.setHours(0, 0, 0, 0)
    const { data } = await supabase
      .from(TABLES.READING_SESSIONS)
      .select('*')
      .gte('created_at', weekStart.toISOString())
    if (data) {
      weeklyMinutes.value = Math.round(data.reduce((s, r) => s + (r.duration || 0), 0) / 60)
    }
  } catch (e) { console.warn(e) }
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
    try {
      await supabase.from(TABLES.READING_SESSIONS).insert({
        book_id: activeBook.value.id,
        duration: elapsed,
      })
      loadReadingMinutes()
      loadWeeklyStats()
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
            status: 'reading',
            source: 'weread',
          })
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
  loadWeeklyStats()
})

onUnmounted(() => {
  if (bookTimer) clearInterval(bookTimer)
})
</script>

<style scoped>
.weread-stats {
  display: flex;
  gap: 24px;
  margin-bottom: 12px;
}

.ws-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.ws-value {
  font-size: 22px;
  font-weight: 700;
  color: var(--primary-dark);
}

.ws-label {
  font-size: 12px;
  color: var(--text-muted);
}

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
