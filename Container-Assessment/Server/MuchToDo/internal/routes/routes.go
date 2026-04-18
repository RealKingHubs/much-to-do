package routes

import (
	"strings"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/handlers"
	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/middleware"

	_ "github.com/Innocent9712/much-to-do/Server/MuchToDo/docs"
	"github.com/Innocent9712/much-to-do/Server/MuchToDo/docs"
)


// RegisterRoutes sets up all application routes.
func RegisterRoutes(
	router *gin.Engine,
	userHandler *handlers.UserHandler,
	todoHandler *handlers.TodoHandler,
	healthHandler *handlers.HealthHandler,
	authMiddleware gin.HandlerFunc,
) {
	// Add the structured logger middleware first to log all requests.
	router.Use(middleware.StructuredLogger())
	// Default Gin recovery middleware (recovers from panics)
	router.Use(gin.Recovery())

	// Public routes
	router.GET("/health", healthHandler.CheckHealth)

	// Swagger documentation route
	router.GET("/swagger/*any", func(c *gin.Context) {
        scheme := "http"
        if c.Request.TLS != nil || strings.HasPrefix(c.Request.Header.Get("X-Forwarded-Proto"), "https") {
            scheme = "https"
        }

        docs.SwaggerInfo.Host = c.Request.Host
        docs.SwaggerInfo.Schemes = []string{scheme}

        // Delegate to gin-swagger after updating docs
        ginSwagger.WrapHandler(swaggerFiles.Handler)(c)
    })

	authRoutes := router.Group("/auth")
	{
		authRoutes.POST("/register", userHandler.Register)
		authRoutes.POST("/login", userHandler.Login)
		authRoutes.POST("/logout", userHandler.Logout)
		authRoutes.GET("/username-check/:username", userHandler.CheckUsernameAvailability)
	}

	// Protected routes
	protected := router.Group("/")
	protected.Use(authMiddleware)
	{
		// Protected user routes
		userRoutes := protected.Group("/users")
		userRoutes.GET("/me", userHandler.GetCurrentUser)
		userRoutes.PUT("/me", userHandler.UpdateUser)
		userRoutes.PUT("/me/password", userHandler.ChangePassword)
		userRoutes.DELETE("/me", userHandler.DeleteUser)

		// Protected todo routes
		todoRoutes := protected.Group("/todos")
		{
			todoRoutes.POST("/", todoHandler.CreateTodo)
			todoRoutes.GET("/", todoHandler.GetAllTodos)
			todoRoutes.GET("/:id", todoHandler.GetTodoByID)
			todoRoutes.PUT("/:id", todoHandler.UpdateTodo)
			todoRoutes.DELETE("/:id", todoHandler.DeleteTodo)
		}
	}
}
