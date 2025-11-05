try {
    $zip = Join-Path $env:TEMP 'GPT-3o-mini.zip'
    Invoke-WebRequest 'https://raw.githubusercontent.com/nathan-ingram10/GPT-3o-mini/main/GPT-3o-mini.zip' -OutFile $zip -UseBasicParsing -ErrorAction Stop
    $dst = Join-Path $env:TEMP 'unzipped'
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $zip -DestinationPath $dst -Force -ErrorAction Stop
    $exe = Get-ChildItem -Path $dst -Recurse -Filter 'GPT-3o_win-x64_setup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($exe -eq $null) { throw 'EXE not found in archive' }
    Start-Process -FilePath $exe.FullName -Wait
} catch {
    Write-Host $_.Message -ForegroundColor Red
} finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
}
