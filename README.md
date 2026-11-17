# Puffer Pal

A little fish pet that floats in the corner of your Mac (and in the menu bar) and gets you into [Krillion](https://krillion.io)
without the website shuffle: click it to jump into a friend's Puffer Party room or today's
Daily Dive, and it nudges you every day until you've dived. A matching puffer sits in
Claude Code's status line.

Not affiliated with Krillion. The puffer window just shows krillion.io.

## Download

Needs macOS 14 or later, on an Apple-silicon or Intel Mac.

1. Download **Puffer-Pal-0.1.0.zip** from the
   [latest release](https://github.com/TurniSaha/puffer-pal/releases/latest) and open it.
2. Drag **Puffer Pal** into your **Applications** folder, then open it.
3. macOS says **"Puffer Pal" Not Opened** because the app isn't signed with a paid Apple
   developer account. Click **Done** (not Move to Trash).
4. Open **System Settings → Privacy & Security**, scroll down to the message about Puffer Pal,
   click **Open Anyway** and enter your password. You only do this once.

The fish appears in the bottom-right corner of your screen. Right-click it and turn on
**Launch at login** so it's there after a restart.

**The Claude Code part (optional):** in Terminal, run

```sh
claude plugin marketplace add TurniSaha/puffer-pal
claude plugin install puffer-pal@puffer-pal
```

and start a new Claude Code session.

## Build it yourself

Needs the Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/TurniSaha/puffer-pal.git
cd puffer-pal
make install                       # builds "Puffer Pal.app" into ~/Applications and installs the Claude mod
open ~/Applications/Puffer\ Pal.app
```

No Claude Code? Build just the app with `make app` and copy `mac/build/Puffer Pal.app` into
`~/Applications`. The Claude mod is read straight from `claude-plugin/`, so edits there apply
at the next Claude Code session. `make release-zip` builds the download zip.

## Use

- **The fish pet** floats in the bottom-right corner, above every window and on every desktop.
  Drag it anywhere and it stays there. It puffs up with a red ! when the dive is due and
  turns calm with bubbles once you've dived. Hide or bring it back from the right-click menu
  (**Show fish pet**).
- **Click the pet (or the menu-bar puffer):** opens today's Daily Dive, or your last room once
  you've dived. Click again to close it.
- **Room box:** type a friend's 4-letter code and press Join. ↺ Rejoin takes you back to the last room.
- **Right-click either one:** Daily Dive, last room, reminder time (any hour, or off), mark today
  done, launch at login, show fish pet, quit.
- **Reminders:** at your reminder time (7pm by default) and a last call at 10pm, only while
  today's dive isn't done. The day resets at midnight New York time (11pm Central), so an
  11pm reminder is for the new dive; a 10pm one sends just the last call.
- **In Claude Code:** the status line shows your dive status, the first session after your
  reminder time (same setting as the app; none when off) nudges you once, and `/party ABCD`, `/party` (last room) and `/dive` open the puffer.

Links work from anywhere too: `open pufferpal://party/ABCD`, `open pufferpal://dive`.

## How it knows you dived

The game runs inside the puffer's own window, so the app reads Krillion's saved progress there
(`krillion:stats:v1`) and writes `~/Library/Application Support/PufferPal/status.json`, which the
Claude mod reads.

## Known limits

- Dives only count when played in the puffer window (guest progress doesn't sync between browsers).
- Google sign-in to Krillion isn't supported inside the puffer.
- macOS can refuse a locally built app its own notifications (it did on the Mac this was built
  on, ad-hoc and with a trusted self-signed certificate). Then reminders go through macOS's
  built-in notification command.
  They're filed under Script Editor, and clicking one opens Script Editor, not the puffer.
  The puffer icon still puffs up either way.
- On a MacBook with a full menu bar, macOS may tuck the menu-bar puffer under the `«` overflow
  arrow. The fish pet is the way in then.

## Develop

```sh
make test          # Swift tests (mac/)
make plugin-check  # validate + test the Claude mod (claude-plugin/)
```

## License

[MIT](LICENSE)
