# Reschedule Feature Implementation Summary

## Overview
Implementasi fitur reschedule job yang muncul ketika user mencoba cancel job. Fitur ini mengikuti wireframe yang diberikan dan menggunakan style UI yang konsisten dengan aplikasi.

---

## Files Created/Modified

### 1. New Files Created

#### a. `lib/data/datasource/reschedule_job_datasource.dart`
- Datasource untuk handle API call reschedule job
- Method: `rescheduleJob(jobId, newDate, notes)`
- Menggunakan HTTP POST ke endpoint `/reschedule-job/{jobId}`
- Error handling yang konsisten dengan datasource lain

#### b. `lib/data/models/response/reschedule_job_response_model.dart`
- Response model untuk reschedule job API
- Fields: `success`, `message`
- Consistent dengan response model lain (cancel, finish, dll)

#### c. `RESCHEDULE_API_SPEC.md`
- Dokumentasi lengkap untuk backend developer
- Spesifikasi endpoint, request/response format
- Business logic requirements
- Database schema suggestions
- Testing checklist

#### d. `RESCHEDULE_IMPLEMENTATION_SUMMARY.md`
- File ini - summary implementasi

### 2. Modified Files

#### a. `lib/core/constants/variables.dart`
- Added: `rescheduleJobEndpoint = '$baseUrl/reschedule-job'`

#### b. `lib/page/jobs/presentation/job_details_page.dart`
**Changes:**
1. Import `reschedule_job_datasource.dart`
2. Added `_rescheduleNotesController` TextEditingController
3. Added method `_showRescheduleDialog()` - Dialog reschedule dengan:
   - Date picker
   - Time picker
   - Notes text field
   - Cancel & Reschedule buttons
   - Gradient background sesuai style app
4. Modified `_cancelJob()` flow:
   - Menampilkan reschedule dialog terlebih dahulu
   - Jika user cancel dari reschedule, baru tampilkan konfirmasi cancel job
   - Flow: Cancel button → Reschedule dialog → Cancel confirmation → Cancel reason

---

## UI/UX Flow

### User Journey
```
1. User pada Job Details Page (ongoing job)
2. User klik tombol "Cancel"
3. ✨ Muncul dialog "Think About Rescheduling"
   - Menampilkan date picker (default: tomorrow)
   - Menampilkan time picker (default: current time)
   - Text field untuk notes (optional)
   - 2 buttons: "Cancel" (red) dan "Reschedule" (orange)
4. User memilih:
   a. Klik "Reschedule" → API call → Success/Error message → Back to jobs list
   b. Klik "Cancel" → Lanjut ke konfirmasi cancel job normal
```

### Dialog Design Features
- **Header:** "Think About\nRescheduling" (center aligned, bold)
- **Date/Time Picker:** 
  - Rounded container dengan border primary color
  - Date section dengan icon calendar
  - Divider
  - Time section dengan icon clock
  - Tap untuk open native picker
- **Notes Field:**
  - Rounded container
  - Placeholder: "Leave notes here"
  - Multi-line (3 lines)
