# Swipe Photos

An iPhone app for cleaning up your photo library with one thumb. It shows your photos and videos one at a time: swipe right to keep, swipe left to mark for deletion. When you finish, you review what you marked and delete it all with one confirmation.

**Film:** [demo/swipe-photos-film.mp4](demo/swipe-photos-film.mp4) is a 29-second motion film with no sound. It is animated with illustrated photos, not recorded from a phone.

**Browser demo:** [demo/index.html](demo/index.html) is a working simulation with drawn pictures. It never touches real photos.

## How it works

- Marked items stay in the app's trash, and your library doesn't change until you confirm.
- Videos play on a loop with the sound off. A button on the card turns the sound on.
- Tap an item in the trash to put it back. Undo brings back your last decision.
- iOS asks for confirmation once for the whole batch. Deleted items stay in Recently Deleted for 30 days.
- Your progress survives a restart, even if iOS closes the app. Items you already kept or marked don't come back.
- If iOS interrupts a deletion, nothing is deleted, your marked items stay in the trash, and you can tap **Try Again**.
- The app has no account or server and makes no network requests of its own. It may download originals of your own photos and videos from iCloud through Apple's Photos framework.

## Run it

You need a Mac with Xcode. The app requires iOS 17 or later.

1. Open `PhotoSwipe.xcodeproj`.
2. Select the `PhotoSwipe` target, open **Signing & Capabilities**, and choose your Team. A free Apple account works, but its builds stop opening after 7 days.
3. If Xcode reports that the bundle identifier is taken, change it to one of your own.
4. Choose your iPhone or a simulator and press **Run**.

## Verify it yourself

You don't have to take our word for any of this.

**Read the code.** It is six short Swift files in `PhotoSwipe/`. To look for networking code, run this from the repo root:

```bash
grep -rnE 'URLSession|NWConnection|NWPathMonitor|CFNetwork|WKWebView|https?://' PhotoSwipe
```

It should print nothing. The app imports only Apple's SwiftUI and Photos frameworks and uses no third-party packages.

**Build it yourself.** Follow the steps in [Run it](#run-it). You then know the app on your phone came from this code. A copy installed any other way can't be proven to match it just by reading this repo.

**Watch it on your iPhone.** Go to **Settings → Privacy & Security → App Privacy Report** and turn it on. Use the app for a while, then check which domains it contacted. Apple's Photos framework handles any iCloud downloads, so they may not appear as the app's own traffic.

**Start small.** When iOS asks for photo access, tap **Select Photos** and choose a few you don't need. The app can only see those.

**Test the safety net.** Mark a photo and delete it. iOS asks you to confirm, and the app can't skip that step. The photo then stays in **Recently Deleted** for 30 days, where you can recover it in the Photos app.

## Status

Tested in the iPhone simulator: swipes, buttons, Undo, very fast use, restart, force-quitting right after a swipe, restoring from the trash, deleting and declining to delete, denied photo access, limited photo access, a 300-photo library, and short videos: playback, looping, swiping and deleting. The app has also been installed on a real iPhone.

With limited access, the test granted 3 of 307 photos. The app showed only those 3, and deleting 2 of them took the library to 305. "Everything reviewed" then refers only to the photos you selected. To change the selection, go to **Settings → Privacy & Security → Photos → Swipe Photos**.

Not tested yet: a full run on a real library with the current version, sound output, long videos, iCloud photos and videos, libraries with thousands of pictures, and changing the selection later.
