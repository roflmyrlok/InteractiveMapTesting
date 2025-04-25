FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY protos ./protos
COPY .      .

RUN dotnet restore LocationService.sln
RUN dotnet build LocationService.API/LocationService.API.csproj -c Release -o /app/build

FROM build AS publish
WORKDIR /src
RUN dotnet publish LocationService.API/LocationService.API.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_ENVIRONMENT=Development
ENV ASPNETCORE_HTTP_PORTS=8080
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

COPY --from=publish /src .
COPY --from=publish /app/publish .
RUN dotnet tool install --global dotnet-ef
ENV PATH="${PATH}:/root/.dotnet/tools"

RUN printf '#!/bin/bash\nDB_HOST=$(echo $ConnectionStrings__DefaultConnection | grep -o "Host=[^;]*" | cut -d= -f2)\nDB_PORT=$(echo $ConnectionStrings__DefaultConnection | grep -o "Port=[^;]*" | cut -d= -f2)\nDB_USER=$(echo $ConnectionStrings__DefaultConnection | grep -o "Username=[^;]*" | cut -d= -f2)\nuntil pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; do sleep 5; done\ndotnet LocationService.API.dll\n' > entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/bin/bash","/app/entrypoint.sh"]
