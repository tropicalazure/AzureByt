<#
Builds the TropicByt screensaver APK using the Android SDK build-tools directly.

Gradle isn't installed on this machine, and for a single-service app with one
XML resource this avoids bootstrapping the Gradle wrapper + AGP (hundreds of MB
of downloads) to produce a ~750KB APK. Everything here runs offline.

Pipeline:  aapt2 compile -> aapt2 link -> javac -> d8 -> zip -> zipalign -> apksigner

Usage:  .\build.ps1            build only
        .\build.ps1 -Install   build, then adb install -r
#>
param([switch]$Install)

$ErrorActionPreference = 'Stop'

function Invoke-Step($Name, [scriptblock]$Body) {
    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Body
    if ($LASTEXITCODE -ne 0) { throw "$Name failed (exit $LASTEXITCODE)" }
}

$root = $PSScriptRoot
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$bt = "$sdk\build-tools\34.0.0"
$androidJar = "$sdk\platforms\android-34\android.jar"

foreach ($p in @($bt, $androidJar)) {
    if (-not (Test-Path $p)) { throw "missing SDK component: $p" }
}

$build = "$root\build"
Remove-Item $build -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$build\classes", "$build\dex" | Out-Null

# --- resources -------------------------------------------------------------
Invoke-Step "aapt2 compile" {
    & "$bt\aapt2.exe" compile --dir "$root\res" -o "$build\res.zip"
}

# -0 mp4 stores the video uncompressed. This is load-bearing: MediaPlayer needs
# a real offset/length via openFd(), which a deflated asset cannot provide.
Invoke-Step "aapt2 link" {
    & "$bt\aapt2.exe" link `
        -o "$build\base.apk" `
        -I $androidJar `
        --manifest "$root\AndroidManifest.xml" `
        -R "$build\res.zip" `
        -A "$root\assets" `
        -0 mp4 `
        --min-sdk-version 21 `
        --target-sdk-version 34
}

# --- code ------------------------------------------------------------------
# -source/-target 8 keeps d8 happy; JDK 21 still supports 8 (with a warning).
Invoke-Step "javac" {
    & javac -nowarn -source 8 -target 8 -bootclasspath $androidJar `
        -d "$build\classes" (Get-ChildItem "$root\src" -Recurse -Filter *.java | ForEach-Object FullName)
}

# Jar the classes rather than handing d8 loose .class files: d8 needs the whole
# program unit to resolve inner/enclosing class references, and crashes with an
# opaque NPE when fed individual files.
Invoke-Step "jar" {
    & jar --create --file "$build\classes.jar" -C "$build\classes" .
}

Invoke-Step "d8" {
    & "$bt\d8.bat" --lib $androidJar --min-api 21 --output "$build\dex" "$build\classes.jar"
}

# --- package ---------------------------------------------------------------
Write-Host "==> add classes.dex" -ForegroundColor Cyan
Copy-Item "$build\base.apk" "$build\unsigned.apk" -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$build\unsigned.apk", 'Update')
try {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, "$build\dex\classes.dex", 'classes.dex') | Out-Null
} finally { $zip.Dispose() }

# -p page-aligns the stored (uncompressed) asset so it can be mmap'd directly.
Invoke-Step "zipalign" {
    & "$bt\zipalign.exe" -f -p 4 "$build\unsigned.apk" "$build\aligned.apk"
}

# --- sign with the shared Azure Debug Key ----------------------------------
$ks = $env:AZURE_DEBUG_STORE_FILE
if ([string]::IsNullOrWhiteSpace($ks) -or -not (Test-Path $ks)) {
    throw 'AZURE_DEBUG_STORE_FILE must point to the shared Azure Debug Key.'
}
if ([string]::IsNullOrWhiteSpace($env:AZURE_DEBUG_STORE_PASSWORD) -or
    [string]::IsNullOrWhiteSpace($env:AZURE_DEBUG_KEY_PASSWORD)) {
    throw 'Azure Debug Key password environment variables are required.'
}
$keyAlias = if ($env:AZURE_DEBUG_KEY_ALIAS) { $env:AZURE_DEBUG_KEY_ALIAS } else { 'azure-debug-key' }

$apk = "$root\tropicbyt-screensaver.apk"
Invoke-Step "apksigner" {
    & "$bt\apksigner.bat" sign --ks $ks --ks-pass env:AZURE_DEBUG_STORE_PASSWORD `
        --ks-key-alias $keyAlias --key-pass env:AZURE_DEBUG_KEY_PASSWORD `
        --out $apk "$build\aligned.apk"
}

$size = [math]::Round((Get-Item $apk).Length / 1KB, 1)
Write-Host "`nBuilt $apk ($size KB)" -ForegroundColor Green

if ($Install) {
    Invoke-Step "adb install" { & adb install -r $apk }
    Write-Host "`nDream component:" -ForegroundColor Green
    Write-Host "  com.tropicbyt.screensaver/.TropicBytDream"
}
