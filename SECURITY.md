# Security Notice

## Environment Variables Setup

This project uses environment variables to store sensitive Firebase configuration. **Never commit the `.env` file to version control.**

### Setup Instructions

1. Copy the `.env.example` file to create your own `.env` file:

   ```bash
   cp .env.example .env
   ```

2. Fill in your actual Firebase configuration values in the `.env` file. You can get these values from:
   - Firebase Console: https://console.firebase.google.com/
   - Project Settings > General > Your apps
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)

3. **IMPORTANT**: Never commit the following files:
   - `.env`
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`

These files are already listed in `.gitignore` to prevent accidental commits.

### Required Environment Variables

See `.env.example` for a complete list of required variables:

- Firebase API keys for Web, Android, iOS, and macOS
- Firebase App IDs
- Firebase project configuration
- Google OAuth Client IDs

### Security Best Practices

1. **Never share your `.env` file** or API keys in public repositories
2. **Rotate API keys** if they are accidentally exposed
3. **Use Firebase security rules** to restrict API access
4. **Enable Firebase App Check** for additional security
5. **Monitor Firebase usage** for suspicious activity

### If API Keys Are Exposed

If you accidentally commit API keys:

1. **Immediately rotate them** in Firebase Console:
   - Go to Project Settings > Service accounts
   - Regenerate keys
   - Update your `.env` file

2. **Remove sensitive commits** from git history:

   ```bash
   # Use git filter-branch or BFG Repo-Cleaner
   # See: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
   ```

3. **Force push the cleaned history** (be careful with this):

   ```bash
   git push --force
   ```

4. **Notify team members** to pull the new history

### Contact

If you discover a security vulnerability, please report it immediately by creating a private security advisory on GitHub or contacting the maintainers directly.
