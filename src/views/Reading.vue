<template>
  <div class="reading-page">
    <div class="page-header">
      <h1 class="page-title">阅读</h1>
      <button v-if="wereadKey" class="btn btn-secondary btn-sm" @click="syncFromWeRead" :disabled="syncing">
        {{ syncing ? '同步中...' : '🔄 同步' }}
      </button>
    </div>

    <!-- 微信读书连接提示 -->
    <div v-if="!wereadKey" class="card">
      <div class="card-title">🔗 微信读书</div>
      <p style="font-size:13px;color:var(--text-secondary);margin-bottom:10px;">
        配置微信读书 API Key 后可自动同步书架和阅读数据
      </p>
      <router-link to="/settings" class="btn btn-secondary">前往设置</router-link>
    </div>

    <!-- 微信读书同步状态 -->
    <div v-if="syncing" class="card">
      <div class="empty-state" style="padding:24px;">
        <div class="icon">🔄</div>
        <div class="text">正在同步微信读书数据...</div>
      </div>
    </div>

    <!-- 添加书目 -->
    <div class="card">
      <div class="card-title">添加阅读书目</div>
      <div class="add-book-row">
        <input v-model="newBook.title" class="input" placeholder="书名" style="flex:2;" />
        <input v-model="newBook.author" class="input" placeholder="作者" style="flex:1;" />
      </div>
      <div class="add-book-row" style="margin-top:8px;">
        <select v-model="newBook.status" class="input" style="flex:1;">
          <option value="reading">在读</option>
          <option value="finished">已读完</option>
          <option value="wishlist">想读</option>
        </select>
        <button class="btn btn-primary" @click="addBook">添加</button>
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
        <div class="current-session" v-if="currentSession > 0">
          本次已读：{{ formatDuration(currentSession) }}
        </div>
      </div>
    </div>

    <!-- 可选当前阅读书目 -->
    <div class="card">
      <div class="card-title">选择在读书目</div>
      <select v-model="activeBookId" class="input" @change="updateActiveBook">
        <option :value="null">不选择</option>
        <option v-for="b in readingBooks" :key="b.id" :value="b.id">{{ b.title }}</option>
      </select>
    </div>

    <!-- 在读 -->
    <div v-if="readingBooks.length > 0" class="card">
      <div class="card-title">在读 ({{ readingBooks.length }})</div>
      <div v-for="book in readingBooks" :key="book.id" class="book-item">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
        <div class="book-stats">
          <span class="book-minutes">{{ getBookMinutes(book.id) }}分钟</span>
        </div>
      </div>
    </div>

    <!-- 已读完 -->
    <div v-if="finishedBooks.length > 0" class="card">
      <div class="card-title">已读完 ({{ finishedBooks.length }})</div>
      <div v-for="book in finishedBooks" :key="book.id" class="book-item" @click="toggleNote(book)">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
        <span class="book-minutes">{{ book.totalMinutes }}分钟</span>
      </div>
    </div>

    <!-- 想读 -->
    <div v-if="wishlistBooks.length > 0" class="card">
      <div class="card-title">想读 ({{ wishlistBooks.length }})</div>
      <div v-for="book in wishlistBooks" :key="book.id" class="book-item">
        <div class="book-info">
          <span class="book-title">{{ book.title }}</span>
          <span class="book-author">{{ book.author }}</span>
        </div>
      </div>
    </div>

    <div v-if="allBooks.length === 0" class="empty-state">
      <div class="icon">📚</div>
      <div class="text">还没有阅读记录，开始添加第一本书吧</div>
    </div>

    <!-- 读后笔记弹窗 -->
    <div v-if="showNoteDialog" class="modal-overlay" @click.self="showNoteDialog = false">
      <div class="modal-content">
        <h3 class="modal-title">{{ noteBook?.title }} - 读后笔记</h3>

        <textarea v-model="noteContent" class="textarea" placeholder="记录你的读后感、思考、金句..." rows="5"></textarea>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="showNoteDialog = false">取消</button>
          <button class="btn btn-primary" @click="saveNote">保存笔记</button>
        </div>

        <!-- 已有笔记列表 -->
        <div v-if="bookNotes.length > 0" style="margin-top:16px;">
          <div class="card-title">历史笔记</div>
          <div v-for="note in bookNotes" :key="note.id" class="note-item">
            <div class="note-date">{{ formatDate(note.created_at) }}</div>
            <div class="note-content">{{ note.content }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import { getShelf, getWeeklyStats } from '../utils/weread.js'

const wereadKey = ref('')
const syncing = ref(false)

const newBook = ref({ title: '', author: '', status: 'reading' })
const allBooks = ref([])
const bookMinutes = ref({})
const activeBookId = ref(null)
const activeBook = ref(null)
const readingSessionStart = ref(null)
const readingActive = ref(false)
const currentSession = ref(0)
const bookReadTimer = ref(null)

const showNoteDialog = ref(false)
const noteBook = ref(null)
const noteContent = ref('')
const bookNotes = ref([])

const readingBooks = computed(() => allBooks.value.filter(b => b.status === 'reading'))
const finishedBooks = computed(() => allBooks.value.filter(b => b.status === 'finished'))
const wishlistBooks = computed(() => allBooks.value.filter(b => b.status === 'wishlist'))

const readingFormattedTime = computed(() => {
  const total = (currentSession.value)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  if (h > 0) return `${h}时${m}分${s}秒`
  return `${m}分${s}秒`
})

function formatDuration(seconds) {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${m}分${s}秒`
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
      // 更新 finishedBooks 的总时长
      allBooks.value.forEach(b => {
        b.totalMinutes = Math.round((bookMinutes.value[b.id] || 0) / 60)
      })
    }
  } catch (e) { console.warn(e) }
}

async function loadSettings() {
  try {
    const { data } = await supabase.from(TABLES.SETTINGS).select('*').eq('key', 'weread_api_key').single()
    if (data) wereadKey.value = data.value
  } catch (e) { /* 未设置 */ }
}

function getBookMinutes(bookId) {
  return Math.round((bookMinutes.value[bookId] || 0) / 60)
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
  } catch (e) { console.error('添加失败', e) }
}

function updateActiveBook() {
  activeBook.value = allBooks.value.find(b => b.id === activeBookId.value) || null
}

function startReading() {
  if (!activeBook.value) {
    alert('请先选择在读的书目')
    return
  }
  readingActive.value = true
  readingSessionStart.value = Date.now()
  currentSession.value = 0
  bookReadTimer.value = setInterval(() => {
    currentSession.value = Math.floor((Date.now() - readingSessionStart.value) / 1000)
  }, 1000)
}

async function stopReading() {
  if (bookReadTimer.value) clearInterval(bookReadTimer.value)
  readingActive.value = false
  const elapsed = currentSession.value

  if (elapsed > 10 && activeBook.value) {
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
    // 同步书架
    const shelf = await getShelf(wereadKey.value)
    if (shelf && shelf.books) {
      for (const book of shelf.books) {
        const exists = allBooks.value.find(b => b.title === book.title)
        if (!exists) {
          await supabase.from(TABLES.READING_BOOKS).insert({
            title: book.title,
            author: book.author || '',
            status: 'reading',
            cover: book.cover || '',
          })
        }
      }
      loadBooks()
    }

    // 同步阅读统计
    const stats = await getWeeklyStats(wereadKey.value)
    if (stats) {
      alert('同步完成！微信读书数据已导入工作台。')
    }
  } catch (e) {
    alert('同步失败，请检查 API Key 是否正确')
    console.error(e)
  }
  syncing.value = false
}

function toggleNote(book) {
  noteBook.value = book
  showNoteDialog.value = true
  noteContent.value = ''
  loadNotes(book.id)
}

async function loadNotes(bookId) {
  try {
    const { data } = await supabase
      .from(TABLES.READING_NOTES)
      .select('*')
      .eq('book_id', bookId)
      .order('created_at', { ascending: false })
    bookNotes.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveNote() {
  if (!noteContent.value.trim()) return
  try {
    await supabase.from(TABLES.READING_NOTES).insert({
      book_id: noteBook.value.id,
      content: noteContent.value,
    })
    noteContent.value = ''
    loadNotes(noteBook.value.id)
  } catch (e) { console.error(e) }
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getMonth() + 1}月${d.getDate()}日`
}

onMounted(() => {
  loadBooks()
  loadReadingMinutes()
  loadSettings()
})

onUnmounted(() => {
  if (bookReadTimer.value) clearInterval(bookReadTimer.value)
})
</script>

<style scoped>
.btn-sm {
  padding: 6px 12px;
  font-size: 12px;
}
.add-book-row {
  display: flex;
  gap: 8px;
}

.reading-timer {
  text-align: center;
  padding: 12px 0;
}
.timer-display {
  font-size: 40px;
  font-weight: 700;
  color: var(--primary-color);
  font-variant-numeric: tabular-nums;
  letter-spacing: 2px;
  margin-bottom: 12px;
}
.timer-actions {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 8px;
}
.current-session {
  font-size: 13px;
  color: var(--text-secondary);
}

.book-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  cursor: pointer;
}
.book-item + .book-item {
  border-top: 1px solid var(--border-color);
}
.book-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.book-title {
  font-size: 14px;
  font-weight: 500;
}
.book-author {
  font-size: 12px;
  color: var(--text-muted);
}
.book-minutes {
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
}

/* 弹窗 */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
  padding: 16px;
}
.modal-content {
  background: var(--card-bg);
  border-radius: var(--radius-lg);
  padding: 20px;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  overflow-y: auto;
}
.modal-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
}
.modal-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 10px;
}
.note-item {
  padding: 8px 0;
  border-bottom: 1px solid var(--border-color);
}
.note-date {
  font-size: 11px;
  color: var(--text-muted);
}
.note-content {
  font-size: 13px;
  margin-top: 4px;
  white-space: pre-wrap;
}
</style>
