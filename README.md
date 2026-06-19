# ERP Production

Offline-first Flutter ERP for Android. Production, Fleet, Warehouse, Payroll, Accounting, Invoices, Customers, Payments.

## Quick Start - Choose Your Build Method

### Method 1: GitHub Actions (Recommended - No PC Required)
Build the APK in the cloud using GitHub's free servers. You just push code, GitHub builds the APK, and you download it.

**Requirements:**
- GitHub account (free)
- Your Supabase URL and Anon Key

**Steps:**
1. Create a new repository on GitHub
2. Push this project to your repo
3. Go to Settings → Secrets and variables → Actions
4. Add two secrets:
   - `SUPABASE_URL` = your Supabase project URL
   - `SUPABASE_ANON_KEY` = your Supabase anon key
5. Go to Actions → "Build Release APK" → Run workflow
6. Wait ~10 minutes, then download the APK from the artifacts

**For automatic releases:** Push a tag like `v1.0.0` and GitHub will create a release with the APK attached.

---

### Method 2: Build on Your Phone with Termux
Build the APK directly on your Android phone without a computer.

**Requirements:**
- Android phone with ARM64 processor (most phones from 2018+)
- At least 10GB free storage
- Android 11+ recommended
- Termux app from F-Droid (NOT Google Play Store)

**Steps:**

1. **Install Termux**
   - Download from F-Droid: https://f-droid.org/packages/com.termux/
   - Or from GitHub: https://github.com/termux/termux-app/releases
   - ⚠️ Do NOT use the Google Play Store version — it's outdated

2. **Grant storage permission**
   ```bash
   termux-setup-storage
   ```

3. **Copy project to Termux**
   - Extract the project ZIP to your phone's Downloads folder
   - In Termux, copy it:
   ```bash
   cp -r ~/storage/shared/Download/erp_production_v2 ~/erp_production
   cd ~/erp_production
   ```

4. **Run the build script**
   ```bash
   bash build_termux.sh
   ```
   - The script will install Flutter SDK (first time only, takes ~20 min)
   - Enter your Supabase URL and Anon Key when prompted
   - Wait for the build (10-30 minutes)
   - The APK will be saved to your Downloads folder

5. **Install the APK**
   ```bash
   xdg-open ~/storage/shared/Download/erp-production-*.apk
   ```
   Or find it in your Downloads app and tap to install.

---

### Method 3: Build on PC/Mac/Linux
Standard Flutter development setup.

```bash
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Supabase Setup

1. Create project at [supabase.com](https://supabase.com)
2. Go to SQL Editor → New query
3. Open `supabase/setup.sql` and run it
4. Copy your Project URL and Anon Key from Settings → API

---

## Architecture
- **Offline-first**: SQLite local DB with outbox sync to Supabase
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Sync**: Bidirectional sync with conflict resolution
- **Background**: WorkManager for periodic sync

## Modules
- Dashboard (live KPIs)
- Customers (CRUD, search, balance)
- Invoices (create with line items, PDF)
- Payments (record, allocate to invoices)
- Accounting (expenses, receipts)
- Fleet (vehicles, trips)
- Warehouse (stock, movements, low-stock alerts)
- Payroll (employees — consult accountant before real use)
- Settings (sync control, export, logout)

## Troubleshooting

### GitHub Actions build fails
- Check that `SUPABASE_URL` and `SUPABASE_ANON_KEY` secrets are set
- Check the Actions log for specific errors
- Make sure `pubspec.yaml` has no syntax errors

### Termux build fails
- Ensure you have at least 10GB free space
- Don't let your phone sleep during build
- If `flutter` command not found after install, restart Termux
- For out-of-memory errors, create swap:
  ```bash
  fallocate -l 2G swapfile
  mkswap swapfile
  swapon swapfile
  ```

### APK won't install
- Enable "Install unknown apps" for your file manager in Android settings
- Make sure you're installing the `app-release.apk`, not the AAB

## License
MIT
