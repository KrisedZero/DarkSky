<#
    Pixel Horror Castle - Placeholder Asset Generator

    Generates production-ready placeholder assets without external tools:
      * 32x32 RGBA PNG sprites (colored pixel-art silhouettes, transparent bg)
      * 32x32 RGBA PNG tileset textures (tiled floor/wall patterns)
      * Silent 44.1kHz 16-bit WAV files for every audio event

    No text labels are baked into sprites (consistent silhouette style only).
    Every asset is directly replaceable by final art without code/scene changes.

    Run:  pwsh tools/gen_placeholders.ps1
#>

$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Definition
$root = Split-Path -Parent $base
$assets = Join-Path $root 'assets'
$spritesDir = Join-Path $assets 'sprites'
$tilesDir = Join-Path $assets 'tilesets'
$audioDir = Join-Path $assets 'audio'

foreach ($d in @($spritesDir, $tilesDir, $audioDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

$W = 32
$H = 32

# ----------------------------------------------------------------------------
# PNG encoder (RGBA8, stored/zlib)
# ----------------------------------------------------------------------------

function Get-CRC32([byte[]]$data) {
    $table = New-Object 'uint32[]' 256
    for ($n = 0; $n -lt 256; $n++) {
        $c = [uint32]$n
        for ($k = 0; $k -lt 8; $k++) {
            if ($c -band 1) { $c = ([uint32]3988292384 -bxor ($c -shr 1)) -band [uint32]::MaxValue } else { $c = $c -shr 1 }
        }
        $table[$n] = $c
    }
    $crc = [uint32]::MaxValue
    foreach ($b in $data) {
        $crc = $table[($crc -bxor [uint32]$b) -band 0xff] -bxor ($crc -shr 8)
    }
    return ($crc -bxor 0xffffffff)
}

function Get-Adler32([byte[]]$data) {
    $a = [uint32]1
    $b = [uint32]0
    foreach ($byte in $data) {
        $a = ($a + [uint32]$byte) % 65521
        $b = ($b + $a) % 65521
    }
    return (($b -shl 16) -bor $a)
}

function BE([long]$value, [int]$nbytes) {
    $arr = New-Object 'byte[]' $nbytes
    for ($i = 0; $i -lt $nbytes; $i++) {
        $shift = 8 * ($nbytes - 1 - $i)
        $arr[$i] = [byte](($value -shr $shift) -band 0xff)
    }
    return [byte[]]$arr
}

function Add-Bytes([System.Collections.Generic.List[byte]]$list, $arr) {
    $list.AddRange([byte[]]$arr)
}

function Add-Chunk([System.Collections.Generic.List[byte]]$out, [string]$type, [byte[]]$data) {
    Add-Bytes $out (BE $data.Length 4)
    $typeBytes = [System.Text.Encoding]::ASCII.GetBytes($type)
    $crcInput = New-Object 'byte[]' ($typeBytes.Length + $data.Length)
    [Array]::Copy($typeBytes, 0, $crcInput, 0, $typeBytes.Length)
    [Array]::Copy($data, 0, $crcInput, $typeBytes.Length, $data.Length)
    $crc = Get-CRC32 $crcInput
    $out.AddRange($typeBytes)
    $out.AddRange($data)
    Add-Bytes $out (BE $crc 4)
}

function Export-PNG([string]$path, [byte[]]$buf) {
    # Build raw scanlines (filter byte 0 + RGBA)
    $raw = New-Object 'byte[]' ($H * (1 + $W * 4))
    $p = 0
    for ($y = 0; $y -lt $H; $y++) {
        $raw[$p++] = 0
        for ($x = 0; $x -lt $W; $x++) {
            $i = ($y * $W + $x) * 4
            $raw[$p++] = $buf[$i]; $raw[$p++] = $buf[$i + 1]; $raw[$p++] = $buf[$i + 2]; $raw[$p++] = $buf[$i + 3]
        }
    }
    # zlib stored block
    $len = $raw.Length
    $nlen = (65535 - $len)
    $zlib = New-Object 'System.Collections.Generic.List[byte]'
    $zlib.Add(0x78); $zlib.Add(0x01)          # zlib header (no compression)
    $zlib.Add(0x01)                            # BFINAL=1, BTYPE=00
    Add-Bytes $zlib (BE $len 2)
    Add-Bytes $zlib (BE $nlen 2)
    $zlib.AddRange($raw)
    $adler = Get-Adler32 $raw
    Add-Bytes $zlib (BE $adler 4)
    $zlibBytes = $zlib.ToArray()

    $sig = [byte[]]@(137, 80, 78, 71, 13, 10, 26, 10)
    $out = New-Object 'System.Collections.Generic.List[byte]'
    $out.AddRange($sig)
    # IHDR
    $ihdr = New-Object 'System.Collections.Generic.List[byte]'
    Add-Bytes $ihdr (BE $W 4)
    Add-Bytes $ihdr (BE $H 4)
    $ihdr.Add(8); $ihdr.Add(6); $ihdr.Add(0); $ihdr.Add(0); $ihdr.Add(0)
    Add-Chunk $out 'IHDR' $ihdr.ToArray()
    Add-Chunk $out 'IDAT' $zlibBytes
    Add-Chunk $out 'IEND' @()
    [System.IO.File]::WriteAllBytes($path, $out.ToArray())
}

# ----------------------------------------------------------------------------
# Canvas drawing helpers
# ----------------------------------------------------------------------------

function New-Canvas { return New-Object 'byte[]' ($W * $H * 4) }

function Set-Px($buf, $x, $y, $c) {
    if ($x -lt 0 -or $x -ge $W -or $y -lt 0 -or $y -ge $H) { return }
    $i = ($y * $W + $x) * 4
    $buf[$i] = $c[0]; $buf[$i + 1] = $c[1]; $buf[$i + 2] = $c[2]; $buf[$i + 3] = $c[3]
}

function Fill-Rect($buf, $x0, $y0, $x1, $y1, $c) {
    for ($y = $y0; $y -le $y1; $y++) { for ($x = $x0; $x -le $x1; $x++) { Set-Px $buf $x $y $c } }
}

function Fill-Circle($buf, $cx, $cy, $r, $c) {
    for ($y = [int]($cy - $r); $y -le [int]($cy + $r); $y++) {
        for ($x = [int]($cx - $r); $x -le [int]($cx + $r); $x++) {
            $dx = $x - $cx; $dy = $y - $cy
            if (($dx * $dx + $dy * $dy) -le ($r * $r)) { Set-Px $buf $x $y $c }
        }
    }
}

function Outline-Rect($buf, $x0, $y0, $x1, $y1, $c) {
    for ($x = $x0; $x -le $x1; $x++) { Set-Px $buf $x $y0 $c; Set-Px $buf $x $y1 $c }
    for ($y = $y0; $y -le $y1; $y++) { Set-Px $buf $x0 $y $c; Set-Px $buf $x1 $y $c }
}

function HLine($buf, $x0, $x1, $y, $c) { for ($x = $x0; $x -le $x1; $x++) { Set-Px $buf $x $y $c } }
function VLine($buf, $x, $y0, $y1, $c) { for ($y = $y0; $y -le $y1; $y++) { Set-Px $buf $x $y $c } }

function Px-Alpha($buf, $x, $y, $c, $a) {
    if ($x -lt 0 -or $x -ge $W -or $y -lt 0 -or $y -ge $H) { return }
    $i = ($y * $W + $x) * 4
    $r = $c[0]; $g = $c[1]; $bl = $c[2]
    $oldA = $buf[$i + 3]
    if ($oldA -eq 0) {
        $buf[$i] = $r; $buf[$i + 1] = $g; $buf[$i + 2] = $bl; $buf[$i + 3] = $a
    } else {
        $nr = [int]($r * $a / 255 + $buf[$i] * (255 - $a) / 255)
        $ng = [int]($g * $a / 255 + $buf[$i + 1] * (255 - $a) / 255)
        $nb = [int]($bl * $a / 255 + $buf[$i + 2] * (255 - $a) / 255)
        $buf[$i] = $nr; $buf[$i + 1] = $ng; $buf[$i + 2] = $nb
        $buf[$i + 3] = [Math]::Max($oldA, $a)
    }
}

function Fill-CircleAA($buf, $cx, $cy, $r, $c) {
    for ($y = [int]($cy - $r - 1); $y -le [int]($cy + $r + 1); $y++) {
        for ($x = [int]($cx - $r - 1); $x -le [int]($cx + $r + 1); $x++) {
            $dx = $x - $cx; $dy = $y - $cy
            $d = [Math]::Sqrt($dx * $dx + $dy * $dy)
            if ($d -le $r - 0.5) { Set-Px $buf $x $y $c }
            elseif ($d -le $r + 0.5) {
                $a = [int](255 * ($r + 0.5 - $d))
                Px-Alpha $buf $x $y $c $a
            }
        }
    }
}

function Fill-CircleOutline($buf, $cx, $cy, $r, $c) {
    for ($y = [int]($cy - $r); $y -le [int]($cy + $r); $y++) {
        for ($x = [int]($cx - $r); $x -le [int]($cx + $r); $x++) {
            $dx = $x - $cx; $dy = $y - $cy
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -le ($r * $r) -and $d2 -ge (($r - 1) * ($r - 1))) { Set-Px $buf $x $y $c }
        }
    }
}

function Outline-Shape($buf, $c) {
    $w = $W; $h = $H
    $marks = New-Object 'bool[]' ($w * $h)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $i = ($y * $w + $x) * 4
            if ($buf[$i + 3] -gt 0) {
                $isEdge = $false
                if ($x -eq 0 -or $x -eq $w - 1 -or $y -eq 0 -or $y -eq $h - 1) { $isEdge = $true }
                else {
                    for ($dy = -1; $dy -le 1 -and -not $isEdge; $dy++) {
                        for ($dx = -1; $dx -le 1; $dx++) {
                            if ($dx -eq 0 -and $dy -eq 0) { continue }
                            $nx = $x + $dx; $ny = $y + $dy
                            if ($nx -lt 0 -or $nx -ge $w -or $ny -lt 0 -or $ny -ge $h) { $isEdge = $true; break }
                            $ni = ($ny * $w + $nx) * 4
                            if ($buf[$ni + 3] -eq 0) { $isEdge = $true; break }
                        }
                    }
                }
                if ($isEdge) { $marks[$y * $w + $x] = $true }
            }
        }
    }
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($marks[$y * $w + $x]) { Set-Px $buf $x $y $c }
        }
    }
}

