<template>
  <div class="reading-page">
    <!-- 顶部 -->
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

    <!-- 阅读统计卡片（始终显示） -->
    <div class="card">
      <div class="card-title">
        📊 阅读统计
        <span v-if="lastSyncText" class="sync-tag">已同步</span>
      </div>
      <div class="stat-grid">
        <div class="stat-card">
          <div class="stat-value">{{ todayMinutes }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">今日阅读</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ weekMinutes }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">本周阅读</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ monthMinutes }}<span class="stat-unit">分钟</span></div>
          <div class="stat-label">本月阅读</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ streakDays }}</div>
          <div class="stat-label">连续天数</div>
        </div>
      </div>

      <!-- 微信读书同步状态 -->
      <div v-if="wereadKey" class="sync-row">
        <button class="btn btn-secondary btn-block" @click="syncFromWeRead" :disabled="syncing">
          {{ syncing ? '同步中...' : '🔄 同步微信读书' }}
        </button>
        <p v-if="lastSyncText" class="last-sync">上次同步：{{ lastSyncText }}</p>
      </div>
      <div v-else class="sync-row">
        <p class="sync-hint">📖 配置微信读书 API Key 可自动同步时长数据</p>
        <router-link to="/settings" class="btn btn-secondary btn-block">前往设置</router-link>
      </div>
    </div>

    <!-- 阅读计时（有选择书籍时显示） -->
    <div class="card" v-if="activeBook">
      <div class="card-title">📖 当前阅读：<strong>{{ activeBook.title }}</strong></div>
      <div class="reading-timer">
        <div class="timer-display">{{ readingFormattedTime }}</div>
        <div class="timer-actions">
          <button v-if="!readingActive" class="btn btn-primary" @click="startReading">▶ 开始阅读</button>
          <button v-if="readingActive" class="btn btn-danger" @click="stopReading">⏹ 结束阅读</button>
        </div>
      </div>
    </div>

    <!-- 选择当前阅读书目 -->
    <div class="card">
      <div class="card-title">📚 选择在读</div>
      <div class="book-select-row">
        <select v-model="activeBookId" class="select" @change="updateActiveBook">
          <option :value="null">— 选择一本书开始计时 —</option>
          <option v-for="b in readingBooks" :key="b.id" :value="b.id">{{ b.title }}</option>
        </select>
      </div>
    </div>

    <!-- 今日阅读思考 -->
    <div class="card">
      <div class="card-title">✍️ 今日阅读思考</div>
      <textarea v-model="thoughtContent" class="textarea" placeholder="读到这里，想到了什么说..." rows="2"></textarea>
      <div class="thought-book-row">
        <select v-model="thoughtBookId" class="select" style="flex:1;">
          <option :value="null">不关联书</option>
          <option v-for="b in readingBooks" :key="b.id" :value="b.id">{{ b.title }}</option>
        </select>
        <button class="btn btn-primary btn-sm" @click="saveThought" :disabled="!thoughtContent">记下</button>
      </div>
      <!-- 今日思考列表 -->
      <div v-if="todayThoughts.length > 0" class="thought-mini-list">
        <div v-for="t in todayThoughts" :key="t.id" class="thought-mini-item">
          <div class="thought-mini-time">{{ formatTime(t.created_at) }}</div>
          <div class="thought-mini-text">{{ t.content }}</div>
          <button class="btn-icon-small danger" @click="deleteThought(t)">✕</button>
        </div>
      </div>
    </div>

    <!-- 添加书目 -->
    <div class="card add-book-card">
      <div class="card-title">➕ 添加书目</div>
      <div class="add-row">
        <input v-model="newBook.title" class="input" placeholder="书名" />
        <input v-model="newBook.author" class="input" placeholder="作者" />
      </div>
      <div class="add-row">
        <select v-model="newBook.status" class="select">
          <option value="reading">在读</option>
          <option value="finished">已读完</option>
          <option value="wishlist">想读</option>
        </select>
        <button class="btn btn-primary" @click="addBook">添加</button>
      </div>
    </div>

    <!-- 书目分组：点击展开 -->
    <div class="book-section-list">
      <!-- 在读 -->
      <div class="card book-section" @click="toggleSection('reading')">
        <div class="section-header">
          <span class="section-icon">📖</span>
          <span class="section-title">在读</span>
          <span class="section-count">{{ readingBooks.length }}</span>
          <span class="section-arrow">{{ expandedSection === 'reading' ? '▼' : '▶' }}</span>
        </div>
        <transition name="fade">
          <div v-if="expandedSection === 'reading'" class="section-body">
            <div v-if="readingBooks.length === 0" class="section-empty">暂无</div>
            <div v-for="book in readingBooks" :key="book.id" class="section-book-item" @click.stop @click="selectAndStart(book)">
              <div class="sb-info">
                <span class="sb-title">{{ book.title }}</span>
                <span class="sb-author">{{ book.author }}</span>
              </div>
              <div class="sb-stats">
                <span class="sb-minutes">{{ getBookMinutes(book.id) }}分钟</span>
                <button class="btn-icon-small" @click.stop="startTimerForBook(book)" title="开始计时">🍅</button>
                <button class="btn-icon-small danger" @click.stop="deleteBook(book)">✕</button>
              </div>
            </div>
          </div>
        </transition>
      </div>

      <!-- 已读完 -->
      <div class="card book-section" @click="toggleSection('finished')">
        <div class="section-header">
          <span class="section-icon">✅</span>
          <span class="section-title">已读完</span>
          <span class="section-count">{{ finishedBooks.length }}</span>
          <span class="section-arrow">{{ expandedSection === 'finished' ? '▼' : '▶' }}</span>
        </div>
        <transition name="fade">
          <div v-if="expandedSection === 'finished'" class="section-body">
            <div v-if="finishedBooks.length === 0" class="section-empty">暂无</div>
            <div v-for="book in finishedBooks" :key="book.id" class="section-book-item">
              <div class="sb-info">
                <span class="sb-title">{{ book.title }}</span>
                <span class="sb-author">{{ book.author }}</span>
              </div>
              <div class="sb-stats">
                <span class="sb-minutes">{{ getBookMinutes(book.id) }}分钟</span>
                <button class="btn-icon-small danger" @click.stop="deleteBook(book)">✕</button>
              </div>
            </div>
          </div>
        </transition>
      </div>

      <!-- 想读 -->
      <div class="card book-section" @click="toggleSection('wishlist')">
        <div class="section-header">
          <span class="section-icon">⭐</span>
          <span class="section-title">想读</span>
          <span class="section-count">{{ wishlistBooks.length }}</span>
          <span class="section-arrow">{{ expandedSection === 'wishlist' ? '▼' : '▶' }}</span>
        </div>
        <transition name="fade">
          <div v-if="expandedSection === 'wishlist'" class="section-body">
            <div v-if="wishlistBooks.length === 0" class="section-empty">暂无</div>
            <div v-for="book in wishlistBooks" :key="book.id" class="section-book-item">
              <div class="sb-info">
                <span class="sb-title">{{ book.title }}</span>
                <span class="sb-author">{{ book.author }}</span>
              </div>
              <div class="sb-stats">
                <button class="btn-icon-small danger" @click.stop="deleteBook(book)">✕</button>
              </div>
            </div>
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'
import { getShelf, getReadDataDetail } from '../utils/weread.js'

