param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [int]$TargetWidth = 660,
    [int]$TargetHeight = 124
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$sourceFullPath = [System.IO.Path]::GetFullPath($SourcePath)
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not [System.IO.File]::Exists($sourceFullPath)) {
    throw "Source image not found: $sourceFullPath"
}

$outputDirectory = [System.IO.Path]::GetDirectoryName($outputFullPath)
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

if (-not ("CrookedGalaxy.UiPanelProcessor" -as [type])) {
    $drawingAssemblies = @(
        [object].Assembly.Location,
        [System.Drawing.Bitmap].Assembly.Location,
        [System.Drawing.Color].Assembly.Location,
        [System.Drawing.Drawing2D.InterpolationMode].Assembly.Location
    ) + @(
        Get-ChildItem -LiteralPath $PSHOME -Include @(
            "System.Private.Windows*.dll",
            "System.Collections*.dll",
            "System.Runtime*.dll",
            "netstandard.dll"
        ) -File |
            ForEach-Object FullName
    )
    $drawingAssemblies = $drawingAssemblies | Select-Object -Unique
    Add-Type -ReferencedAssemblies $drawingAssemblies -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace CrookedGalaxy
{
    public static class UiPanelProcessor
    {
        private static bool IsExteriorBlack(Color color)
        {
            int maximum = Math.Max(color.R, Math.Max(color.G, color.B));
            int minimum = Math.Min(color.R, Math.Min(color.G, color.B));
            return maximum <= 20 && maximum - minimum <= 5;
        }

        public static void Prepare(string sourcePath, string outputPath, int targetWidth, int targetHeight)
        {
            using (var source = new Bitmap(sourcePath))
            {
                int width = source.Width;
                int height = source.Height;
                var exterior = new bool[width * height];
                var queue = new int[width * height];
                int queueStart = 0;
                int queueEnd = 0;

                Action<int, int> enqueue = (x, y) =>
                {
                    int index = y * width + x;
                    if (exterior[index] || !IsExteriorBlack(source.GetPixel(x, y)))
                        return;
                    exterior[index] = true;
                    queue[queueEnd++] = index;
                };

                for (int x = 0; x < width; x++)
                {
                    enqueue(x, 0);
                    enqueue(x, height - 1);
                }
                for (int y = 0; y < height; y++)
                {
                    enqueue(0, y);
                    enqueue(width - 1, y);
                }

                while (queueStart < queueEnd)
                {
                    int index = queue[queueStart++];
                    int x = index % width;
                    int y = index / width;
                    if (x > 0) enqueue(x - 1, y);
                    if (x + 1 < width) enqueue(x + 1, y);
                    if (y > 0) enqueue(x, y - 1);
                    if (y + 1 < height) enqueue(x, y + 1);
                }

                int left = width;
                int top = height;
                int right = -1;
                int bottom = -1;
                for (int y = 0; y < height; y++)
                {
                    for (int x = 0; x < width; x++)
                    {
                        if (exterior[y * width + x])
                            continue;
                        left = Math.Min(left, x);
                        top = Math.Min(top, y);
                        right = Math.Max(right, x);
                        bottom = Math.Max(bottom, y);
                    }
                }

                if (right < left || bottom < top)
                    throw new InvalidOperationException("No panel pixels remained after exterior extraction.");

                int padding = 2;
                left = Math.Max(0, left - padding);
                top = Math.Max(0, top - padding);
                right = Math.Min(width - 1, right + padding);
                bottom = Math.Min(height - 1, bottom + padding);

                int croppedWidth = right - left + 1;
                int croppedHeight = bottom - top + 1;
                using (var cropped = new Bitmap(croppedWidth, croppedHeight, PixelFormat.Format32bppArgb))
                {
                    for (int y = 0; y < croppedHeight; y++)
                    {
                        for (int x = 0; x < croppedWidth; x++)
                        {
                            int sourceX = left + x;
                            int sourceY = top + y;
                            if (exterior[sourceY * width + sourceX])
                            {
                                cropped.SetPixel(x, y, Color.Transparent);
                                continue;
                            }
                            Color color = source.GetPixel(sourceX, sourceY);
                            cropped.SetPixel(x, y, Color.FromArgb(255, color.R, color.G, color.B));
                        }
                    }

                    using (var output = new Bitmap(targetWidth, targetHeight, PixelFormat.Format32bppArgb))
                    using (var graphics = Graphics.FromImage(output))
                    {
                        graphics.Clear(Color.Transparent);
                        graphics.CompositingMode = CompositingMode.SourceCopy;
                        graphics.CompositingQuality = CompositingQuality.HighQuality;
                        graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                        graphics.SmoothingMode = SmoothingMode.HighQuality;
                        graphics.DrawImage(cropped, new Rectangle(0, 0, targetWidth, targetHeight));
                        output.Save(outputPath, ImageFormat.Png);
                    }
                }
            }
        }
    }
}
'@
}

[CrookedGalaxy.UiPanelProcessor]::Prepare(
    $sourceFullPath,
    $outputFullPath,
    $TargetWidth,
    $TargetHeight
)

$result = [System.Drawing.Bitmap]::FromFile($outputFullPath)
try {
    [pscustomobject]@{
        Output = $outputFullPath
        Width = $result.Width
        Height = $result.Height
        PixelFormat = $result.PixelFormat.ToString()
        CornerAlpha = $result.GetPixel(0, 0).A
    } | Format-List
}
finally {
    $result.Dispose()
}
