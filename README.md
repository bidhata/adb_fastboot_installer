# Windows ADB & Fastboot Installer Tool

# 🚀 One-Click ADB, Fastboot & Android Driver Installer

Whenever I format my Windows laptop, I somehow end up in the same painful loop:

> **"Time to install ADB and Fastboot… may the odds be ever in your favour."**

Most tools on GitHub look like they were last updated during the Android KitKat era.  
And those random `.exe` installers? Yeah… I'm never fully sure whether they're installing ADB or secretly mining Bitcoin.

So I finally decided: **Enough!**

Introducing my **single-click, open-source ADB, Fastboot, and Android Driver Installer**. 🎉  
It doesn’t just install the tools — it behaves like a civilized piece of software.

## ✅ What It Does
- Downloads ADB & Fastboot **directly from Google**  
- Installs proper Android drivers  
- Automatically sets the **PATH** (goodbye “adb not recognized” 🙏)  
- Configures an **auto-update** using Windows Task Scheduler  
- 100% clean, open-source, and drama-free

If fresh Windows installs keep breaking your ADB setup, this little tool might just save your sanity.

---

**#Android #Tools #ADB #Universal**


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

### Quick Install (One-Line Command)
Run this command in PowerShell (Admin):
```powershell
irm https://raw.githubusercontent.com/bidhata/adb_fastboot_installer/main/Install-AdbTool.ps1 | iex
```

1.  Open PowerShell as **Administrator**.
2.  Navigate to the directory containing the script.
3.  Run the installation command:

### Manual Installation

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



