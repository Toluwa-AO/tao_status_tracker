# Security Setup Guide

## Environment Variables Setup

### 1. Create Environment File
```bash
cp .env.example .env
```

### 2. Fill Real Values
Edit `.env` with your actual API keys from Firebase Console

### 3. Verify Protection
Ensure `.env` is in `.gitignore`

## Security Checklist

### ✅ Files Protected
- [x] `.env` in `.gitignore`
- [x] Firebase config removed from git
- [x] Template file safe for git
- [x] No hardcoded keys in source

### ⚠️ Files to Check
- [ ] Android Google Services file
- [ ] iOS Google Services file
- [ ] Any config files with keys

### 🚨 Never Commit
- Real API keys
- Firebase config files
- Google Services files
- Environment files with real values

## Key Management
- Rotate keys every 90 days
- Monitor usage in console
- Use least privilege access