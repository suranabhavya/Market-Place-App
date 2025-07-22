# GitHub Actions Permissions Fix

## Problem
The GitHub Actions workflow was failing with a 403 permission error when trying to commit version bumps:

```
remote: Permission to suranabhavya/Market-Place-App.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/suranabhavya/Market-Place-App/': The requested URL returned error: 403
Error: Process completed with exit code 128.
```

## Root Cause
GitHub Actions has restricted permissions by default for security. The workflow needs explicit permissions to:
1. Write to the repository (push commits)
2. Create releases
3. Access repository contents

## Solution Applied

### 1. Added Workflow Permissions
```yaml
jobs:
  deploy:
    name: 📱 Build & Deploy Android
    runs-on: ubuntu-latest
    
    # Grant necessary permissions for the workflow
    permissions:
      contents: write        # Required to push commits and create releases
      actions: read         # Required to read workflow status
      security-events: write # Required for security scanning
```

### 2. Updated Checkout Action
```yaml
- name: 📥 Checkout Repository
  uses: actions/checkout@v4
  with:
    fetch-depth: 0
    token: ${{ secrets.GITHUB_TOKEN }}  # Explicit token usage
```

### 3. Improved Commit Process
```yaml
- name: 📝 Commit Version Bump
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    # Configure git with proper bot credentials
    git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    
    # Set up authentication and push
    git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${{ github.repository }}
    git push origin HEAD:${{ github.ref_name }}
```

## Alternative Solutions

### Option 1: Use Personal Access Token (PAT)
If the above doesn't work due to branch protection rules:

1. Create a PAT in GitHub Settings > Developer settings > Personal access tokens
2. Add it as a repository secret (e.g., `PERSONAL_ACCESS_TOKEN`)
3. Use it in checkout:
```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
```

### Option 2: Disable Version Bump Commits
If version bumping isn't critical, comment out the commit step:
```yaml
# - name: 📝 Commit Version Bump
#   run: |
#     # Version bump commit disabled
```

## Repository Settings to Check

### Branch Protection Rules
If your main/master branch has protection rules:
1. Go to Settings > Branches
2. Edit branch protection rule
3. Check "Allow GitHub Actions to bypass branch protection"
4. Or add the GitHub Actions bot as an exception

### Actions Permissions
1. Go to Settings > Actions > General
2. Ensure "Read and write permissions" is selected
3. Check "Allow GitHub Actions to create and approve pull requests"

## Verification Steps

1. ✅ Workflow permissions added
2. ✅ GITHUB_TOKEN explicitly used
3. ✅ Proper git configuration with bot credentials
4. ✅ Remote URL set with authentication token
5. ✅ Error handling for no changes scenario

## Expected Outcome
The workflow should now successfully commit version bumps back to the repository without permission errors.

## Troubleshooting

If you still get 403 errors:
1. Check repository settings for Actions permissions
2. Verify branch protection rules
3. Consider using a Personal Access Token
4. Ensure the workflow is running on the correct branch

## Security Considerations
- The GITHUB_TOKEN has limited scope to the current repository
- Bot commits are clearly identified as automated
- The `[skip ci]` tag prevents infinite workflow loops
- Minimal permissions are granted (only what's needed) 