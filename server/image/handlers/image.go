package handlers

import (
	"fmt"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	"github.com/socialdev/image/config"
	"github.com/socialdev/image/models"
	"github.com/socialdev/image/services"
)

var allowedMime = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/webp": true,
}

func ownerID(c fiber.Ctx) string {
	if v := c.Locals("user_id"); v != nil {
		return fmt.Sprintf("%v", v)
	}
	return ""
}

func Upload(c fiber.Ctx) error {
	fh, err := c.FormFile("file")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "file is required")
	}
	if fh.Size > 30*1024*1024 {
		return fiber.NewError(fiber.StatusRequestEntityTooLarge, "max 30MB")
	}
	if !allowedMime[fh.Header.Get("Content-Type")] {
		return fiber.NewError(fiber.StatusUnsupportedMediaType, "jpeg/png/webp only")
	}

	folder := c.FormValue("folder", "uploads")
	res, err := services.Upload(c.Context(), fh, folder)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	img := models.Image{
		ID:        uuid.NewString(),
		OwnerID:   ownerID(c),
		Bucket:    config.Bucket,
		Key:       res.Key,
		URL:       res.URL,
		Folder:    folder,
		Mime:      res.Mime,
		Size:      res.Size,
		CreatedAt: time.Now(),
	}
	if err := config.DB.Create(&img).Error; err != nil {
		_ = services.Delete(c.Context(), res.Key)
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(img)
}

func List(c fiber.Ctx) error {
	var imgs []models.Image
	if err := config.DB.Where("owner_id = ?", ownerID(c)).Order("created_at desc").Find(&imgs).Error; err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(imgs)
}

func Get(c fiber.Ctx) error {
	img, err := findOwned(c)
	if err != nil {
		return err
	}
	return c.JSON(img)
}

func Presign(c fiber.Ctx) error {
	img, err := findOwned(c)
	if err != nil {
		return err
	}
	url, err := services.Presign(c.Context(), img.Key, 15*time.Minute)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(fiber.Map{"url": url})
}

func Delete(c fiber.Ctx) error {
	img, err := findOwned(c)
	if err != nil {
		return err
	}
	if err := services.Delete(c.Context(), img.Key); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	if err := config.DB.Delete(&img).Error; err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func findOwned(c fiber.Ctx) (*models.Image, error) {
	id := c.Params("id")
	var img models.Image
	if err := config.DB.Where("id = ? AND owner_id = ?", id, ownerID(c)).First(&img).Error; err != nil {
		return nil, fiber.NewError(fiber.StatusNotFound, "image not found")
	}
	return &img, nil
}
