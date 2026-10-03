param(
    [Parameter(Mandatory = $true)][string]$SourceDirectory,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [Parameter(Mandatory = $true)][ValidateRange(0, 16777215)][int]$ColorBgr,
    [Parameter(Mandatory = $true)][string]$ResultFile,
    [ValidateSet('Recolor', 'Original')][string]$Mode = 'Recolor'
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

function Write-Result([string[]]$Lines) {
    $temporaryResult = $ResultFile + '.tmp'
    [IO.File]::WriteAllLines($temporaryResult, $Lines, $utf8)
    [IO.File]::Move($temporaryResult, $ResultFile)
}

try {
    $sourceRoot = [IO.Path]::GetFullPath($SourceDirectory).TrimEnd('\')
    $outputRoot = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
    if ($sourceRoot -eq $outputRoot) { throw 'Source and output Images folders must be different.' }
    if (-not [IO.Directory]::Exists($sourceRoot)) { throw "Source folder not found: $sourceRoot" }
    [IO.Directory]::CreateDirectory($outputRoot) | Out-Null
    if ($Mode -eq 'Recolor') {
        Add-Type -AssemblyName System.Drawing
        Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class LibraryStylePng
{
    public static void Recolor(string sourcePath, string targetPath, int bgr)
    {
        using (Bitmap source = new Bitmap(sourcePath))
        using (Bitmap target = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            Rectangle bounds = new Rectangle(0, 0, source.Width, source.Height);
            BitmapData input = source.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try
            {
                BitmapData output = target.LockBits(bounds, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                try
                {
                    byte[] row = new byte[source.Width * 4];
                    for (int y = 0; y < source.Height; y++)
                    {
                        Marshal.Copy(IntPtr.Add(input.Scan0, y * input.Stride), row, 0, row.Length);
                        for (int x = 0; x < row.Length; x += 4)
                        {
                            row[x] = (byte)(bgr >> 16);
                            row[x + 1] = (byte)(bgr >> 8);
                            row[x + 2] = (byte)bgr;
                            // row[x + 3] is the original alpha, including antialiasing.
                        }
                        Marshal.Copy(row, 0, IntPtr.Add(output.Scan0, y * output.Stride), row.Length);
                    }
                }
                finally { target.UnlockBits(output); }
            }
            finally { source.UnlockBits(input); }
            target.Save(targetPath, ImageFormat.Png);
        }
    }
}
'@
    }

    $files = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.png' | Sort-Object Name)
    if ($files.Count -eq 0) { throw "No PNG files found in $sourceRoot" }
    $result = New-Object 'System.Collections.Generic.List[string]'
    $result.Add('OK')
    # Altium TColor is BGR; filenames use ordinary RGB.
    $rgbHex = '{0:X2}{1:X2}{2:X2}' -f ($ColorBgr -band 255), (($ColorBgr -shr 8) -band 255), (($ColorBgr -shr 16) -band 255)
    foreach ($file in $files) {
        if ($Mode -eq 'Original') {
            $name = $file.Name
        }
        else {
            $name = $file.BaseName + '_HEX' + $rgbHex + '.png'
        }
        $targetPath = Join-Path $outputRoot $name
        # Refresh even an existing name: the original pixels may have changed.
        $temporaryImage = $targetPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
        try {
            if ($Mode -eq 'Original') {
                # Restore the exact source bytes, including metadata and transparency.
                [IO.File]::Copy($file.FullName, $temporaryImage)
            }
            else {
                [LibraryStylePng]::Recolor($file.FullName, $temporaryImage, $ColorBgr)
            }
            if ([IO.File]::Exists($targetPath)) {
                [IO.File]::Replace($temporaryImage, $targetPath, [NullString]::Value)
            }
            else {
                [IO.File]::Move($temporaryImage, $targetPath)
            }
        }
        finally {
            if ([IO.File]::Exists($temporaryImage)) { [IO.File]::Delete($temporaryImage) }
        }
        # Alternating name/path lines avoid INI escaping and support spaces and '='.
        $result.Add($file.Name)
        $result.Add($targetPath)
    }
    Write-Result $result.ToArray()
}
catch {
    Write-Result @('ERROR', $_.Exception.ToString())
    exit 1
}
