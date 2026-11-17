import AppKit
import PufferCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private let store = StatusStore(url: StatusStore.defaultURL)
    private let reminders = Reminders()
    private var statusItem: NSStatusItem!
    private var panel: PufferPanel!
    private var pet: PetWindow!
    private var mood: PufferMood?
    private var tick: Timer?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.toolTip = "Puffer Pal"

        panel = PufferPanel(bridge: KrillionBridge { [weak self] snapshot in
            self?.handle(snapshot: snapshot)
        })
        panel.onURLChange = { [weak self] url in self?.noteRoom(in: url) }
        wirePanelActions()
        setUpPet()

        reminders.onOpenDive = { [weak self] in self?.open(.dive) }
        reminders.start()

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        tick = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        if store.read()?.reminderHour != settings.reminderHour { save(currentStatus) }
        refresh()

        let waiting = pendingURLs
        pendingURLs = []
        if !waiting.isEmpty { application(NSApp, open: waiting) }
    }

    /// Links can arrive before applicationDidFinishLaunching (a link that launched the app);
    /// they wait here until the status item and panel exist.
    private var pendingURLs: [URL] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        guard panel != nil else {
            pendingURLs += urls
            return
        }
        for url in urls {
            guard let link = DeepLink.parse(url) else {
                NSLog("Puffer Pal: ignoring unknown link \(url)")
                continue
            }
            open(link)
        }
    }

    // MARK: Status

    private var today: String { DiveClock.diveDate(at: Date()) }

    private var currentStatus: DiveStatus {
        if let saved = store.read(), saved.diveDate == today { return saved }
        let saved = store.read()
        return DiveStatus(diveDate: today, diveDone: false, streak: nil,
                          lastRoom: settings.lastRoom?.value ?? saved?.lastRoom,
                          reminderHour: settings.reminderHour, updatedAt: StatusStore.timestamp())
    }

    private func save(_ status: DiveStatus) {
        var status = status
        status.reminderHour = settings.reminderHour
        status.updatedAt = StatusStore.timestamp()
        do { try store.write(status) } catch { NSLog("Puffer Pal: couldn't write status: \(error)") }
        refresh()
    }

    private func handle(snapshot: [String: String]?) {
        let reading = snapshot.map { DiveDetector.evaluate(storage: $0, diveDate: today) } ?? .unknown
        var status = currentStatus
        // Once today's dive is done it stays done; later reads only add depth/streak.
        let alreadyDone = status.isDone(on: today) == true
        switch reading {
        case let .done(depth, streak):
            status.diveDone = true
            status.depthMeters = depth ?? status.depthMeters
            status.streak = streak ?? status.streak
        case .notDone:
            if !alreadyDone { status.diveDone = false }
        case .unknown:
            if !alreadyDone { status.diveDone = nil }
        }
        if status != store.read() { save(status) }
    }

    private func noteRoom(in url: URL) {
        guard let room = RoomCode(fromKrillionURL: url), room != settings.lastRoom else { return }
        settings.lastRoom = room
        var status = currentStatus
        status.lastRoom = room.value
        save(status)
    }

    /// Recomputes the icon, the panel header and any due reminder.
    @objc private func refresh() {
        let now = Date()
        let status = currentStatus
        let done = status.isDone(on: today)
        let planner = ReminderPlanner(reminderHour: settings.reminderHour, localZone: .current)

        if let kind = planner.due(now: now, status: status, alreadySent: settings.sentReminders(on: today)),
           reminders.post(kind, statusKnown: done != nil) {
            settings.markSent(kind, on: today)
        }

        let sent = settings.sentReminders(on: today)
        let newMood: PufferMood = done == true ? .calm : (sent.isEmpty ? .plain : .puffed)
        setMood(newMood)
        pet.setMood(newMood, tooltip: petTooltip(done: done, depth: status.depthMeters))

        panel.model.lastRoom = settings.lastRoom?.value
        if done == true {
            let depth = status.depthMeters.map { " \($0.formatted())m" } ?? ""
            panel.model.diveLabel = "Daily Dive ✓\(depth)"
        } else {
            panel.model.diveLabel = "Daily Dive"
        }
    }

    private func petTooltip(done: Bool?, depth: Int?) -> String {
        switch done {
        case true?: return "Dove today" + (depth.map { " · \($0.formatted())m" } ?? "") + " · click for Puffer Party"
        case false?: return "Daily Dive is waiting · click to dive"
        case nil: return "Done your Daily Dive? Click to check"
        }
    }

    private func setMood(_ newMood: PufferMood) {
        guard newMood != mood, let button = statusItem.button else { return }
        let wasPlain = mood != .puffed
        mood = newMood
        button.image = PufferIcon.image(for: newMood)
        if newMood == .puffed && wasPlain { wiggle(button) }
    }

    private func wiggle(_ button: NSStatusBarButton) {
        let tilts: [CGFloat] = [0.25, -0.25, 0.18, -0.18, 0]
        for (i, tilt) in tilts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 * Double(i + 1)) {
                button.image = PufferIcon.image(for: .puffed, tilt: tilt)
            }
        }
    }

    // MARK: Panel and links

    private func wirePanelActions() {
        let model = panel.model
        model.onJoin = { [weak self] code in self?.open(.party(code)) }
        model.onRejoin = { [weak self] in self?.open(.party(nil)) }
        model.onDive = { [weak self] in self?.open(.dive) }
        model.onHost = { [weak self] in
            guard let self else { return }
            panel.show(url: KrillionURL.party, near: defaultAnchor)
        }
    }

    /// Next to the pet when it's out, else under the menu-bar icon.
    private var defaultAnchor: PufferPanel.Anchor {
        pet.isVisible ? .pet(pet) : .menuBar(statusItem.button)
    }

    private func open(_ link: DeepLink, near anchor: PufferPanel.Anchor? = nil) {
        panel.show(url: link.krillionURL(lastRoom: settings.lastRoom), near: anchor ?? defaultAnchor)
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            toggleGame(near: .menuBar(statusItem.button))
        }
    }

    /// Click on the pet or icon: close the game if it's in front, bring it back if covered,
    /// otherwise open today's dive (or the last room once today's dive is done).
    private func toggleGame(near anchor: PufferPanel.Anchor) {
        if panel.isVisible && panel.isKeyWindow && NSApp.isActive {
            panel.close()
        } else if panel.isVisible {
            // Covered by other windows: bring it back rather than dropping out of the game.
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            let link: DeepLink = currentStatus.isDone(on: today) == true ? .party(nil) : .dive
            open(link, near: anchor)
        }
    }

    // MARK: Right-click menu

    private func showMenu() {
        statusItem.menu = makeMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("Daily Dive", #selector(menuDive)))
        let rejoin = item(settings.lastRoom.map { "Join last room (\($0.value))" } ?? "Puffer Party", #selector(menuParty))
        menu.addItem(rejoin)
        menu.addItem(.separator())
        menu.addItem(reminderSubmenu())
        menu.addItem(item("Mark today's dive done", #selector(menuMarkDone)))
        let login = item("Launch at login", #selector(menuToggleLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        let showPet = item("Show fish pet", #selector(menuTogglePet))
        showPet.state = settings.petVisible ? .on : .off
        menu.addItem(showPet)
        menu.addItem(.separator())
        menu.addItem(item("Quit Puffer Pal", #selector(menuQuit)))
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func reminderSubmenu() -> NSMenuItem {
        let parent = NSMenuItem(title: "Remind me at", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for hour in ReminderHours.all {
            let entry = item(ReminderHours.label(hour), #selector(menuSetReminder(_:)))
            entry.tag = hour
            entry.state = settings.reminderHour == hour ? .on : .off
            sub.addItem(entry)
        }
        let off = item("Off", #selector(menuSetReminder(_:)))
        off.tag = -1
        off.state = settings.reminderHour == nil ? .on : .off
        sub.addItem(off)
        parent.submenu = sub
        return parent
    }

    @objc private func menuDive() { open(.dive) }
    @objc private func menuParty() { open(.party(nil)) }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    @objc private func menuTogglePet() {
        settings.petVisible.toggle()
        showOrHidePet()
    }

    @objc private func menuSetReminder(_ sender: NSMenuItem) {
        settings.reminderHour = sender.tag >= 0 ? sender.tag : nil
        save(currentStatus) // the Claude mod reads the reminder hour from status.json
    }

    @objc private func menuMarkDone() {
        var status = currentStatus
        status.diveDone = true
        save(status)
    }

    @objc private func menuToggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Puffer Pal: launch at login change failed: \(error)")
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}

// MARK: - Fish pet

extension AppDelegate {
    private func setUpPet() {
        pet = PetWindow()
        pet.onClick = { [weak self] in
            guard let self else { return }
            toggleGame(near: .pet(pet))
        }
        pet.onMoved = { [weak self] origin in self?.settings.petOrigin = origin }
        pet.menuProvider = { [weak self] in self?.makeMenu() ?? NSMenu() }
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        showOrHidePet()
    }

    /// Puts the pet back on its saved spot (or the bottom-right corner), fully on a screen.
    private func placePet() {
        guard let main = NSScreen.main?.visibleFrame else { return }
        let origin = PetPlacement.restore(
            saved: settings.petOrigin, petSize: pet.frame.size,
            screens: NSScreen.screens.map(\.visibleFrame), main: main)
        pet.setFrameOrigin(origin)
    }

    fileprivate func showOrHidePet() {
        if settings.petVisible {
            placePet()
            pet.orderFrontRegardless()
        } else {
            pet.orderOut(nil)
        }
    }

    @objc private func screensChanged() {
        if pet.isVisible { placePet() }
    }
}