function Dither-Rect($buf, $x0, $y0, $x1, $y1, $c1, $c2) {
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) {
            if ((($x + $y) % 2) -eq 0) { Set-Px $buf $x $y $c1 } else { Set-Px $buf $x $y $c2 }
        }
    }
}

function Shade-Top($buf, $x0, $y0, $x1, $y1, $c, $h) {
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) { Set-Px $buf $x $y $c }
    }
    for ($y = $y0; $y -le [Math]::Min($y1, $y0 + $h - 1); $y++) {
        for ($x = $x0; $x -le $x1; $x++) { Set-Px $buf $x $y $c }
    }
}

function Pix-If($buf, $x, $y, $c, $cond) {
    if ($cond) { Set-Px $buf $x $y $c }
}

function Tile-Base($buf, $base, $line, [int]$step) {
    Fill-Rect $buf 0 0 ($W - 1) ($H - 1) $base
    for ($y = 0; $y -lt $H; $y += $step) { HLine $buf 0 ($W - 1) $y $line }
    for ($x = 0; $x -lt $W; $x += $step) { VLine $buf $x 0 ($H - 1) $line }
}

function Write-PNG([string]$name, [byte[]]$buf) {
    $path = Join-Path $spritesDir $name
    Export-PNG $path $buf
    Write-Import $path 'Texture2D' @'
[gd_resource type="Texture2D" load_steps=1 format=3 uid="__UID__"]

[params]
compress/mode=0
mipmaps/generate=false
mipmaps/limit=-1
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map=0
process/hdr_compression=1
process/flags=0
detect_3d/compress_to=0
'@
}

function Write-Tile([string]$name, [byte[]]$buf) {
    $path = Join-Path $tilesDir $name
    Export-PNG $path $buf
    Write-Import $path 'Texture2D' @'
[gd_resource type="Texture2D" load_steps=1 format=3 uid="__UID__"]

[params]
compress/mode=0
mipmaps/generate=false
mipmaps/limit=-1
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map=0
process/hdr_compression=1
process/flags=1
detect_3d/compress_to=0
'@
}

$script:uidCounter = 0
function Write-Import([string]$path, [string]$type, [string]$template) {
    $script:uidCounter++
    $uid = 'uid://ph' + $script:uidCounter.ToString('x8')
    $content = $template.Replace('__UID__', $uid)
    [System.IO.File]::WriteAllText($path + '.import', $content)
}

# ----------------------------------------------------------------------------
# Palette — 3-tone shading (highlight / midtone / shadow) per color
# ----------------------------------------------------------------------------
$TR = @(0,0,0,0)

# Player boy
$skin    = @(208,172,138,255)
$skinH   = @(232,198,162,255)
$skinS   = @(172,136,104,255)
$hair    = @(52,38,28,255)
$hairH   = @(72,54,38,255)
$coat    = @(58,68,92,255)
$coatH   = @(82,94,118,255)
$coatS   = @(38,46,66,255)
$coatO   = @(26,32,48,255)   # outline
$scarf   = @(128,32,32,255)
$scarfH  = @(168,48,48,255)
$boots   = @(38,32,28,255)
$bootsH  = @(58,48,42,255)
$button  = @(200,180,120,255)

# Lantern
$lantern   = @(218,170,82,255)
$lanternH  = @(248,200,110,255)
$lanternS  = @(170,128,58,255)
$lanternG  = @(255,220,130,255)
$lanternGlow = @(255,200,90,160)

# Monster shadow
$monBody  = @(32,28,42,255)
$monBodyH = @(52,46,68,255)
$monBodyS = @(18,16,26,255)
$monOutline = @(10,8,14,255)
$eye      = @(238,50,42,255)
$eyeGlow  = @(255,80,60,180)
$eyeCore  = @(255,200,180,255)
$wisp     = @(48,42,62,200)

# Merchant ghost
$ghost    = @(142,196,236,120)
$ghostH   = @(182,222,248,160)
$ghostS   = @(96,142,192,100)
$ghostEye = @(200,230,255,200)
$robe     = @(98,92,140,140)

# Bed
$bedFrame  = @(88,62,42,255)
$bedFrameH = @(118,86,58,255)
$bedFrameS = @(58,40,26,255)
$bedSheet  = @(208,210,220,255)
$bedSheetH = @(232,234,242,255)
$bedSheetS = @(178,180,192,255)
$bedPillow = @(236,236,244,255)
$bedPillowS = @(200,200,210,255)
$bedQuilt  = @(128,52,52,255)
$bedQuiltH = @(160,72,72,255)

# Wardrobe
$wardWood  = @(92,62,42,255)
$wardWoodH = @(122,86,58,255)
$wardWoodS = @(62,40,26,255)
$wardWoodD = @(72,48,32,255)
$wardHandle = @(200,176,92,255)
$wardHandleH = @(232,210,130,255)
$wardCarve = @(60,38,24,255)

# Chest
$chestWood  = @(112,78,48,255)
$chestWoodH = @(148,108,68,255)
$chestWoodS = @(78,52,32,255)
$chestWoodD = @(62,42,26,255)
$chestMetal = @(200,176,92,255)
$chestMetalH = @(238,218,130,255)
$chestMetalS = @(160,140,68,255)
$chestLid  = @(96,66,40,255)
$chestLidH = @(132,94,58,255)
$chestInside = @(38,28,18,255)
$chestGlow = @(255,220,100,200)

# Door
$doorWood   = @(104,72,44,255)
$doorWoodH  = @(138,98,62,255)
$doorWoodS  = @(72,48,28,255)
$doorWoodD  = @(56,36,20,255)
$doorHandle = @(200,176,92,255)
$doorHandleH = @(238,218,130,255)
$doorHinge  = @(120,100,60,255)
$doorHingeH = @(160,140,84,255)
$doorOpenBg = @(28,22,16,255)

# Key
$keyMetal   = @(210,184,96,255)
$keyMetalH  = @(242,220,140,255)
$keyMetalS  = @(168,144,68,255)
$keyOutline = @(90,74,38,255)

# Food items
$apple     = @(192,50,48,255)
$appleH    = @(228,88,80,255)
$appleS    = @(148,32,32,255)
$appleLeaf = @(80,140,60,255)
$appleStem = @(90,70,40,255)

$cookie    = @(186,138,78,255)
$cookieH   = @(214,166,104,255)
$cookieS   = @(144,104,58,255)
$chipD     = @(104,72,42,255)
$chipL     = @(156,200,120,255)

$cheese    = @(228,196,82,255)
$cheeseH   = @(246,220,110,255)
$cheeseS   = @(188,160,64,255)
$cheeseHole = @(180,148,54,255)

$pie       = @(196,158,108,255)
$pieH      = @(222,184,132,255)
$pieS      = @(160,124,80,255)
$pieLattice = @(232,200,148,255)
$pieLatticeS = @(192,158,118,255)
$piePan    = @(140,140,148,255)

