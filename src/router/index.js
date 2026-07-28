import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'dashboard', component: () => import('../views/Dashboard.vue') },
  // 待办
  { path: '/todo', name: 'todo', component: () => import('../views/Todo.vue') },
  { path: '/todo/summary', name: 'todo-summary', component: () => import('../views/TodoSummary.vue') },
  // 工作
  { path: '/work', name: 'work', component: () => import('../views/Work.vue') },
  { path: '/work/files', name: 'work-files', component: () => import('../views/WorkFiles.vue') },
  { path: '/work/reflect', name: 'work-reflect', component: () => import('../views/WorkReflect.vue') },
  { path: '/work/communicate', name: 'work-communicate', component: () => import('../views/WorkCommunicate.vue') },
  // 运动
  { path: '/sports', name: 'sports', component: () => import('../views/Sports.vue') },
  { path: '/sports/videos', name: 'sports-videos', component: () => import('../views/SportsVideos.vue') },
  // 阅读
  { path: '/reading', name: 'reading', component: () => import('../views/Reading.vue') },
  { path: '/reading/reflections', name: 'reading-reflections', component: () => import('../views/ReadingReflections.vue') },
  { path: '/reading/stats', name: 'reading-stats', component: () => import('../views/ReadingStats.vue') },
  // 碎碎念
  { path: '/snippets', name: 'snippets', component: () => import('../views/Snippets.vue') },
  { path: '/snippets/calendar', name: 'snippets-calendar', component: () => import('../views/SnippetsCalendar.vue') },
  { path: '/snippets/gallery', name: 'snippets-gallery', component: () => import('../views/SnippetsGallery.vue') },
  // 设置
  { path: '/settings', name: 'settings', component: () => import('../views/Settings.vue') },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
