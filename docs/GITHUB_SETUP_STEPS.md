# GitHub Setup Steps

Follow these steps to publish your Raspberry Pi OS project to GitHub:

## 1. Create the GitHub Repository

1. Go to https://github.com/new in your web browser
2. Enter "my_rasp_OS" as the Repository name
3. Add a description: "Custom Raspberry Pi OS for 3B with AirPlay, Google Cast, and WiFi tools"
4. Choose "Public" or "Private" as desired
5. Do NOT initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## 2. Push Your Code (HTTPS Method)

Run the following command in your terminal:

```bash
git push -u origin main
```

If prompted for credentials:

- Username: Your GitHub username
- Password: Use your Personal Access Token (PAT), not your GitHub password

## 3. Create a Personal Access Token (if needed)

If you don't have a Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token"
3. Give it a name like "my_rasp_OS"
4. Select at least the "repo" scope
5. Click "Generate token"
6. Copy the token immediately (you won't see it again)
7. Use this token as your password when pushing

## 4. Alternative: SSH Method

If you prefer using SSH:

1. Generate an SSH key:

   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. Add the key to your SSH agent:

   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. Add the public key to GitHub:

   - Copy the public key:
     ```bash
     cat ~/.ssh/id_ed25519.pub
     ```
   - Go to https://github.com/settings/keys
   - Click "New SSH key"
   - Paste your key and save

4. Change remote URL to SSH:

   ```bash
   git remote set-url origin git@github.com:5u00n/my_rasp_OS.git
   ```

5. Push your code:
   ```bash
   git push -u origin main
   ```

## 5. Verify Your Repository

After pushing, visit https://github.com/5u00n/my_rasp_OS to confirm your code is uploaded.
