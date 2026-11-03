import { ROLE_PERMISSIONS, type Permission } from '~/config/roles'

export function usePermissions() {
  const { role } = useAuth()

  const can = (permission: Permission) =>
    role.value ? ROLE_PERMISSIONS[role.value].includes(permission) : false

  return { can }
}
