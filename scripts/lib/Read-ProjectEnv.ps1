# Shared PowerShell function to read project.env
# Returns a hashtable with ORG and PROJECT_NAME

function Read-ProjectEnv {
  param(
    [string]$EnvFilePath
  )

  if (-not (Test-Path $EnvFilePath)) {
    Write-Error "project.env not found at: $EnvFilePath"
    return $null
  }

  $config = @{}
  Get-Content $EnvFilePath | Where-Object { $_ -match '^\s*[A-Z_]+\s*=' } | ForEach-Object {
    $key, $value = $_ -split '=', 2
    $key = $key.Trim()
    $value = $value.Trim().Trim('"').Trim("'")
    $config[$key] = $value
  }

  # Validate required keys
  if (-not $config['ORG']) {
    Write-Error "ORG not found in project.env"
    return $null
  }
  if (-not $config['PROJECT_NAME']) {
    Write-Error "PROJECT_NAME not found in project.env"
    return $null
  }

  # Optional keys with defaults (older project.env files may not define them)
  if (-not $config['APP_PACKAGE']) {
    $config['APP_PACKAGE'] = 'mobile_app'
  }

  return $config
}
