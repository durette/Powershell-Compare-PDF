Function Compare-TwoPdfs
{
   Param(
      [Parameter(Mandatory = $true)] [String] $PdfFile1,
      [Parameter(Mandatory = $true)] [String] $PdfFile2,
      [Parameter(Mandatory = $true)] [String] $OutputJpg)
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
   [void] [System.Reflection.Assembly]::LoadWithPartialName("System.IO")
   $tempJpeg1 = '1.jpg'
   $tempJpeg2 = '2.jpg'
   $ghostscriptExecutable = 'C:\bin\gswin64c.exe'
   $jpgDpiOption = '-r144'

   $ghostscript_parameters = '-dBATCH', '-dNOPAUSE', '-sDEVICE=jpeg', $jpgDpiOption, "-sOutputFile=$tempJpeg1", $PdfFile1
   & $ghostscriptExecutable $ghostscript_parameters
   $ghostscript_parameters = '-dBATCH', '-dNOPAUSE', '-sDEVICE=jpeg', $jpgDpiOption, "-sOutputFile=$tempJpeg2", $PdfFile2
   & $ghostscriptExecutable $ghostscript_parameters

   # A naive solution would lock the jpeg files.
   # $bitmap1 = New-Object System.Drawing.Bitmap $tempJpeg1
   # $bitmap2 = New-Object System.Drawing.Bitmap $tempJpeg2
   # Instead, read the files into memory first to avoid this.

   $bytes1 = [System.IO.File]::ReadAllBytes($tempJpeg1)
   $memoryStream1 = New-Object System.IO.MemoryStream(, $bytes1)
   $bitmap1 = [System.Drawing.Image]::FromStream($memoryStream1)

   $bytes2 = [System.IO.File]::ReadAllBytes($tempJpeg2)
   $memoryStream2 = New-Object System.IO.MemoryStream(, $bytes2)
   $bitmap2 = [System.Drawing.Image]::FromStream($memoryStream2)

   $bitmapHeight = [Math]::Max($bitmap1.Height, $bitmap2.Height)
   $bitmapWidth = [Math]::Max($bitmap1.Width, $bitmap2.Width)

   $bitmap_diff = New-Object System.Drawing.Bitmap $bitmapWidth, $bitmapHeight

   For ($y = [UInt64] 0; $y -Lt $bitmapHeight; $y += 1)
   {
      For ($x = [UInt64] 0; $x -Lt $bitmapWidth; $x += 1)
      {
         If ($x -Lt $bitmap1.Width -And $y -Lt $bitmap1.Height)
         {
            $pixel1 = $bitmap1.GetPixel($x, $y)
         }
         Else
         {
            $pixel1 = [System.Drawing.Color]::FromArgb(255, 255, 255)
         }

         If ($x -Lt $bitmap2.Width -And $y -Lt $bitmap2.Height)
         {
            $pixel2 = $bitmap2.GetPixel($x, $y)
         }
         Else
         {
            $pixel2 = [System.Drawing.Color]::FromArgb(255, 255, 255)
         }

         # Subtract difference from white. Larger differences will be dark.
         $r = 255 - [Math]::Abs($pixel1.R - $pixel2.R)
         $g = 255 - [Math]::Abs($pixel1.G - $pixel2.G)
         $b = 255 - [Math]::Abs($pixel1.B - $pixel2.B)
         $diff_color = [System.Drawing.Color]::FromArgb($r, $g, $b)
         $bitmap_diff.SetPixel($x, $y, $diff_color)
      }
   }

   $bitmap_diff.Save($OutputJpg, [System.Drawing.Imaging.ImageFormat]::Jpeg)
}

Compare-TwoPdfs -PdfFile1 '1.pdf' -PdfFile2 '2.pdf' -OutputJpg 'out.jpg'
