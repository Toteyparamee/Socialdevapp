package config

import (
	"context"
	"fmt"
	"os"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

var (
	Client *minio.Client
	Bucket string
)

func InitMinio() error {
	endpoint := os.Getenv("MINIO_ENDPOINT")
	accessKey := os.Getenv("MINIO_ACCESS_KEY")
	secretKey := os.Getenv("MINIO_SECRET_KEY")
	useSSL := os.Getenv("MINIO_USE_SSL") == "true"
	Bucket = os.Getenv("MINIO_BUCKET")

	if endpoint == "" || accessKey == "" || secretKey == "" || Bucket == "" {
		return fmt.Errorf("missing MINIO_* env vars")
	}

	c, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		return err
	}
	Client = c

	ctx := context.Background()
	exists, err := c.BucketExists(ctx, Bucket)
	if err != nil {
		return err
	}
	if !exists {
		if err := c.MakeBucket(ctx, Bucket, minio.MakeBucketOptions{}); err != nil {
			return err
		}
	}
	return nil
}
