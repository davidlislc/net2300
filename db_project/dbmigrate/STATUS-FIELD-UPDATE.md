# Status Field Update

## Overview
Added a `status` field to the logs table with four possible values:
- **pending** (default)
- **processing**
- **done**
- **error**

## Changes Made

### 1. Backend (server.js)
- ✅ Updated database schema to include `status` ENUM field
- ✅ Added index on status field for better query performance
- ✅ Modified POST endpoint to accept and validate status
- ✅ Added new PATCH endpoint `/api/logs/:id/status` to update status
- ✅ Added PATCH to CORS allowed methods

### 2. Frontend - LogForm.js
- ✅ Added status field to form state (defaults to 'pending')
- ✅ Added status dropdown selector with all 4 options
- ✅ Status is included in POST request
- ✅ Form resets status to 'pending' after submission

### 3. Frontend - LogList.js
- ✅ Added status dropdown in each log item header
- ✅ Added status badge display
- ✅ Added color coding for different statuses
- ✅ Added `onStatusChange` callback for updating status
- ✅ Status changes update via PATCH request

### 4. Frontend - App.js
- ✅ Added `updateLogStatus()` function
- ✅ Passed `onStatusChange` prop to LogList component
- ✅ Automatic refresh after status update

### 5. Frontend - App.css
- ✅ Added styles for status badges (pending, processing, done, error)
- ✅ Added styles for status dropdown selector
- ✅ Added color-coded left border for log items based on status
- ✅ Color scheme:
  - **Pending**: Yellow/Gold (#ffc107)
  - **Processing**: Blue (#0d6efd)
  - **Done**: Green (#198754)
  - **Error**: Red (#dc3545)

## API Endpoints

### Existing Endpoints
- `GET /api/logs` - Get all logs (includes status)
- `POST /api/logs` - Create log (now accepts status)
- `DELETE /api/logs/:id` - Delete log
- `DELETE /api/logs` - Clear all logs

### New Endpoint
- `PATCH /api/logs/:id/status` - Update log status
  ```json
  {
    "status": "done"
  }
  ```

## How to Apply Changes

### Option 1: Recreate Database (Clean Start)
```bash
cd log-app

# Stop and remove containers
docker compose down

# Remove the database volume to force recreation
docker volume rm log-app_mariadb_data

# Rebuild and start
docker compose up -d --build

# Verify the new schema
docker exec -it logapp-mariadb mysql -uroot -prootpassword migrate -e "DESCRIBE logs;"
```

### Option 2: Alter Existing Table (Preserve Data)
If you want to keep existing log entries:

```bash
# Add status column to existing table
docker exec -it logapp-mariadb mysql -uroot -prootpassword migrate -e "
ALTER TABLE logs 
ADD COLUMN status ENUM('pending', 'processing', 'done', 'error') DEFAULT 'pending' AFTER source,
ADD INDEX idx_status (status);
"

# Verify the change
docker exec -it logapp-mariadb mysql -uroot -prootpassword migrate -e "DESCRIBE logs;"

# Rebuild containers to apply code changes
docker compose up -d --build
```

## Expected Table Schema

After applying changes, your `logs` table should look like:

```
+------------+--------------------------------------------------+------+-----+-------------------+
| Field      | Type                                             | Null | Key | Default           |
+------------+--------------------------------------------------+------+-----+-------------------+
| id         | int(11)                                          | NO   | PRI | NULL              |
| message    | text                                             | NO   |     | NULL              |
| source     | varchar(100)                                     | YES  |     | NULL              |
| status     | enum('pending','processing','done','error')      | YES  | MUL | pending           |
| timestamp  | timestamp                                        | NO   | MUL | CURRENT_TIMESTAMP |
+------------+--------------------------------------------------+------+-----+-------------------+
```

## Testing

1. **Create a new log entry**
   - Form now has a Status dropdown
   - Default is "Pending"
   - Select different status before submitting

2. **View log entries**
   - Each log shows a color-coded status badge
   - Left border color matches status
   - Status dropdown in header allows inline updates

3. **Update status**
   - Click status dropdown on any log
   - Select new status
   - Page refreshes automatically with updated status

4. **Visual indicators**
   - 🟡 Yellow = Pending
   - 🔵 Blue = Processing
   - 🟢 Green = Done
   - 🔴 Red = Error

## Validation

The backend validates that status values are one of the four allowed options:
- `pending`
- `processing`
- `done`
- `error`

Any other value will be rejected with a 400 error.

## Notes

- Default status is `pending` if not specified
- Status can be changed after creation via the dropdown
- Status updates trigger a page refresh to show latest data
- The ENUM constraint at database level ensures data integrity
- Indexed for efficient filtering by status (future enhancement)

