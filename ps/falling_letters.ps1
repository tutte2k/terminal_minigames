
$width = 50 
$height = 20 
$global:letters = @()
$lettersToFall = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
$global:gameOver = $false
$global:score = 0 
$global:maxLetters = 1 

function Add-Letter {
    if ($global:letters.Count -lt $global:maxLetters) {  
        $randomLetter = $lettersToFall | Get-Random
        $position = @{
            X = Get-Random -Min 1 -Max ($width - 2)  
            Y = 0                                  
            Letter = $randomLetter
        }
        $global:letters += $position  
    }
}

function Draw-GameArea {
    $buffer = @()
    for ($y = 0; $y -lt $height; $y++) {
        $bufferLine = "|" + (" " * ($width - 2)) + "|"
        $buffer += $bufferLine
    }
    foreach ($letter in $global:letters) {
        $line = $buffer[$letter.Y - 1] 
        $buffer[$letter.Y - 1] = $line.Substring(0, $letter.X) + $letter.Letter + $line.Substring($letter.X + 1)
    }
    [Console]::Clear()
    foreach ($line in $buffer) {
        Write-Host $line
    }
    Display-DebugInfo
}

function Update-Letters {
    $lettersToRemove = @()
    foreach ($letter in $global:letters) {
        $letter.Y++
        if ($letter.Y -ge $height) {
            $global:gameOver = $true  
        } else {
            $lettersToRemove += $letter
        }
    }
    $global:letters = $lettersToRemove
}

function Display-DebugInfo {
    $cursorY = [Console]::WindowHeight - 1 
    if ($cursorY -gt $height) {
        $cursorY = $height + 1  
    }
    [Console]::SetCursorPosition(0, $cursorY)
    Write-Host (" " * $width) -NoNewline  
    [Console]::SetCursorPosition(0, $cursorY)
    Write-Host "Score: $global:score" -NoNewline
}

function Check-Input {
    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true).KeyChar.ToString().ToUpper()
        $matchingLettersCount = ($global:letters | Where-Object { $_.Letter -eq $key }).Count
        if ($matchingLettersCount -gt 0) {
            $global:score += $matchingLettersCount  
            $global:letters = $global:letters | Where-Object { $_.Letter -ne $key }
            $global:maxLetters = [Math]::Min(10, 1 + [Math]::Floor($global:score / 10)) 
        }
    }
}

do {
    Add-Letter
    Update-Letters
    Check-Input 
    Draw-GameArea  

    if ($global:gameOver) {
        [Console]::SetCursorPosition(0, $height + 5)
        Write-Host "Game Over! A letter hit the bottom."
        break
    }
    $fallingSpeed = [Math]::Max(100, 500 - ($global:score * 5)) 
    Start-Sleep -Milliseconds $fallingSpeed  
} while (-not $global:gameOver)