# Oil flask
$oilGlow   = @(220,190,100,255)
$oilGlowH  = @(248,222,140,255)
$oilGlass  = @(180,200,210,180)
$oilGlassH = @(210,228,238,220)
$oilCap    = @(120,100,60,255)
$oilCapH   = @(160,140,90,255)
$oilShadow = @(100,140,80,200)

# Coin
$coin      = @(240,200,68,255)
$coinH     = @(255,228,120,255)
$coinS     = @(196,160,48,255)
$coinEdge  = @(160,128,40,255)
$coinShine = @(255,248,200,255)

# HUD
$hudLantern   = @(220,170,82,255)
$hudLanternH  = @(248,210,130,255)
$hudLanternS  = @(170,128,58,255)
$hudLanternFlame = @(255,140,50,255)
$hudEnergy    = @(80,200,120,255)
$hudEnergyH   = @(130,240,160,255)
$hudEnergyS   = @(50,160,90,255)
$hudEnergyLow = @(220,200,80,255)
$hudCoin      = @(240,200,68,255)
$hudCoinH     = @(255,228,120,255)
$hudCoinS     = @(180,148,48,255)

# ----------------------------------------------------------------------------
# Sprite drawers
# ----------------------------------------------------------------------------

function Draw-Player([string]$pose) {
    $b = New-Canvas

    if ($pose -eq 'hide') {
        # Crouched player — compressed, knees bent
        # Head
        Fill-CircleAA $b 16 16 5 $skin
        Fill-CircleAA $b 14 14 1 $skinH
        # Hair on top
        Fill-Rect $b 11 10 21 13 $hair
        Fill-Rect $b 12 14 20 14 $hairH
        # Scarf
        Fill-Rect $b 11 19 21 21 $scarf
        Fill-Rect $b 11 19 21 19 $scarfH
        # Body (compressed coat)
        Fill-Rect $b 11 21 21 27 $coat
        Fill-Rect $b 11 21 21 22 $coatH
        # Buttons
        Set-Px $b 16 23 $button
        Set-Px $b 16 25 $button
        # Arms hanging down
        Fill-Rect $b 9 21 11 27 $coat
        Set-Px $b 9 21 $coatH
        Fill-Rect $b 21 21 23 27 $coat
        Set-Px $b 21 21 $coatH
        # Boot tips
        Fill-Rect $b 12 27 15 28 $boots
        Fill-Rect $b 17 27 20 28 $boots
        Set-Px $b 12 28 $bootsH
        Set-Px $b 17 28 $bootsH
        # Lantern on the ground
        Fill-CircleAA $b 24 26 2 $lantern
        Set-Px $b 24 25 $lanternH
        Outline-Shape $b $coatO
        return $b
    }

    # standing player
    # Head shape
    Fill-CircleAA $b 16 8 4 $skin
    # Cheek highlight
    Fill-CircleAA $b 14 9 1 $skinH
    Fill-CircleAA $b 18 9 1 $skinH
    # Hair on top and sides
    Fill-Rect $b 12 4 20 7 $hair
    Fill-Rect $b 12 4 13 8 $hairH
    Set-Px $b 12 5 $hair; Set-Px $b 19 4 $hair; Set-Px $b 20 5 $hair
    # Eyes (small dark dots)
    Set-Px $b 14 8 @(48,36,28,255)
    Set-Px $b 18 8 @(48,36,28,255)
    Set-Px $b 14 9 @(72,54,42,255)
    Set-Px $b 18 9 @(72,54,42,255)
    # Mouth
    Set-Px $b 15 10 @(120,80,60,255)
    Set-Px $b 16 10 @(120,80,60,255)
    Set-Px $b 17 10 @(120,80,60,255)
    # Scarf/collar
    Fill-Rect $b 12 11 20 12 $scarf
    Fill-Rect $b 12 11 20 11 $scarfH
    Set-Px $b 13 12 $scarf
    Set-Px $b 19 12 $scarf
    # Coat body
    Fill-Rect $b 11 12 21 24 $coat
    # Coat highlights (left side lighter — simulate light from upper-left)
    Fill-Rect $b 11 12 12 22 $coatH
    Set-Px $b 11 23 $coatH
    # Coat shadows (right side darker)
    Fill-Rect $b 20 12 21 22 $coatS
    Fill-Rect $b 11 23 21 24 $coatS
    # Button line
    Set-Px $b 16 15 $button
    Set-Px $b 16 18 $button
    Set-Px $b 16 21 $button
    # Belt
    Fill-Rect $b 11 22 21 22 $boots
    Set-Px $b 11 22 $bootsH
    Set-Px $b 21 22 $bootsH
    # Arms
    Fill-Rect $b 9 13 11 21 $coat
    Fill-Rect $b 9 13 9 20 $coatH
    Fill-Rect $b 21 13 23 21 $coat
    Fill-Rect $b 23 13 23 20 $coatS
    # Hand
    Set-Px $b 10 21 $skin
    Set-Px $b 22 21 $skin
    Set-Px $b 10 20 $skinS
    Set-Px $b 22 20 $skinS

    if ($pose -eq 'walk1') {
        # Left leg forward, right back
        Fill-Rect $b 12 24 15 28 $coatS
        Set-Px $b 12 24 $coat
        Fill-Rect $b 13 28 15 29 $boots
        Set-Px $b 13 28 $bootsH
        Fill-Rect $b 18 24 20 27 $coatS
        Fill-Rect $b 17 27 19 28 $boots
        Set-Px $b 17 27 $bootsH
    } elseif ($pose -eq 'walk2') {
        # Right leg forward, left back
        Fill-Rect $b 17 24 20 28 $coatS
        Set-Px $b 20 24 $coat
        Fill-Rect $b 18 28 20 29 $boots
        Set-Px $b 18 28 $bootsH
        Fill-Rect $b 12 24 14 27 $coatS
        Fill-Rect $b 13 27 15 28 $boots
        Set-Px $b 13 27 $bootsH
    } else {
        # idle: legs together
        Fill-Rect $b 12 24 15 28 $coatS
        Fill-Rect $b 17 24 20 28 $coatS
        Set-Px $b 12 24 $coat
        Set-Px $b 20 24 $coat
        Fill-Rect $b 12 28 15 29 $boots
        Fill-Rect $b 17 28 20 29 $boots
        Set-Px $b 12 28 $bootsH
        Set-Px $b 17 28 $bootsH
    }

    # Lantern in right hand
    Fill-CircleAA $b 23 22 2 $lantern
    Set-Px $b 22 21 $lanternH
    Set-Px $b 23 23 $lanternS
    # Lantern handle on top
    Set-Px $b 23 19 $lanternS
    Set-Px $b 22 19 $lanternS
    Set-Px $b 24 19 $lanternS
    # Inner glow
    Set-Px $b 23 22 $lanternG

    Outline-Shape $b $coatO
    return $b
}

function Draw-Monster([int]$frame) {
    $b = New-Canvas

    # Wispy tendril body (ragged bottom, tapering)
    # Core body shape — wider near top, ragged wisps at bottom
    Fill-CircleAA $b 16 8 5 $monBody
    Fill-Rect $b 10 7 22 22 $monBody
    # Highlight (left side, subtle)
    Fill-CircleAA $b 13 7 2 $monBodyH
    Fill-Rect $b 10 8 12 20 $monBodyH
    # Shadow (right side, darker)
    Fill-Rect $b 20 7 22 22 $monBodyS
    Fill-Rect $b 10 22 22 24 $monBodyS

    # Ragged bottom edges — wisp-like tendrils
    for ($x = 10; $x -le 22; $x += 2) {
        $h = 23 + ($x % 4)
        VLine $b $x 23 $h $monBodyS
        if ($x % 3 -eq 0) { Set-Px $b $x ($h + 1) $wisp }
    }

    # Eyes — glowing, with halo
    # Left eye
    Fill-CircleAA $b 13 8 2 $eye
    Set-Px $b 12 7 $eyeGlow
    Set-Px $b 14 7 $eyeGlow
    Set-Px $b 12 9 $eyeGlow
    Set-Px $b 14 9 $eyeGlow
    Set-Px $b 13 8 $eyeCore
    # Right eye
    Fill-CircleAA $b 19 8 2 $eye
    Set-Px $b 18 7 $eyeGlow
    Set-Px $b 20 7 $eyeGlow
    Set-Px $b 18 9 $eyeGlow
    Set-Px $b 20 9 $eyeGlow
    Set-Px $b 19 8 $eyeCore

    # Mouth — jagged grin
    Fill-Rect $b 12 12 20 13 $monBodyS
    Set-Px $b 12 12 $eyeCore
    Set-Px $b 16 12 $eyeCore
    Set-Px $b 20 12 $eyeCore

    if ($frame -eq 2) {
        # Sway: body leans right, eyes squint
        Fill-Rect $b 10 6 22 7 $monBody
        Fill-CircleAA $b 18 8 4 $monBody
        # Move eyes to the left more
        Set-Px $b 12 12 $eye
        Set-Px $b 14 12 $eye
        Set-Px $b 18 12 $eye
        Set-Px $b 20 12 $eye
        Set-Px $b 12 7 $wisp
        Set-Px $b 11 8 $wisp
        Set-Px $b 22 7 $wisp
        Set-Px $b 23 8 $wisp
    }

    # Subtle outline
    Outline-Shape $b $monOutline
    return $b
}

