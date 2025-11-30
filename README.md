# Windows ADB & Fastboot Installer Tool

Whenever I format my Windows laptop, I enter the same ancient ritual:
“Thou shall suffer while installing ADB and Fastboot.”

Seriously — every time it’s the same pain. Half the tools on GitHub look like they were last updated when Android KitKat was still cool. And those random .exe installers… bro, I’m never sure if they’re installing ADB or secretly mining Bitcoin in the background.

So I finally snapped.
And made my own single-click, open-source ADB + Fastboot + Android Driver installer. 🎉

✔ Downloads everything directly from Google (no shady files, promise!)
✔ Installs drivers like a grown-up
✔ Sets the PATH automatically (because why should we suffer?)
✔ Even auto-updates itself using Windows Task Scheduler — like a well-trained robot.

If you’ve ever felt the pain of “adb not recognized” after a fresh format… this one’s for you.
Hope it saves your sanity. 😎

#Android #Tools #ADB #Universal

A simple, automated tool to install and maintain the latest Android Platform Tools (ADB, Fastboot) and Google USB Drivers on Windows.

## Features

*   **Automated Installation**: Downloads and installs the latest official binaries from Google.
*   **Driver Setup**: Automatically installs the Google USB Driver for ADB debugging.
*   **System Integration**: Adds ADB and Fastboot to your system `PATH` for easy access from any terminal.
*   **Auto-Updates**: Sets up a daily scheduled task to check for and install updates automatically.

## Requirements

*   Windows 10 or 11
*   PowerShell 5.1 or later
*   **Administrator Privileges** (required for driver installation and setting system PATH)

## Installation

1.  Open PowerShell as **Administrator**.
2.  Navigate to the directory containing the script.
3.  Run the installation command:

    ```powershell
    .\Install-AdbTool.ps1 -Install
    ```

The script will:
*   Create the installation directory at `C:\AdbTool`.
*   Download and extract the latest Platform Tools.
*   Download and install the Google USB Drivers.
*   Add `C:\AdbTool\platform-tools` to your System PATH.
*   Create a scheduled task named `AdbToolAutoUpdate` that runs daily at 3:00 AM.

## Usage

### Verification
After installation, open a **new** terminal window and run:
```powershell
adb --version
```

### Manual Update
To manually check for updates, run:
```powershell
.\Install-AdbTool.ps1 -Update
```

## How it Works
The script compares the `ETag` (a unique identifier) of the remote file on Google's servers with the one stored locally in `C:\AdbTool\version_info.json`. If they differ, it downloads the new version and replaces the old one.

## Uninstallation
To remove the tool:
1.  Delete the `C:\AdbTool` directory.
2.  Remove `C:\AdbTool\platform-tools` from your System Environment Variables.
3.  Delete the `AdbToolAutoUpdate` task from Task Scheduler.

## Author
Krishnendu Paul (@bidhata)

