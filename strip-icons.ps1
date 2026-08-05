# Deletes every icon resource (RT_ICON + RT_GROUP_ICON) from a PE file.
#
# Called by installer.nsi through !packhdr, which hands us the installer's exe
# stub while makensis is still building it - before the data is appended and
# the CRC is computed, so the finished installer stays valid. Uses the Windows
# resource API directly rather than an external editor, and re-checks the file
# afterwards, so a silent failure cannot slip through.

param([Parameter(Mandatory = $true)][string]$Path)

$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class PeRes {
    const uint LOAD_LIBRARY_AS_DATAFILE = 0x00000002;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr LoadLibraryEx(string file, IntPtr reserved, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool FreeLibrary(IntPtr module);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool EnumResourceNames(IntPtr module, IntPtr type, EnumNameProc cb, IntPtr param);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool EnumResourceLanguages(IntPtr module, IntPtr type, IntPtr name, EnumLangProc cb, IntPtr param);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr BeginUpdateResource(string file, bool deleteExisting);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool UpdateResource(IntPtr update, IntPtr type, IntPtr name, ushort lang, IntPtr data, uint cb);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool EndUpdateResource(IntPtr update, bool discard);

    delegate bool EnumNameProc(IntPtr module, IntPtr type, IntPtr name, IntPtr param);
    delegate bool EnumLangProc(IntPtr module, IntPtr type, IntPtr name, ushort lang, IntPtr param);

    public struct Entry {
        public int Type;
        public IntPtr Name;
        public ushort Lang;
        public override string ToString() {
            string n = (Name.ToInt64() >> 16) == 0 ? "#" + Name.ToInt64() : Marshal.PtrToStringUni(Name);
            return (Type == 3 ? "RT_ICON" : "RT_GROUP_ICON") + " " + n + " (lang " + Lang + ")";
        }
    }

    // Icon resources are always numeric ids in practice, so the name pointers
    // stay valid after the module is unloaded; keep them as integers anyway.
    public static List<Entry> List(string file, int[] types) {
        var found = new List<Entry>();
        IntPtr mod = LoadLibraryEx(file, IntPtr.Zero, LOAD_LIBRARY_AS_DATAFILE);
        if (mod == IntPtr.Zero)
            throw new Exception("LoadLibraryEx failed on " + file + ": " + Marshal.GetLastWin32Error());
        try {
            foreach (int t in types) {
                int type = t;
                IntPtr typePtr = new IntPtr(type);
                // EnumResourceNames returns false when the type is absent; that is not an error.
                EnumResourceNames(mod, typePtr, delegate(IntPtr m, IntPtr ty, IntPtr name, IntPtr p) {
                    EnumResourceLanguages(m, ty, name, delegate(IntPtr m2, IntPtr ty2, IntPtr n2, ushort lang, IntPtr p2) {
                        var e = new Entry();
                        e.Type = type; e.Name = name; e.Lang = lang;
                        found.Add(e);
                        return true;
                    }, IntPtr.Zero);
                    return true;
                }, IntPtr.Zero);
            }
        } finally {
            FreeLibrary(mod);
        }
        return found;
    }

    public static void Delete(string file, List<Entry> entries) {
        IntPtr upd = BeginUpdateResource(file, false);
        if (upd == IntPtr.Zero)
            throw new Exception("BeginUpdateResource failed on " + file + ": " + Marshal.GetLastWin32Error());
        foreach (Entry e in entries) {
            // NULL data + zero length deletes the resource.
            if (!UpdateResource(upd, new IntPtr(e.Type), e.Name, e.Lang, IntPtr.Zero, 0)) {
                int err = Marshal.GetLastWin32Error();
                EndUpdateResource(upd, true);
                throw new Exception("UpdateResource failed for " + e + ": " + err);
            }
        }
        if (!EndUpdateResource(upd, false))
            throw new Exception("EndUpdateResource failed on " + file + ": " + Marshal.GetLastWin32Error());
    }
}
"@

# Anything after the last section's raw data is an overlay. EndUpdateResource
# rewrites the image and drops it, so save it and put it back. makensis hands
# us a bare stub with no overlay, but losing appended data silently is the kind
# of bug that only shows up in the finished installer, so don't risk it.
function Get-OverlayStart([byte[]]$bytes) {
    $peOff = [BitConverter]::ToUInt32($bytes, 0x3C)
    if ($bytes[$peOff] -ne 0x50 -or $bytes[$peOff + 1] -ne 0x45) { throw "not a PE file: $Path" }
    $sections = [BitConverter]::ToUInt16($bytes, $peOff + 6)
    $optSize  = [BitConverter]::ToUInt16($bytes, $peOff + 20)
    $table    = $peOff + 24 + $optSize
    $end = 0
    for ($i = 0; $i -lt $sections; $i++) {
        $s   = $table + $i * 40
        $ptr = [BitConverter]::ToUInt32($bytes, $s + 20)
        $siz = [BitConverter]::ToUInt32($bytes, $s + 16)
        if ($ptr -ne 0 -and ($ptr + $siz) -gt $end) { $end = $ptr + $siz }
    }
    return $end
}

$types = @(3, 14)   # RT_ICON, RT_GROUP_ICON

$file = (Resolve-Path -LiteralPath $Path).Path
$before = [PeRes]::List($file, $types)
Write-Host "strip-icons: $file has $($before.Count) icon resource(s)"

if ($before.Count -gt 0) {
    $raw = [IO.File]::ReadAllBytes($file)
    $overlayStart = Get-OverlayStart $raw
    $overlay = if ($raw.Length -gt $overlayStart) { $raw[$overlayStart..($raw.Length - 1)] } else { @() }
    if ($overlay.Count) { Write-Host "  preserving $($overlay.Count) bytes of overlay data" }

    foreach ($e in $before) { Write-Host "  deleting $e" }
    [PeRes]::Delete($file, $before)

    if ($overlay.Count) {
        $fs = [IO.File]::Open($file, 'Append', 'Write')
        try { $fs.Write($overlay, 0, $overlay.Count) } finally { $fs.Dispose() }
    }
}

# Prove it worked rather than trusting the API's return value.
$after = [PeRes]::List($file, $types)
if ($after.Count -ne 0) {
    foreach ($e in $after) { Write-Host "  still present: $e" }
    Write-Error "strip-icons: $($after.Count) icon resource(s) survived in $file"
    exit 1
}
Write-Host "strip-icons: no icon resources left"
exit 0
