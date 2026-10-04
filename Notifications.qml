// Notifications.qml
// Owns the notification daemon, the sidebar's display model and the transient
// toast list.
//
// `display` is a single ListModel in display order (one row per notification,
// groups contiguous, newest first) updated incrementally, so the sidebar's
// ListView can run real add/remove/displaced transitions instead of rebuilding.
// `toasts` is a ListModel of keys driving the popups. ListModel can't hold
// QObjects in Qt6, so Notification objects live in `objectMap` keyed by int.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  readonly property NotificationServer server: NotificationServer {
    keepOnReload: true
    inlineReplySupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: (notification) => {
      notification.tracked = true
      // Notifications carried over a reload are already in the sidebar; don't
      // re-toast them.
      if (!notification.lastGeneration)
        root.pushToast(notification)
    }
  }

  // Sidebar model: roles key, nid, appName, appIcon, isStart, groupSize,
  // groupIndex.
  readonly property alias display: displayModel
  ListModel { id: displayModel }

  // Toasts: role key, newest first.
  readonly property alias toasts: toastModel
  ListModel { id: toastModel }

  // Number of tracked notifications; kept in sync by reconcile().
  property int count: 0

  property var objectMap: ({})   // key -> Notification
  property var nidToKey: ({})    // appName+id -> key
  property int nextKey: 1

  // Which groups are expanded, keyed by app name. Reassigned on toggle so
  // bindings re-evaluate.
  property var expandedGroups: ({})

  function nidOf(notification): string {
    return (notification.appName || "") + "\u0000" + notification.id
  }

  // Stable key for a notification, shared by the display model and toasts.
  function keyOf(notification): int {
    const nid = root.nidOf(notification)
    let key = root.nidToKey[nid]
    if (key === undefined) {
      key = root.nextKey++
      root.nidToKey[nid] = key
      root.objectMap[key] = notification
    }
    return key
  }

  function objectFor(key): var {
    return root.objectMap[key] ?? null
  }

  // ---- Sidebar display model ----

  Component.onCompleted: root.reconcile()

  Connections {
    target: root.server.trackedNotifications
    function onValuesChanged() { root.reconcile() }
  }

  function rowIndexFor(nid): int {
    for (let i = 0; i < displayModel.count; i++)
      if (displayModel.get(i).nid === nid)
        return i
    return -1
  }

  // Plain copy of the server's list (its `.values` is array-like, not a JS
  // array).
  function liveList(): var {
    const v = root.server.trackedNotifications.values
    const out = []
    for (let i = 0; i < v.length; i++)
      out.push(v[i])
    return out
  }

  // ponytail: full reconcile is O(notifications × display rows); fine to a few
  // hundred. Upgrade to an incremental nid→row map if the tracked list grows.
  function reconcile(): void {
    const live = root.server.trackedNotifications.values
    const liveNids = ({})
    for (let i = 0; i < live.length; i++)
      liveNids[root.nidOf(live[i])] = true

    // Drop rows whose notification is gone.
    for (let i = displayModel.count - 1; i >= 0; i--)
      if (!liveNids[displayModel.get(i).nid])
        displayModel.remove(i)

    // Insert rows for new notifications at the start of their group (newest
    // first).
    for (let i = 0; i < live.length; i++) {
      const n = live[i]
      if (root.rowIndexFor(root.nidOf(n)) !== -1)
        continue
      const app = n.appName || ""
      let pos = displayModel.count
      for (let j = 0; j < displayModel.count; j++)
        if (displayModel.get(j).appName === app) {
          pos = j
          break
        }
      displayModel.insert(pos, {
        key: root.keyOf(n),
        nid: root.nidOf(n),
        appName: app,
        appIcon: n.appIcon || "",
        isStart: false,
        groupSize: 1,
        groupIndex: 0
      })
    }

    root.refreshGroups()
    root.count = live.length
    root.prune(liveNids)
  }

  // Drop key maps for notifications that are gone and have no live toast.
  function prune(liveNids): void {
    const toastKeys = ({})
    for (let i = 0; i < toastModel.count; i++)
      toastKeys[toastModel.get(i).key] = true

    const nidMap = ({})
    const objMap = ({})
    for (const nid in root.nidToKey) {
      const key = root.nidToKey[nid]
      if (liveNids[nid] || toastKeys[key]) {
        nidMap[nid] = key
        objMap[key] = root.objectMap[key]
      }
    }
    root.nidToKey = nidMap
    root.objectMap = objMap
  }

  function setRowIf(index, role, value): void {
    if (displayModel.get(index)[role] !== value)
      displayModel.setProperty(index, role, value)
  }

  // Recompute isStart/groupSize/groupIndex over each contiguous app run.
  function refreshGroups(): void {
    let start = 0
    while (start < displayModel.count) {
      const app = displayModel.get(start).appName
      let end = start
      while (end < displayModel.count && displayModel.get(end).appName === app)
        end++
      const size = end - start
      for (let i = start; i < end; i++) {
        root.setRowIf(i, "isStart", i === start)
        root.setRowIf(i, "groupSize", size)
        root.setRowIf(i, "groupIndex", i - start)
      }
      start = end
    }
  }

  // ---- Toasts ----

  function pushToast(notification): void {
    toastModel.insert(0, { key: root.keyOf(notification) })
    // Cap the stack so it can't grow without bound.
    while (toastModel.count > IslandConfig.notifToastMax)
      dropAt(toastModel.count - 1)
  }

  function dropAt(index): void {
    toastModel.remove(index)
  }

  function dropKey(key): void {
    for (let i = 0; i < toastModel.count; i++)
      if (toastModel.get(i).key === key) {
        dropAt(i)
        return
      }
  }

  // ---- Group expand/collapse ----

  function isExpanded(appName): bool {
    return root.expandedGroups[appName] === true
  }

  function toggleGroup(appName): void {
    const next = Object.assign({}, root.expandedGroups)
    next[appName] = !root.isExpanded(appName)
    root.expandedGroups = next
  }

  // ---- Dismissal ----

  // Dismissed one at a time so each row animates out individually.
  property var dismissQueue: []

  function dismissStaggered(items): void {
    root.dismissQueue = root.dismissQueue.concat(items)
    if (!staggerTimer.running)
      staggerTimer.start()
  }

  function dismissGroup(appName): void {
    root.dismissStaggered(root.liveList().filter(n => (n.appName || "") === appName))
  }

  function clearAll(): void {
    root.dismissStaggered(root.liveList())
    while (toastModel.count > 0)
      dropAt(toastModel.count - 1)
  }

  Timer {
    id: staggerTimer
    interval: IslandConfig.notifAnimStagger
    repeat: true
    onTriggered: {
      if (root.dismissQueue.length === 0) {
        stop()
        return
      }
      const next = root.dismissQueue.shift()
      if (next)
        next.dismiss()
    }
  }
}
