# CI/CD Pipeline Guide for iTeaGrow

A simple guide for the team on how our automated pipeline works.

---

## Quick Summary

Our pipeline automatically:
- Checks your code for errors and security issues
- Runs tests before merging
- Blocks secrets and large files from being committed
- Builds and deploys the application

---

## For Developers: Daily Workflow

### Step 1: Create a Branch

Always work on a feature branch, never directly on `main`:

```bash
git checkout -b feature/your-feature-name
```

**Branch naming rules:**
| Prefix | Use for | Example |
|--------|---------|---------|
| `feature/` | New features | `feature/add-login` |
| `bugfix/` | Bug fixes | `bugfix/fix-crash` |
| `hotfix/` | Urgent production fixes | `hotfix/security-patch` |
| `docs/` | Documentation only | `docs/update-readme` |

### Step 2: Make Your Changes

Write your code as usual. The pre-commit hooks will automatically check your code when you commit.

### Step 3: Commit Your Changes

```bash
git add .
git commit -m "feat: add user login feature"
```

**Commit message format:**
```
type: short description

Types:
- feat: new feature
- fix: bug fix
- docs: documentation
- style: formatting (no code change)
- refactor: code restructuring
- test: adding tests
- chore: maintenance
```

**Examples:**
- `feat: add disease detection API endpoint`
- `fix: resolve image upload crash`
- `docs: update API documentation`

### Step 4: Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then go to GitHub and create a Pull Request to `main`.

### Step 5: Wait for Checks

The pipeline will automatically run these checks on your PR:

| Check | What it does | Must pass? |
|-------|--------------|------------|
| Security Gate | Scans for secrets and vulnerabilities | Yes |
| Backend CI | Lints and tests Python code | Yes |
| Frontend CI | Analyzes and tests Flutter code | Yes |
| Docker Build | Validates Docker configuration | Yes |

You'll see green checkmarks or red X marks next to each check.

### Step 6: Fix Any Issues

If checks fail:
1. Click on the failed check to see details
2. Fix the issues in your code
3. Commit and push again
4. Checks will re-run automatically

### Step 7: Get Review and Merge

Once all checks pass:
1. Request review from a teammate
2. Address any review comments
3. Reviewer approves and merges

---

## What Gets Blocked Automatically

The pipeline will **reject** your code if it contains:

### Secrets (Blocked)
- API keys
- Passwords
- Private keys
- Tokens

**Fix:** Use environment variables instead. Add secrets to `.env` (which is gitignored).

### Large Files (Blocked)
- Files over 5MB
- ML model files (`.pt`, `.onnx`, `.h5`)

**Fix:** Use Git LFS or external storage for large files.

### Direct Commits to Main (Blocked)
- You cannot push directly to `main`
- All changes must go through Pull Requests

---

## Common Scenarios

### Scenario 1: Pre-commit Hook Fails

```
ruff.............................Failed
- src/api/routes.py:15:1 - unused import
```

**Solution:** The hook often auto-fixes issues. Just run:
```bash
git add .
git commit -m "your message"
```

If it still fails, manually fix the issue shown in the error.

### Scenario 2: CI Check Fails on GitHub

1. Go to your PR on GitHub
2. Click "Details" next to the failed check
3. Read the error message
4. Fix locally, commit, and push

### Scenario 3: "Secret Detected" Error

```
ERROR: Potential secret detected in config.py
```

**Solution:**
1. Remove the secret from your code
2. Use environment variables instead:
   ```python
   # Bad
   API_KEY = "sk-abc123..."

   # Good
   import os
   API_KEY = os.getenv("API_KEY")
   ```
3. Add the actual value to `.env` file (not committed)

### Scenario 4: Merge Conflicts

1. Update your branch with latest main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```
2. Resolve conflicts in your editor
3. Continue rebase:
   ```bash
   git add .
   git rebase --continue
   ```
4. Force push (only your feature branch):
   ```bash
   git push --force-with-lease
   ```

---

## Running Checks Locally

Before pushing, you can run checks locally to save time:

### Python Linting
```bash
pip install ruff black isort
ruff check src/
black --check src/
```

### Python Tests
```bash
pip install pytest
pytest tests/
```

### Flutter Analysis
```bash
cd frontend/iTeaGrow---Research-Project
flutter analyze
flutter test
```

### All Pre-commit Hooks
```bash
pre-commit run --all-files
```

---

## Pipeline Overview Diagram

```
Your Code
    │
    ▼
┌─────────────────┐
│  Pre-commit     │ ◄── Runs on your computer before commit
│  Hooks          │     (formatting, linting, secrets)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Push to        │
│  GitHub         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Create Pull    │
│  Request        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  GitHub Actions CI (Automatic)          │
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │ Security │ │ Backend  │ │Frontend │ │
│  │   Gate   │ │   CI     │ │   CI    │ │
│  └────┬─────┘ └────┬─────┘ └────┬────┘ │
│       │            │            │       │
│       └────────────┼────────────┘       │
│                    │                    │
└────────────────────┼────────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ All Checks   │
              │   Pass?      │
              └──────┬───────┘
                     │
           ┌─────────┴─────────┐
           │                   │
           ▼                   ▼
    ┌────────────┐      ┌────────────┐
    │  ✅ Ready   │      │  ❌ Fix     │
    │  to Merge  │      │  Issues    │
    └────────────┘      └────────────┘
```

---

## Deployment Process

### Automatic Deployments

| Branch | Deploys to | When |
|--------|------------|------|
| `main` | Staging | Automatically after merge |
| `v*.*.*` tag | Production | After manual approval |

### Creating a Release

1. Ensure `main` is stable and tested on staging
2. Create a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The release workflow will:
   - Build Docker images
   - Create GitHub release
   - Generate changelog
   - Deploy to production (after approval)

---

## Quick Reference Card

### Commands You'll Use Often

```bash
# Start new feature
git checkout -b feature/my-feature

# Check your code locally
pre-commit run --all-files

# Commit with good message
git commit -m "feat: description"

# Push to GitHub
git push origin feature/my-feature

# Update from main
git fetch origin && git rebase origin/main

# Run Python tests
pytest tests/

# Run Flutter tests
cd frontend/iTeaGrow---Research-Project && flutter test
```

### Commit Types Cheat Sheet

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting |
| `refactor` | Code restructure |
| `test` | Tests |
| `chore` | Maintenance |
| `ci` | CI/CD changes |

---

## Getting Help

- **Pipeline fails:** Check the error logs on GitHub Actions
- **Unsure about process:** Ask in team chat
- **Bug in pipeline:** Create issue in repository

---

## Summary

1. **Always use branches** - Never commit to main directly
2. **Write good commit messages** - Use the format: `type: description`
3. **Let the pipeline check your code** - Don't skip checks
4. **Fix issues before merging** - All checks must pass
5. **Ask for help** - If stuck, ask the team

The pipeline is here to help catch issues early and keep our codebase clean!
