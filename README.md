# 2022 RoR Typescript Coding Test
[To get started!](https://explorator.notion.site/explorator/Explorator-Labs-Coding-Challenge-a530c7984e904998a8862493f4f681c2)

## Existing bugs (fixed)

1. Reset button doesn't work
1. Unable to check / un-check any todo item

## Live 

https://todoapp-codingtest.herokuapp.com/

## Setup note

Database seeding has been moved from a migration to `db/seeds.rb`, so it is necessary to call `bin/rake db:seed` to setup the initial data (after calling `bin/rake db:migrate`).

## Version 0.0.1.5

This is an intermediate version, with the 'insert', 'edit', 'delete' and 'move' action kinds now supported in their most basic forms.

## Version 0.0.1

You'll notice I haven't actually added any hard features yet, but I have re-engineered the data management on both the backend and frontend - it is now an efficient and ultra-fast real-time app that syncs across all opened sessions, and can maintain an offline state and sync up when back online. No page reloading, you'll notice a subtle spinner/tick at the bottom right that indicates when the data is syncing/has synced. Any attempt to close the window while data is still syncing results in a warning.

The idea was to construct the basis of a real-time collaborative app - see [Road Map](#road-map) below.

## Architecture

I added the following models: *TodoList* and *TodoAction*. Each TodoAction represents a change to the TodoList data state. A TodoList has a "version" at any given moment, which is the number of actions that have been performed on it. Each TodoAction has a "todo_id" and a "kind". For now the only kinds are "check" and "uncheck", but eventually there will also be "insert", "edit", "delete" and "move", as well as additional fields to describe the other actions ("title" and "after_todo_id").

Adding a TodoAction to a TodoList also applies the actual changes to the *Todo* model.

Upon loading, the app requests the actual TodoList data state (the list title and a collection of todo items) along with the current version.

When an action is performed locally it is immediately applied to the local data state, but maintained in a list of pending actions, paired with a rollback action that can undo the change. Any pending actions are sent to the server along with the current version - the server will lock the TodoList, add those actions as TodoAction records, update the appropriate Todo records, update the TodoList version, unlock the TodoList, and then return the updated version along with any intermediate actions that existed between the version in the request and the applied actions, if any.

On the frontend side, upon receiving the response, if there are no intermediate actions, the current version is updated and the pending actions are discarded. If there are intermediate actions however, the local data state is rolled back of all of the pending actions in reverse, the intermediate actions are applied and then the pending actions are applied forward - the current version is then updated and the pending actions discarded.

The spinner/warning-on-close are active as long as there are pending actions - any new actions performed while pending actions are being processed are added to the pending list, and are automatically picked up either after a successful update (a new request is made), or on a retry (when a network connection is absent). On fail, the update request is retried every 5 seconds. All available pending actions are always sent in a single request.

Finally, an ActionCable subscription is used to broadcast/receive an update whenever a TodoList version is updated in the database. Upon receiving such an update on the frontend, if the new version is greater than the current version, an update request is initiated with zero new actions. Such an empty update does not activate the spinner/warning-on-close.

## Road Map

This assessment process made me realize I don't have a good public showcase of my Rails experience/skills, so I'm planning to extend this app for that purpose, whether for this recruitment process or any future ones. So I'll be pushing the following versions as I complete them, feel free to follow along if it is still of interest to you. The general idea is to construct something that broadly represents my skills as a full-stack developer.

#### Version 0.0.2

* Insert, edit (title), delete and move (reorder) todo items.
* Select multiple items/select all/unselect all, and delete multiple items at once.
* Deletions without confirmation, but can be undone for a few seconds after deletion (through a dismissable toast).
* Manage multiple todo lists (will be the landing page instead of the one todo list) - insert, edit (title), delete and move (reorder) todo lists. This will also be part of the real-time data framework.

#### Version 0.0.3

* Add user account management (Register, Forgot password, Login/Logout, Edit profile, Delete account)

#### Version 0.0.4

* Create/manage/revoke invitation links to invite other users to collaborate on specific todo lists.
* Manage/revoke access granted to collaborators.
* Differentiate between todo lists created by the user, and those they have been invited to.
* View a history of all actions performed on a todo list, along with which user performed each of them - filter by a specific user.
