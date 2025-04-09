# Build stage
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the entire solution
COPY . .

# Restore dependencies using solution file
RUN dotnet restore ReviewService.sln

# Build the API project directly instead of the solution
RUN dotnet build ReviewService.API/ReviewService.API.csproj -c Release -o /app/build

# Publish stage
FROM --platform=linux/amd64 build AS publish
WORKDIR "/src"
RUN dotnet publish ReviewService.API/ReviewService.API.csproj -c Release -o /app/publish /p:UseAppHost=false

# Final stage - using SDK image to ensure migration tools are available
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:8.0 AS final
WORKDIR /app

# Set environment variables
ENV ASPNETCORE_ENVIRONMENT=Development
ENV ASPNETCORE_HTTP_PORTS=8080

# Install curl and postgresql-client for dependency checks
RUN apt-get update && \
    apt-get install -y postgresql-client curl && \
    rm -rf /var/lib/apt/lists/*

# Copy only the published files
COPY --from=publish /src .
COPY --from=publish /app/publish .

# Create entrypoint script directly with proper line endings
RUN printf '#!/bin/bash\n\
# Extract host from the connection string\n\
DB_HOST=$(echo $ConnectionStrings__DefaultConnection | grep -o "Host=[^;]*" | cut -d= -f2)\n\
DB_PORT=$(echo $ConnectionStrings__DefaultConnection | grep -o "Port=[^;]*" | cut -d= -f2)\n\
DB_USER=$(echo $ConnectionStrings__DefaultConnection | grep -o "Username=[^;]*" | cut -d= -f2)\n\
\n\
echo "Waiting for database to be ready at $DB_HOST:$DB_PORT..."\n\
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do\n\
  echo "Waiting for database to be ready..."\n\
  sleep 5\n\
done\n\
\n\
echo "Starting ReviewService..."\n\
dotnet ReviewService.API.dll\n' > /app/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]