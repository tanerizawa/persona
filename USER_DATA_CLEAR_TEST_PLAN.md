# Final User Data Clearing Test Plan

## Overview
Memastikan bahwa semua data user-specific benar-benar dihapus saat logout atau switch account, sehingga tidak ada data yang tersisa untuk user berikutnya.

## Test Scenarios

### 1. Login Test Account A
**Steps:**
1. Jalankan aplikasi
2. Login dengan akun A (username: testuser1, password: test123)
3. Navigasi ke Chat page dan kirim beberapa pesan
4. Navigasi ke Settings > Little Brain Dashboard
5. Tambahkan beberapa memories atau data personality
6. Catat data yang tersimpan

**Expected Result:**
- Login berhasil
- Chat history terekam
- Little Brain memories tersimpan
- User dapat melihat semua data yang dibuat

### 2. User Data Clear Test via Settings
**Steps:**
1. Masih dalam session account A
2. Navigasi ke Settings
3. Scroll ke bawah, cari "User Management Test"
4. Tap "Test Clear User Data"
5. Konfirmasi clear data
6. Periksa apakah semua data terhapus

**Expected Result:**
- Semua chat history terhapus
- Semua Little Brain memories terhapus
- Biometric session cleared
- Auth tokens cleared
- UI menunjukkan data kosong

### 3. Login Test Account B
**Steps:**
1. Setelah clear data, login dengan akun B (username: testuser2, password: test456)
2. Periksa Chat page - harus kosong
3. Periksa Little Brain Dashboard - harus kosong
4. Tambahkan data baru untuk account B
5. Catat bahwa tidak ada data dari account A

**Expected Result:**
- Chat history kosong (tidak ada data dari account A)
- Little Brain memories kosong
- Dapat menambah data baru untuk account B
- No cross-contamination antar account

### 4. Logout Test
**Steps:**
1. Masih dalam session account B
2. Tambahkan beberapa chat dan memories
3. Logout melalui Settings > Logout
4. Verify logout berhasil dan kembali ke login screen
5. Login kembali dengan account A
6. Periksa apakah tidak ada data dari account B

**Expected Result:**
- Logout berhasil
- Kembali ke authentication screen
- Login dengan account A hanya menunjukkan data account A (jika ada)
- Tidak ada data account B yang terlihat

### 5. App Restart Test
**Steps:**
1. Close aplikasi completely
2. Restart aplikasi
3. Login dengan account C (username: testuser3, password: test789)
4. Verify app mulai dengan state yang bersih

**Expected Result:**
- App restart dengan state bersih
- Login berhasil
- Tidak ada data residual dari session sebelumnya

## Critical Checkpoints

### A. Data Yang Harus Dihapus:
- [ ] Access token dan refresh token
- [ ] Biometric session
- [ ] Chat conversation history
- [ ] Little Brain memories
- [ ] Personality profile data
- [ ] User preferences (jika user-specific)

### B. Data Yang Boleh Tetap:
- [ ] App settings global (theme, language jika tidak user-specific)
- [ ] Device-level configurations
- [ ] App installation data

## Manual Verification Commands

```bash
# Check stored data in secure storage (for debugging)
# This would be done via UserManagementTestWidget in the app

# Verify auth state
# Check: SecureStorageService.isAuthenticated()

# Verify chat data
# Check: ChatLocalDataSource.getConversationHistory()

# Verify Little Brain data  
# Check: LittleBrainLocalRepository.getAllMemories()

# Verify biometric session
# Check: BiometricAuthService.isBiometricSessionActive()
```

## Implementation Status

✅ **COMPLETED:**
- [x] ClearUserDataUseCase implementation
- [x] AuthBloc integration with ClearUserDataUseCase
- [x] UserManagementTestWidget for manual testing
- [x] Settings page integration
- [x] Dependency injection setup
- [x] All critical errors resolved

🔄 **TESTING:**
- [ ] Manual QA testing dengan test plan ini
- [ ] Verify cross-account data isolation
- [ ] Performance impact assessment

## Notes for QA Tester

1. **Focus Areas:**
   - Data persistence across sessions
   - Cross-account contamination
   - Complete data clearing
   - UI state reset

2. **Edge Cases:**
   - App crash during logout
   - Network interruption during clear
   - Multiple rapid logins/logouts
   - Background app termination

3. **Success Criteria:**
   - Zero data leakage between accounts
   - Complete data clearing on logout
   - Clean state on each login
   - Robust error handling

## Test Environment
- Flutter Version: 3.32.5
- Target Platform: Android Emulator (API 35)
- Test Mode: Debug with monitoring enabled
- Backend: Production auth service with test accounts
