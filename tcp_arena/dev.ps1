function RunCommandInDirectory($directory, $command, $title) {
    $originalDir = Get-Location
    Set-Location $directory
    Start-Process "cmd.exe" -ArgumentList "/c title $title && ($command || (echo Error encountered. Press any key to close. && pause))"
    Set-Location $originalDir
}

$commandsWithDirectoriesAndTitles = @(
    @{ Directory = "./"; Command = "go run pvp_game_server.go"; Title = "Gameserver" },
    @{ Directory = "./"; Command = "node pvp_game_client.js"; Title = "Client1" },
    @{ Directory = "./"; Command = "node pvp_game_client.js"; Title = "Client2" },
    @{ Directory = "./"; Command = "node pvp_game_client.js"; Title = "Client3" }
)

foreach ($entry in $commandsWithDirectoriesAndTitles) {
    RunCommandInDirectory $entry.Directory $entry.Command $entry.Title
}