# 🚀 CI/CD Pipeline Setup Guide

This guide explains how to set up automated deployment to Google Play Store using GitHub Actions.

## 📋 Overview

Our CI/CD pipeline consists of two workflows:

1. **🚀 Deploy Android App to Play Store** (`deploy-android.yml`)
   - Triggers on push to `main`/`master` branch
   - Builds, signs, and deploys to Google Play Store
   - Auto-increments version numbers
   - Creates GitHub releases

2. **🔍 Build & Test (Development)** (`build-and-test.yml`)
   - Triggers on pull requests and development branches
   - Runs code analysis, tests, and builds debug APK
   - Provides feedback on code quality

## 🛠 Prerequisites Setup

### 1. Google Play Console Setup

#### Step 1: Create a Service Account
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Name it `github-actions-play-store`
6. Click **Create and Continue**
7. Skip role assignment for now
8. Click **Done**

#### Step 2: Generate Service Account Key
1. Click on your newly created service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Choose **JSON** format
5. Download the JSON file (keep it secure!)

#### Step 3: Enable Google Play Developer API
1. Go to [Google Cloud Console APIs](https://console.cloud.google.com/apis/)
2. Search for "Google Play Developer API"
3. Click **Enable**

#### Step 4: Grant Permissions in Play Console
1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to **Setup** → **API access**
3. Find your service account and click **Grant Access**
4. Grant these permissions:
   - **View app information and download bulk reports**
   - **Manage store listings, in-app products, and pricing**
   - **Manage and publish app updates**

### 2. Android Keystore Setup

#### Step 1: Prepare Your Keystore
Your keystore file should already exist at `/Users/bhavyasurana/my-release-key.jks`

#### Step 2: Convert Keystore to Base64
```bash
# Navigate to your keystore location
cd /Users/bhavyasurana/

# Convert keystore to base64
base64 -i my-release-key.jks -o keystore-base64.txt

# Copy the contents of keystore-base64.txt
cat keystore-base64.txt
```

## 🔐 GitHub Secrets Configuration

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these **Repository Secrets**:

### 🔑 API & Service Credentials
```
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```
- **Value:** Paste the entire contents of the service account JSON file

### 🗝 Android Keystore Secrets
```
ANDROID_KEYSTORE_BASE64
```
- **Value:** The base64 encoded keystore from Step 2 above

```
ANDROID_KEYSTORE_PASSWORD
```
- **Value:** Mission2018

```
ANDROID_KEY_PASSWORD  
```
- **Value:** Mission2018

```
ANDROID_KEY_ALIAS
```
- **Value:** my-key-alias

### 🌍 Environment Variables
```
API_KEY
```
- **Value:** Your main API key

```
IOS_API_BASE_URL
```
- **Value:** https://django-backend-236498773398.us-central1.run.app

```
ANDROID_API_BASE_URL
```
- **Value:** https://django-backend-236498773398.us-central1.run.app

```
IOS_WS_BASE_URL
```
- **Value:** wss://django-backend-236498773398.us-central1.run.app

```
ANDROID_WS_BASE_URL
```
- **Value:** wss://django-backend-236498773398.us-central1.run.app

### 🗺 Google Services
```
MAPS_API_KEY
```
- **Value:** Your Google Maps API key

```
FIREBASE_WEB_API_KEY
```
- **Value:** AIzaSyAZ_iAD9FJeMVicdkSouosVrbKuIpG3yjQ

```
FIREBASE_WEB_APP_ID
```
- **Value:** 1:767184260939:web:1c8a110b9b20860f7122ce

```
FIREBASE_MESSAGING_SENDER_ID
```
- **Value:** 767184260939

```
FIREBASE_PROJECT_ID
```
- **Value:** homiswap-b0dcf

### 🔐 OAuth Configuration
```
GOOGLE_OAUTH_SERVER_CLIENT_ID
```
- **Value:** 236498773398-om4ilh99d8haq7hdr9vf3fvcmbkncbbd.apps.googleusercontent.com

```
GOOGLE_OAUTH_REDIRECT_SCHEME
```
- **Value:** com.googleusercontent.apps.236498773398-08f9crnjv1hgqv6ksonmk135rdtrmnta

## 🚀 How the Pipeline Works

### Deployment Workflow (Production)

1. **Trigger:** Push to `main` branch
2. **Environment Setup:** 
   - Install Flutter, Java, dependencies
   - Create production environment file from secrets
3. **Security:** 
   - Decode keystore from base64
   - Create signing configuration
4. **Version Management:**
   - Auto-increment build number
   - Update pubspec.yaml
5. **Build:**
   - Create signed Android App Bundle (.aab)
   - Optimize for release
6. **Deploy:**
   - Upload to Google Play Store
   - Set to production track
7. **Finalize:**
   - Commit version bump
   - Create GitHub release
   - Cleanup sensitive files

### Development Workflow

1. **Trigger:** Pull request or push to development branches
2. **Quality Checks:**
   - Code analysis (flutter analyze)
   - Code formatting check
   - Unit tests with coverage
3. **Build Testing:**
   - Build debug APK
   - Upload as artifact
   - Comment on PR with download link

## 🎯 Usage Instructions

### For Production Deployment
```bash
# Simple: just push to main branch
git checkout main
git merge your-feature-branch
git push origin main

# The pipeline will automatically:
# ✅ Build the app
# ✅ Increment version
# ✅ Deploy to Play Store
# ✅ Create GitHub release
```

### For Manual Deployment
1. Go to **Actions** tab in GitHub
2. Select **🚀 Deploy Android App to Play Store**
3. Click **Run workflow**
4. Add release notes (optional)
5. Click **Run workflow**

### For Development Testing
```bash
# Create a pull request - APK will be automatically built
git checkout -b feature/my-new-feature
git push origin feature/my-new-feature
# Create PR on GitHub

# Or push to development branch
git checkout develop
git push origin develop
```

## 🔧 Customization Options

### Change Deployment Track
Edit `.github/workflows/deploy-android.yml`:
```yaml
track: internal  # Options: internal, alpha, beta, production
```

### Change Version Increment Strategy
Modify the version increment step to change major/minor versions instead of just build numbers.

### Add Slack Notifications
Add Slack webhook step to notify team of deployments:
```yaml
- name: 📢 Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 🛡 Security Best Practices

### ✅ What We Do Right
- All secrets stored in GitHub encrypted secrets
- Keystore handled as base64 to avoid binary issues
- Temporary files cleaned up after use
- Service account has minimal required permissions
- Environment variables injected at build time

### 🚨 Important Security Notes
- Never commit the service account JSON to repository
- Regularly rotate API keys and passwords
- Monitor Google Play Console for unauthorized access
- Use separate service accounts for different environments

## 🐛 Troubleshooting

### Common Issues

#### "Service account not found"
- Ensure service account JSON is correctly pasted in GitHub secrets
- Verify the service account has Play Console permissions

#### "Keystore password incorrect"
- Double-check keystore password in GitHub secrets
- Ensure base64 encoding is correct

#### "Version code already exists"
- The auto-increment failed - manually increment version in pubspec.yaml
- Check if a previous deployment partially succeeded

#### "Flutter build failed"
- Check Flutter version matches your local development
- Verify all dependencies are compatible
- Review build logs for specific error messages

### Debug Steps
1. Check **Actions** tab for detailed logs
2. Verify all secrets are set correctly
3. Test build locally with same Flutter version
4. Check Google Play Console for any policy violations

## 📞 Support

For issues with this CI/CD setup:
1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Verify all secrets are correctly configured
4. Test individual steps locally

---

**🎉 Once set up, you'll have a fully automated deployment pipeline!**
- Push code → Automatic Play Store deployment
- Pull requests → Automatic testing and APK generation
- Version management → Completely automated
- Release notes → Auto-generated from commits 