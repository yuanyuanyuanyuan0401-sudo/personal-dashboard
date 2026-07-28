<template>
  <div class="gallery-page">
    <div class="sub-header">
      <router-link to="/snippets" class="back-btn">←</router-link>
      <span class="sub-title">🖼️ 朋友圈</span>
    </div>

    <div v-if="snippets.length === 0" class="empty-state">
      <div class="icon">🖼️</div>
      <div class="text">还没有图片<br/>写日记时上传图片吧</div>
    </div>

    <div v-else class="moments-grid">
      <div v-for="s in snippets" :key="s.id" class="moment-card">
        <div class="moment-header">
          <div class="moment-avatar">🌱</div>
          <div class="moment-meta">
            <div class="moment-author">luna</div>
            <div class="moment-date">{{ formatDate(s.created_at) }}</div>
          </div>
        </div>
        <div v-if="s.content" class="moment-content">{{ s.content }}</div>
        <div v-if="s.images && s.images.length" class="moment-images">
          <img v-for="(img, i) in s.images" :key="i" :src="img" class="moment-img" @click="previewImage = img" />
        </div>
        <div v-if="s.location" class="moment-location">📍 {{ s.location }}</div>
        <div v-if="s.weather" class="moment-weather">{{ s.weather }}</div>
      </div>
    </div>

    <div v-if="previewImage" class="image-overlay" @click="previewImage = null">
      <img :src="previewImage" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const snippets = ref([])
const previewImage = ref(null)

async function loadData() {
  try {
    const { data } = await supabase
      .from(TABLES.SNIPPETS)
      .select('*')
      .not('images', 'eq', '[]')
      .order('created_at', { ascending: false })
    snippets.value = (data || []).filter(s => s.images && s.images.length > 0)
  } catch (e) { console.warn(e) }
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  const months = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月']
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  return `${months[d.getMonth()]}${d.getDate()}日 ${hours}:${minutes}`
}

onMounted(loadData)
</script>

<style scoped>
.moments-grid {
  padding: 0 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.moment-card {
  background: var(--card-bg);
  border-radius: var(--radius-md);
  padding: 16px;
  border: 1px solid var(--border-soft);
  box-shadow: var(--shadow-sm);
}

.moment-header {
  display: flex;
  gap: 10px;
  margin-bottom: 8px;
}

.moment-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--primary-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.moment-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.moment-author {
  font-size: 14px;
  font-weight: 600;
  color: var(--primary-dark);
}

.moment-date {
  font-size: 11px;
  color: var(--text-muted);
}

.moment-content {
  font-size: 14px;
  line-height: 1.7;
  color: var(--text-primary);
  text-indent: 2em;
  margin-bottom: 10px;
  white-space: pre-wrap;
}

.moment-images {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  margin-bottom: 8px;
}

.moment-img {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: 6px;
  cursor: pointer;
}

.moment-location, .moment-weather {
  font-size: 12px;
  color: var(--text-muted);
}
</style>
