FROM golang:1.16.4-alpine AS builder
WORKDIR /src
RUN adduser --disabled-password --uid 10001 shioriuser
RUN apk --update add ca-certificates musl-dev gcc
COPY go.mod go.sum ./
RUN go env -w GO111MODULE=on && go env -w  GOPROXY=https://goproxy.io,direct
COPY . .
RUN go generate ./... && CGO_ENABLED=1 go build -a -ldflags '-linkmode external -extldflags "-static" -s -w' .
ADD https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz /src
RUN tar xvf upx-3.96-amd64_linux.tar.xz && \
    mv upx-3.96-amd64_linux/upx . && \
    ./upx --best --lzma -o /src/iroihs /src/shiori && \
    ./upx -t iroihs && mv /src/iroihs /src/shiori


FROM scratch
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /src/shiori /usr/local/bin/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
USER shioriuser
ENV SHIORI_DIR /srv/shiori/
EXPOSE 8080
CMD ["/usr/local/bin/shiori", "serve"]
