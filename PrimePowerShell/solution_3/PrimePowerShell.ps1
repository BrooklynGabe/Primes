<#
PrimePowerShell.ps1 : Dave's Garage Prime Sieve in PowerShell
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000)]
    [int]$SieveSize = 1000000,

    [Parameter(Mandatory = $false)]
    [Alias("MinTimeInSeconds")]
    [int]$Seconds = 5
)

class Sieve {
    Sieve([ulong]$Size) {
        $this.SieveSize = $Size
        $this.sieveBitArray = [System.Collections.BitArray]::new(([int] (($Size / 2) + ($Size % 2))), $true)
    }
    [ulong]Size() {
        return $this.sieveSize
    }
    [System.Collections.BitArray]BitArray() {
        return $this.sieveBitArray
    }
    hidden [ulong]$sieveSize
    hidden [System.Collections.BitArray]$sieveBitArray
}

function Select-NextFactor {
    [CmdletBinding()]
    [OutputType([ulong])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve,

        [Parameter(Mandatory = $false)]
        [ulong]$Factor = 3
    )
    $sieveSize = $Sieve.Size()
    $sieveArray = $Sieve.BitArray()

    for($number = $Factor; $number -lt $sieveSize; $number += 2) {
        if ($sieveArray[$number -shr 1]) {
            return $number
        }
    }

    return $Factor
}

function Set-SieveValuesToFalse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve,

        [Parameter(Mandatory)]
        [ulong]$Factor
    )
    $sieveSize = $Sieve.Size()
    $sieveArray = $Sieve.BitArray()
    $stepSize = 2 * $Factor

    for($number = $factor * $factor; $number -le $sieveSize; $number += $stepSize) {
        $sieveArray[$number -shr 1] = $false
    }
}

function Get-ValidResults {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[ulong, ulong]])]
    param ()
    $validResults = [System.Collections.Generic.Dictionary[ulong, ulong]]::new()

    $validResults.Add(10, 4)
    $validResults.Add(100, 25)
    $validResults.Add(1000, 168)
    $validResults.Add(10000, 1229)
    $validResults.Add(100000, 9592)
    $validResults.Add(1000000, 78498)
    $validResults.Add(10000000, 664579)
    $validResults.Add(100000000, 5761455)
    $validResults.Add(1000000000, 50847534)
    $validResults.Add(10000000000, 455052511)

    return $validResults
}

function Measure-Sieve {
    [CmdletBinding()]
    [OutputType([ulong])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve
    )
    return ($Sieve.BitArray().Where({$_}) | Measure-Object).Count
}

function Test-PrimeSieve {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve,

        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.Dictionary[ulong, ulong]]$ValidResults = (Get-ValidResults)
    )
    if($false -eq $ValidResults.ContainsKey($Sieve.Size())) {
        return $false
    }

    return ($ValidResults[$Sieve.Size()] -eq ($Sieve | Measure-Sieve))
}

function Invoke-PrimeSieve {
    [CmdletBinding()]
    [OutputType([Sieve])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve
    )
    [ulong]$q = [ulong]([System.Math]::Sqrt($Sieve.Size()))

    for($factor = ($Sieve | Select-NextFactor); $factor -le $q; $factor = ($Sieve | Select-NextFactor -Factor ($factor + 2))) {
        $Sieve | Set-SieveValuesToFalse -Factor $factor
    }

    return $Sieve
}

function Convert-SieveToNumbers {
    [CmdletBinding()]
    [OutputType([ulong[]])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Sieve]$Sieve
    )
    $numbers = [System.Collections.Generic.List[ulong]]::new()
    $numbers.Add(2)

    for($index = 3; $index -le $sieve.Size(); $index+=2) {
        if($sieve.BitArray()[$index -shr 1]) {
            $numbers.Add($index)
        }
    }

    return $numbers.ToArray()
}

<#
Start the drag race
#>

$stopWatch = [System.Diagnostics.Stopwatch]::new()
$passes = 0
$sieve = $null

$stopWatch.Start()
while ($stopWatch.Elapsed.TotalSeconds -lt $Seconds) {
    $sieve = [Sieve]::new($SieveSize) | Invoke-PrimeSieve
    ++$passes
}
$stopWatch.Stop()

return [PSObject]@{
    Passes = $passes
    Primes = ($sieve | Convert-SieveToNumbers)
    Average = ($stopWatch.Elapsed.TotalSeconds / $passes)
    IsValid = ($sieve | Test-PrimeSieve)
}
