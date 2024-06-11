# Use the official .NET SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /sources

# Copy csproj and restore as distinct layers
COPY /UmbracoContainer/*.csproj .
RUN dotnet restore

# Copy everything else and build website
COPY /UmbracoContainer/appsettings.json .
COPY /UmbracoContainer/Program.cs .
COPY /UmbracoContainer/Startup.cs .
COPY /UmbracoContainer/Properties ./Properties
COPY /UmbracoContainer/Views ./Views

# Build the application
RUN dotnet build
RUN dotnet publish -c release -o /output --no-restore

# Use the official ASP.NET Core image for runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Install curl and wget
RUN apt-get update && apt-get install -y --no-install-recommends curl wget && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /output

# Copy the published output from the build stage
COPY --from=build /output ./

# Copy the wait-for-it.sh script as an mssql prerequisite
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

# Configure healthcheck with logging
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost/ > /tmp/healthcheck.log 2>&1 || (cat /tmp/healthcheck.log && exit 1)

# Set the entry point for the container
ENTRYPOINT ["dotnet", "UmbracoContainer.dll"]