function Draw-Merchant {
    $b = New-Canvas

    # Ghost body — semi-transparent, floating
    # Upper rounded part
    Fill-CircleAA $b 16 10 5 $ghost
    Fill-Rect $b 11 10 21 24 $ghost
    # Highlight on upper-left
    Fill-CircleAA $b 13 8 2 $ghostH
    # Shadow on right
    Fill-Rect $b 19 10 21 22 $ghostS
    Fill-Rect $b 11 22 21 24 $ghostS

    # Ghost wisp bottom
    for ($x = 11; $x -le 21; $x += 2) {
        $h = 24 + ($x % 3)
        VLine $b $x 24 $h $ghostS
        if ($x % 4 -eq 0) { Set-Px $b $x ($h + 1) $ghost }
    }

    # Eyes — ghostly blue
    Fill-CircleAA $b 13 9 1 $ghostEye
    Fill-CircleAA $b 19 9 1 $ghostEye
    Set-Px $b 13 8 @(100,132,180,255)
    Set-Px $b 19 8 @(100,132,180,255)

    # Mouth — small "o" shape (whispering)
    Set-Px $b 15 12 $ghostS
    Set-Px $b 16 12 $ghostS
    Set-Px $b 17 12 $ghostS
    Set-Px $b 16 13 $ghostS

    # Robe — vertical fold lines
    VLine $b 14 14 24 $robe
    VLine $b 16 14 24 $robe
    VLine $b 18 14 24 $robe
    # Hem line
    Fill-Rect $b 11 22 21 23 $robe

    # Soft glow halo
    for ($x = 9; $x -le 22; $x++) {
        Px-Alpha $b $x 4 $ghostH 40
        Px-Alpha $b $x 27 $ghostH 30
    }

    return $b
}

function Draw-Bed {
    $b = New-Canvas
    # Bed frame (oak wood)
    Fill-Rect $b 3 10 28 28 $bedFrame
    Fill-Rect $b 3 10 28 11 $bedFrameH
    Fill-Rect $b 3 27 28 28 $bedFrameS
    # Frame legs
    Fill-Rect $b 3 28 5 31 $bedFrameS
    Fill-Rect $b 26 28 28 31 $bedFrameS

    # Mattress / sheet
    Fill-Rect $b 6 12 25 22 $bedSheet
    Fill-Rect $b 6 12 25 13 $bedSheetH
    # Sheet seam line
    HLine $b 6 25 20 $bedSheetS

    # Quilt (lower 1/3 of bed)
    Fill-Rect $b 6 20 25 26 $bedQuilt
    Fill-Rect $b 6 20 25 21 $bedQuiltH
    # Quilt diamond pattern
    for ($x = 8; $x -le 23; $x += 4) {
        Set-Px $b $x 22 $bedSheetS
        Set-Px $b $x 24 $bedSheetS
    }
    HLine $b 6 25 20 $bedQuiltH

    # Pillow
    Fill-Rect $b 7 12 16 15 $bedPillow
    Fill-Rect $b 7 12 16 12 $bedPillowS
    HLine $b 7 15 16 15 $bedPillowS
    Set-Px $b 8 13 $bedSheetH
    Set-Px $b 12 14 $bedSheetH
    Set-Px $b 15 13 $bedSheetH

    # Headboard post at top
    Fill-Rect $b 3 6 5 10 $bedFrame
    Fill-Rect $b 3 6 4 9 $bedFrameH
    Fill-Rect $b 26 6 28 10 $bedFrame
    Fill-Rect $b 26 6 27 9 $bedFrameH

    Outline-Shape $b $bedFrameS
    return $b
}

function Draw-Wardrobe {
    $b = New-Canvas
    # Outer frame
    Fill-Rect $b 7 2 24 30 $wardWood
    # Left door
    Fill-Rect $b 8 3 15 27 $wardWoodH
    Fill-Rect $b 8 3 9 27 $wardWoodH
    Fill-Rect $b 14 3 15 27 $wardWoodS
    # Right door
    Fill-Rect $b 16 3 23 27 $wardWoodH
    Fill-Rect $b 16 3 17 27 $wardWoodH
    Fill-Rect $b 22 3 23 27 $wardWoodS
    # Rectangular shadows on door bottoms
    VLine $b 8 28 29 $wardWoodD
    VLine $b 15 3 27 $wardWood
    VLine $b 16 3 27 $wardWoodS

    # Carved panel insets on left door
    Fill-Rect $b 9 6 14 12 $wardCarve
    Fill-Rect $b 9 6 14 7 $wardWoodD
    Fill-Rect $b 9 15 14 21 $wardCarve
    Fill-Rect $b 9 15 14 16 $wardWoodD
    # Carved panel insets on right door
    Fill-Rect $b 17 6 22 12 $wardCarve
    Fill-Rect $b 17 6 22 7 $wardWoodD
    Fill-Rect $b 17 15 22 21 $wardCarve
    Fill-Rect $b 17 15 22 16 $wardWoodD

    # Top crown molding
    Fill-Rect $b 6 2 25 3 $wardWoodS
    HLine $b 6 25 2 $wardWoodD
    Fill-Rect $b 6 4 25 5 $wardWood
    HLine $b 6 25 4 $wardCarve

    # Bottom baseboard
    Fill-Rect $b 6 28 25 29 $wardWoodS
    Fill-Rect $b 6 30 25 31 $wardWoodD
    HLine $b 6 25 29 $wardCarve

    # Handles (ornate round pulls)
    Fill-CircleAA $b 14 16 1 $wardHandle
    Fill-CircleAA $b 17 16 1 $wardHandle
    Set-Px $b 14 15 $wardHandleH
    Set-Px $b 17 15 $wardHandleH
    Set-Px $b 14 17 $wardHandle
    Set-Px $b 17 17 $wardHandle

    Outline-Shape $b $wardWoodS
    return $b
}

function Draw-Chest([bool]$open) {
    $b = New-Canvas

    if ($open) {
        # Open chest — show inside with glow
        # Back walls of chest (inside)
        Fill-Rect $b 5 8 26 24 $chestInside
        # Gold/glow inside
        Fill-CircleAA $b 16 14 4 $chestGlow
        Fill-Rect $b 8 12 24 16 $chestGlow
        Set-Px $b 12 14 @(255,240,160,255)
        Set-Px $b 20 14 @(255,240,160,255)
        Set-Px $b 16 12 @(255,255,200,255)
        # Inside rim (darker)
        Outline-Rect $b 5 8 26 24 @(48,38,28,255)
        HLine $b 5 26 24 $chestWoodD
        # Lid open (hinging from back, top edge visible)
        Fill-Rect $b 5 4 26 8 $chestLid
        Fill-Rect $b 5 4 26 5 $chestLidH
        Fill-Rect $b 5 7 26 8 $chestWoodS
        # Lid hinge
        Fill-Rect $b 5 7 6 8 $chestMetal
        Fill-Rect $b 25 7 26 8 $chestMetal
        # Metal bands on lid
        VLine $b 10 4 7 $chestMetal
        VLine $b 21 4 7 $chestMetal
        # Wood plank lines on lid
        HLine $b 5 6 26 6 $chestWoodS
        HLine $b 5 5 26 5 $chestLid
        # Chest body (front)
        Fill-Rect $b 5 18 26 24 $chestWood
        Fill-Rect $b 5 18 26 19 $chestWoodH
        Fill-Rect $b 5 23 26 24 $chestWoodS
        Outline-Shape $b $chestWoodS
        return $b
    }

    # Closed chest
    # Body
    Fill-Rect $b 5 14 26 26 $chestWood
    Fill-Rect $b 5 14 26 15 $chestWoodH
    Fill-Rect $b 5 24 26 26 $chestWoodS
    # Wood plank detail
    HLine $b 5 20 26 20 $chestWoodS
    Set-Px $b 8 20 $chestWood
    Set-Px $b 16 20 $chestWood
    Set-Px $b 24 20 $chestWood
    # Right side shadow
    VLine $b 25 14 26 $chestWoodS

    # Lid
    Fill-Rect $b 5 10 26 15 $chestLid
    Fill-Rect $b 5 10 26 11 $chestLidH
    Fill-Rect $b 5 14 26 15 $chestWoodS
    # Lid curve (arched)
    Fill-Rect $b 6 10 25 10 $chestLid
    Set-Px $b 5 11 $chestWood
    Set-Px $b 27 11 $chestWood

    # Metal bands (vertical, on corners)
    VLine $b 5 10 26 $chestMetal
    VLine $b 26 10 26 $chestMetal
    # Metal band highlight
    VLine $b 5 10 15 $chestMetalH
    VLine $b 26 10 15 $chestMetalH
    # Horizontal band across lid
    HLine $b 5 12 26 12 $chestMetal
    VLine $b 5 12 12 $chestMetalS
    VLine $b 26 12 12 $chestMetalS

    # Lock plate (center)
    Fill-Rect $b 13 16 18 20 $chestMetal
    Fill-Rect $b 13 16 18 17 $chestMetalH
    Fill-Rect $b 13 19 18 20 $chestMetalS
    # Keyhole
    Fill-Rect $b 15 17 17 18 $chestInside
    Set-Px $b 16 18 $chestInside
    Set-Px $b 16 19 $chestInside

    # Corner studs (rivets)
    $rx = @(8, 24)
    $ry = @(13, 22)
    foreach ($cx in $rx) {
        foreach ($cy in $ry) {
            Set-Px $b $cx $cy $chestMetalH
            Set-Px $b ($cx + 1) $cy $chestMetalS
        }
    }

    Outline-Shape $b $chestWoodS
    return $b
}

