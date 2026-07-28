<template>
  <div class="sports-page">
    <div class="page-header">
      <h1 class="page-title">运动</h1>
      <router-link to="/sports/videos" class="btn btn-secondary btn-sm">📺 视频</router-link>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">{{ touchMomentText }}</div>
    </div>

    <!-- 打卡 -->
    <div class="card">
      <div class="card-title">💪 运动打卡</div>
      <div class="card-subtitle">坚持打卡，遇见更好的自己</div>
      <button :class="['checkin-btn', { done: checkedInToday }]" @click="toggleCheckin">
        {{ checkedInToday ? '✓ 今日已打卡' : '标记完成' }}
      </button>
    </div>

    <!-- 数据统计 -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-value">{{ streakDays }}<span class="stat-unit">天</span></div>
        <div class="stat-label">连续打卡</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ weekCount }}</div>
        <div class="stat-label">本周次数</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ monthMinutes }}<span class="stat-unit">h</span></div>
        <div class="stat-label">本月时长</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ totalCalories }}</div>
        <div class="stat-label">消耗(千卡)</div>
      </div>
    </div>

    <!-- 今日跟练 -->
    <div class="card">
      <div class="card-title">🏃 今日跟练打卡</div>
      <div class="card-subtitle">选择跟练课程</div>
      <div class="course-tags">
        <button
          v-for="cat in courseCategories"
          :key="cat"
          :class="['course-tag', { active: selectedCategory === cat }]"
          @click="selectedCategory = cat"
        >
          {{ catEmoji(cat) }} {{ cat }}
        </button>
      </div>
      <div class="duration-row">
        <span class="duration-label">跟练时长：</span>
        <input type="number" v-model.number="duration" class="input" min="0" style="flex:1;padding:8px 10px;" />
        <span class="duration-unit">分钟</span>
      </div>
      <button class="btn btn-primary btn-block" @click="saveSport" :disabled="!duration || !selectedCategory">
        ✓ 立即打卡
      </button>
    </div>

    <!-- 看照片 -->
    <div class="card" v-if="sportsWithImages.length > 0">
      <div class="card-title">📸 运动照片</div>
      <div class="photo-grid">
        <div v-for="(img, idx) in sportsWithImages" :key="idx" class="photo-item" @click="previewImage = img.url">
          <img :src="img.url" />
          <span class="photo-date">{{ img.date }}</span>
        </div>
      </div>
    </div>

    <!-- 视频推荐 -->
    <div class="card">
      <div class="card-title">📺 跟练视频推荐</div>
      <div v-if="favoriteVideos.length === 0" class="empty-hint">
        还没有收藏视频，去
        <router-link to="/sports/videos" class="link">添加</router-link>
        吧
      </div>
      <div v-for="video in favoriteVideos" :key="video.id" class="video-item" @click="openVideo(video)">
        <div class="video-emoji">{{ videoEmoji(video.category) }}</div>
        <div class="video-info">
          <div class="video-title">{{ video.title }}</div>
          <div class="video-meta">
            <span v-if="video.duration" class="video-duration">{{ video.duration }}min</span>
            <span class="video-category">{{ video.category }}</span>
          </div>
        </div>
        <span class="video-play">▶</span>
      </div>
    </div>

    <!-- 历史记录 -->
    <div class="card" v-if="sports.length > 0">
      <div class="card-title">📊 历史记录</div>
      <div v-for="sport in sports" :key="sport.id" class="sport-item">
        <div class="sport-header">
          <span class="sport-type">{{ sport.type }}</span>
          <span class="sport-date">{{ sport.date }}</span>
          <button class="btn-icon-small danger" @click="deleteSport(sport)">✕</button>
        </div>
        <div class="sport-details">
          <span>⏱ {{ sport.duration }}分钟</span>
          <span v-if="sport.distance">📏 {{ sport.distance }}km</span>
          <span v-if="sport.calories">🔥 {{ sport.calories }}千卡</span>
        </div>
      </div>
    </div>

    <div v-if="previewImage" class="image-overlay" @click="previewImage = null">
      <img :src="previewImage" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const sports = ref([])
const videos = ref([])
const duration = ref(15)
const selectedCategory = ref('腹腹')
const previewImage = ref(null)

const courseCategories = ['腹腹', '瘦腿', '瘦背', '直角肩', '体态', '改善睡眠']

const touchMoments = [
  '欧阳春晓·锻炼，坚持打卡',
  '每一次挥汗，都是与更好的自己相遇。',
  '健康的身体，给生活更多可能。',
  '坚持运动，是最值得的投资。',
  '今天也要好好照顾自己。',
  '汗水是脂肪的眼泪。',
]
const touchMomentText = ref(touchMoments[0])

const checkedInToday = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return sports.value.some(s => s.date === today)
})

const streakDays = computed(() => {
  if (sports.value.length === 0) return 0
  const dates = [...new Set(sports.value.map(s => s.date))].sort().reverse()
  let streak = 0
  const today = new Date()
  for (let i = 0; i < dates.length; i++) {
    const expected = new Date(today)
    expected.setDate(today.getDate() - i)
    if (dates[i] === expected.toISOString().split('T')[0]) {
      streak++
    } else break
  }
  return streak
})

const weekCount = computed(() => {
  const weekStart = new Date()
  weekStart.setDate(weekStart.getDate() - 6)
  weekStart.setHours(0, 0, 0, 0)
  return sports.value.filter(s => new Date(s.date) >= weekStart).length
})

