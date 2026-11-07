# fraimwork app

This repository is a fork of [cmux](https://github.com/manaflow-ai/cmux) by Manaflow, Inc.,
distributed under the GNU General Public License v3.0 or later (see `LICENSE`).
fraimwork is not affiliated with or endorsed by Manaflow. "cmux" is their name; this fork does not use it as a product name.

Changes in this fork (branch `fraimwork`), as required by GPL-3.0 section 5(a):

- 2026-11-07: replaced the upstream CI workflows with `.github/workflows/fraimwork-build.yml`.
- 2026-11-07: renamed what users see to "fraimwork". `scripts/fraimwork-rebrand.py` changes the app name,
  bundle id, permission prompts and translated strings at build time; the upstream sources stay as they are.
  `scripts/fraimwork-check-brand.sh` fails the build when user-visible text still says cmux.
  New placeholder icon drawn by `scripts/fraimwork-icon.swift`. The bundle adds a `fraimwork` command
  next to the upstream `cmux` command.

The BUSL-1.1 directories listed in `LICENSE` are not built or shipped by this fork.