function Draw-Door([bool]$open) {
    $b = New-Canvas

    if ($open) {
        # Open door — dark doorway
        Fill-Rect $b 11 1 21 30 $doorOpenBg
        # Door visible from the side (opened inward)
        Fill-Rect $b 8 2 11 30 $doorWood
        Fill-Rect $b 8 2 9 30 $doorWoodH
        Fill-Rect $b 10 2 11 30 $doorWoodS
        # Handle on door side
        Fill-CircleAA $b 10 16 1 $doorHandle
        Set-Px $b 10 15 $doorHandleH
        # Hinges visible
        Fill-Rect $b 11 6 12 8 $doorHinge
        Fill-Rect $b 11 22 12 24 $doorHinge
        Set-Px $b 11 6 $doorHingeH
        Set-Px $b 11 22 $doorHingeH
        # Dark frame
        VLine $b 21 1 30 @(18,14,10,255)
        VLine $b 11 1 30 $doorWoodD
        Outline-Shape $b $doorWoodS
        return $b
    }

    # Closed door
    # Frame/door body
    Fill-Rect $b 11 1 21 30 $doorWood
    # Highlight on left (light from upper-left)
    Fill-Rect $b 11 1 12 30 $doorWoodH
    VLine $b 11 1 30 $doorWoodH
    # Shadow on right
    Fill-Rect $b 20 1 21 30 $doorWoodS
    VLine $b 21 1 30 $doorWoodS
    # Bottom shadow
    Fill-Rect $b 11 28 21 30 $doorWoodS

    # Wood plank lines (vertical seams)
    VLine $b 14 4 28 $doorWoodD
    VLine $b 18 4 28 $doorWoodD
    Set-Px $b 14 4 $doorWood
    Set-Px $b 18 4 $doorWood

    # Top arch
    Fill-CircleAA $b 16 4 3 $doorWood
    Fill-Rect $b 11 1 21 3 $doorWood
    Fill-CircleAA $b 14 3 1 $doorWoodH

    # Cross-brace (horizontal, near top and bottom)
    HLine $b 11 8 21 8 $doorWoodD
    HLine $b 11 22 21 22 $doorWoodD
    HLine $b 11 9 21 9 $doorWood
    HLine $b 11 23 21 23 $doorWood

    # Hinges (left side)
    Fill-Rect $b 10 6 13 8 $doorHinge
    Fill-Rect $b 10 6 11 8 $doorHingeH
    Fill-Rect $b 10 22 13 24 $doorHinge
    Fill-Rect $b 10 22 11 24 $doorHingeH
    # Rivets on hinges
    Set-Px $b 11 7 $doorHandle
    Set-Px $b 12 7 $doorHandleH
    Set-Px $b 11 23 $doorHandle
    Set-Px $b 12 23 $doorHandleH

    # Handle/lock plate (right side, center)
    Fill-Rect $b 17 14 19 18 $doorHandle
    Fill-Rect $b 17 14 19 15 $doorHandleH
    Fill-Rect $b 17 17 19 18 $chestMetalS
    # Knob
    Fill-CircleAA $b 18 16 1 $doorHandle
    Set-Px $b 18 15 $doorHandleH
    Set-Px $b 18 17 $chestMetalS
    # Keyhole under handle
    Set-Px $b 18 19 $doorWoodD
    Set-Px $b 18 20 $doorWoodD

    Outline-Shape $b $doorWoodD
    return $b
}

function Draw-Key {
    $b = New-Canvas
    # Key bow (round handle ring)
    Fill-CircleAA $b 12 9 4 $keyMetal
    Fill-CircleAA $b 11 8 1 $keyMetalH
    # Inner hole
    Fill-CircleAA $b 12 9 2 $TR
    Set-Px $b 12 6 $keyMetalS
    Set-Px $b 12 12 $keyMetalS
    Set-Px $b 9 9 $keyMetalS
    Set-Px $b 15 9 $keyMetalS
    # Engraved ring detail
    Fill-CircleOutline $b 12 9 3 $keyMetalS
    Set-Px $b 12 6 $keyMetal
    Set-Px $b 12 12 $keyMetal
    Set-Px $b 9 9 $keyMetal
    Set-Px $b 15 9 $keyMetal
    # Shaft
    Fill-Rect $b 15 8 26 11 $keyMetal
    Fill-Rect $b 15 8 26 8 $keyMetalH
    Fill-Rect $b 15 11 26 11 $keyMetalS
    # Key teeth (bit)
    Fill-Rect $b 22 11 24 14 $keyMetal
    Fill-Rect $b 24 11 25 14 $keyMetalS
    Fill-Rect $b 18 11 20 13 $keyMetal
    Fill-Rect $b 18 11 19 13 $keyMetalS
    # Shaft tip
    Fill-Rect $b 25 8 26 11 $keyMetalS
    Set-Px $b 26 8 $keyMetalS
    Set-Px $b 26 11 $keyMetalS
    # Ornate detail on bow
    Set-Px $b 10 8 $keyMetalH
    Set-Px $b 13 10 $keyMetalH
    Set-Px $b 11 7 $keyMetalH
    Outline-Shape $b $keyOutline
    return $b
}

