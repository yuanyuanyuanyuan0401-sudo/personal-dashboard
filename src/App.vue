<template>
  <div class="app-container">
    <!-- 侧边栏导航（参考 Lumi 风格） -->
    <nav class="sidebar">
      <div class="sidebar-logo">
        <span class="logo-icon">🌱</span>
        <span class="logo-text">luna</span>
      </div>

      <div class="nav-list">
        <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' }">
          <span class="nav-icon">🏠</span>
          <span class="nav-label">首页</span>
        </router-link>
        <router-link to="/todo" class="nav-item" :class="{ active: $route.path.startsWith('/todo') }">
          <span class="nav-icon">✅</span>
          <span class="nav-label">待办</span>
        </router-link>
        <router-link to="/work" class="nav-item" :class="{ active: $route.path.startsWith('/work') }">
          <span class="nav-icon">📚</span>
          <span class="nav-label">工作</span>
        </router-link>
        <router-link to="/sports" class="nav-item" :class="{ active: $route.path.startsWith('/sports') }">
          <span class="nav-icon">💪</span>
          <span class="nav-label">运动</span>
        </router-link>
        <router-link to="/reading" class="nav-item" :class="{ active: $route.path.startsWith('/reading') }">
          <span class="nav-icon">📖</span>
          <span class="nav-label">阅读</span>
        </router-link>
        <router-link to="/snippets" class="nav-item" :class="{ active: $route.path.startsWith('/snippets') }">
          <span class="nav-icon">💭</span>
          <span class="nav-label">碎碎念</span>
        </router-link>
      </div>

      <div class="sidebar-footer">
        <router-link to="/settings" class="nav-item" :class="{ active: $route.path === '/settings' }">
          <span class="nav-icon">⚙️</span>
          <span class="nav-label">设置</span>
        </router-link>
      </div>
    </nav>

    <!-- 主内容 -->
    <main class="main-content">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup>
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
  min-height: 100dvh;
  background: var(--bg-color);
}

/* 侧边栏 - 桌面端 */
.sidebar {
  width: 88px;
  background: var(--card-bg);
  border-right: 1px solid var(--border-soft);
  display: flex;
  flex-direction: column;
  padding: 16px 0;
  flex-shrink: 0;
}

.sidebar-logo {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 0 24px;
  border-bottom: 1px solid var(--border-soft);
  margin-bottom: 12px;
}

.logo-icon {
  font-size: 32px;
  animation: gentle-fade-in 0.8s ease;
}

.logo-text {
  font-size: 14px;
  font-weight: 600;
  color: var(--primary-dark);
  letter-spacing: 2px;
  font-family: var(--font-serif);
}

.nav-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 0 8px;
}

.sidebar-footer {
  padding: 0 8px;
  border-top: 1px solid var(--border-soft);
  padding-top: 12px;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 10px 4px;
  border-radius: var(--radius-sm);
  text-decoration: none;
  color: var(--text-secondary);
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
}

.nav-item.active {
  background: var(--primary-bg);
  color: var(--primary-dark);
}

.nav-item:not(.active):hover {
  background: var(--bg-warm);
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
  overflow-y: auto;
  background: var(--bg-color);
}

/* 移动端：底部导航 */
@media (max-width: 767px) {
  .app-container {
    flex-direction: column;
  }

  .sidebar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    width: 100%;
    height: 64px;
    flex-direction: row;
    border-right: none;
    border-top: 1px solid var(--border-soft);
    padding: 0;
    z-index: 100;
  }

  .sidebar-logo,
  .sidebar-footer {
    display: none;
  }

  .nav-list {
    flex-direction: row;
    justify-content: space-around;
    padding: 0;
    align-items: center;
  }

  .nav-item {
    padding: 6px 8px;
    min-width: 56px;
  }

  .nav-icon {
    font-size: 22px;
  }

  .nav-label {
    font-size: 10px;
  }

  .main-content {
    padding-bottom: 76px;
  }
}
</style>
