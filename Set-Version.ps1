param(
    [string]$GitTag = ""
)

<#
.SYNOPSIS
    Updates project version from Git tag
.DESCRIPTION
    This script updates Directory.Build.props with version information from Git tags.
    Supports both stable versions (v1.10.0) and pre-release versions (v1.10.1-rc1).
    Can be integrated into CI/CD pipelines for automatic versioning.
.PARAMETER GitTag
    Specific git tag to use. If not provided, uses the latest tag from git.
    Supports formats: v1.10.0, v1.10.1-rc1, v1.10.1-beta.2, etc.
.EXAMPLE
    .\Set-Version.ps1 -GitTag "v1.11.0"
    Sets version to 1.11.0
.EXAMPLE
    .\Set-Version.ps1 -GitTag "v1.11.0-rc1"
    Sets version to 1.11.0-rc1 (AssemblyVersion will be 1.11.0.0)
.EXAMPLE
    .\Set-Version.ps1  # Uses latest git tag
#>

Write-Host "Setting project version..." -ForegroundColor Cyan

# Get version from git tag
if ([string]::IsNullOrEmpty($GitTag)) {
    Write-Host "No tag specified, attempting to get latest from git..."
    $GitTag = git describe --tags --abbrev=0 2>$null
    
    if ([string]::IsNullOrEmpty($GitTag)) {
        Write-Warning "No git tags found. Using default version 1.10.0"
        $fullVersion = "1.10.0"
        $numericVersion = "1.10.0"
    }
    else {
        # Remove 'v' prefix if present
        $fullVersion = $GitTag -replace '^v', ''
        Write-Host "Found git tag: $GitTag -> Version: $fullVersion" -ForegroundColor Green
    }
}
else {
    # Remove 'v' prefix if present
    $fullVersion = $GitTag -replace '^v', ''
    Write-Host "Using provided tag: $GitTag -> Version: $fullVersion" -ForegroundColor Green
}

# Extract numeric version for AssemblyVersion (must be numeric only)
# Examples: "1.10.0" -> "1.10.0", "1.10.1-rc1" -> "1.10.1"
if ($fullVersion -match '^(\d+\.\d+\.\d+)') {
    $numericVersion = $matches[1]
}
else {
    Write-Warning "Could not parse version from '$fullVersion', using default 1.10.0"
    $numericVersion = "1.10.0"
    $fullVersion = "1.10.0"
}

# Get current year for copyright
$currentYear = (Get-Date).Year

# Update Directory.Build.props
$propsPath = Join-Path $PSScriptRoot "Directory.Build.props"
$propsContent = @"
<Project>
  <PropertyGroup>
    <!-- Version Configuration - Update here to change version across all projects -->
    <VersionPrefix>$fullVersion</VersionPrefix>
    <AssemblyVersion>$numericVersion.0</AssemblyVersion>
    <FileVersion>$numericVersion.0</FileVersion>
    <InformationalVersion>$fullVersion</InformationalVersion>
    
    <!-- Copyright - Automatically uses current year -->
    <Copyright>Copyright © $currentYear</Copyright>
    <Company></Company>
  </PropertyGroup>
</Project>
"@

Set-Content $propsPath $propsContent -Encoding UTF8
Write-Host "✓ Updated Directory.Build.props with version $fullVersion" -ForegroundColor Green
Write-Host "  Version Prefix: $fullVersion" -ForegroundColor Gray
Write-Host "  Assembly Version: $numericVersion.0 (numeric only)" -ForegroundColor Gray
Write-Host "  Informational Version: $fullVersion (full version)" -ForegroundColor Gray
Write-Host "  Copyright: Copyright © $currentYear" -ForegroundColor Gray

