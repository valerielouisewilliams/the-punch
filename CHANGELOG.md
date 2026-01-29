# Changelog
All notable changes to this project will be documented in this file.
---

## [0.3.0] - 2026-01-29
### Added
- Support for image uploads using Amazon S3
- Backend logic to store image URLs alongside posts
- Initial AWS infrastructure documentation (EC2, RDS, S3)

### Changed
- Ongoing refactors to support media uploads and deployment workflow

### Fixed
- 

---

## [0.2.0] – 2026-01-28
### Added
- AWS RDS MySQL database for persistent data storage
- Initial Amazon S3 bucket for post image uploads
- IAM roles to securely allow EC2 access to S3
- Backend deployment workflow via GitHub → EC2 pull → server restart

### Changed
- Migrated database usage from local MySQL to AWS RDS
- Updated backend configuration to support cloud-based storage and networking

### Fixed
- Removed reliance on local-only database setup

