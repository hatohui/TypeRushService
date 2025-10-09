package services

import (
	"gin/internal/repositories"
)

// Services holds all service instances
type Services struct {
	Role       RoleServiceInterface
	Permission PermissionServiceInterface
	UserBan    UserBanServiceInterface
}

// NewServices creates and returns all service instances
func NewServices(repos *repositories.Repositories) *Services {
	return &Services{
		Role:       NewRoleService(repos.Role, repos.Permission),
		Permission: NewPermissionService(repos.Permission),
		UserBan:    NewUserBanService(repos.UserBan, repos.Permission),
	}
}