# Number Snake for Mac

## What it is

Number Snake is a small simulation. A blue creature moves over a grid of numbered cells and hunts red and black glitchy infections.

It is a single web page, called `index.html`. The Mac versions below wrap that same page so you can use it as an app or as a screen saver.

## What you get

There are two downloads for Mac. Both are version 0.2.0 and need macOS 12 or newer. They work on Apple Silicon and Intel Macs.

**1. Number Snake.app** (in the zip called `Number-Snake-mac-app.zip`)

This is a normal Mac app. It opens the simulation in its own window.

- It has a menu bar.
- It remembers the size of its window.
- It has full screen.
- Cmd+R starts a new run.
- The page's own keys work: Space pauses, R restarts, F goes full screen.
- The Record button saves a video clip to your Downloads folder.

**2. Number Snake.saver** (in the zip called `Number-Snake-screensaver.zip`)

Each time the screensaver starts it shows one of the two defenders, the hunter or the warden, chosen at random.

This is a screen saver. It shows the same simulation, with no controls.

## Install the app

1. Unzip `Number-Snake-mac-app.zip`.
2. Drag **Number Snake.app** into your Applications folder.
3. Double-click it to open.

If Mac shows a warning when you first open it, see the section "The warning about malicious software" below.

## Install the screen saver

1. Unzip `Number-Snake-screensaver.zip`.
2. Double-click **Number Snake.saver**.
3. When asked, choose **Install for this user**.
4. Open **System Settings**, go to **Screen Saver**, and pick **Number Snake**.

## The warning about malicious software

You may see a message saying the app "cannot be opened because Apple cannot check it for malicious software". The exact wording can vary between versions of macOS.

This happens because the apps are not notarised. Notarising is Apple's checking service, and it needs a paid Apple Developer account. The apps are signed only with a free "ad-hoc" signature. The files are not harmful, but only open them if you got them from someone you trust.

To get past the warning, try one of these:

- **Right-click (or Control-click)** the app and choose **Open**. Then click **Open** again.
- Or open **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the message about Number Snake.

For the screen saver, the same **Privacy & Security** button applies.

**Terminal alternative**

You can also remove the warning from the file with the Terminal app. Type this, then a space:

```
xattr -dr com.apple.quarantine
```

Then drag the app or the `.saver` file into the Terminal window. This fills in the file's location for you, so you do not need to type it. Press Return.

## Remove it

**The app:** drag **Number Snake.app** to the Bin.

**The screen saver:** delete **Number Snake.saver** from the folder `~/Library/Screen Savers`. To open that folder in Finder, use the **Go** menu, choose **Go to Folder**, and type `~/Library/Screen Savers`.

## Build it yourself

You only need this if you want to make the downloads from the source files.

**Step 1: install the tools.** Open Terminal and type this, then press Return:

```
xcode-select --install
```

This installs Apple's Command Line Tools. You do not need the full Xcode program.

**Step 2: run the build.** Open the project folder in Terminal. Then run:

```
mac/build.sh
```

The build writes everything to the `mac/dist/` folder. That includes the `.app`, the `.saver`, and the two zip files.

The build also makes a new app icon, `mac/icon.png`, at 1024 pixels.

The build copies the current `index.html` into both the app and the screen saver. This means they always match the web page.

## Known limits

- The apps are not notarised, so Mac shows the warning described above the first time.
- The screen saver is third-party software. On recent versions of macOS it runs inside a system helper. It may occasionally need a restart of System Settings before it shows up in the list.
