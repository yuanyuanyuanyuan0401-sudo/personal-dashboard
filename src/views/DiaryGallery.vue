<template>
  <div class="gallery-page">
    <div class="sub-header">
      <router-link to="/diary" class="back-btn">← 返回日记</router-link>
      <span class="sub-title">图片</span>
    </div>

    <div v-if="allImages.length === 0" class="empty-state">
      <div class="icon">🖼️</div>
      <div class="text">还没有带图片的日记</div>
    </div>

    <div v-else class="gallery-grid">
      <div v-for="(item, idx) in allImages" :key="idx" class="gallery-item" @click="previewImage = item.url">
        <img :src="item.url" loading="lazy" />
        <div class="gallery-date">{{ item.date }}</div>
      </div>
    </div>

    <!-- 查看大图 -->
    <div v-if="previewImage" class="image-overlay" @click="previewImage = null">
      <img :src="previewImage" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, TABLES } from '../supabase.js'

const allImages = ref([])
const previewImage = ref(null)

async function loadImages() {
  try {
    const { data } = await supabase
      .from(TABLES.DIARY)
      .select('date, images')
      .not('images', 'eq', '[]')
      .order('date', { ascending: false })

    if (data) {
      const images = []
      data.forEach(entry => {
        if (entry.images && Array.isArray(entry.images)) {
          entry.images.forEach(url => {
            images.push({ url, date: entry.date })
          })
        }
      })
      allImages.value = images
    }
  } catch (e) {
    console.warn('加载图片失败', e)
  }
}

onMounted(loadImages)
</script>

<style scoped>
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  padding: 0 4px;
}
.gallery-item {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
  border-radius: 4px;
  cursor: pointer;
}
.gallery-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.2s;
}
.gallery-item:active img {
  transform: scale(1.05);
}
.gallery-date {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 4px 6px;
  background: linear-gradient(transparent, rgba(0,0,0,0.6));
  color: white;
  font-size: 11px;
}
</style>
