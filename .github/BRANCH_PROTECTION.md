# Branch Protection Rules

This document outlines the recommended branch protection configuration for the iTeaGrow repository to ensure code quality, security, and a stable main branch.

## Protected Branches

### `main` (Production)

The main branch represents production-ready code. Configure the following protections in GitHub Settings → Branches → Add rule:

#### Required Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Require a pull request before merging** | ✅ Enabled | All changes must go through PR review |
| **Required approving reviews** | 2 | Minimum two reviewers for production code |
| **Dismiss stale reviews** | ✅ Enabled | New commits require re-review |
| **Require review from Code Owners** | ✅ Enabled | Ensure domain experts approve changes |
| **Require status checks to pass** | ✅ Enabled | Gate on CI pipeline |
| **Required status checks** | See list below | Specific checks that must pass |
| **Require branches to be up to date** | ✅ Enabled | Ensure latest main is integrated |
| **Require conversation resolution** | ✅ Enabled | All review comments must be addressed |
| **Require signed commits** | ✅ Recommended | Verify commit authenticity |
| **Require linear history** | ✅ Enabled | Clean, bisectable history |
| **Include administrators** | ✅ Enabled | No exceptions, even for admins |
| **Restrict who can push** | ✅ Enabled | Only merge via PR |
| **Allow force pushes** | ❌ Disabled | Prevent history rewriting |
| **Allow deletions** | ❌ Disabled | Prevent accidental deletion |

#### Required Status Checks for `main`

```
✅ PR Validation / Security Gate
✅ PR Validation / PR Status
✅ Backend CI / Backend CI Status
✅ Frontend CI / Frontend CI Status (if frontend changed)
✅ Docker Build / Docker Build Status (if docker changed)
✅ Security Scan / secret-scan
```

### `develop` (Integration)

Development integration branch for feature work.

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Require a pull request before merging** | ✅ Enabled | All changes must go through PR review |
| **Required approving reviews** | 1 | Single reviewer for faster iteration |
| **Dismiss stale reviews** | ✅ Enabled | New commits require re-review |
| **Require status checks to pass** | ✅ Enabled | Gate on CI pipeline |
| **Required status checks** | `Security Gate`, `Backend CI Status` | Core checks only |
| **Allow force pushes** | ❌ Disabled | Prevent history rewriting |

### `staging` (Pre-Production)

Staging environment for final testing before production.

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Require a pull request before merging** | ✅ Enabled | Controlled promotions |
| **Required approving reviews** | 1 | Single approval for staging |
| **Require status checks to pass** | ✅ Enabled | All tests must pass |

## Branch Naming Conventions

Enforce branch naming via repository ruleset:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `feature/*` | New features | `feature/user-authentication` |
| `bugfix/*` | Bug fixes | `bugfix/login-crash` |
| `hotfix/*` | Production hotfixes | `hotfix/security-patch` |
| `release/*` | Release preparation | `release/v1.2.0` |
| `docs/*` | Documentation only | `docs/api-guide` |
| `chore/*` | Maintenance tasks | `chore/update-dependencies` |

## Merge Strategy

### Recommended: Squash Merge for Feature Branches

```
Settings → General → Pull Requests:
✅ Allow squash merging (default)
❌ Allow merge commits
❌ Allow rebase merging

✅ Automatically delete head branches
```

**Rationale:**
- Clean, linear history on main
- Each feature = one commit
- Easy to revert entire features
- Automatic branch cleanup

## Tag Protection

Protect version tags:

```
Settings → Tags → Add rule:
Pattern: v*
Restrict who can create: Maintainers only
```

## Environment Protection

### Staging Environment

```yaml
Name: staging
Protection rules:
  - Required reviewers: 0 (automated deployment OK)
  - Wait timer: 0 minutes
  - Deployment branches: main, develop
```

### Production Environment

```yaml
Name: production
Protection rules:
  - Required reviewers: 1 (manual approval required)
  - Wait timer: 10 minutes (allow abort window)
  - Deployment branches: main only
  - Custom deployment policy: Only from tags matching v*.*.*
```

## Automated Setup via GitHub CLI

Run these commands to configure branch protection (requires admin access):

```bash
# Protect main branch
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["PR Validation / Security Gate","PR Validation / PR Status","Backend CI / Backend CI Status"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field required_linear_history=true \
  --field required_conversation_resolution=true

# Protect develop branch
gh api repos/{owner}/{repo}/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["PR Validation / Security Gate"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false

# Create tag protection rule
gh api repos/{owner}/{repo}/tags/protection \
  --method POST \
  --field pattern='v*'
```

## Rulesets (Modern Alternative)

GitHub Rulesets provide more granular control. Create via Settings → Rules → Rulesets:

```yaml
name: Main Branch Protection
target: branch
enforcement: active
bypass_actors:
  - organization_admin (with PR only)
conditions:
  ref_name:
    include: ["refs/heads/main"]
rules:
  - type: pull_request
    parameters:
      required_approving_review_count: 2
      dismiss_stale_reviews_on_push: true
      require_code_owner_review: true
      require_last_push_approval: true
  - type: required_status_checks
    parameters:
      strict_required_status_checks_policy: true
      required_status_checks:
        - context: "PR Validation / Security Gate"
        - context: "PR Validation / PR Status"
  - type: non_fast_forward
  - type: deletion
  - type: required_linear_history
  - type: required_signatures
```

## Security Recommendations

1. **Enable Secret Scanning**: Settings → Security → Secret scanning
2. **Enable Dependabot**: Settings → Security → Dependabot alerts + updates
3. **Require 2FA**: Settings → Moderation → Require two-factor authentication
4. **Audit Log Streaming**: Enterprise feature for compliance
5. **IP Allow Lists**: Restrict access to known IPs (Enterprise)

## Monitoring & Alerts

Set up notifications for:
- Failed required status checks
- Deployment failures
- Security alerts
- Branch protection bypasses (audit log)

## Exceptions Process

For emergency hotfixes requiring bypass:
1. Document the emergency in an issue
2. Get verbal approval from 2 maintainers
3. Create hotfix with `[EMERGENCY]` prefix
4. Complete full review within 24 hours post-merge
5. Conduct post-incident review
