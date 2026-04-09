# Generic builder for any Go service in server/<SERVICE>.
# Build context MUST be the server/ directory so the local `replace ../shared` works.
#
# Example:
#   docker build --build-arg SERVICE=problem -t socialdev/problem -f server/Dockerfile server/

FROM golang:1.25-alpine AS build
ARG SERVICE
RUN apk add --no-cache git
WORKDIR /src
COPY . .
WORKDIR /src/${SERVICE}
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o /out/app .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
COPY --from=build /out/app /app
ENTRYPOINT ["/app"]
