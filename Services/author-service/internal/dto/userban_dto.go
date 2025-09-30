package dto

// User Ban DTOs
type BanUserRequest struct {
	PermissionID int    `json:"permission_id" binding:"required"`
	Reason       string `json:"reason" binding:"required" validate:"min=1,max=500"`
}

type UpdateBanReasonRequest struct {
	Reason string `json:"reason" binding:"required" validate:"min=1,max=500"`
}

type UserBanResponse struct {
	ID         uint                `json:"id"`
	UserID     string              `json:"user_id"`
	PermID     int                 `json:"perm_id"`
	Reason     string              `json:"reason"`
	Permission *PermissionResponse `json:"permission,omitempty"`
	CreatedAt  string              `json:"created_at"`
	UpdatedAt  string              `json:"updated_at"`
}

type CheckUserBanResponse struct {
	UserID       string `json:"user_id"`
	PermissionID int    `json:"permission_id"`
	IsBanned     bool   `json:"is_banned"`
}