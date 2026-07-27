import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'Dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '首页' } },
  { path: '/todo', name: 'Todo', component: () => import('../views/Todo.vue'), meta: { title: '待办' } },
  { path: '/diary', name: 'Diary', component: () => import('../views/Diary.vue'), meta: { title: '日记' } },
  { path: '/diary/calendar', name: 'DiaryCalendar', component: () => import('../views/DiaryCalendar.vue'), meta: { title: '日历' } },
  { path: '/diary/gallery', name: 'DiaryGallery', component: () => import('../views/DiaryGallery.vue'), meta: { title: '图片' } },
  { path: '/reading', name: 'Reading', component: () => import('../views/Reading.vue'), meta: { title: '阅读' } },
  { path: '/sports', name: 'Sports', component: () => import('../views/Sports.vue'), meta: { title: '运动' } },
  { path: '/settings', name: 'Settings', component: () => import('../views/Settings.vue'), meta: { title: '设置' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