function Draw-Item([string]$kind) {
    $b = New-Canvas
    switch ($kind) {
        'apple' {
            # Apple body with shading
            Fill-CircleAA $b 16 18 7 $apple
            Fill-CircleAA $b 13 16 3 $appleH
            Fill-Rect $b 9 22 23 24 $appleS
            # Stem
            Fill-Rect $b 16 9 17 12 $appleStem
            Fill-Rect $b 16 9 16 11 $apple
            # Leaf
            Fill-Rect $b 13 8 16 9 $appleLeaf
            Fill-Rect $b 12 9 13 10 $appleLeaf
            Set-Px $b 12 10 @(58,100,42,255)
            Set-Px $b 13 8 @(110,180,80,255)
            # Highlight shine
            Set-Px $b 12 15 @(255,220,210,255)
            Set-Px $b 13 15 @(255,180,170,255)
            Set-Px $b 12 16 @(242,124,116,255)
        }
        'cookie' {
            # Cookie circle
            Fill-CircleAA $b 16 17 7 $cookie
            Fill-CircleAA $b 13 15 3 $cookieH
            Fill-Rect $b 9 21 23 23 $cookieS
            # Chocolate chips
            Set-Px $b 12 15 $chipD
            Set-Px $b 13 14 $chipD
            Set-Px $b 18 18 $chipD
            Set-Px $b 19 17 $chipD
            Set-Px $b 14 20 $chipD
            Set-Px $b 15 19 $chipD
            Set-Px $b 20 14 $chipD
            Set-Px $b 21 16 $chipD
            # Small chip highlights
            Set-Px $b 12 14 $chipL
            Set-Px $b 18 17 $chipL
            Set-Px $b 14 18 $chipL
        }
        'cheese' {
            # Cheese wedge (triangle pointing left)
            for ($y = 16; $y -le 26; $y++) {
                $xMax = [int](10 + ($y - 16) * 1.4)
                HLine $b 9 $xMax $y $cheese
            }
            # Cheese top
            HLine $b 9 25 16 $cheeseH
            for ($y = 17; $y -le 26; $y++) {
                $xMax = [int](10 + ($y - 16) * 1.4)
                Set-Px $b $xMax $y $cheeseS
                Set-Px $b ($xMax - 1) $y $cheese
            }
            # Holes (swiss cheese)
            Set-Px $b 16 19 $cheeseHole
            Set-Px $b 17 19 $cheeseHole
            Set-Px $b 16 22 $cheeseHole
            Set-Px $b 18 23 $cheeseHole
            Set-Px $b 14 24 $cheeseHole
            Set-Px $b 21 20 $cheeseHole
            Set-Px $b 20 21 $cheeseHole
            # Highlight (top edge)
            HLine $b 9 25 16 $cheeseH
            Set-Px $b 10 17 $cheeseH
            Set-Px $b 11 18 $cheeseH
        }
        'pie' {
            # Pie filling (top crust)
            Fill-Rect $b 7 18 25 26 $pie
            Fill-Rect $b 7 18 25 19 $pieH
            Fill-Rect $b 7 25 25 26 $pieS
            # Lattice pattern on top
            # Diagonal stripes
            for ($i = 0; $i -lt 4; $i++) {
                for ($x = 7; $x -le 25; $x++) {
                    $y1 = 18 + (($x + $i * 2) % 8)
                    if ($y1 -le 24) { Set-Px $b $x $y1 $pieLattice }
                }
            }
            # Cross stripes
            for ($x = 9; $x -le 24; $x += 4) {
                VLine $b $x 18 24 $pieLatticeS
            }
            # Pie pan/metal edge (bottom)
            Fill-Rect $b 6 26 26 27 $piePan
            Fill-Rect $b 6 27 26 28 @(100,100,108,255)
            # Pie crust overlap (raised edge)
            Fill-Rect $b 6 17 26 18 @(212,176,124,255)
            # Highlight on pan
            Set-Px $b 7 26 @(180,180,190,255)
            Set-Px $b 24 26 @(180,180,190,255)
        }
        'oil_s' {
            # Small oil flask
            # Glass body
            Fill-Rect $b 13 11 19 26 $oilGlass
            Fill-Rect $b 13 11 14 26 $oilGlassH
            Fill-Rect $b 19 11 19 26 @(140,160,170,160)
            # Oil glow inside
            Fill-Rect $b 14 16 18 24 $oilGlow
            Fill-Rect $b 14 16 15 24 $oilGlowH
            Fill-Rect $b 17 16 18 24 @(180,150,60,255)
            # Glass shine
            VLine $b 14 12 24 @(232,242,248,255)
            Set-Px $b 14 11 @(232,242,248,255)
            # Cap/cork
            Fill-Rect $b 14 8 18 11 $oilCap
            Fill-Rect $b 14 8 15 11 $oilCapH
            Fill-Rect $b 17 8 18 11 @(90,72,42,255)
            Set-Px $b 16 8 $oilCapH
            # Flask outline
            VLine $b 13 11 26 @(108,128,138,255)
            VLine $b 19 11 26 @(108,128,138,255)
            HLine $b 13 26 19 @(108,128,138,255)
            HLine $b 14 11 18 11 @(108,128,138,255)
            # Glow halo
            Px-Alpha $b 16 27 $oilGlow 100
            Set-Px $b 16 25 @(255,230,140,255)
        }
        'oil_l' {
            # Large oil flask (bigger bottle)
            # Glass body
            Fill-Rect $b 10 10 22 28 $oilGlass
            Fill-Rect $b 10 10 12 28 $oilGlassH
            Fill-Rect $b 21 10 22 28 @(130,150,164,160)
            # Oil glow inside
            Fill-Rect $b 12 15 20 26 $oilGlow
            Fill-Rect $b 12 15 13 26 $oilGlowH
            Fill-Rect $b 19 15 20 26 @(180,150,60,255)
            # Glass shine
            VLine $b 12 11 26 @(232,242,248,255)
            Set-Px $b 12 10 @(232,242,248,255)
            Set-Px $b 13 10 @(232,242,248,255)
            # Cap/cork
            Fill-Rect $b 13 6 19 10 $oilCap
            Fill-Rect $b 13 6 14 10 $oilCapH
            Fill-Rect $b 18 6 19 10 @(90,72,42,255)
            # Neck of flask
            Fill-Rect $b 13 10 19 12 $oilGlass
            Fill-Rect $b 12 12 20 13 $oilGlass
            # Flask outline
            Outline-Shape $b @(108,128,138,255)
            # Glow halo
            Set-Px $b 16 28 @(255,210,100,255)
            Px-Alpha $b 15 28 $oilGlow 200
            Px-Alpha $b 17 28 $oilGlow 200
        }
        'coin' {
            # Gold coin
            Fill-CircleAA $b 16 16 8 $coin
            Fill-CircleAA $b 13 14 3 $coinH
            Fill-Rect $b 8 22 24 24 $coinS
            # Inner ring (engraved detail)
            Fill-CircleOutline $b 16 16 5 $coinEdge
            # Star/symbol in center
            Set-Px $b 16 15 $coinEdge
            Set-Px $b 15 16 $coinEdge
            Set-Px $b 17 16 $coinEdge
            Set-Px $b 16 17 $coinEdge
            Fill-CircleAA $b 16 16 1 $coinShine
            # Edge highlight
            Set-Px $b 10 14 $coinH
            Set-Px $b 10 15 $coinH
            Set-Px $b 11 12 $coinH
            Set-Px $b 21 20 $coinS
            Set-Px $b 22 18 $coinS
            # Shine
            Set-Px $b 12 14 $coinShine
            Set-Px $b 12 13 @(255,250,220,255)
        }
    }
    return $b
}

function Draw-HUDIcon([string]$kind) {
    $b = New-Canvas
    switch ($kind) {
        'lantern' {
            # Lantern body
            Fill-Rect $b 11 12 21 22 $hudLantern
            Fill-Rect $b 11 12 12 22 $hudLanternH
            Fill-Rect $b 20 12 21 22 $hudLanternS
            # Top cap
            Fill-Rect $b 10 10 22 12 $hudLanternS
            Fill-Rect $b 10 10 22 11 $hudLanternH
            # Handle
            Fill-CircleOutline $b 16 8 2 $hudLanternS
            Set-Px $b 16 10 $hudLanternS
            # Flame inside
            Fill-CircleAA $b 16 17 2 $hudLanternFlame
            Set-Px $b 16 16 @(255,200,80,255)
            Set-Px $b 15 18 @(200,80,40,255)
            Set-Px $b 17 18 @(200,80,40,255)
            Set-Px $b 16 19 @(200,80,40,255)
            # Glass top
            HLine $b 11 12 21 12 $hudLanternS
            HLine $b 11 22 21 22 $hudLanternS
            # Frame bars
            VLine $b 11 13 21 $hudLanternS
            VLine $b 21 13 21 $hudLanternS
            VLine $b 16 13 21 @(138,100,42,255)
            Outline-Shape $b @(90,64,28,255)
        }
        'energy' {
            # Energy bar icon (lightning bolt)
            for ($y = 8; $y -le 25; $y++) {
                $cx = 16
                if ($y -lt 12) { $cx = 14 + ($y - 8) * 0.5 }
                elseif ($y -lt 18) { $cx = 18 - ($y - 12) * 0.5 }
                else { $cx = 14 + ($y - 18) * 0.5 }
                $cx = [int]$cx
                HLine $b ($cx - 3) ($cx + 3) $y $hudEnergy
                if ($y -lt 16) { HLine $b ($cx - 2) ($cx + 2) $y $hudEnergyH }
                else { HLine $b ($cx - 3) ($cx + 3) $y $hudEnergyS }
            }
            # Tip
            Set-Px $b 14 8 $hudEnergyH
            Set-Px $b 15 8 $hudEnergy
            Set-Px $b 17 25 $hudEnergyS
            # Low-energy indicator (bottom red tint)
            Fill-Rect $b 10 24 22 25 $hudEnergyLow
        }
        'coin' {
            # Gold coin HUD icon
            Fill-CircleAA $b 16 16 9 $hudCoin
            Fill-CircleAA $b 13 13 4 $hudCoinH
            Fill-Rect $b 7 22 24 24 $hudCoinS
            # Inner engraved circle
            Fill-CircleOutline $b 16 16 6 @(160,128,40,255)
            # Central symbol
            Set-Px $b 16 15 @(160,128,40,255)
            Set-Px $b 15 16 @(160,128,40,255)
            Set-Px $b 17 16 @(160,128,40,255)
            Set-Px $b 16 17 @(160,128,40,255)
            Set-Px $b 16 18 @(160,128,40,255)
            Set-Px $b 16 14 @(160,128,40,255)
            # Shine dots
            Set-Px $b 11 12 @(255,250,220,255)
            Set-Px $b 20 22 @(180,140,40,255)
        }
    }
    return $b
}

