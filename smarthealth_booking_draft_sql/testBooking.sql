/*
===============================================================================
INFO6002 Assignment 1 - Task 4
File: testBooking.sql
Purpose: Test cases for dbo.makeBooking

IMPORTANT:
Run order:
1. createTables.sql
2. dataEntry.sql
3. makeBooking.sql
4. testBooking.sql

This script assumes that dataEntry.sql has inserted at least:
- one active patient
- one active clinic
- one active doctor
- one available consultation room
- one active medical service offered by that clinic
- optionally one active nurse

After Sheheryar shares the final schema, update table/column names if needed.
===============================================================================
*/

SET NOCOUNT ON;

PRINT '============================================================';
PRINT 'Loading sample IDs from current database...';
PRINT '============================================================';

DECLARE
    @PatientID INT,
    @ClinicID INT,
    @DoctorID INT,
    @RoomNo NVARCHAR(20),
    @ServiceID INT,
    @NurseID INT,
    @SecondDoctorID INT,
    @SecondRoomNo NVARCHAR(20),
    @FutureAppointmentDateTime DATETIME2(0),
    @OverlappingDateTime DATETIME2(0),
    @NewAppointmentID INT;

-- Pick sample data from existing populated tables.
-- Adjust these queries if final column/table names differ.

SELECT TOP (1)
    @PatientID = patientID
FROM dbo.Patient
ORDER BY patientID;

SELECT TOP (1)
    @ClinicID = clinicID
FROM dbo.Clinic
WHERE LOWER(status) = 'active'
ORDER BY clinicID;

SELECT TOP (1)
    @DoctorID = d.staffID
FROM dbo.Doctor d
INNER JOIN dbo.Staff s
    ON s.staffID = d.staffID
WHERE LOWER(s.employmentStatus) = 'active'
ORDER BY d.staffID;

SELECT TOP (1)
    @RoomNo = roomNo
FROM dbo.ConsultationRoom
WHERE clinicID = @ClinicID
  AND LOWER(status) = 'available'
ORDER BY roomNo;

SELECT TOP (1)
    @ServiceID = cs.serviceID
FROM dbo.ClinicService cs
INNER JOIN dbo.MedicalService ms
    ON ms.serviceID = cs.serviceID
WHERE cs.clinicID = @ClinicID
  AND LOWER(ms.status) = 'active'
  AND CAST(SYSDATETIME() AS DATE) >= cs.startDate
  AND (cs.endDate IS NULL OR CAST(SYSDATETIME() AS DATE) <= cs.endDate)
ORDER BY cs.serviceID;

SELECT TOP (1)
    @NurseID = n.staffID
FROM dbo.Nurse n
INNER JOIN dbo.Staff s
    ON s.staffID = n.staffID
WHERE LOWER(s.employmentStatus) = 'active'
ORDER BY n.staffID;

SELECT TOP (1)
    @SecondDoctorID = d.staffID
FROM dbo.Doctor d
INNER JOIN dbo.Staff s
    ON s.staffID = d.staffID
WHERE LOWER(s.employmentStatus) = 'active'
  AND d.staffID <> @DoctorID
ORDER BY d.staffID;

SELECT TOP (1)
    @SecondRoomNo = roomNo
FROM dbo.ConsultationRoom
WHERE clinicID = @ClinicID
  AND LOWER(status) = 'available'
  AND roomNo <> @RoomNo
ORDER BY roomNo;

-- Future date at 10:00, seven days from now.
SET @FutureAppointmentDateTime =
    DATEADD(HOUR, 10, CAST(DATEADD(DAY, 7, CAST(SYSDATETIME() AS DATE)) AS DATETIME2(0)));

-- Same time for overlap tests.
SET @OverlappingDateTime = @FutureAppointmentDateTime;

