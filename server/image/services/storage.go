package services

import (
	"context"
	"fmt"
	"mime/multipart"
	"net/url"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"

	"github.com/socialdev/image/config"
)

type UploadResult struct {
	Key  string `json:"key"`
	URL  string `json:"url"`
	Size int64  `json:"size"`
	Mime string `json:"mime"`
}

func Upload(ctx context.Context, fh *multipart.FileHeader, folder string) (*UploadResult, error) {
	f, err := fh.Open()
	if err != nil {
		return nil, err
	}
	defer f.Close()

	ext := filepath.Ext(fh.Filename)
	if folder == "" {
		folder = "uploads"
	}
	key := fmt.Sprintf("%s/%s%s", folder, uuid.NewString(), ext)
	mime := fh.Header.Get("Content-Type")

	_, err = config.Client.PutObject(ctx, config.Bucket, key, f, fh.Size, minio.PutObjectOptions{
		ContentType: mime,
	})
	if err != nil {
		return nil, err
	}

	return &UploadResult{
		Key:  key,
		URL:  publicURL(key),
		Size: fh.Size,
		Mime: mime,
	}, nil
}

func Download(ctx context.Context, key string) (*minio.Object, string, error) {
	obj, err := config.Client.GetObject(ctx, config.Bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, "", err
	}
	info, err := obj.Stat()
	if err != nil {
		obj.Close()
		return nil, "", err
	}
	return obj, info.ContentType, nil
}

func Delete(ctx context.Context, key string) error {
	return config.Client.RemoveObject(ctx, config.Bucket, key, minio.RemoveObjectOptions{})
}

func Presign(ctx context.Context, key string, ttl time.Duration) (string, error) {
	u, err := config.Client.PresignedGetObject(ctx, config.Bucket, key, ttl, url.Values{})
	if err != nil {
		return "", err
	}
	// MinIO signs with internal host — rewrite to public host keeping signature intact.
	// This works because MINIO_SERVER_URL tells MinIO to sign with the public host,
	// so the signature remains valid after the rewrite.
	publicBase := getEnv("MINIO_PUBLIC_URL", "")
	if publicBase != "" {
		pub, err := url.Parse(publicBase)
		if err == nil {
			u.Scheme = pub.Scheme
			u.Host = pub.Host
			// pub.Path is e.g. "/storage", key is "activity/file.jpg"
			// MinIO path is "/<bucket>/<key>", rewrite to "<pubPath>/<key>"
			u.Path = pub.Path + "/" + config.Bucket + "/" + key
		}
	}
	return u.String(), nil
}

func publicURL(key string) string {
	base := getEnv("MINIO_PUBLIC_URL", "")
	if base == "" {
		return key
	}
	return fmt.Sprintf("%s/%s/%s", base, config.Bucket, key)
}
