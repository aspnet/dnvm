function BlastFromThePast([switch]$EndOfLine, [switch]$Finished){
    $EscChar = "`r"
    if($EndOfLine){ $EscChar = "`b" }
    if($Finished){Write-Host "$EscChar"; return;}
    if(!$tickcounter){ Set-Variable -Name "tickcounter" -Scope global -Value 0 -Force -Option AllScope }

   switch($tickcounter){
        0 { Write-Host "$EscChar|" -NoNewline }
        1 { Write-Host "$EscChar/" -NoNewline }
        2 { Write-Host "$EscChar-" -NoNewline }
        3 { Write-Host "$EscChar\" -NoNewline }
    }

    if($tickcounter -eq 3){ $tickcounter = 0 }
    else{ $tickcounter++ }
}

Write-Host "  Ticker at front of line" -NoNewline
for($i=0;$i -lt 20; $i++){BlastFromThePast; Start-Sleep -Milliseconds 100}
BlastFromThePast -Finished;

Write-Host "Ticker at end of line  " -NoNewline
for($i=0;$i -lt 20; $i++){BlastFromThePast -EndOfLine; Start-Sleep -Milliseconds 100}
BlastFromThePast -EndOfLine -Finished;