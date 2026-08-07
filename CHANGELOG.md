# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2026-07-29

### Added

- **Guided troubleshooting**: `ds_list_process_instances` now attaches a `next_action` hint to RUNNING/FAILURE instances, pointing agents to `ds_list_task_instances` for detailed node inspection (v2.0.19)
- **58 tools** covering all DolphinScheduler operations (up from 53 in v0.1.0)
- **Navigational help**: `ds_help()` tool for category-based tool discovery
- **Raw API passthrough**: 4 tools (GET/POST/PUT/DELETE) for uncovered scenarios

### Changed

- **Reliable serial backfill**: `ds_complement_data` with `RUN_MODE_SERIAL` now uses `complementStartDate`/`complementEndDate` range format to ensure day-by-day execution order (v2.0.18)
- **Flexible task updates**: `ds_update_task_param` accepts both `snake_case` and `camelCase` field names (e.g., `pre_statements` or `preStatements`) (v2.0.17)
- **Enhanced timeout control**: Added missing timeout fields (`timeout`, `timeoutFlag`, `timeoutNotifyStrategy`) to `ds_update_task_param` (v2.0.17)

### Fixed

- **Backfill ordering bug**: Serial complement data no longer generates instances in random order (v2.0.18)
- **Field compatibility**: Resolved issues with `preStatements` field name variations (v2.0.17)

### Documentation

- Migrated to standard open source project structure
- Added `CONTRIBUTING.md` with contribution guidelines
- Added `OWNERS` file for project governance
- Reorganized docs into `docs/` directory
- Enhanced README with Landscape ecosystem attribution

---

## [0.1.0] - 2025-12-xx

### Added

- Initial release with 53+ tools
- Support for stdio / SSE / HTTP transports
- Dual authentication modes (header token / username+password)
- Docker and docker-compose deployment
- Examples for Claude Desktop and CodeBuddy integration

---

## Version Numbering

- **Major version (X.0.0)**: Breaking API changes
- **Minor version (0.X.0)**: New features, backward compatible (quarterly)
- **Patch version (0.0.X)**: Bug fixes, backward compatible (monthly)