# ----------------------------------------------------------------------------
# Sprites
# ----------------------------------------------------------------------------
Write-PNG 'player_idle.png'   (Draw-Player 'idle')
Write-PNG 'player_walk1.png'  (Draw-Player 'walk1')
Write-PNG 'player_walk2.png'  (Draw-Player 'walk2')
Write-PNG 'player_hide.png'   (Draw-Player 'hide')
Write-PNG 'monster_1.png'     (Draw-Monster 1)
Write-PNG 'monster_2.png'     (Draw-Monster 2)
Write-PNG 'merchant.png'      (Draw-Merchant)
Write-PNG 'bed.png'           (Draw-Bed)
Write-PNG 'wardrobe.png'      (Draw-Wardrobe)
Write-PNG 'chest.png'         (Draw-Chest $false)
Write-PNG 'chest_open.png'    (Draw-Chest $true)
Write-PNG 'door_closed.png'   (Draw-Door $false)
Write-PNG 'door_open.png'     (Draw-Door $true)
Write-PNG 'key.png'           (Draw-Key)
Write-PNG 'item_apple.png'    (Draw-Item 'apple')
Write-PNG 'item_cookie.png'   (Draw-Item 'cookie')
Write-PNG 'item_cheese.png'   (Draw-Item 'cheese')
Write-PNG 'item_pie.png'      (Draw-Item 'pie')
Write-PNG 'item_oil_small.png'(Draw-Item 'oil_s')
Write-PNG 'item_oil_large.png'(Draw-Item 'oil_l')
Write-PNG 'item_coin.png'     (Draw-Item 'coin')
Write-PNG 'hud_lantern.png'   (Draw-HUDIcon 'lantern')
Write-PNG 'hud_energy.png'    (Draw-HUDIcon 'energy')
Write-PNG 'hud_coin.png'      (Draw-HUDIcon 'coin')

# ----------------------------------------------------------------------------
# Tilesets — textured surfaces
# ----------------------------------------------------------------------------
$tWoodBase = @(72,52,36,255);   $tWoodH = @(96,68,46,255);   $tWoodS = @(52,36,24,255);   $tWoodLine = @(40,28,18,255)
$tStoneBase = @(96,96,104,255); $tStoneH = @(124,124,132,255); $tStoneS = @(72,72,80,255); $tStoneCrack = @(48,48,56,255)
$tCorBase = @(82,70,56,255);    $tCorH = @(106,90,72,255);   $tCorS = @(58,48,38,255);    $tCorLine = @(42,34,26,255)
$tBalBase = @(122,138,158,255); $tBalH = @(148,164,182,255); $tBalS = @(98,114,134,255); $tBalLine = @(78,92,112,255)
$tWallBase = @(62,62,72,255);   $tWallH = @(86,86,96,255);   $tWallS = @(42,42,50,255);   $tWallCrack = @(28,28,36,255)
$tWallDBase = @(40,40,50,255);  $tWallDH = @(58,58,68,255);  $tWallDS = @(26,26,34,255);  $tWallDCrack = @(16,16,22,255)


function Draw-WoodTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tWoodBase
    # Three vertical planks
    Fill-Rect $b 0 0 10 31 $tWoodH
    Fill-Rect $b 21 0 31 31 $tWoodS
    # Plank sep lines
    VLine $b 10 0 31 $tWoodLine
    VLine $b 20 0 31 $tWoodLine
    # Wood grain in each plank (wavy horizontal lines)
    for ($y = 2; $y -lt 31; $y += 5) {
        $offsetPhase = [int]([Math]::Sin($y * 0.5) * 1)
        for ($x = 0; $x -lt 31; $x++) {
            if (($x + $y) % 11 -lt 1) {
                Set-Px $b $x ([int]($y + $offsetPhase)) $tWoodS
            }
        }
    }
    # Highlight sheen at top of each plank
    HLine $b 0 9 0 $tWoodH
    HLine $b 11 19 0 $tWoodH
    HLine $b 21 31 0 $tWoodH
    # Knot in first plank
    Fill-CircleAA $b 4 16 1 @(58,40,24,255)
    Set-Px $b 4 16 @(74,52,30,255)
    # Knot in second plank
    Set-Px $b 16 22 @(48,34,20,255)
    Set-Px $b 15 22 @(58,40,24,255)
    # Bottom shadow
    HLine $b 0 31 31 $tWoodLine
    return $b
}

function Draw-StoneTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tStoneBase
    # Cobblestone pattern — irregular blocks
    Fill-Rect $b 0 0 14 14 $tStoneH
    Fill-Rect $b 15 0 31 10 $tStoneS
    Fill-Rect $b 0 15 10 31 $tStoneS
    Fill-Rect $b 11 15 22 22 $tStoneH
    Fill-Rect $b 23 15 31 31 $tStoneS
    # Mortar lines between cobbles
    HLine $b 0 31 14 $tStoneCrack
    VLine $b 14 0 14 $tStoneCrack
    VLine $b 10 15 31 $tStoneCrack
    HLine $b 11 22 22 $tStoneCrack
    VLine $b 22 15 22 $tStoneCrack
    VLine $b 32 10 31 $tStoneCrack
    HLine $b 23 31 22 $tStoneCrack
    # Surface texture — subtle speckle dots
    Set-Px $b 4 6 @(72,72,80,255)
    Set-Px $b 8 3 @(108,108,116,255)
    Set-Px $b 17 5 @(84,84,92,255)
    Set-Px $b 26 4 @(108,108,116,255)
    Set-Px $b 5 18 @(92,92,100,255)
    Set-Px $b 15 18 @(108,108,116,255)
    Set-Px $b 25 28 @(72,72,80,255)
    Set-Px $b 12 27 @(88,88,96,255)
    # Crack (diagonal)
    Set-Px $b 18 16 $tStoneCrack
    Set-Px $b 19 17 $tStoneCrack
    Set-Px $b 20 18 $tStoneCrack
    Set-Px $b 21 19 $tStoneCrack
    Set-Px $b 22 20 $tStoneCrack
    # Highlight
    Set-Px $b 4 2 $tStoneH
    Set-Px $b 16 17 $tStoneH
    Set-Px $b 24 17 $tStoneH
    # Edge shadow
    HLine $b 0 31 31 $tStoneS
    return $b
}

function Draw-CorridorTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tCorBase
    # Worn wooden floor boards
    Fill-Rect $b 0 0 31 9 $tCorH
    Fill-Rect $b 0 20 31 31 $tCorS
    # Board lines
    HLine $b 0 31 9 $tCorLine
    HLine $b 0 31 20 $tCorLine
    # Vertical seams
    VLine $b 7 0 9 $tCorLine
    VLine $b 16 0 9 $tCorLine
    VLine $b 24 0 9 $tCorLine
    VLine $b 11 10 20 $tCorLine
    VLine $b 22 10 20 $tCorLine
    VLine $b 5 21 31 $tCorLine
    VLine $b 14 21 31 $tCorLine
    VLine $b 25 21 31 $tCorLine
    # Scuff marks
    Set-Px $b 13 4 @(72,62,48,255)
    Set-Px $b 14 4 @(72,62,48,255)
    Set-Px $b 15 4 $tCorH
    Set-Px $b 3 27 @(52,42,32,255)
    Set-Px $b 18 14 @(58,48,38,255)
    # Moss/damp spot
    Set-Px $b 24 28 @(64,72,46,255)
    Set-Px $b 25 28 @(78,84,58,255)
    Set-Px $b 23 29 @(52,60,42,255)
    # Grain detail
    Set-Px $b 3 3 $tCorS
    Set-Px $b 4 6 $tCorS
    Set-Px $b 19 14 $tCorS
    Set-Px $b 20 17 $tCorS
    Set-Px $b 8 24 $tCorS
    return $b
}

function Draw-BalconyTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tBalBase
    # Moonlit stone slabs
    Fill-Rect $b 0 0 15 15 $tBalH
    Fill-Rect $b 16 16 31 31 $tBalH
    Fill-Rect $b 16 0 31 15 $tBalS
    Fill-Rect $b 0 16 15 31 $tBalS
    # Grout lines
    HLine $b 0 31 15 @(88,104,124,255)
    VLine $b 15 0 31 @(88,104,124,255)
    # Tile highlights
    HLine $b 0 14 0 $tBalH
    HLine $b 16 31 16 $tBalH
    VLine $b 0 0 14 $tBalH
    VLine $b 16 16 31 $tBalH
    # Moonlight reflection (top-left)
    Set-Px $b 5 5 @(188,210,230,255)
    Set-Px $b 6 5 @(188,210,230,255)
    Set-Px $b 5 6 @(188,210,230,255)
    Set-Px $b 20 21 @(176,198,218,255)
    Set-Px $b 21 21 @(176,198,218,255)
    Set-Px $b 21 22 @(176,198,218,255)
    # Minor speckles
    Set-Px $b 10 8 @(108,124,144,255)
    Set-Px $b 24 8 @(108,124,144,255)
    Set-Px $b 8 24 @(108,124,144,255)
    Set-Px $b 26 26 @(108,124,144,255)
    # Edge shadow
    HLine $b 0 31 31 @(78,92,112,255)
    return $b
}

