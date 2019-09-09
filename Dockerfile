FROM golang:1.12 AS cache
WORKDIR /src/Naglfar
COPY go.mod .
COPY go.sum .
RUN go mod download
RUN go mod verify

FROM golang:1.12-alpine as builder
RUN apk update && apk add --no-cache git ca-certificates tzdata && update-ca-certificates
COPY --from=cache $GOCACHE $GOCACHE
COPY --from=cache $GOPATH/pkg/mod $GOPATH/pkg/mod
RUN adduser -D -g '' hymir
WORKDIR /src/Naglfar
COPY . .
ENV GOOS=linux
ENV GOARCH=amd64
RUN go build -ldflags="-w -s" -o /bin/Naglfar ./cmd

FROM scratch
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /bin/Naglfar /bin/Naglfar
USER hymir
ENTRYPOINT ["/bin/Naglfar"]