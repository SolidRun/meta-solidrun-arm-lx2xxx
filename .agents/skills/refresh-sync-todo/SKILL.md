---
name: refresh-sync-todo
description: Remove open points from SYNC_TODO.md that hand-written changes to this Yocto layer (meta-solidrun-arm-lx2xxx) have resolved since the last sync with lx2160a_build. Run sporadically, not after every commit - most importantly right before the next sync, otherwise when asked to refresh or clean up SYNC_TODO.md. Does not sync, add new open points or change anything else (that is skill sync-lx2160a-build).
---

# Refresh SYNC_TODO.md after hand-written changes

`SYNC_TODO.md` lists what the SolidRun reference BSP **lx2160a_build** has and this layer does not. It is
written by skill [sync-lx2160a-build](../sync-lx2160a-build/SKILL.md). This skill has one job: after
hand-written changes, find the open points those changes resolved since the last sync, and drop them.

**When to run it:** sporadically, not after every hand-written commit - one run covers all commits since the
last sync. Most importantly **right before the next sync** (sync-lx2160a-build step 1 asks for it), so the
sync starts from an accurate list; otherwise only when the user asks, e.g. before reviewing open points.

Read first: [sync-lx2160a-build/SKILL.md](../sync-lx2160a-build/SKILL.md) (terminology, and step 2: format
of SYNC_TODO.md) and [project-map.md](../sync-lx2160a-build/project-map.md).

## Rules

1. **Only SYNC_TODO.md is written, and only by removing or annotating existing items.** No new items, no
   other files: the user's changes, layer files, skill files, AGENTS.md and project-map.md stay untouched.
   Anything else found goes into the report.
2. **Never guess.** An item is resolved only if check-sync.sh no longer reports its key.
3. Do not download component sources (rule 6 of sync-lx2160a-build applies).

## Procedure

### 1. Scope

- Find the last sync commit: the newest commit with a `lx2160a_build: <branch> @ <sha>` trailer. If there is
  none, stop: there is nothing to refresh.
- Read the commits after it (`git log -p --reverse <sync commit>..HEAD`). If there are none, report that
  SYNC_TODO.md is current and stop.

### 2. Check against the last synced revision

Run the check with lx2160a_build at the revision of the trailer, so newer lx2160a_build commits do not
interfere. Use a temporary detached worktree, leaving the user's checkout untouched:

```sh
git -C <lx2160a_build> worktree add --detach /tmp/lx2160a_build-pinned <sha from trailer>
.agents/skills/sync-lx2160a-build/check-sync.sh -p -s <yocto>/sources /tmp/lx2160a_build-pinned
git -C <lx2160a_build> worktree remove /tmp/lx2160a_build-pinned
```

`-s` is optional here (it adds the SRCREV and layer dependency checks, which this skill does not act on).

### 3. Drop resolved items

For each item in SYNC_TODO.md:

- **Key no longer reported as TODO** → resolved: remove the item. Remove `###`/`##` headings left empty;
  with no items left, keep title, note, intro and the line `No open points.`
- **Key still reported, but a commit since the last sync evidently implements it** (it is reported only
  because its project-map.md row is missing) → keep the item, and append to it:
  `Implemented in <short sha>; project-map.md row pending.` Propose the row in the report.
- **Otherwise** → leave the item unchanged.

TODO keys reported by the check that have no item are **not** added - that is the next sync's job;
mention them in the report.

### 4. Commit

If SYNC_TODO.md changed, commit only that file, authored and signed off by the LLM as described in
sync-lx2160a-build step 11 (no `git commit -s`, no `Co-Authored-By` for yourself), without an
`lx2160a_build:` trailer:

```
sync todo: drop points resolved by <subject of the resolving commit, or "hand-written changes">

- resolved: <keys>
- implemented, project-map.md row pending: <keys>
```

Do not push.

### 5. Report

Tell the user: the commits looked at, the items dropped (and by which commit they were resolved), the items
marked as implemented with the proposed project-map.md rows (as diffs), and the check-sync.sh summary line.
Mention in one line each, without acting on them: FAILs, TODO keys without an item, and anything else the
check reported.
