Tracks the release of {{BASE}} for DocumentServer and DesktopEditors. Each round (`-rc.N`, final) gets its own checklist comment from the [Release issue](https://github.com/Euro-Office/release/actions/workflows/issue.yml) workflow.

- Milestone: [open items in {{BASE}}](https://github.com/search?q=org%3AEuro-Office+milestone%3A{{BASE}}+is%3Aopen&type=issues)
- Pending changes: #4

## Blockers

Add issues and pull requests that must be fixed before the release.

- [ ] ...

## Preparation

- [ ] Day before: announce the release in the team chat and Matrix, ask for blockers and link this issue
- [ ] Review the open items in the milestone: add them as blockers or move them to the next milestone

## After the final release

Milestone commands use [`scripts/milestones.sh`](https://github.com/Euro-Office/.github/blob/main/scripts/milestones.sh) from Euro-Office/.github.

- [ ] Create the next milestone: `./scripts/milestones.sh create <next>`
- [ ] Move open items: `./scripts/milestones.sh move {{BASE}} <next>`
- [ ] Close the milestone: `./scripts/milestones.sh close {{BASE}}`
- [ ] Ask a Nextclouder to release the Euro-Office connector app, if needed
- [ ] Close this issue
