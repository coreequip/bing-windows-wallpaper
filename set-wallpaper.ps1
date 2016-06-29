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

Add-Type -Assembly System.Web | Out-Null
$wc = New-Object Net.WebClient
$wc.Encoding = [Text.Encoding]::UTF8

$json = ConvertFrom-Json ($wc.DownloadString('https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1'))
$url = 'http://www.bing.com{0}_1920x1080.jpg' -f $json.images.urlbase

Write-Host ("`n Image copyright: {0}`n URL: {1}" -f $json.images.copyright, $url)

$destPath = $targetPath = Join-Path -Path ([environment]::getfolderpath('mypictures')) -ChildPath 'BingWallpaper'
if (-not (Test-Path $destPath -PathType Container)) {
    New-Item $destPath -ItemType Directory | Out-Null
}
$filename = Join-Path $destPath (New-Object System.Uri $url).Segments[-1]

if (Test-Path $filename -PathType Leaf) {
    Write-Host "`n Already downloaded, exiting."
    exit 1
}

$wc.DownloadFile($url, $filename)
[Wallpaper]::SetWallpaper($filename)