PRINT 'Selected sample values:';
SELECT
    @PatientID AS patientID,
    @ClinicID AS clinicID,
    @DoctorID AS doctorID,
    @RoomNo AS roomNo,
    @ServiceID AS serviceID,
    @NurseID AS optionalNurseID,
    @SecondDoctorID AS secondDoctorID,
    @SecondRoomNo AS secondRoomNo,
    @FutureAppointmentDateTime AS futureAppointmentDateTime;

IF @PatientID IS NULL
    THROW 52001, 'Test setup failed: no patient found. Add sample patient data first.', 1;

IF @ClinicID IS NULL
    THROW 52002, 'Test setup failed: no active clinic found. Add sample clinic data first.', 1;

IF @DoctorID IS NULL
    THROW 52003, 'Test setup failed: no active doctor found. Add sample doctor/staff data first.', 1;

IF @RoomNo IS NULL
    THROW 52004, 'Test setup failed: no available consultation room found. Add sample room data first.', 1;

IF @ServiceID IS NULL
    THROW 52005, 'Test setup failed: no active clinic service found. Add sample service/clinic service data first.', 1;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 1: Valid booking should succeed';
PRINT '============================================================';
BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = @PatientID,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @ServiceID,
        @AppointmentDateTime = @FutureAppointmentDateTime,
        @BookingMethod = 'online',
        @NurseID = @NurseID,
        @ServiceNotes = 'Test 1: valid appointment booking.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 1 PASSED' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 1 FAILED unexpectedly' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 2: Invalid patient should fail';
PRINT '============================================================';
BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = -999,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @ServiceID,
        @AppointmentDateTime = DATEADD(DAY, 1, @FutureAppointmentDateTime),
        @BookingMethod = 'phone',
        @NurseID = NULL,
        @ServiceNotes = 'Test 2: invalid patient.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 2 FAILED: invalid patient was accepted' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 2 PASSED: invalid patient rejected' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 3: Invalid booking method should fail';
PRINT '============================================================';
BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = @PatientID,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @ServiceID,
        @AppointmentDateTime = DATEADD(DAY, 2, @FutureAppointmentDateTime),
        @BookingMethod = 'referral',
        @NurseID = NULL,
        @ServiceNotes = 'Test 3: invalid booking method.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 3 FAILED: invalid booking method was accepted' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 3 PASSED: invalid booking method rejected' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 4: Past appointment date/time should fail';
PRINT '============================================================';
BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = @PatientID,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @ServiceID,
        @AppointmentDateTime = DATEADD(DAY, -1, SYSDATETIME()),
        @BookingMethod = 'in person',
        @NurseID = NULL,
        @ServiceNotes = 'Test 4: past appointment date/time.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 4 FAILED: past appointment was accepted' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 4 PASSED: past appointment rejected' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 5: Doctor double-booking should fail';
PRINT '============================================================';
BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = @PatientID,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @ServiceID,
        @AppointmentDateTime = @OverlappingDateTime,
        @BookingMethod = 'phone',
        @NurseID = NULL,
        @ServiceNotes = 'Test 5: overlapping doctor booking.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 5 FAILED: doctor double-booking was accepted' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 5 PASSED: doctor double-booking rejected' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 6: Room double-booking should fail if a second doctor exists';
PRINT '============================================================';

IF @SecondDoctorID IS NULL
BEGIN
    SELECT
        'TEST 6 SKIPPED: no second active doctor available in sample data' AS testResult;
END
ELSE
BEGIN
    BEGIN TRY
        SET @NewAppointmentID = NULL;

        EXEC dbo.makeBooking
            @PatientID = @PatientID,
            @ClinicID = @ClinicID,
            @DoctorID = @SecondDoctorID,
            @RoomNo = @RoomNo,
            @ServiceID = @ServiceID,
            @AppointmentDateTime = @OverlappingDateTime,
            @BookingMethod = 'online',
            @NurseID = NULL,
            @ServiceNotes = 'Test 6: overlapping room booking with different doctor.',
            @NewAppointmentID = @NewAppointmentID OUTPUT;

        SELECT
            'TEST 6 FAILED: room double-booking was accepted' AS testResult,
            @NewAppointmentID AS newAppointmentID;
    END TRY
    BEGIN CATCH
        SELECT
            'TEST 6 PASSED: room double-booking rejected' AS testResult,
            ERROR_MESSAGE() AS errorMessage;
    END CATCH;
