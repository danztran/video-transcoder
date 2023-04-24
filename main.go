package main

import (
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	var (
		e = echo.New()
	)

	// pre middleware
	e.Use(middleware.Recover())
	e.Use(middleware.Logger())
	e.Use(middleware.Gzip())
	e.Use(middleware.CORS())

	// serve static files
	e.Static("/dist", "dist")

	// routes
	e.GET("/health", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})

	e.Logger.Fatal(e.Start("127.0.0.1:" + getenv("PORT", "9090")))
}

func getenv(key string, def string) string {
	if env, ok := os.LookupEnv(key); ok {
		return env
        }
	return def
}
