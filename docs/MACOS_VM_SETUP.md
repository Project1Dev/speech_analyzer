# macOS VM Setup Guide

Complete guide for setting up the macOS virtual machine for iOS development in the Speech Mastery App project.

## Overview

This guide covers:
- Setting up a macOS VM on your host machine
- Installing required development tools
- Cloning the repository
- Generating and configuring the Xcode project
- Connecting to the backend running on Linux VM
- Testing and troubleshooting

## Prerequisites

### Host Machine Requirements

- **Virtualization support**: CPU with VT-x/AMD-V enabled in BIOS
- **RAM**: At least 8GB allocated to macOS VM (16GB recommended)
- **Storage**: 60GB minimum for macOS + Xcode + project
- **Hypervisor**: One of:
  - VMware Workstation/Fusion (recommended for best performance)
  - VirtualBox (free, but slower)
  - QEMU/KVM with macOS patches
  - UTM (macOS host only)

### macOS Image

- **macOS version**: Ventura (13.0) or later
- **ISO/DMG source**: Official Apple installer or pre-built VM image
- Legal note: macOS VM licensing varies by hypervisor and host OS

---

## Part 1: macOS VM Installation

### Option A: VMware Workstation (Recommended)

**Advantages**: Best performance, good macOS support, stable

1. **Download VMware Workstation/Fusion**
   - VMware Workstation Pro (Windows/Linux host)
   - VMware Fusion (macOS host)

2. **Get macOS installer**
   ```bash
   # On a Mac, download macOS installer
   # Then create ISO using Apple's createinstallmedia
   ```

3. **Create new VM**
   - Type: Apple macOS
   - Version: macOS 13 or later
   - Memory: 8GB minimum, 16GB recommended
   - Processors: 4 cores minimum
   - Hard Disk: 60GB minimum (thin provisioned)
   - Network: Bridged (for VM-to-VM communication)

4. **Install macOS**
   - Boot from installer ISO
   - Format disk as APFS
   - Complete macOS setup wizard
   - Create user account

### Option B: VirtualBox

**Advantages**: Free and open-source

1. **Install VirtualBox** and Extension Pack

2. **Create macOS VM**
   ```bash
   # Use scripts like "macOS-Simple-KVM" or manual VirtualBox configuration
   # Configure: 8GB RAM, 4 CPU cores, 60GB disk, Bridged network
   ```

3. **Apply macOS patches**
   - VirtualBox requires additional configuration for macOS
   - Set guest OS type to "macOS 64-bit"
   - Apply VBoxManage commands for macOS compatibility

4. **Install macOS** from recovery or installer image

### Network Configuration

**Critical**: Set network adapter to **Bridged Mode**

This allows the macOS VM to get an IP on the same network as the Linux VM.

- VMware: VM Settings → Network Adapter → Bridged
- VirtualBox: Settings → Network → Attached to: Bridged Adapter

**Verify network**:
```bash
# On macOS VM
ifconfig | grep "inet "
# Should show an IP like 192.168.1.XXX (same subnet as Linux VM)
```

---

## Part 2: Development Tools Installation

### 1. Install Xcode

**From App Store** (easiest):
1. Open App Store app
2. Search for "Xcode"
3. Click "Get" or "Download"
4. Wait for installation (12+ GB download, ~40 GB installed)

**From Apple Developer Portal** (alternative):
1. Visit https://developer.apple.com/download/
2. Sign in with Apple ID
3. Download Xcode .xip file
4. Extract and move to /Applications

### 2. Install Xcode Command Line Tools

```bash
# Install Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
# Expected: /Applications/Xcode.app/Contents/Developer

# Accept license
sudo xcodebuild -license accept
```

