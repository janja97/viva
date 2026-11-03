import { ADMIN_AUTH_PATHS } from '~/config/navigation'

// Globalno, kako nova admin stranica ne bi mogla ostati nezaštićena.
export default defineNuxtRouteMiddleware(async (to) => {
  if (import.meta.server) return

  const path = to.path.replace(/\/$/, '') || '/'
  if (path !== '/admin' && !path.startsWith('/admin/')) return

  const { init, user, role } = useAuth()
  await init()

  const hasAccess = Boolean(user.value && role.value)

  if (!hasAccess && !ADMIN_AUTH_PATHS.includes(path)) {
    return navigateTo({ path: '/admin/prijava', query: { redirect: to.fullPath } })
  }
  if (hasAccess && path === '/admin/prijava') {
    return navigateTo('/admin')
  }
})
