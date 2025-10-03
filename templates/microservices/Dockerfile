# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY ["src/MaestroAI.Gateway.API/MaestroAI.Gateway.API.csproj", "src/MaestroAI.Gateway.API/MaestroAI.Gateway.API.csproj"]
COPY ["src/Directory.Build.props", "./"]
COPY ["nuget.config", "./"]

# Configure NuGet sources for GitHub Packages
RUN --mount=type=secret,id=github_token \
    if [ -f /run/secrets/github_token ]; then \
      dotnet nuget remove source github 2>/dev/null || true; \
      dotnet nuget add source --username docker --password "$(cat /run/secrets/github_token)" --store-password-in-clear-text --name github "https://nuget.pkg.github.com/marcelpiva-org/index.json"; \
    fi

# Restore dependencies
RUN dotnet restore "src/MaestroAI.Gateway.API/MaestroAI.Gateway.API.csproj"

# Copy source code and build
COPY . .
WORKDIR "/src/src/MaestroAI.Gateway.API"
RUN dotnet build "MaestroAI.Gateway.API.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "MaestroAI.Gateway.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

# Create non-root user
RUN addgroup --group --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup appuser

WORKDIR /app

# Copy published app
COPY --from=publish /app/publish .

# Set ownership and permissions
RUN chown -R appuser:appgroup /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Expose ports
EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["dotnet", "MaestroAI.Gateway.API.dll"]