### 3. Install Homebrew

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (follow Homebrew's post-install instructions)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify
brew --version
```

### 4. Install XcodeGen

```bash
# Install XcodeGen
brew install xcodegen

# Verify installation
xcodegen --version
# Expected: Version 2.39.0 or later
```

### 5. Install Git (if not already present)

```bash
# Git is usually pre-installed, but verify
git --version

# If not installed
brew install git
```

---

## Part 3: Clone Repository

### 1. Configure Git

```bash
# Set your git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Set default branch name
git config --global init.defaultBranch master
```

### 2. Set up SSH Keys (recommended)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy

# Add to GitHub: Settings → SSH and GPG keys → New SSH key
```

### 3. Clone Repository

```bash
# Navigate to projects directory
cd ~/Documents
mkdir projects
cd projects

# Clone via SSH (recommended)
git clone git@github.com:yourusername/speech_analyzer.git

# Or via HTTPS
git clone https://github.com/yourusername/speech_analyzer.git

# Navigate to project
cd speech_analyzer
```

---

## Part 4: iOS Project Setup

### 1. Generate Xcode Project

```bash
# Navigate to iOS directory
cd ios

# Generate Xcode project from project.yml
xcodegen generate

# Expected output:
# ⚙️  Generating plists...
# ⚙️  Generating project...
# ⚙️  Writing project...
# Created project at ios/SpeechMastery.xcodeproj
```

**If generation fails**:
- Verify `project.yml` exists in `ios/` directory
- Check XcodeGen version: `xcodegen --version`
- Review error messages for missing dependencies

### 2. Open Xcode Project

```bash
# From ios/ directory
open SpeechMastery.xcodeproj

# Or double-click SpeechMastery.xcodeproj in Finder
```

### 3. Configure Signing

In Xcode:

1. **Select project** in navigator (top level "SpeechMastery")
2. **Select target** "SpeechMastery"
3. **Go to "Signing & Capabilities" tab**
4. **Check "Automatically manage signing"**
5. **Select your Team** (create free Apple ID team if needed)

**For free Apple ID**:
- Bundle identifier may need to be unique
- Edit in project.yml: `bundleIdPrefix: com.yourname.speechmastery`
- Re-run `xcodegen generate`

### 4. Select Simulator

In Xcode toolbar:
- Click device selector (next to Play button)
- Choose: iPhone 15 (or any available simulator)
- If no simulators available: Xcode → Window → Devices and Simulators → Add simulator

---

## Part 5: Configure Backend Connection

### 1. Find Linux VM IP Address

**On the Linux VM**, run:

```bash
# Find IP address
hostname -I

# Or more detailed
ip addr show | grep "inet " | grep -v 127.0.0.1

# Example output: 192.168.1.150
```

**Note this IP address** - you'll use it in the next step.

### 2. Update iOS Constants

**On the macOS VM**, edit the API endpoint:

```bash
# Open Constants.swift in Xcode or terminal editor
open ios/SpeechMastery/Utilities/Constants.swift
```

Update the file:

```swift
struct APIConstants {
    // IMPORTANT: Replace with your Linux VM's IP address
    static let baseURL = "http://192.168.1.150:8000"  // ← Change this!

    static let authToken = "SINGLE_USER_DEV_TOKEN_12345"

    // Timeout configuration
    static let requestTimeout: TimeInterval = 30.0
}
```

**Save the file**.

### 3. Verify Backend is Running

**On the Linux VM**, ensure backend is running:

```bash
# Start backend services
docker-compose up -d

# Verify services are running
docker-compose ps

# Check logs
docker-compose logs -f fastapi
```

Expected: Backend listening on port 8000.

### 4. Test Connectivity

**On the macOS VM**, test connection:

```bash
# Ping Linux VM
ping 192.168.1.150

# Test backend endpoint
curl http://192.168.1.150:8000/health

# Expected response:
# {"status":"healthy","version":"1.0.0"}

# Test authenticated endpoint
curl -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
     http://192.168.1.150:8000/recordings

# Expected: [] or list of recordings
```

**If connection fails**, see Troubleshooting section below.

---

## Part 6: Build and Run iOS App

### 1. Build the Project

In Xcode:

1. **Select target**: SpeechMastery
2. **Select simulator**: iPhone 15
3. **Build**: Product → Build (Cmd+B)

**Wait for build to complete**. First build may take a few minutes.

**If build fails**:
- Check error messages in Xcode
- Ensure all Swift files are syntactically correct
- Try: Product → Clean Build Folder (Cmd+Shift+K)
- Re-generate project: `cd ios && xcodegen generate`

### 2. Run the App

1. **Run**: Product → Run (Cmd+R)
2. **Simulator should launch** with the app
3. **Grant microphone permission** when prompted

### 3. Test Recording

1. In the app, tap **"Record"** or the microphone button
2. Allow microphone access (Simulator uses Mac's microphone)
3. Speak for a few seconds
4. Tap **"Stop"**
5. Tap **"Analyze"** to upload to backend

**Expected behavior**:
- Recording saves locally
- Upload progress indicator
- Analysis results display after processing
- Scores and feedback appear

**If upload fails**:
- Check backend is running on Linux VM
- Verify IP address in Constants.swift
- Check network connectivity (see Troubleshooting)

---

## Part 7: Development Workflow

### Daily Workflow

**Starting work**:
```bash
# Pull latest changes
git pull origin master

# Regenerate Xcode project (if project.yml changed)
cd ios
xcodegen generate

# Open project
open SpeechMastery.xcodeproj
```

**Making changes**:
1. Edit Swift files in Xcode
2. Test with Simulator (Cmd+R)
3. Run unit tests (Cmd+U)
4. Iterate

**Committing changes**:
```bash
# Stage changes
git add ios/

# Commit with clear message
git commit -m "feat: Add new analysis visualization view"

# Push to remote
git push origin master
```

### Git Best Practices

- **Pull before starting work**: `git pull origin master`
- **Commit iOS changes separately** from backend changes
- **Use descriptive commit messages**: "feat:", "fix:", "docs:", etc.
- **Push frequently** to keep Linux VM in sync
- **Don't commit generated files**: `.xcodeproj/` is in .gitignore

### Testing Changes

**Unit tests**:
```bash
# Command line
xcodebuild test \
  -scheme SpeechMastery \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: Cmd+U
```

**Integration tests** (with backend):
1. Ensure backend is running on Linux VM
2. Run app in Simulator
3. Test full user flows: Record → Analyze → View Results
4. Check backend logs for API calls

---

## Troubleshooting

### Issue: Cannot reach backend from iOS app

**Symptoms**: Network errors, timeouts, "Could not connect to server"

**Solutions**:

1. **Verify Linux VM IP hasn't changed**
   ```bash
   # On Linux VM
   hostname -I
   ```
   Update Constants.swift if different.

2. **Check firewall on Linux VM**
   ```bash
   # On Linux VM
   sudo ufw status

   # If active, allow port 8000
   sudo ufw allow 8000
   ```

3. **Verify backend is running**
   ```bash
   # On Linux VM
   docker-compose ps
   # FastAPI should show "Up"

   docker-compose logs fastapi
   # Check for errors
   ```

4. **Test from macOS terminal**
   ```bash
   # On macOS VM
   curl http://192.168.1.150:8000/health
   ```
   If this fails, it's a network issue, not an iOS app issue.

5. **Check VM network settings**
   - Both VMs should use **Bridged networking**
   - Both should be on same subnet (e.g., 192.168.1.x)
   - Test ping: `ping <linux-vm-ip>`

### Issue: Xcode project generation fails

**Symptoms**: `xcodegen generate` errors

**Solutions**:

1. **Verify XcodeGen is installed**
   ```bash
   xcodegen --version
   ```

2. **Check project.yml syntax**
   ```bash
   # Validate YAML syntax
   cat ios/project.yml
   ```
   Look for indentation errors.

3. **Clean and retry**
   ```bash
   cd ios
   rm -rf SpeechMastery.xcodeproj
   xcodegen generate
   ```

4. **Update XcodeGen**
   ```bash
   brew upgrade xcodegen
   ```

### Issue: Build fails in Xcode

**Symptoms**: Compilation errors, missing modules

**Solutions**:

1. **Clean build folder**
   - Xcode: Product → Clean Build Folder (Cmd+Shift+K)

2. **Reset package caches**
   - Xcode: File → Packages → Reset Package Caches

3. **Delete derived data**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

4. **Check Swift version**
   - Xcode: Project Settings → Build Settings → Swift Language Version
   - Should be Swift 5.5 or later

5. **Re-generate project**
   ```bash
   cd ios
   rm -rf SpeechMastery.xcodeproj
   xcodegen generate
   ```

### Issue: Simulator not available

**Symptoms**: No simulators in Xcode device list

**Solutions**:

1. **Check available simulators**
   ```bash
   xcrun simctl list devices
   ```

2. **Add simulator in Xcode**
   - Xcode → Window → Devices and Simulators
   - Click "+" to add new simulator
   - Choose iPhone 15, iOS 17.0+

3. **Reset simulator**
   - Simulators → Device → Erase All Content and Settings

### Issue: Microphone not working in Simulator

**Symptoms**: Recording fails, no audio captured

**Solutions**:

1. **Grant microphone permission to Simulator**
   - System Settings → Privacy & Security → Microphone
   - Enable "Simulator"

2. **Reset iOS Simulator privacy**
   - Simulator menu: Device → Erase All Content and Settings
   - Re-run app, re-grant permission

3. **Check Mac microphone**
   - Test Mac mic is working: System Settings → Sound → Input

### Issue: Git push fails

**Symptoms**: "remote: Permission denied", "Authentication failed"

**Solutions**:

1. **Verify SSH key is added to GitHub**
   ```bash
   ssh -T git@github.com
   # Expected: "Hi username! You've successfully authenticated..."
   ```

2. **Check remote URL**
   ```bash
   git remote -v
   # Should show SSH (git@github.com:...) or HTTPS
   ```

3. **Re-authenticate**
   ```bash
   # For HTTPS, may need to enter credentials
   # For SSH, add key: ssh-add ~/.ssh/id_ed25519
   ```

---

## Next Steps

After completing setup:

1. ✅ **Build and run app** in Simulator
2. ✅ **Test recording** a sample audio clip
3. ✅ **Verify backend communication** by uploading for analysis
4. ✅ **Explore the codebase**:
   - `Models/`: Data structures
   - `Services/`: API and audio logic
   - `ViewModels/`: Business logic
   - `Views/`: UI components
5. ✅ **Run unit tests**: Cmd+U
6. ✅ **Start developing**: Pick a task and code!

---

## Reference: Key Commands

### Xcode
```bash
# Build project
xcodebuild -scheme SpeechMastery -configuration Debug build

# Run tests
xcodebuild test -scheme SpeechMastery -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean
xcodebuild clean -scheme SpeechMastery
```

### XcodeGen
```bash
# Generate project
cd ios && xcodegen generate

# Show version
xcodegen --version

# Show help
xcodegen --help
```

### Git
```bash
# Pull latest
git pull origin master

# Commit changes
git add ios/
git commit -m "message"
git push origin master

# Check status
git status

# View diff
git diff
```

### Networking
```bash
# Find macOS VM IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Test connectivity to Linux VM
ping 192.168.1.150
curl http://192.168.1.150:8000/health

# Test with authentication
curl -H "Authorization: Bearer SINGLE_USER_DEV_TOKEN_12345" \
     http://192.168.1.150:8000/recordings
```

---

## Additional Resources

- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [XcodeGen GitHub](https://github.com/yonaskolb/XcodeGen)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [AVFoundation Guide](https://developer.apple.com/av-foundation/)
- [Project DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
- [Project ARCHITECTURE.md](./ARCHITECTURE.md)

---

## Support

If you encounter issues not covered here:

1. Check project documentation in `docs/`
2. Review CLAUDE.md for project-specific guidance
3. Check backend logs on Linux VM: `docker-compose logs -f`
4. Review Xcode console output for iOS errors
5. Test network connectivity between VMs

Happy coding!
