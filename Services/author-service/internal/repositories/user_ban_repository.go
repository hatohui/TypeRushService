package repositories

import (
	"gin/internal/models"
	"time"

	"gorm.io/gorm"
)

// UserBanRepositoryInterface defines the contract for user ban operations
type UserBanRepositoryInterface interface {
	Create(userBan *models.UserBan) error
	GetByID(id uint) (*models.UserBan, error)
	GetByUserID(userID string) ([]models.UserBan, error)
	GetByUserIDAndPermission(userID string, permID int) (*models.UserBan, error)
	GetAll() ([]models.UserBan, error)
	Update(userBan *models.UserBan) error
	Delete(id uint) error
	GetWithPermission(id uint) (*models.UserBan, error)
	GetActiveUserBans(userID string) ([]models.UserBan, error)
	IsUserBanned(userID string, permID int) (bool, error)
}

// UserBanRepository implements UserBanRepositoryInterface
type UserBanRepository struct {
	db *gorm.DB
}

// NewUserBanRepository creates a new user ban repository
func NewUserBanRepository(db *gorm.DB) UserBanRepositoryInterface {
	return &UserBanRepository{db: db}
}

// Create creates a new user ban
func (u *UserBanRepository) Create(userBan *models.UserBan) error {
	return u.db.Create(userBan).Error
}

// GetByID retrieves a user ban by ID
func (u *UserBanRepository) GetByID(id uint) (*models.UserBan, error) {
	var userBan models.UserBan
	err := u.db.First(&userBan, id).Error
	if err != nil {
		return nil, err
	}
	return &userBan, nil
}

// GetByUserID retrieves all bans for a specific user
func (u *UserBanRepository) GetByUserID(userID string) ([]models.UserBan, error) {
	var userBans []models.UserBan
	err := u.db.Where("user_id = ?", userID).Find(&userBans).Error
	return userBans, err
}

// GetByUserIDAndPermission retrieves a specific ban for a user and permission
func (u *UserBanRepository) GetByUserIDAndPermission(userID string, permID int) (*models.UserBan, error) {
	var userBan models.UserBan
	err := u.db.Where("user_id = ? AND perm_id = ?", userID, permID).First(&userBan).Error
	if err != nil {
		return nil, err
	}
	return &userBan, nil
}

// GetAll retrieves all user bans
func (u *UserBanRepository) GetAll() ([]models.UserBan, error) {
	var userBans []models.UserBan
	err := u.db.Find(&userBans).Error
	return userBans, err
}

// Update updates a user ban
func (u *UserBanRepository) Update(userBan *models.UserBan) error {
	return u.db.Save(userBan).Error
}

// Delete deletes a user ban by ID
func (u *UserBanRepository) Delete(id uint) error {
	return u.db.Delete(&models.UserBan{}, id).Error
}

// GetWithPermission retrieves a user ban with its permission details
func (u *UserBanRepository) GetWithPermission(id uint) (*models.UserBan, error) {
	var userBan models.UserBan
	err := u.db.Preload("Permission").First(&userBan, id).Error
	if err != nil {
		return nil, err
	}
	return &userBan, nil
}

// GetActiveUserBans retrieves all active bans for a user (you might add expiration logic later)
func (u *UserBanRepository) GetActiveUserBans(userID string) ([]models.UserBan, error) {
	var userBans []models.UserBan
	// For now, just get all bans. You can add expiration logic here later
	err := u.db.Where("user_id = ?", userID).Preload("Permission").Find(&userBans).Error
	return userBans, err
}

// IsUserBanned checks if a user is banned for a specific permission
func (u *UserBanRepository) IsUserBanned(userID string, permID int) (bool, error) {
	var count int64
	err := u.db.Model(&models.UserBan{}).Where("user_id = ? AND perm_id = ?", userID, permID).Count(&count).Error
	return count > 0, err
}

// Additional helper methods

// BanUser creates a new ban for a user
func (u *UserBanRepository) BanUser(userID string, permID int, reason string) error {
	userBan := &models.UserBan{
		UserID:    userID,
		PermID:    permID,
		Reason:    reason,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	return u.Create(userBan)
}

// UnbanUser removes a ban for a user and permission
func (u *UserBanRepository) UnbanUser(userID string, permID int) error {
	return u.db.Where("user_id = ? AND perm_id = ?", userID, permID).Delete(&models.UserBan{}).Error
}

// GetRecentBans retrieves recent bans (last 30 days)
func (u *UserBanRepository) GetRecentBans(limit int) ([]models.UserBan, error) {
	var userBans []models.UserBan
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	
	query := u.db.Where("created_at > ?", thirtyDaysAgo).
		Preload("Permission").
		Order("created_at DESC")
	
	if limit > 0 {
		query = query.Limit(limit)
	}
	
	err := query.Find(&userBans).Error
	return userBans, err
}