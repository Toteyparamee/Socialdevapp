package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"login-service/config"
	"login-service/models"

	"socialdev/shared/events"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

// ── Request / Response structs ──

type RegisterRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type GoogleLoginRequest struct {
	AccessToken string `json:"access_token"`
	Role        string `json:"role"`
}

type AuthResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

// ── Handlers ──

// Register - สมัครสมาชิกแบบธรรมดา
func Register(c fiber.Ctx) error {
	var req RegisterRequest
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.Username == "" || req.Email == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "username, email, password are required"})
	}

	// Check existing user
	var existing models.User
	if result := config.DB.Where("username = ? OR email = ?", req.Username, req.Email).First(&existing); result.Error == nil {
		return c.Status(409).JSON(fiber.Map{"error": "Username or email already exists"})
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to hash password"})
	}

	role := req.Role
	if role == "" {
		role = "นักเรียน"
	}

	user := models.User{
		Username: req.Username,
		Email:    req.Email,
		Password: string(hash),
		Role:     role,
		Provider: "local",
	}

	if result := config.DB.Create(&user); result.Error != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
	}

	token, err := generateJWT(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	events.Publish(events.TopicUserRegistered, map[string]interface{}{
		"user_id":  user.ID,
		"email":    user.Email,
		"username": user.Username,
		"role":     user.Role,
		"provider": "local",
	})

	return c.Status(201).JSON(AuthResponse{Token: token, User: user})
}

// Login - เข้าสู่ระบบแบบธรรมดา (username + password)
func Login(c fiber.Ctx) error {
	var req LoginRequest
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.Email == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "email and password are required"})
	}

	log.Printf("[Login] email=%q password_len=%d", req.Email, len(req.Password))

	var user models.User
	if result := config.DB.Where("email = ? AND provider::text = ?", req.Email, "local").First(&user); result.Error != nil {
		return c.Status(401).JSON(fiber.Map{"error": "ไม่พบบัญชีนี้ กรุณาสมัครสมาชิก"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "รหัสผ่านไม่ถูกต้อง"})
	}

	token, err := generateJWT(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	return c.JSON(AuthResponse{Token: token, User: user})
}

// GoogleLogin - เข้าสู่ระบบด้วย Google (ผ่าน Auth0)
func GoogleLogin(c fiber.Ctx) error {
	var req GoogleLoginRequest
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.AccessToken == "" {
		return c.Status(400).JSON(fiber.Map{"error": "access_token is required"})
	}

	// Verify token with Auth0 userinfo endpoint
	auth0Cfg := config.LoadAuth0Config()
	userInfo, err := getAuth0UserInfo(auth0Cfg.Domain, req.AccessToken)
	if err != nil {
		log.Printf("[GoogleLogin] Auth0 userinfo error: %v", err)
		return c.Status(401).JSON(fiber.Map{"error": "Invalid Google token", "detail": err.Error()})
	}

	// Find or create user
	var user models.User
	result := config.DB.Where("email = ?", userInfo.Email).First(&user)

	if result.Error != nil {
		// สร้าง user ใหม่
		role := req.Role
		if role == "" {
			role = "นักเรียน"
		}

		user = models.User{
			Username:  userInfo.Name,
			Email:     userInfo.Email,
			Provider:  "google",
			GoogleID:  userInfo.Sub,
			AvatarURL: userInfo.Picture,
			Role:      role,
		}
		if err := config.DB.Create(&user).Error; err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
		}
		events.Publish(events.TopicUserRegistered, map[string]interface{}{
			"user_id":  user.ID,
			"email":    user.Email,
			"username": user.Username,
			"role":     user.Role,
			"provider": "google",
		})
	} else {
		// อัพเดทข้อมูลจาก Google
		config.DB.Model(&user).Updates(models.User{
			AvatarURL: userInfo.Picture,
			GoogleID:  userInfo.Sub,
		})
	}

	token, err := generateJWT(user)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate token"})
	}

	return c.JSON(AuthResponse{Token: token, User: user})
}

// ── Helper functions ──

func generateJWT(user models.User) (string, error) {
	claims := jwt.MapClaims{
		"user_id":  user.ID,
		"username": user.Username,
		"email":    user.Email,
		"role":     user.Role,
		"exp":      time.Now().Add(72 * time.Hour).Unix(),
		"iat":      time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(config.GetJWTSecret()))
}

// Auth0 userinfo response
type auth0UserInfo struct {
	Sub     string `json:"sub"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	Picture string `json:"picture"`
}

func getAuth0UserInfo(domain, accessToken string) (*auth0UserInfo, error) {
	url := fmt.Sprintf("https://%s/userinfo", domain)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("auth0 userinfo failed: %s", string(body))
	}

	var info auth0UserInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, err
	}

	return &info, nil
}
