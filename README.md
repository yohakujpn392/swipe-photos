# Swipe Photos

An iPhone app for cleaning up your photo library with one thumb. It shows your photos and videos one at a time: swipe right to keep, swipe left to mark for deletion. When you finish, you review what you marked and delete it all with one confirmation.

Free and open source. Made by Yohaku: [X @yohakujpn](https://x.com/yohakujpn).

**[How to install it →](#install-it-on-your-iphone)**

<p align="center"><img src="demo/swipe-photos.gif" width="260" alt="Swiping photos right to keep and left to trash"></p>

**Film:** [demo/swipe-photos-film.mp4](demo/swipe-photos-film.mp4) is a 29-second motion film with no sound. It is animated with illustrated photos, not recorded from a phone.

**Browser demo:** [demo/index.html](demo/index.html) is a working simulation with drawn pictures. It never touches real photos.

## How it works

- Marked items stay in the app's trash, and your library doesn't change until you confirm.
- Videos play on a loop with the sound off. A button on the card turns the sound on.
- Tap an item in the trash to put it back. Undo brings back your last decision. **Start Over** in the ··· menu shows everything you kept again.
- iOS asks for confirmation once for the whole batch. Deleted items stay in Recently Deleted for 30 days.
- Your progress survives a restart, even if iOS closes the app. Items you already kept or marked don't come back.
- If iOS interrupts a deletion, nothing is deleted, your marked items stay in the trash, and you can tap **Try Again**.
- The app has no account or server and makes no network requests of its own. It may download originals of your own photos and videos from iCloud through Apple's Photos framework.

## Install it on your iPhone

The app isn't on the App Store yet, so you build it yourself with Xcode. It takes about 15 minutes the first time, most of it waiting for Xcode to download.

**You need:**

- a Mac with macOS 14 (Sonoma) or later
- an iPhone with iOS 17 or later, and its cable
- an Apple Account (the one you use for the App Store is fine, you don't need to pay)

### 1. Install Xcode

Get [Xcode](https://apps.apple.com/app/xcode/id497799835) from the Mac App Store. It's free and large, so let it download. Open it once and let it install its components. If it asks which platforms to add, choose **iOS**.

### 2. Download the code

On this page, click the green **Code** button, then **Download ZIP**. Unzip it and open the folder.

If you use Git:

```bash
git clone https://github.com/yohakujpn392/swipe-photos.git
```

### 3. Open the project and sign it

1. Double-click `PhotoSwipe.xcodeproj`. Xcode opens.
2. In Xcode, go to **Xcode → Settings → Accounts**, click **+**, choose **Apple Account**, and sign in.
3. In the left sidebar, click the blue **PhotoSwipe** project at the top. In the middle, under **Targets**, select **PhotoSwipe** and open the **Signing & Capabilities** tab.
4. Check **Automatically manage signing** and pick your name under **Team** (it says *Personal Team*).
5. Change **Bundle Identifier** to something only you use, for example `com.yourname.swipephotos`. Without this Xcode will say the identifier is taken.

### 4. Prepare your iPhone

1. Connect the iPhone to the Mac with the cable. Unlock it and tap **Trust** if it asks.
2. Turn on Developer Mode: **Settings → Privacy & Security → Developer Mode**, switch it on and restart the phone when asked. If you don't see this option yet, do step 5 once, then look again.

### 5. Install

1. At the top of the Xcode window, open the device menu and choose your iPhone.
2. Press **Run** (the ▶ button) or **⌘R**. The first build takes a minute.
3. The first time, the iPhone says the developer isn't trusted. On the phone, go to **Settings → General → VPN & Device Management**, tap your Apple Account email under *Developer App*, and tap **Trust**.
4. Press **Run** again. Swipe Photos opens on your phone.

When iOS asks for photo access, you can tap **Select Photos** and give it only a few to start.

### Every 7 days

With a free Apple Account, the app stops opening after 7 days. Your progress isn't lost. Connect the phone, open the project in Xcode and press **Run** again. A paid Apple Developer account makes builds last a year.

### If something goes wrong

- **"No account for team" or "Signing requires a development team":** repeat step 3.2 and 3.4.
- **"Failed to register bundle identifier":** pick a different identifier in step 3.5.
- **Your iPhone isn't in the device menu:** unlock it, reconnect the cable, tap **Trust**, and wait a minute while Xcode prepares it.
- **"Developer Mode disabled":** do step 4.2.
- **"Untrusted Developer" on the phone:** do step 5.3.

Something else? [Open an issue](https://github.com/yohakujpn392/swipe-photos/issues) or message me on X.

You can also try it without an iPhone: pick any iPhone simulator in the device menu and press **Run**.

## Verify it yourself

You don't have to take our word for any of this.

**Read the code.** It is six short Swift files in `PhotoSwipe/`. To look for networking code, run this from the repo root:

```bash
grep -rnE 'URLSession|NWConnection|NWPathMonitor|CFNetwork|WKWebView|https?://' PhotoSwipe
```

It should print nothing. The app imports only Apple's SwiftUI and Photos frameworks and uses no third-party packages.

**Build it yourself.** Follow the steps in [Install it on your iPhone](#install-it-on-your-iphone). You then know the app on your phone came from this code. A copy installed any other way can't be proven to match it just by reading this repo.

**Watch it on your iPhone.** Go to **Settings → Privacy & Security → App Privacy Report** and turn it on. Use the app for a while, then check which domains it contacted. Apple's Photos framework handles any iCloud downloads, so they may not appear as the app's own traffic.

**Start small.** When iOS asks for photo access, tap **Select Photos** and choose a few you don't need. The app can only see those.

**Test the safety net.** Mark a photo and delete it. iOS asks you to confirm, and the app can't skip that step. The photo then stays in **Recently Deleted** for 30 days, where you can recover it in the Photos app.

## Status

Tested in the iPhone simulator: swipes, buttons, Undo, very fast use, restart, force-quitting right after a swipe, restoring from the trash, deleting and declining to delete, denied photo access, limited photo access, a 300-photo library, and short videos: playback, looping, swiping and deleting. The app has also been installed on a real iPhone.

With limited access, the test granted 3 of 307 photos. The app showed only those 3, and deleting 2 of them took the library to 305. "Everything reviewed" then refers only to the photos you selected. To change the selection, go to **Settings → Privacy & Security → Photos → Swipe Photos**.

Not tested yet: a full run on a real library with the current version, sound output, long videos, iCloud photos and videos, libraries with thousands of pictures, and changing the selection later.

## Author

Made by **Yohaku** for a friend who hated cleaning her camera roll.

- X: [@yohakujpn](https://x.com/yohakujpn)
- GitHub: [@yohakujpn392](https://github.com/yohakujpn392)

Feedback, bugs and ideas are welcome in [Issues](https://github.com/yohakujpn392/swipe-photos/issues) or in my DMs.

## License

MIT. See [LICENSE](LICENSE).
