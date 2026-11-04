# Install Swipe Photos with an AI assistant

Don't want to figure out Xcode on your own? Copy the prompt below into an AI assistant and it will set the app up with you, step by step.

**Where to paste it:**

- **Claude Code** or **Codex** (AI that can run commands on your Mac): it runs each step for you, after you approve it.
- **Claude** or **ChatGPT** in a browser or app: it tells you exactly what to click and what to type.

**Read it before you paste it.** It's plain text, and that's the point: you can see everything it asks the AI to do. It only uses this repository, asks before every command, never uses `sudo`, and never asks for your password.

**Some steps are always yours:** signing in to your Apple Account in Xcode, and tapping a few switches on your iPhone. Apple doesn't let anyone else do those, and that's a good thing.

You need a Mac (macOS 14 or later), an iPhone with iOS 17 or later, and its cable.

---

## The prompt

```text
Help me install the iPhone app "Swipe Photos" on my own iPhone from its open-source code:
https://github.com/yohakujpn392/swipe-photos

I'm not a developer, so explain each step in simple words, one step at a time, and wait for me before moving on.

Rules you must follow:
- Use only that GitHub repository. Don't download or install anything else, except Xcode from the Mac App Store, which I'll install myself.
- Before running any command, show it to me, say in one sentence what it does, and wait for my OK. If you can't run commands, tell me exactly what to type or click instead.
- Never use sudo. Never ask for my Apple Account password, a verification code or any other password. I'll sign in myself when Xcode asks.
- Don't change anything outside the project folder, and don't change the app's code. The only thing you may change in the project is the signing team and the bundle identifier.
- If something fails, show me the error and explain it before trying anything else. Don't try more than two fixes for the same problem without asking me.

Steps:

1. Check my Mac. Run `sw_vers -productVersion` (needs 14 or later) and `xcodebuild -version`. If Xcode is missing, tell me to install it from the Mac App Store (https://apps.apple.com/app/xcode/id497799835), open it once, let it install its components including the iOS platform, and tell you when I'm done.

2. Download the code into my home folder:
   cd ~ && git clone https://github.com/yohakujpn392/swipe-photos.git
   If the folder already exists, ask me before doing anything with it.

3. Signing (I do this part in Xcode, you guide me):
   a. Open the project: open ~/swipe-photos/PhotoSwipe.xcodeproj
   b. Tell me to go to Xcode > Settings > Accounts, click +, choose Apple Account and sign in.
   c. Tell me to click the blue PhotoSwipe project in the left sidebar, select the PhotoSwipe target, open Signing & Capabilities, check "Automatically manage signing" and choose my Personal Team.
   d. Tell me to change Bundle Identifier to something unique like com.<myname>.swipephotos (help me pick one; letters, numbers, dots and hyphens only).
   e. After I say done, confirm it worked by running:
      grep -E "DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER" ~/swipe-photos/PhotoSwipe.xcodeproj/project.pbxproj
      Both lines should show my team ID and my new identifier.

4. Prepare my iPhone (I do this, you guide me):
   a. Connect it with the cable, unlock it and tap Trust if asked.
   b. Turn on Settings > Privacy & Security > Developer Mode and restart the phone when asked. If the option isn't there yet, we'll come back after the first install attempt.

5. Find my iPhone: xcrun devicectl list devices
   Show me the list and confirm which one is my iPhone. Use its identifier below.

6. Build the app:
   cd ~/swipe-photos && xcodebuild -project PhotoSwipe.xcodeproj -scheme PhotoSwipe -configuration Debug -destination "id=<IPHONE_ID>" -derivedDataPath build -allowProvisioningUpdates build
   If it says the scheme isn't found, ask me to keep the project open in Xcode for a few seconds and try again once.

7. Install it on my iPhone:
   xcrun devicectl device install app --device <IPHONE_ID> ~/swipe-photos/build/Build/Products/Debug-iphoneos/PhotoSwipe.app

8. The first time, the iPhone won't open the app until I trust it. Tell me to go to Settings > General > VPN & Device Management, tap my Apple Account under Developer App and tap Trust. Then I can open Swipe Photos from the home screen.

9. Finally, tell me two things:
   - With a free Apple Account the app stops opening after 7 days. To renew it, I connect the phone and you run steps 6 and 7 again. My progress in the app is kept.
   - When the app asks for photo access, I can tap "Select Photos" and give it only a few photos to start.

If at any point I get lost, use the README of the repository as the reference.
```

---

## If the AI gets stuck

Follow the manual guide in the [README](README.md#install-it-on-your-iphone), or [open an issue](https://github.com/yohakujpn392/swipe-photos/issues).