const wereadKey = ref('')
const syncing = ref(false)
const weReadConnected = ref(false)
const lastSyncTime = ref(null)
const allBooks = ref([])
const bookMinutes = ref({})
const activeBookId = ref(null)
const activeBook = ref(null)
const readingActive = ref(false)
const currentSession = ref(0)
const sessionStart = ref(null)
let bookTimer = null

const newBook = ref({ title: '', author: '', status: 'reading' })
const expandedSection = ref(null)  // 'reading' | 'finished' | 'wishlist' | null

// 今日阅读思考
const thoughts = ref([])
const todayThoughts = ref([])
const thoughtContent = ref('')
const thoughtBookId = ref(null)

// 同步状态文本
const lastSyncText = computed(() => {
  if (!lastSyncTime.value) return ''
  const d = lastSyncTime.value
  const now = new Date()
  const diff = Math.floor((now - d) / 1000)
  if (diff < 60) return '刚刚'
  if (diff < 3600) return `${Math.floor(diff / 60)} 分钟前`
  if (diff < 86400) return `${Math.floor(diff / 3600)} 小时前`
  return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
})

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

function formatTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

function toggleSection(section) {
  expandedSection.value = expandedSection.value === section ? null : section
}

function selectAndStart(book) {
  activeBookId.value = book.id
  activeBook.value = book
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function startTimerForBook(book) {
  activeBookId.value = book.id
  activeBook.value = book
  startReading()
}

async function loadBooks() {
  try {
    const { data } = await supabase.from(TABLES.READING_BOOKS).select('*').order('created_at', { ascending: false })
    allBooks.value = data || []
  } catch (e) { console.warn(e) }
}

async function loadReadingMinutes() {
  try {
    // 优先从 reading_daily_stats 读取（微信读书同步数据）
    const { data: stats } = await supabase
      .from(TABLES.READING_DAILY_STATS)
      .select('*')
      .order('date', { ascending: false })
      .limit(365)

    if (stats && stats.length > 0) {
      const todayStr = new Date().toISOString().split('T')[0]
      const weekStart = new Date()
      weekStart.setDate(weekStart.getDate() - 6)
      weekStart.setHours(0, 0, 0, 0)
      const monthStart = new Date()
      monthStart.setDate(1)
      monthStart.setHours(0, 0, 0, 0)

      let todayTotal = 0, weekTotal = 0, monthTotal = 0
      const days = new Set()

      stats.forEach(s => {
        const d = new Date(s.date)
        if (s.date === todayStr) todayTotal += s.total_minutes || 0
        if (d >= weekStart) weekTotal += s.total_minutes || 0
        if (d >= monthStart) {
          monthTotal += s.total_minutes || 0
          if (s.total_minutes > 0) days.add(s.date)
        }
      })

      // 优先用微信读书数据
      todayMinutes.value = todayTotal
      weekMinutes.value = weekTotal
      monthMinutes.value = monthTotal
      streakDays.value = computeStreak(days)

      // 同时从 reading_sessions 累加手动计时（如果存在）
      const { data: sessions } = await supabase
        .from(TABLES.READING_SESSIONS)
        .select('book_id, duration, created_at')
      if (sessions) {
        const map = {}
        sessions.forEach(s => {
          map[s.book_id] = (map[s.book_id] || 0) + (s.duration || 0)
        })
        bookMinutes.value = map
      }
    } else {
      // 没数据时显示 0
      todayMinutes.value = 0
      weekMinutes.value = 0
      monthMinutes.value = 0
      streakDays.value = 0
      bookMinutes.value = {}
    }
  } catch (e) {
    console.warn('加载阅读时长失败', e)
    todayMinutes.value = 0
    weekMinutes.value = 0
    monthMinutes.value = 0
    streakDays.value = 0
  }
}

async function loadLastSync() {
  try {
    const { data } = await supabase
      .from(TABLES.SETTINGS)
      .select('*')
      .eq('key', 'weread_last_sync')
      .single()
    if (data && data.value) {
      lastSyncTime.value = new Date(data.value)
    }
  } catch (e) { /* no sync yet */ }
}

async function saveLastSync() {
  try {
    const now = new Date().toISOString()
    await supabase.from(TABLES.SETTINGS).upsert({
      key: 'weread_last_sync',
      value: now,
    }, { onConflict: 'key' })
    lastSyncTime.value = new Date(now)
  } catch (e) { console.warn('保存同步时间失败', e) }
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
  if (!wereadKey.value) {
    alert('请先在设置中配置微信读书 API Key')
    return
  }
  syncing.value = true
  weReadConnected.value = false
  try {
    // 1. 同步书架
    const shelf = await getShelf(wereadKey.value)
    const books = (shelf && (shelf.books || shelf)) || []
    if (Array.isArray(books)) {
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
    }

    // 2. 同步每日阅读时长（从微信读书获取）
    try {
      const detail = await getReadDataDetail(wereadKey.value)
      console.log('微信读书阅读数据:', detail)

      // 微信读书的返回格式可能是 { data: [{date, readTime, ...}] } 或 { readTime: [...days] }
      let dailyData = []
      if (detail) {
        if (Array.isArray(detail)) {
          dailyData = detail
        } else if (detail.data && Array.isArray(detail.data)) {
          dailyData = detail.data
        } else if (detail.readData && Array.isArray(detail.readData)) {
          dailyData = detail.readData
        } else if (detail.books && Array.isArray(detail.books)) {
          // 如果是另一种格式
          dailyData = detail.books
        }
      }

      // 尝试解析每日阅读时长数据
      const today = new Date()
      const yearStart = new Date(today.getFullYear(), 0, 1)
      const days = []
      let todayMinutes = 0, weekMinutes = 0, monthMinutes = 0

      for (let d = new Date(yearStart); d <= today; d.setDate(d.getDate() + 1)) {
        const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
        // 从 detail 中找这一天的数据
        const dayData = dailyData.find(x => {
          const xDate = x.date || x.dateKey || x.day
          if (!xDate) return false
          return xDate.toString().startsWith(dateStr) || xDate === dateStr
        })
        const minutes = dayData?.readTime || dayData?.minutes || dayData?.time || 0
        if (minutes > 0) {
          days.push({ date: dateStr, total_minutes: minutes })
        }
      }

      // 批量写入 reading_daily_stats
      if (days.length > 0) {
        for (const d of days) {
          await supabase.from(TABLES.READING_DAILY_STATS).upsert({
            date: d.date,
            total_minutes: d.total_minutes,
            source: 'weread',
            updated_at: new Date().toISOString(),
          }, { onConflict: 'date' })
        }
      }

      // 无论是否有数据，都保存同步时间
      await saveLastSync()
      loadReadingMinutes()
      weReadConnected.value = true
      loadBooks()
    } catch (e) {
      console.warn('同步阅读时长失败（可能接口路径不同）', e)
      // 部分同步成功也算成功
      await saveLastSync()
      weReadConnected.value = true
    }

    alert(`同步成功！从微信读书导入了 ${books.length} 本书`)
  } catch (e) {
    alert('同步失败，请检查 API Key')
    console.error(e)
  }
  syncing.value = false
}

async function autoSyncIfNeeded() {
  // 如果有 key 且超过 1 小时没同步，自动同步
  if (!wereadKey.value) return
  if (!lastSyncTime.value) {
    // 首次同步
    syncFromWeRead()
    return
  }
  const now = new Date()
  const diff = (now - lastSyncTime.value) / 1000 / 60  // 分钟
  if (diff > 60) {
    console.log('Auto-syncing WeChat Reading...')
    syncFromWeRead()
  }
}

onMounted(async () => {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
  loadBooks()
  loadReadingMinutes()
  loadSettings()
  loadThoughts()
  await loadLastSync()
  // 等待设置加载后检查是否需要自动同步
  setTimeout(() => autoSyncIfNeeded(), 1000)
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

/* 统计卡片 */
.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-bottom: 12px;
}

.stat-card {
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  padding: 12px 8px;
  text-align: center;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-dark);
  font-variant-numeric: tabular-nums;
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

.sync-row {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sync-hint {
  font-size: 12px;
  color: var(--text-muted);
  text-align: center;
}

.last-sync {
  font-size: 11px;
  color: var(--text-muted);
  text-align: center;
  margin-top: 4px;
}

.sync-tag {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  background: var(--primary-bg);
  color: var(--primary-dark);
  border-radius: 8px;
  font-size: 10px;
  font-weight: 500;
  margin-left: 6px;
}

.wechat-status {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-left: auto;
  font-size: 12px;
  color: var(--text-secondary);
  font-weight: normal;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--text-muted);
}

.status-dot.online {
  background: var(--success-color);
  box-shadow: 0 0 0 3px rgba(122, 148, 118, 0.2);
  animation: pulse 2s infinite;
}

.status-dot.offline {
  background: var(--text-muted);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

/* 阅读计时 */
.reading-timer {
  text-align: center;
  padding: 10px 0;
}

.timer-display {
  font-size: 40px;
  font-weight: 700;
  color: var(--primary-dark);
  font-variant-numeric: tabular-nums;
  letter-spacing: 3px;
  margin-bottom: 10px;
  font-family: var(--font-serif);
}

.timer-actions {
  display: flex;
  justify-content: center;
  gap: 10px;
}

/* 选择书目 */
.book-select-row .select {
  padding: 12px 14px;
  font-size: 15px;
}

/* 今日思考 */
.thought-book-row {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.thought-mini-list {
  margin-top: 10px;
}

.thought-mini-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 8px 10px;
  background: var(--bg-warm);
  border-radius: var(--radius-sm);
  margin-top: 6px;
  border-left: 3px solid var(--accent-yellow);
}

.thought-mini-time {
  font-size: 11px;
  color: var(--text-muted);
  white-space: nowrap;
  min-width: 40px;
  padding-top: 2px;
}

.thought-mini-text {
  flex: 1;
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.6;
}

/* 添加书目 */
.add-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.add-row:last-child {
  margin-bottom: 0;
}

/* 可展开书目分组 */
.book-section-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 16px 80px;
}

.book-section {
  padding: 0;
  overflow: hidden;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 16px;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
  user-select: none;
}

.section-header:active {
  background: var(--bg-warm);
}

.section-icon {
  font-size: 20px;
}

.section-title {
  flex: 1;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.section-count {
  font-size: 12px;
  color: var(--text-muted);
  background: var(--bg-warm);
  padding: 2px 10px;
  border-radius: 10px;
}

.section-arrow {
  font-size: 10px;
  color: var(--text-muted);
}

.section-body {
  padding: 0 16px 12px;
  border-top: 1px solid var(--border-soft);
  padding-top: 8px;
}

.section-empty {
  text-align: center;
  padding: 16px;
  color: var(--text-muted);
  font-size: 13px;
}

.section-book-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--border-soft);
}

.section-book-item:last-child {
  border-bottom: none;
}

.sb-info {
  flex: 1;
  min-width: 0;
}

.sb-title {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sb-author {
  display: block;
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 2px;
}

.sb-stats {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

.sb-minutes {
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
  font-size: 12px;
}

.btn-icon-small.danger {
  color: var(--danger-color);
}

@media (max-width: 480px) {
  .stat-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
