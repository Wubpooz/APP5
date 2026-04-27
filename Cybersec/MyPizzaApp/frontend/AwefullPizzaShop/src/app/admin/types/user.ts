export type UserRole = 'Admin' | 'User';

export const UserRole = {
  Admin: 'Admin' as UserRole,
  User: 'User' as UserRole
};

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
}
