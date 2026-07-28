<template>
  <div class="videos-page">
    <div class="sub-header">
      <router-link to="/sports" class="back-btn">←</router-link>
      <span class="sub-title">📺 跟练视频</span>
    </div>

    <!-- 触动瞬间 -->
    <div class="touch-moment">
      <div class="touch-moment-title">✨ 触动瞬间</div>
      <div class="touch-moment-text">收藏喜欢的视频，随时开始跟练。</div>
    </div>

    <!-- 添加视频 -->
    <div class="card">
      <div class="card-title">➕ 收藏视频</div>
      <input v-model="form.title" class="input" placeholder="视频标题" style="margin-bottom:8px;" />
      <select v-model="form.category" class="select" style="margin-bottom:8px;">
        <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
      </select>
      <input v-model="form.url" class="input" placeholder="B站视频链接（如 https://www.bilibili.com/video/BVxxx）" style="margin-bottom:8px;" />
      <input type="number" v-model.number="form.duration" class="input" placeholder="时长（分钟，可选）" style="margin-bottom:8px;" />
      <textarea v-model="form.description" class="textarea" placeholder="简介（可选）" rows="2" style="margin-bottom:8px;"></textarea>
      <button class="btn btn-primary btn-block" @click="saveVideo" :disabled="!form.title || !form.url">收藏</button>
    </div>

    <!-- 筛选 -->
    <div class="card">
      <div class="filter-row">
        <button :class="['filter-btn', { active: filterCat === 'all' }]" @click="filterCat = 'all'">全部</button>
        <button v-for="c in categories" :key="c" :class="['filter-btn', { active: filterCat === c }]" @click="filterCat = c">{{ c }}</button>
      </div>

      <div v-if="filteredVideos.length === 0" class="empty-state">
        <div class="icon">📺</div>
        <div class="text">还没有收藏视频</div>
      </div>

      <div v-for="video in filteredVideos" :key="video.id" class="video-card">
        <div class="video-icon">{{ catEmoji(video.category) }}</div>
        <div class="video-body">
          <div class="video-title">{{ video.title }}</div>
          <div class="video-meta">
            <span class="tag tag-yellow">{{ video.category }}</span>
            <span v-if="video.duration" class="video-duration">{{ video.duration }}min</span>
          </div>
          <div v-if="video.description" class="video-desc">{{ video.description }}</div>
        </div>
        <div class="video-actions">
          <button :class="['fav-btn', { active: video.favorite }]" @click="toggleFav(video)" title="收藏">
            {{ video.favorite ? '★' : '☆' }}
          </button>
          <button class="btn-icon-small danger" @click="deleteVideo(video)">✕</button>
        </div>
        <button class="play-btn" @click="openVideo(video)">▶ 打开视频</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const videos = ref([])
const filterCat = ref('all')

const categories = ['腹腹', '瘦腿', '瘦背', '直角肩', '体态', '改善睡眠']

const form = ref({
  title: '',
  category: '腹腹',
  url: '',
  duration: null,
  description: '',
})

const filteredVideos = computed(() => {
  if (filterCat.value === 'all') return videos.value
  return videos.value.filter(v => v.category === filterCat.value)
})

function catEmoji(cat) {
  const map = { '腹腹': '🔥', '瘦腿': '🦵', '瘦背': '🧘', '直角肩': '👚', '体态': '🕴', '改善睡眠': '😴' }
  return map[cat] || '💪'
}

async function loadVideos() {
  try {
    const { data } = await supabase.from(TABLES.SPORTS_VIDEOS).select('*').order('created_at', { ascending: false })
    videos.value = data || []
  } catch (e) { console.warn(e) }
}

async function saveVideo() {
  if (!form.value.title || !form.value.url) return
  try {
    const { data } = await supabase.from(TABLES.SPORTS_VIDEOS).insert({
      title: form.value.title,
      category: form.value.category,
      url: form.value.url,
      duration: form.value.duration,
      description: form.value.description,
    }).select()
    if (data) {
      videos.value.unshift(data[0])
      form.value = { title: '', category: '腹腹', url: '', duration: null, description: '' }
    }
  } catch (e) { console.error('保存失败', e) }
}

async function toggleFav(video) {
  try {
    await supabase.from(TABLES.SPORTS_VIDEOS).update({ favorite: !video.favorite }).eq('id', video.id)
    video.favorite = !video.favorite
  } catch (e) { console.error(e) }
}

async function deleteVideo(video) {
  if (!confirm(`删除"${video.title}"？`)) return
  try {
    await supabase.from(TABLES.SPORTS_VIDEOS).delete().eq('id', video.id)
    videos.value = videos.value.filter(v => v.id !== video.id)
  } catch (e) { console.error(e) }
}

function openVideo(video) {
  window.open(video.url, '_blank')
}

onMounted(loadVideos)
</script>

<style scoped>
.filter-row {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 4px 12px;
  border-radius: 14px;
  border: 1px solid var(--border-color);
  background: transparent;
  font-size: 12px;
  color: var(--text-secondary);
  cursor: pointer;
}

.filter-btn.active {
  background: var(--primary-bg);
  border-color: var(--primary-light);
  color: var(--primary-dark);
}

.video-card {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  padding: 14px 0;
  border-bottom: 1px solid var(--border-soft);
}

.video-card:last-child {
  border-bottom: none;
}

.video-icon {
  font-size: 36px;
  flex-shrink: 0;
}

.video-body {
  flex: 1;
  min-width: 0;
  min-width: 200px;
}

.video-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 6px;
}

.video-meta {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 6px;
}

.video-duration {
  font-size: 11px;
  color: var(--text-muted);
}

.video-desc {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.video-actions {
  display: flex;
  gap: 4px;
  align-items: flex-start;
}

.fav-btn {
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 50%;
  background: transparent;
  font-size: 18px;
  color: var(--text-muted);
  cursor: pointer;
}

.fav-btn.active {
  color: var(--accent-yellow);
  background: rgba(212, 165, 116, 0.1);
}

.play-btn {
  width: 100%;
  padding: 8px;
  background: var(--primary-bg);
  color: var(--primary-dark);
  border: none;
  border-radius: var(--radius-sm);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 8px;
}

.play-btn:active {
  background: var(--primary-light);
  color: white;
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
