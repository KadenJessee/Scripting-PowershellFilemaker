#!/usr/bin/env pwsh
# Kaden Jessee
# Lab 9 - PowerShell Filemaker
# CS 3030 - Scripting Languages

# Writing to an output file
function Write-ToFile ($outputFile, $outputString) {
    $outputString = $outputString -replace [regex]::escape("\t"), "`t"
    $outputString = $outputString -replace [regex]::escape("\n"), "`n"
    try {
        Add-Content -Path $outputFile -Value $outputString -NoNewline
    } catch {
        Write-Host "Write failed to file $($outputFile): $_"
        exit 1
    }
}

# Verify the commandline
if ($args.Length -ne 3) {
    Write-Host "Usage: ./filemaker.ps1 <commandfile> <outputfile> <recordcount>"
    exit 1
}

# Reading a file
try {
    $inputCommands = Get-Content -Path $args[0] -ErrorAction Stop
} catch {
    Write-Host "Error opening or reading command file: $($_)"
    exit 1
}

# Creating a new file
try {
    $outputFile = $args[1]
    New-Item -path $outputFile -erroraction stop | out-null 
}
catch {
    write-host ("Error opening output file: $($_)") 
    exit 1
}


# Record count
try {
    $recordCount = [int]$args[2]
    if ($recordCount -le 0) {
        throw "Record count should be a positive integer."
    }
} catch {
    Write-Host "Error: Record count should be a positive integer."
    exit 1
}

# Initialize variables
$randomFiles = @{}
$commands = @()

# Parsing commands
foreach ($command in $inputCommands) {
    #matching header
    if ($command -match '^HEADER\s+"(.*)"$') {
        Write-ToFile $outputFile ("$($matches[1])")
    }#matching string 
    elseif ($command -match '^STRING\s+"(.*)"$' -or $command -match "^STRING\s+'(.*)'$") {
        $commands += @{ 'type' = 'STRING'; 'value' = $matches[1] }
    }#matching word
    elseif ($command -match '^WORD\s+(\w+)\s+"(.*)"$') {
        $label = $matches[1]
        $filename = $matches[2]
        try {
            $randomFiles[$filename] = Get-Content -Path $filename
        } catch {
            Write-Host "Error: Could not read the file $filename"
            exit 1
        }
        $commands += @{ 'type' = 'WORD'; 'label' = $label; 'filename' = $filename }
    }#matching integer
    elseif ($command -match '^INTEGER\s+(\w+)\s+(\d+)\s+(\d+)$') {
        $commands += @{
            'type' = 'INTEGER';
            'label' = $matches[1];
            'min' = [int]$matches[2];
            'max' = [int]$matches[3]
        }
    }#matching refer
    elseif ($command -match '^REFER\s+(\w+)$') {
        $commands += @{ 'type' = 'REFER'; 'label' = $matches[1] }
    }
}

# Generating output
for ($i = 0; $i -lt $recordCount; $i++) {
    $randomData = @{}
    $outputString = ""
    
    foreach ($cmd in $commands) {
        switch ($cmd['type']) {
            'STRING' {
                $outputString += $cmd['value']
            }
            'WORD' {
                #Using random numbers
                $randomWord = Get-Random -InputObject $randomFiles[$cmd['filename']]
                $randomData[$cmd['label']] = $randomWord
                $outputString += $randomWord
            }
            'INTEGER' {
                $randomInt = Get-Random -Minimum $cmd['min'] -Maximum $cmd['max']
                $randomData[$cmd['label']] = $randomInt
                $outputString += $randomInt
            }
            'REFER' {
                $outputString += $randomData[$cmd['label']]
            }
        }
    }
    
    Write-ToFile $outputFile $outputString
}

exit 0