- **Buttons:**
  - Cancel: Red background, white text
  - Reschedule: Orange (#FF9800), white text
  - Both: Rounded corners, equal width

---

## Technical Implementation Details

### Date/Time Handling
```dart
// Default values
DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
TimeOfDay selectedTime = TimeOfDay.now();

// Combine to DateTime
final scheduledDateTime = DateTime(
  selectedDate.year,
  selectedDate.month,
  selectedDate.day,
  selectedTime.hour,
  selectedTime.minute,
);

// Convert to ISO 8601 for API
newDate.toIso8601String()
```

### API Call Structure
```dart
POST /reschedule-job/{jobId}?x-key={apiKey}
Headers: Content-Type: application/json
Body: {
  "new_date": "2024-12-25T14:30:00.000Z",
  "notes": "Optional notes"
}
```

### Error Handling
- API key validation
- Network error handling
- Server error message extraction
- User-friendly error messages via SnackBar
- Loading indicator during API call

---

## Backend Requirements (BELUM DIIMPLEMENTASI)

### Endpoint yang Harus Dibuat
**URL:** `POST /reschedule-job/{jobId}`

### Yang Harus Disiapkan Backend:
1. **Endpoint Handler**
   - Accept POST request dengan jobId parameter
   - Validate API key dari query parameter
   - Parse JSON body (new_date, notes)

2. **Validation**
   - Job ID exists
   - New date is in the future
   - User has permission to reschedule
   - ISO 8601 date format validation

3. **Database Operations**
   - Update job_date field
   - Save reschedule notes
   - Update reschedule_count
   - Save to history table

4. **Response**
   - Return JSON: `{"Success": true/false, "Message": "..."}`
   - Appropriate HTTP status codes

5. **Optional Features**
   - Send notification to customer
   - Update calendar system
   - Audit logging

### Database Schema Suggestions
```sql
-- Add to jobs table
ALTER TABLE jobs ADD COLUMN reschedule_count INT DEFAULT 0;
ALTER TABLE jobs ADD COLUMN last_rescheduled_at TIMESTAMP NULL;
ALTER TABLE jobs ADD COLUMN reschedule_notes TEXT NULL;

-- Create history table
CREATE TABLE job_reschedule_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  job_id INT NOT NULL,
  old_date DATETIME NOT NULL,
  new_date DATETIME NOT NULL,
  notes TEXT NULL,
  rescheduled_by INT NOT NULL,
  rescheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id),
  FOREIGN KEY (rescheduled_by) REFERENCES users(id)
);
```

---

## Testing Instructions

### Frontend Testing (Can Test Now)
1. Run aplikasi
2. Login sebagai driver
3. Start a job (ongoing job)
4. Klik tombol "Cancel"
5. Verify reschedule dialog muncul dengan:
   - Title "Think About Rescheduling"
   - Date picker (tap to change)
   - Time picker (tap to change)
   - Notes field
   - Cancel & Reschedule buttons
6. Test date picker functionality
7. Test time picker functionality
8. Test notes input
9. Klik "Cancel" → should proceed to cancel confirmation
10. Klik "Reschedule" → will show error (backend not ready)

### Backend Testing (After Implementation)
1. Test dengan valid data → should return success
2. Test dengan invalid job ID → should return 404
3. Test dengan past date → should return validation error
4. Test database updates
5. Test history logging
6. Test with/without notes
7. Test concurrent requests
8. Test with invalid API key

---

## Code Style Compliance

### ✅ Follows Existing Patterns
- Datasource pattern consistent dengan `CancelJobDatasource`, `FinishJobDatasource`
- Response model pattern consistent dengan existing models
- Error handling pattern sama dengan existing code
- UI style menggunakan gradient, rounded corners, dan color scheme yang sama
- TextEditingController management (init & dispose)
- Dialog pattern dengan StatefulBuilder
- Loading indicator pattern
- SnackBar notification pattern

### ✅ UI Consistency
- Menggunakan `theme.colorScheme` dan `theme.textTheme`
- Gradient backgrounds sesuai dengan card designs di app
- Border radius konsisten (16-28px)
- Button styles konsisten dengan existing buttons
- Color scheme: Primary blue, Error red, Orange untuk reschedule
- Spacing dan padding konsisten

---

## Next Steps

### For Backend Developer:
1. ✅ Baca `RESCHEDULE_API_SPEC.md` untuk detail lengkap
2. ⏳ Implement endpoint `/reschedule-job/{jobId}`
3. ⏳ Setup database schema (jobs table updates + history table)
4. ⏳ Implement validation logic
5. ⏳ Test endpoint dengan Postman/cURL
6. ⏳ Deploy ke server
7. ⏳ Inform frontend developer when ready

### For Frontend Developer (You):
1. ✅ Implementation complete
2. ⏳ Test UI flow (can test now)
3. ⏳ Wait for backend implementation
4. ⏳ Test integration with real API
5. ⏳ Handle edge cases if any
6. ⏳ Update error messages if needed based on actual API responses

---

## Notes

### Design Decisions
1. **Reschedule First Approach:** Dialog reschedule muncul dulu sebelum cancel untuk encourage user untuk reschedule instead of cancel
2. **Default Date:** Tomorrow untuk convenience
3. **Optional Notes:** Tidak required agar user tidak terhambat
4. **Two-Step Cancel:** Reschedule dialog → Cancel confirmation untuk prevent accidental cancellation

### Potential Improvements (Future)
- [ ] Add validation untuk prevent reschedule ke waktu yang sudah lewat
- [ ] Add confirmation message sebelum reschedule
- [ ] Show current job date di dialog
- [ ] Add quick date options (Tomorrow, Next Week, etc.)
- [ ] Add reschedule history view
- [ ] Add ability to reschedule multiple times
- [ ] Add notification when job is rescheduled

---

## Contact & Support
Untuk pertanyaan atau issue, contact frontend developer.

**Implementation Date:** 2024-11-06  
**Status:** ✅ Frontend Complete | ⏳ Backend Pending  
**Version:** 1.0.0
