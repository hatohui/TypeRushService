package services

import (
	"fmt"
	"gin/internal/models"
	"gin/internal/repositories"
)

type PermissionServiceInterface interface {
	CreatePermission(name string) (*models.Permission, error)
	GetPermissionByID(id uint) (*models.Permission, error)
	GetPermissionByName(name string) (*models.Permission, error)
	GetAllPermissions() ([]models.Permission, error)
	UpdatePermission(permission *models.Permission) error
	DeletePermission(id uint) error
	GetPermissionWithRoles(id uint) (*models.Permission, error)
}

type PermissionService struct {
	permissionRepo repositories.PermissionRepositoryInterface
}

func NewPermissionService(permissionRepo repositories.PermissionRepositoryInterface) PermissionServiceInterface {
	return &PermissionService{
		permissionRepo: permissionRepo,
	}
}

func (s *PermissionService) CreatePermission(name string) (*models.Permission, error) {
	if name == "" {
		return nil, fmt.Errorf("permission name cannot be empty")
	}

	// Check if permission already exists
	existingPermission, err := s.permissionRepo.GetByName(name)
	if err == nil && existingPermission != nil {
		return nil, fmt.Errorf("permission with name '%s' already exists", name)
	}

	permission := &models.Permission{
		Name: name,
	}

	if err := s.permissionRepo.Create(permission); err != nil {
		return nil, fmt.Errorf("failed to create permission: %w", err)
	}

	return permission, nil
}

// GetPermissionByID retrieves a permission by ID
func (s *PermissionService) GetPermissionByID(id uint) (*models.Permission, error) {
	if id == 0 {
		return nil, fmt.Errorf("invalid permission ID")
	}

	permission, err := s.permissionRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("permission not found: %w", err)
	}

	return permission, nil
}

// GetPermissionByName retrieves a permission by name
func (s *PermissionService) GetPermissionByName(name string) (*models.Permission, error) {
	if name == "" {
		return nil, fmt.Errorf("permission name cannot be empty")
	}

	permission, err := s.permissionRepo.GetByName(name)
	if err != nil {
		return nil, fmt.Errorf("permission not found: %w", err)
	}

	return permission, nil
}

// GetAllPermissions retrieves all permissions
func (s *PermissionService) GetAllPermissions() ([]models.Permission, error) {
	return s.permissionRepo.GetAll()
}

// UpdatePermission updates an existing permission
func (s *PermissionService) UpdatePermission(permission *models.Permission) error {
	if permission == nil {
		return fmt.Errorf("permission cannot be nil")
	}

	if permission.Name == "" {
		return fmt.Errorf("permission name cannot be empty")
	}

	// Check if permission exists
	existingPermission, err := s.permissionRepo.GetByID(permission.PermID)
	if err != nil {
		return fmt.Errorf("permission not found: %w", err)
	}

	// Check if another permission with the same name exists (excluding current permission)
	if permissionWithSameName, err := s.permissionRepo.GetByName(permission.Name); err == nil && permissionWithSameName.PermID != permission.PermID {
		return fmt.Errorf("permission with name '%s' already exists", permission.Name)
	}

	existingPermission.Name = permission.Name
	return s.permissionRepo.Update(existingPermission)
}

// DeletePermission deletes a permission
func (s *PermissionService) DeletePermission(id uint) error {
	if id == 0 {
		return fmt.Errorf("invalid permission ID")
	}

	// Check if permission exists
	_, err := s.permissionRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("permission not found: %w", err)
	}

	return s.permissionRepo.Delete(id)
}

// GetPermissionWithRoles retrieves a permission with its associated roles
func (s *PermissionService) GetPermissionWithRoles(id uint) (*models.Permission, error) {
	if id == 0 {
		return nil, fmt.Errorf("invalid permission ID")
	}

	permission, err := s.permissionRepo.GetWithRoles(id)
	if err != nil {
		return nil, fmt.Errorf("permission not found: %w", err)
	}

	return permission, nil
}