END;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 7: Nurse double-booking should fail if sample data allows it';
PRINT '============================================================';

IF @NurseID IS NULL
BEGIN
    SELECT
        'TEST 7 SKIPPED: no active nurse available in sample data' AS testResult;
END
ELSE IF @SecondDoctorID IS NULL
BEGIN
    SELECT
        'TEST 7 SKIPPED: no second active doctor available to isolate nurse conflict' AS testResult;
END
ELSE IF @SecondRoomNo IS NULL
BEGIN
    SELECT
        'TEST 7 SKIPPED: no second available room available to isolate nurse conflict' AS testResult;
END
ELSE
BEGIN
    BEGIN TRY
        SET @NewAppointmentID = NULL;

        EXEC dbo.makeBooking
            @PatientID = @PatientID,
            @ClinicID = @ClinicID,
            @DoctorID = @SecondDoctorID,
            @RoomNo = @SecondRoomNo,
            @ServiceID = @ServiceID,
            @AppointmentDateTime = @OverlappingDateTime,
            @BookingMethod = 'online',
            @NurseID = @NurseID,
            @ServiceNotes = 'Test 7: overlapping nurse booking with different doctor and room.',
            @NewAppointmentID = @NewAppointmentID OUTPUT;

        SELECT
            'TEST 7 FAILED: nurse double-booking was accepted' AS testResult,
            @NewAppointmentID AS newAppointmentID;
    END TRY
    BEGIN CATCH
        SELECT
            'TEST 7 PASSED: nurse double-booking rejected' AS testResult,
            ERROR_MESSAGE() AS errorMessage;
    END CATCH;
END;


PRINT ' ';
PRINT '============================================================';
PRINT 'TEST 8: Service not offered by clinic should fail';
PRINT '============================================================';

DECLARE @InvalidServiceID INT;

SELECT TOP (1)
    @InvalidServiceID = ms.serviceID
FROM dbo.MedicalService ms
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.ClinicService cs
    WHERE cs.clinicID = @ClinicID
      AND cs.serviceID = ms.serviceID
)
ORDER BY ms.serviceID;

IF @InvalidServiceID IS NULL
BEGIN
    -- Fallback: use a clearly invalid service ID if all services are offered.
    SET @InvalidServiceID = -999;
END;

BEGIN TRY
    SET @NewAppointmentID = NULL;

    EXEC dbo.makeBooking
        @PatientID = @PatientID,
        @ClinicID = @ClinicID,
        @DoctorID = @DoctorID,
        @RoomNo = @RoomNo,
        @ServiceID = @InvalidServiceID,
        @AppointmentDateTime = DATEADD(DAY, 3, @FutureAppointmentDateTime),
        @BookingMethod = 'online',
        @NurseID = NULL,
        @ServiceNotes = 'Test 8: service not offered by clinic.',
        @NewAppointmentID = @NewAppointmentID OUTPUT;

    SELECT
        'TEST 8 FAILED: invalid/unoffered service was accepted' AS testResult,
        @NewAppointmentID AS newAppointmentID;
END TRY
BEGIN CATCH
    SELECT
        'TEST 8 PASSED: invalid/unoffered service rejected' AS testResult,
        ERROR_MESSAGE() AS errorMessage;
END CATCH;


PRINT ' ';
PRINT '============================================================';
PRINT 'Review appointments created during successful tests';
PRINT '============================================================';

SELECT
    a.appointmentID,
    a.patientID,
    a.clinicID,
    a.doctorID,
    a.roomNo,
    a.bookingDate,
    a.appointmentDateTime,
    a.status,
    a.bookingMethod
FROM dbo.Appointment a
WHERE a.appointmentDateTime >= DATEADD(DAY, -1, @FutureAppointmentDateTime)
ORDER BY a.appointmentID DESC;