const monthMinutes = computed(() => {
  const monthStart = new Date()
  monthStart.setDate(1)
  monthStart.setHours(0, 0, 0, 0)
  const total = sports.value
    .filter(s => new Date(s.date) >= monthStart)
    .reduce((sum, s) => sum + (s.duration || 0), 0)
  return Math.round(total / 60)
})

const totalCalories = computed(() => {
  return sports.value.reduce((sum, s) => sum + (s.calories || 0), 0)
})

const sportsWithImages = computed(() => {
  const result = []
  sports.value.forEach(s => {
    if (s.images && Array.isArray(s.images)) {
      s.images.forEach(url => result.push({ url, date: s.date }))
    }
  })
  return result.slice(0, 9)
})

const favoriteVideos = computed(() => {
  return videos.value.filter(v => v.favorite).slice(0, 5)
})

function catEmoji(cat) {
  const map = { '腹腹': '🔥', '瘦腿': '🦵', '瘦背': '🧘', '直角肩': '👚', '体态': '🕴', '改善睡眠': '😴' }
  return map[cat] || '💪'
}

function videoEmoji(cat) {
  return catEmoji(cat)
}

async function toggleCheckin() {
  const today = new Date().toISOString().split('T')[0]
  if (checkedInToday.value) return
  try {
    await supabase.from(TABLES.SPORTS).insert({
      type: '运动打卡',
      date: today,
      duration: 0,
      notes: '每日打卡',
    })
    loadSports()
  } catch (e) { console.error(e) }
}

async function saveSport() {
  if (!selectedCategory.value || !duration.value) return
  try {
    const { data } = await supabase.from(TABLES.SPORTS).insert({
      type: selectedCategory.value,
      date: new Date().toISOString().split('T')[0],
      duration: duration.value,
      notes: `${selectedCategory.value}跟练 ${duration.value}分钟`,
    }).select()
    if (data) {
      sports.value.unshift(data[0])
    }
  } catch (e) { console.error('打卡失败', e) }
}

async function deleteSport(sport) {
  if (!confirm('删除这条记录？')) return
  try {
    await supabase.from(TABLES.SPORTS).delete().eq('id', sport.id)
    sports.value = sports.value.filter(s => s.id !== sport.id)
  } catch (e) { console.error(e) }
}

function openVideo(video) {
  window.open(video.url, '_blank')
}

async function loadSports() {
  try {
    const { data } = await supabase.from(TABLES.SPORTS).select('*').order('date', { ascending: false }).limit(100)
    sports.value = data || []
  } catch (e) { console.warn(e) }
}

async function loadVideos() {
  try {
    const { data } = await supabase.from(TABLES.SPORTS_VIDEOS).select('*').order('created_at', { ascending: false })
    videos.value = data || []
  } catch (e) { console.warn(e) }
}

onMounted(() => {
  touchMomentText.value = touchMoments[Math.floor(Math.random() * touchMoments.length)]
  loadSports()
  loadVideos()
})
</script>

<style scoped>
.card-subtitle {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 12px;
  margin-top: -8px;
}

.checkin-btn {
  width: 100%;
  padding: 14px;
  border-radius: var(--radius-md);
  border: 1.5px solid var(--primary-light);
  background: var(--primary-bg);
  color: var(--primary-dark);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.checkin-btn.done {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.course-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.course-tag {
  padding: 6px 12px;
  border-radius: 16px;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
}

.course-tag.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  color: var(--primary-dark);
  font-weight: 500;
}

.duration-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.duration-label, .duration-unit {
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
}

/* 照片 */
.photo-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
}

.photo-item {
  position: relative;
  aspect-ratio: 1;
  border-radius: var(--radius-sm);
  overflow: hidden;
  cursor: pointer;
}

.photo-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.photo-date {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 3px 6px;
  background: linear-gradient(transparent, rgba(0,0,0,0.6));
  color: white;
  font-size: 10px;
  text-align: center;
}

/* 视频项 */
.video-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--border-soft);
  cursor: pointer;
  transition: background 0.15s;
}

.video-item:last-child {
  border-bottom: none;
}

.video-item:active {
  background: var(--bg-warm);
}

.video-emoji {
  font-size: 30px;
  flex-shrink: 0;
}

.video-info {
  flex: 1;
  min-width: 0;
}

.video-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.video-meta {
  display: flex;
  gap: 8px;
  margin-top: 4px;
  font-size: 11px;
  color: var(--text-muted);
}

.video-duration {
  padding: 1px 8px;
  background: var(--primary-bg);
  color: var(--primary-dark);
  border-radius: 8px;
}

.video-play {
  font-size: 16px;
  color: var(--primary-color);
}

.empty-hint {
  text-align: center;
  padding: 20px;
  color: var(--text-muted);
  font-size: 13px;
}

.link {
  color: var(--primary-dark);
  text-decoration: underline;
}

/* 历史 */
.sport-item {
  padding: 12px 0;
  border-bottom: 1px solid var(--border-soft);
}

.sport-item:last-child {
  border-bottom: none;
}

.sport-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.sport-type {
  font-size: 14px;
  font-weight: 600;
  color: var(--primary-dark);
}

.sport-date {
  font-size: 12px;
  color: var(--text-muted);
  flex: 1;
}

.sport-details {
  display: flex;
  gap: 12px;
  margin-top: 6px;
  font-size: 13px;
  color: var(--text-secondary);
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
