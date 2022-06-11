Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
public class Wallpaper {
   [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
   private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
   public static void SetWallpaper(string path) {
      SystemParametersInfo( 0x14, 0, path, 3 );
   }
}
"@

Add-Type -Assembly System.Drawing | Out-Null
Add-Type -Assembly System.Web | Out-Null
$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
# Markets: de-DE / es-XL, see: https://msdn.microsoft.com/de-de/library/dd251064.aspx
$json = ConvertFrom-Json ($wc.DownloadString('https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&mkt=es-XL&n=1'))
$urlLand = 'http://www.bing.com{0}_UHD.jpg' -f $json.images.urlbase
$urlPort = 'http://www.bing.com{0}_1080x1920.jpg' -f $json.images.urlbase

Write-Host ("`n Image copyright: {0}`n URL: {1}" -f $json.images.copyright, $urlLand)

$destPath = $targetPath = Join-Path -Path ([environment]::getfolderpath('mypictures')) -ChildPath 'BingWallpaper'
if (-not (Test-Path $destPath -PathType Container)) {
    New-Item $destPath -ItemType Directory | Out-Null
}
$urlLand -match 'OHR\.([^_]+)' | Out-Null
$filenamePort = Join-Path $destPath "$($Matches[1])_1080x1920.jpg"
$filenameLand = Join-Path $destPath "$($Matches[1])_UHD.jpg"
$filenameComp = Join-Path $destPath '_composited.jpg'

if (-not (Test-Path $filenamePort -PathType Leaf)) {
    $wc.DownloadFile($urlPort, $filenamePort)
}

if (-not (Test-Path $filenameLand -PathType Leaf)) {
    $wc.DownloadFile($urlLand, $filenameLand)
}

$i1 = [System.Drawing.Bitmap]::FromFile($filenameLand)
$i2 = [System.Drawing.Bitmap]::FromFile($filenamePort)

$bmp = New-Object Drawing.Bitmap(5280, 2560, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$cv = [System.Drawing.Graphics]::FromImage($bmp)

# 5280 x 2560 / 3840 x 2160
$cv.DrawImage($i1, 0, 400, 3840, 2160)
$cv.DrawImage($i2, 3840, 0, 1440, 2560)

$bmp.Save($filenameComp, [System.Drawing.Imaging.ImageFormat]::Jpeg)

[Wallpaper]::SetWallpaper($filenameComp)
# [Wallpaper]::SetWallpaper($filenameLand)
