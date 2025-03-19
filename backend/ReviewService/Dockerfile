# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the entire solution
COPY . .

# Restore dependencies using solution file
RUN dotnet restore ReviewService.sln

# Build the API project directly instead of the solution
RUN dotnet build ReviewService.API/ReviewService.API.csproj -c Release -o /app/build

# Publish stage
FROM build AS publish
WORKDIR "/src"
RUN dotnet publish ReviewService.API/ReviewService.API.csproj -c Release -o /app/publish /p:UseAppHost=false

# Final stage - using SDK image to ensure migration tools are available
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS final
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

# Create entrypoint script with service dependency checks
RUN echo '#!/bin/bash' > /app/entrypoint.sh && \
    echo 'until pg_isready -h postgres -p 5432 -U postgres; do' >> /app/entrypoint.sh && \
    echo '  echo "Waiting for postgres to be ready..."' >> /app/entrypoint.sh && \
    echo '  sleep 2' >> /app/entrypoint.sh && \
    echo 'done' >> /app/entrypoint.sh && \
    echo 'echo "Checking if LocationService is reachable..."' >> /app/entrypoint.sh && \
    echo 'until curl -f -s -o /dev/null http://locationservice:8080/health || [ $? -eq 22 ]; do' >> /app/entrypoint.sh && \
    echo '  echo "Waiting for LocationService to be ready..."' >> /app/entrypoint.sh && \
    echo '  sleep 2' >> /app/entrypoint.sh && \
    echo 'done' >> /app/entrypoint.sh && \
    echo 'echo "Starting ReviewService..."' >> /app/entrypoint.sh && \
    echo 'dotnet ReviewService.API.dll' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]