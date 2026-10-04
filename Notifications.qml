// Notifications.qml
// Owns the notification daemon and the transient toast list. `server` is the
// model backing the sidebar; `toasts` (a ListModel of keys) drives the on-screen
// popups so adding/removing one only animates that item. ListModel can't hold
// QObjects in Qt6, so the Notification objects live in a side map keyed by an
// integer. The daemon exists as long as this singleton is loaded.
pragma Singleton

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

  // Newest first.
  readonly property alias toasts: toastModel

  ListModel { id: toastModel }

  property var objectMap: ({})
  property int nextKey: 1

  function pushToast(notification): void {
    const key = root.nextKey++
    root.objectMap[key] = notification
    toastModel.insert(0, { key: key })
    // Cap the stack so it can't grow without bound.
    while (toastModel.count > IslandConfig.notifToastMax)
      dropAt(toastModel.count - 1)
  }

  function dropAt(index): void {
    const key = toastModel.get(index).key
    delete root.objectMap[key]
    toastModel.remove(index)
  }

  function removeToast(notification): void {
    for (let i = 0; i < toastModel.count; i++)
      if (root.objectMap[toastModel.get(i).key] === notification) {
        dropAt(i)
        return
      }
  }

  function objectFor(key): var {
    return root.objectMap[key] ?? null
  }

  function clearAll(): void {
    const items = root.server.trackedNotifications.values
    for (let i = 0; i < items.length; i++)
      items[i].dismiss()
  }
}
