<template>
  <div class="app-container">
    <!-- 导航栏 -->
    <nav class="nav-bar">
      <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' }">
        <span class="nav-icon">📊</span>
        <span class="nav-label">首页</span>
      </router-link>
      <router-link to="/todo" class="nav-item" :class="{ active: $route.path.startsWith('/todo') }">
        <span class="nav-icon">✅</span>
        <span class="nav-label">待办</span>
      </router-link>
      <router-link to="/diary" class="nav-item" :class="{ active: $route.path.startsWith('/diary') }">
        <span class="nav-icon">📝</span>
        <span class="nav-label">日记</span>
      </router-link>
      <router-link to="/reading" class="nav-item" :class="{ active: $route.path.startsWith('/reading') }">
        <span class="nav-icon">📖</span>
        <span class="nav-label">阅读</span>
      </router-link>
      <router-link to="/sports" class="nav-item" :class="{ active: $route.path.startsWith('/sports') }">
        <span class="nav-icon">🏃</span>
        <span class="nav-label">运动</span>
      </router-link>
    </nav>

    <!-- 主内容 -->
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup>
// 页面切换时自动滚动到顶部
import { watch } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
watch(() => route.path, () => {
  window.scrollTo(0, 0)
})
</script>

<style scoped>
.app-container {
  display: flex;
  flex-direction: column;
  min-height: 100dvh;
  background: var(--bg-color);
}

.nav-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: space-around;
  align-items: center;
  height: 64px;
  background: var(--card-bg);
  border-top: 1px solid var(--border-color);
  padding-bottom: env(safe-area-inset-bottom, 0);
  z-index: 100;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 6px 12px;
  text-decoration: none;
  color: var(--text-secondary);
  transition: color 0.2s;
  -webkit-tap-highlight-color: transparent;
}

.nav-item.active {
  color: var(--primary-color);
}

.nav-icon {
  font-size: 22px;
  line-height: 1;
}

.nav-label {
  font-size: 11px;
  font-weight: 500;
}

.main-content {
  flex: 1;
  padding-bottom: 80px;
  overflow-y: auto;
}

/* 平板及以上设备显示侧边导航 */
@media (min-width: 768px) {
  .app-container {
    flex-direction: row;
  }

  .nav-bar {
    position: sticky;
    top: 0;
    flex-direction: column;
    width: 80px;
    height: 100vh;
    border-top: none;
    border-right: 1px solid var(--border-color);
    padding-top: 24px;
    padding-bottom: 24px;
  }

  .main-content {
    padding-bottom: 0;
  }
}
</style>
