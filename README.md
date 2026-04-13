# Task Manager App

A Flutter app that lets you manage a task list using Firebase Firestore. You can add tasks, check them off, add subtasks, and delete them. Everything syncs to the cloud so nothing resets when you restart the app.

---

## What It Does

- Add tasks by typing a name and pressing Add
- Check a checkbox to mark a task as complete (title gets crossed out)
- Tap the arrow to expand a task and see its subtasks
- Add and remove subtasks inside each task
- Delete a task with the trash button (asks you to confirm first)
- Everything saves to Firebase Firestore in real time

---

## Enhanced Features

**Dark Mode** — the app automatically follows whatever theme your device is set to. If your phone is in dark mode, the app goes dark too. I added this because it only took a couple lines in main.dart and makes the app feel more complete.

**Confirmation Dialog Before Delete** — when you tap the delete button, a popup asks "are you sure?" before actually removing the task. I added this because it's easy to accidentally tap delete and lose a task with no way to get it back.

---

## Project Structure

```
lib/
  main.dart                  — starts the app and connects to Firebase
  models/
    task.dart                — the Task class with toMap and fromMap
  services/
    task_service.dart        — all Firestore read/write calls
  screens/
    task_list_screen.dart    — the main UI screen
```

---

## How to Run It

1. Clone the repo
2. Run `flutter pub get` to install packages
3. Set up Firebase by running `flutterfire configure` and selecting your project
4. Run `flutter run` and pick your device

---

## Firebase Setup

- Go to console.firebase.google.com and create a project
- Enable Firestore in test mode
- Run `flutterfire configure` inside the project folder — this creates firebase_options.dart automatically
- Use these Firestore security rules for development:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## CRUD Breakdown

| Operation | How it works |
|-----------|-------------|
| Create | Type a task name and press Add — saves to Firestore |
| Read | StreamBuilder listens to Firestore and updates the list automatically |
| Update | Checkbox toggles isCompleted, subtask changes update the subtasks list |
| Delete | Trash button removes the document from Firestore after confirmation |
