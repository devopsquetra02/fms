# Reschedule Job API Specification

## Overview
Dokumentasi ini menjelaskan spesifikasi API yang diperlukan untuk fitur reschedule job pada aplikasi FMS.

## Endpoint

### Reschedule Job
**Endpoint:** `POST /reschedule-job/{jobId}`

**Base URL:** `http://quetraverse.pro/efms/api/myapi`

**Full URL:** `http://quetraverse.pro/efms/api/myapi/reschedule-job/{jobId}`

---

## Request

### URL Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `jobId` | integer | Yes | ID dari job yang akan di-reschedule |

### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x-key` | string | Yes | API Key untuk autentikasi user |

### Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "new_date": "2024-12-25T14:30:00.000Z",
  "notes": "Customer request to reschedule due to unavailability"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `new_date` | string (ISO 8601) | Yes | Tanggal dan waktu baru untuk job dalam format ISO 8601 |
| `notes` | string | No | Catatan tambahan untuk reschedule (optional) |

---

## Response

### Success Response (200 OK)
```json
{
  "Success": true,
  "Message": "Job rescheduled successfully"
}
```

### Error Response (4xx/5xx)
```json
{
  "Success": false,
  "Message": "Error message description"
}
```

---

## Response Fields
| Field | Type | Description |
|-------|------|-------------|
| `Success` | boolean | Status keberhasilan request |
| `Message` | string | Pesan response dari server |

---

## Example Request

### cURL
```bash
curl -X POST "http://quetraverse.pro/efms/api/myapi/reschedule-job/123?x-key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "new_date": "2024-12-25T14:30:00.000Z",
    "notes": "Customer request to reschedule"
  }'
```

### Dart (Current Implementation)
```dart
final uri = Uri.parse(
  '${Variables.rescheduleJobEndpoint}/$jobId',
).replace(queryParameters: {'x-key': apiKey});

final body = {
  'new_date': newDate.toIso8601String(),
  if (notes != null && notes.isNotEmpty) 'notes': notes,
};

final response = await http.post(
  uri,
  headers: {'Content-Type': 'application/json'},
  body: json.encode(body),
);
```

---

## Business Logic Requirements

### Backend Should Handle:
1. **Validation**
   - Validasi bahwa `jobId` exists dan valid
   - Validasi bahwa `new_date` adalah tanggal di masa depan
   - Validasi bahwa user memiliki permission untuk reschedule job tersebut
   - Validasi format ISO 8601 untuk `new_date`

2. **Database Updates**
   - Update field `job_date` pada tabel jobs dengan nilai `new_date`
   - Simpan `notes` jika ada (bisa di field terpisah atau di history)
   - Update status job jika diperlukan
   - Catat timestamp reschedule dan user yang melakukan reschedule

3. **Logging & History**
   - Simpan history reschedule untuk audit trail
   - Log informasi: old_date, new_date, user_id, timestamp, notes

4. **Notifications (Optional)**
   - Kirim notifikasi ke customer tentang perubahan jadwal
   - Kirim notifikasi ke admin/dispatcher
   - Update calendar/schedule system jika ada

5. **Error Handling**
   - Return appropriate HTTP status codes
   - Return descriptive error messages
   - Handle edge cases (job already completed, job cancelled, etc.)

---

## Status Codes
| Code | Description |
|------|-------------|
| 200 | Success - Job berhasil di-reschedule |
| 400 | Bad Request - Invalid input atau validation error |
| 401 | Unauthorized - API key tidak valid |
| 403 | Forbidden - User tidak memiliki permission |
| 404 | Not Found - Job ID tidak ditemukan |
| 500 | Internal Server Error - Server error |

---

## Notes for Backend Developer

### Database Schema Suggestion
Pertimbangkan untuk menambahkan field berikut pada tabel jobs (jika belum ada):
```sql
ALTER TABLE jobs ADD COLUMN reschedule_count INT DEFAULT 0;
ALTER TABLE jobs ADD COLUMN last_rescheduled_at TIMESTAMP NULL;
ALTER TABLE jobs ADD COLUMN reschedule_notes TEXT NULL;
```

### History Table Suggestion
Buat tabel untuk menyimpan history reschedule:
```sql
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

### Integration Points
1. **Frontend Flow:**
   - User klik tombol "Cancel" pada ongoing job
   - Muncul dialog "Think About Rescheduling"
   - User pilih tanggal/waktu baru dan optional notes
   - Klik "Reschedule" → API dipanggil
   - Klik "Cancel" → Lanjut ke flow cancel job normal

2. **Related Endpoints:**
   - Endpoint ini terkait dengan `/cancel-job/{jobId}` endpoint
   - User flow: Reschedule dialog → Cancel confirmation → Cancel reason

---

## Testing Checklist
- [ ] Test dengan valid job ID
- [ ] Test dengan invalid/non-existent job ID
- [ ] Test dengan tanggal di masa lalu (should fail)
- [ ] Test dengan tanggal di masa depan (should success)
- [ ] Test dengan notes kosong
- [ ] Test dengan notes panjang
- [ ] Test dengan API key tidak valid
- [ ] Test dengan job yang sudah completed
- [ ] Test dengan job yang sudah cancelled
- [ ] Verify database updates correctly
- [ ] Verify history logging works
- [ ] Test concurrent reschedule requests

---

## Contact
Untuk pertanyaan atau klarifikasi, hubungi frontend developer.

**Last Updated:** 2024-11-06
