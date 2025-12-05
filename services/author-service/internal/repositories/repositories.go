package repositories

import "gorm.io/gorm"

// Repositories holds all repository instances
type Repositories struct {
	Role       RoleRepositoryInterface
	Permission PermissionRepositoryInterface
	UserBan    UserBanRepositoryInterface
}

// NewRepositories creates and returns all repository instances
func NewRepositories(db *gorm.DB) *Repositories {
	return &Repositories{
		Role:       NewRoleRepository(db),
		Permission: NewPermissionRepository(db),
		UserBan:    NewUserBanRepository(db),
	}
}