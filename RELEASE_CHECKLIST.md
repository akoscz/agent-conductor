# Agent Conductor Release Checklist

This checklist should be followed for each release of Agent Conductor.

## Pre-Release Checklist

### Code Preparation
- [ ] All feature branches merged to main
- [ ] All tests passing locally
- [ ] Code reviewed and approved
- [ ] Documentation updated
  - [ ] README.md reflects new features
  - [ ] Installation guide updated
  - [ ] Architecture docs current
  - [ ] Configuration examples updated

### Version Management
- [ ] VERSION file updated with new version number
- [ ] Version follows semantic versioning (v{MAJOR}.{MINOR}.{PATCH})
- [ ] Commit message follows format: "chore: bump version to v0.0.1"

### Testing
- [ ] Run full test suite: `./orchestration/scripts/tests/run_tests.sh`
- [ ] Manual testing on macOS
- [ ] Manual testing on Linux (if available)
- [ ] Installer script tested locally

## Release Process

### GitHub Release
1. [ ] Push all changes to main branch
2. [ ] Go to GitHub Actions tab
3. [ ] Select "Release Agent Conductor" workflow
4. [ ] Click "Run workflow"
5. [ ] Enter version (e.g., v0.0.1)
6. [ ] Monitor workflow execution
7. [ ] Verify all jobs complete successfully

### Release Validation
- [ ] GitHub release created with correct tag
- [ ] Release assets uploaded:
  - [ ] agent-conductor-v{VERSION}.tar.gz
  - [ ] checksums.txt
  - [ ] install.sh
- [ ] Release notes generated
- [ ] Download links working

### Post-Release Testing
- [ ] Test installation from release:
  ```bash
  curl -LO https://github.com/{USER}/agent-conductor/releases/download/v0.0.1/install.sh
  chmod +x install.sh
  ./install.sh --version v0.0.1
  ```
- [ ] Verify installed version works
- [ ] Test basic conductor commands

## Post-Release Checklist

### Communication
- [ ] Update project status in README if needed
- [ ] Create announcement (if applicable)
- [ ] Update any external documentation

### Monitoring
- [ ] Monitor GitHub issues for installation problems
- [ ] Check for any automated alerts
- [ ] Gather initial feedback

### Planning
- [ ] Create issues for any bugs found
- [ ] Plan next release features
- [ ] Update roadmap if needed

## Rollback Plan

If critical issues are found:
1. [ ] Delete the problematic release from GitHub
2. [ ] Fix the issues in a hotfix branch
3. [ ] Create new release with patch version bump
4. [ ] Communicate the issue and fix to users

## Version 0.0.1 Specific Notes

For the initial v0.0.1 release:
- This is an alpha release focused on basic functionality
- macOS is the primary supported platform
- Manual release process via GitHub Actions
- Basic installer script functionality
- Limited to core orchestration features

Remember: This is Phase 1 of the distribution strategy. Advanced features like automated releases, cross-platform support, and package manager integration will come in future phases.