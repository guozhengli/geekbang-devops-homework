FROM golang:1.17

WORKDIR /opt/app
COPY . .

RUN go build -o example

CMD ["/opt/app/example"]