function Draw-WallTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tWallBase
    # Brick/block pattern
    # Row 1 (y=0-7)
    Fill-Rect $b 0 0 14 7 $tWallH
    Fill-Rect $b 15 0 31 7 $tWallS
    HLine $b 0 31 7 $tWallCrack
    VLine $b 14 0 7 $tWallCrack
    # Row 2 (y=8-15) — offset bricks
    Fill-Rect $b 0 8 7 15 $tWallS
    Fill-Rect $b 8 8 22 15 $tWallH
    Fill-Rect $b 23 8 31 15 $tWallS
    HLine $b 0 31 15 $tWallCrack
    VLine $b 7 8 15 $tWallCrack
    VLine $b 22 8 15 $tWallCrack
    # Row 3 (y=16-23)
    Fill-Rect $b 0 16 14 23 $tWallH
    Fill-Rect $b 15 16 31 23 $tWallS
    HLine $b 0 31 23 $tWallCrack
    VLine $b 14 16 23 $tWallCrack
    # Row 4 (y=24-31) — offset
    Fill-Rect $b 0 24 7 31 $tWallS
    Fill-Rect $b 8 24 22 31 $tWallH
    Fill-Rect $b 23 24 31 31 $tWallS
    VLine $b 7 24 31 $tWallCrack
    VLine $b 22 24 31 $tWallCrack
    # Stone texture
    Set-Px $b 4 3 $tWallS
    Set-Px $b 10 3 $tWallS
    Set-Px $b 20 3 $tWallH
    Set-Px $b 25 3 $tWallS
    Set-Px $b 4 11 $tWallH
    Set-Px $b 12 11 $tWallS
    Set-Px $b 25 11 $tWallS
    Set-Px $b 4 19 $tWallH
    Set-Px $b 20 19 $tWallS
    Set-Px $b 25 19 $tWallH
    Set-Px $b 4 27 $tWallS
    Set-Px $b 25 27 $tWallS
    # Crack
    Set-Px $b 20 11 $tWallCrack
    Set-Px $b 21 12 $tWallCrack
    Set-Px $b 22 13 $tWallCrack
    # Top highlight
    HLine $b 0 31 0 $tWallH
    # Bottom shadow
    HLine $b 0 31 31 $tWallS
    return $b
}

function Draw-WallDarkTile {
    $b = New-Canvas
    Fill-Rect $b 0 0 31 31 $tWallDBase
    # Same brick layout but darker
    Fill-Rect $b 0 0 14 7 $tWallDH
    Fill-Rect $b 15 0 31 7 $tWallDS
    HLine $b 0 31 7 $tWallDCrack
    VLine $b 14 0 7 $tWallDCrack
    Fill-Rect $b 0 8 7 15 $tWallDS
    Fill-Rect $b 8 8 22 15 $tWallDH
    Fill-Rect $b 23 8 31 15 $tWallDS
    HLine $b 0 31 15 $tWallDCrack
    VLine $b 7 8 15 $tWallDCrack
    VLine $b 22 8 15 $tWallDCrack
    Fill-Rect $b 0 16 14 23 $tWallDH
    Fill-Rect $b 15 16 31 23 $tWallDS
    HLine $b 0 31 23 $tWallDCrack
    VLine $b 14 16 23 $tWallDCrack
    Fill-Rect $b 0 24 7 31 $tWallDS
    Fill-Rect $b 8 24 22 31 $tWallDH
    Fill-Rect $b 23 24 31 31 $tWallDS
    VLine $b 7 24 31 $tWallDCrack
    VLine $b 22 24 31 $tWallDCrack
    # Less texture (it's dark)
    Set-Px $b 4 3 $tWallDS
    Set-Px $b 10 3 $tWallDH
    Set-Px $b 20 3 $tWallDS
    Set-Px $b 4 11 $tWallDS
    Set-Px $b 12 11 $tWallDH
    Set-Px $b 25 11 $tWallDS
    Set-Px $b 4 19 $tWallDS
    Set-Px $b 20 19 $tWallDH
    Set-Px $b 4 27 $tWallDH
    Set-Px $b 25 27 $tWallDS
    # Shadow
    HLine $b 0 31 31 $tWallDS
    # Slight glow at top (residual)
    HLine $b 0 31 0 $tWallDH
    return $b
}

Write-Tile 'floor_wood.png'      (Draw-WoodTile)
Write-Tile 'floor_stone.png'     (Draw-StoneTile)
Write-Tile 'floor_corridor.png'  (Draw-CorridorTile)
Write-Tile 'balcony_floor.png'   (Draw-BalconyTile)
Write-Tile 'wall_stone.png'      (Draw-WallTile)
Write-Tile 'wall_stone_dark.png' (Draw-WallDarkTile)

# ----------------------------------------------------------------------------
# Silent WAV generator (44.1kHz, 16-bit, mono)
# ----------------------------------------------------------------------------
function Write-WAV([string]$name, [double]$seconds, [bool]$loop) {
    $path = Join-Path $audioDir $name
    $sr = 44100
    $ch = 1
    $bits = 16
    $samples = [int]($sr * $seconds)
    $dataBytes = $samples * $ch * ($bits / 8)
    $out = New-Object 'System.Collections.Generic.List[byte]'
    Add-Bytes $out ([byte[]][char[]]'RIFF')
    $chunkSize = 36 + $dataBytes
    Add-Bytes $out (BE $chunkSize 4)
    Add-Bytes $out ([byte[]][char[]]'WAVE')
    Add-Bytes $out ([byte[]][char[]]'fmt ')
    Add-Bytes $out (BE 16 4)
    Add-Bytes $out (BE 1 2)
    Add-Bytes $out (BE $ch 2)
    $byteRate = $sr * $ch * ($bits / 8)
    Add-Bytes $out (BE $byteRate 4)
    $blockAlign = $ch * ($bits / 8)
    Add-Bytes $out (BE $blockAlign 2)
    Add-Bytes $out (BE $bits 2)
    Add-Bytes $out ([byte[]][char[]]'data')
    Add-Bytes $out (BE $dataBytes 4)
    # silent samples (all zeros)
    Add-Bytes $out (New-Object 'byte[]' $dataBytes)
    [System.IO.File]::WriteAllBytes($path, $out.ToArray())

    $loopStr = if ($loop) { 'true' } else { 'false' }
    $import = @"
[gd_resource type="AudioStreamWAV" load_steps=1 format=3 uid="__UID__"]

[params]
loop=$loopStr
loop_offset=0
bpm=0
beat_count=0
bar_beats=4
detect_3d/compress_to=0
"@
    $script:uidCounter++
    $uid = 'uid://ph' + $script:uidCounter.ToString('x8')
    [System.IO.File]::WriteAllText($path + '.import', $import.Replace('__UID__', $uid))
}

Write-WAV 'music_menu.wav'   1.0 $true
Write-WAV 'music_floor.wav'  1.0 $true
Write-WAV 'ambient_rain.wav' 1.0 $true
Write-WAV 'ambient_wind.wav' 1.0 $true
Write-WAV 'ambient_floor.wav' 1.0 $true
Write-WAV 'sfx_footstep_player.wav' 0.2 $false
Write-WAV 'sfx_footstep_monster.wav' 0.2 $false
Write-WAV 'sfx_heartbeat.wav' 0.5 $false
Write-WAV 'sfx_detection.wav' 0.4 $false
Write-WAV 'sfx_pickup.wav' 0.2 $false
Write-WAV 'sfx_lantern_on.wav' 0.15 $false
Write-WAV 'sfx_lantern_off.wav' 0.15 $false
Write-WAV 'sfx_door_open.wav' 0.4 $false
Write-WAV 'sfx_door_lock.wav' 0.3 $false
Write-WAV 'sfx_ui_hover.wav' 0.1 $false
Write-WAV 'sfx_ui_confirm.wav' 0.15 $false
Write-WAV 'sfx_game_over.wav' 0.8 $false

Write-Host "Generated placeholder assets in $assets"
Write-Host "  sprites: $((Get-ChildItem $spritesDir -Filter *.png).Count) png"
Write-Host "  tilesets: $((Get-ChildItem $tilesDir -Filter *.png).Count) png"
Write-Host "  audio: $((Get-ChildItem $audioDir -Filter *.wav).Count) wav"
