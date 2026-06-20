/*===============================================================================
  testBooking.sql
  Test cases for dbo.makeBooking  (Task 4)
  Author : Yoon (Member 1)
  Target : Microsoft SQL Server (T-SQL)
  -----------------------------------------------------------------------------
  Each test calls makeBooking in its own TRY/CATCH and prints the outcome, so
  an expected error doesn't stop the run. Read the Messages tab top-to-bottom.

  REQUIRED SEED DATA  (must exist in Sheheryar's dataEntry.sql - adjust IDs to match)
    Patient            : patientID 1, 2
    Doctor             : staffID 10, 11
    Clinic             : clinicID 1
    ConsultationRoom   : (clinicID 1, roomNo '101'), (clinicID 1, roomNo '102')
    Nurse              : staffID 20
    MedicalService     : serviceID 100 (offered by clinic 1), serviceID 200 (NOT offered by clinic 1)
    ClinicService      : (clinicID 1, serviceID 100)   -- clinic 1 offers service 100, not 200
  -----------------------------------------------------------------------------
  COVERAGE
    Test 1  Valid booking ......................... expect SUCCESS
    Test 2  Doctor double-booked ................... expect ERROR 50020
    Test 3  Room double-booked ..................... expect ERROR 50021
    Test 4  Appointment in the past ............... expect ERROR 50004
    Test 5  Invalid booking method ('referral') ... expect ERROR 50002
    Test 6  Non-existent patient .................. expect ERROR 50010
    Test 7  Service added without agreed price .... expect ERROR 50015
    Test 8  Service not offered by the clinic ..... expect ERROR 50016
    Test 9  Valid booking with nurse + service .... expect SUCCESS
===============================================================================*/

SET NOCOUNT ON;

DECLARE @id        INT;
DECLARE @SlotTime  DATETIME2 = DATEADD(HOUR, 10,
                                DATEADD(DAY, 7, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2)));
                                -- a fixed slot 7 days from today at 10:00
DECLARE @PastTime  DATETIME2 = DATEADD(DAY, -1, SYSDATETIME());

/*------------------------------------------------------------------ Test 1 */
PRINT '--- Test 1: Valid booking (expect SUCCESS) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = @SlotTime, @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 2 */
PRINT '--- Test 2: Same doctor, overlapping time (expect ERROR 50020) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 2, @DoctorID = 10, @ClinicID = 1, @RoomNo = '102',
        @AppointmentDateTime = DATEADD(MINUTE, 15, @SlotTime),  -- overlaps Test 1's 30-min slot
        @BookingMethod = 'phone',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 3 */
PRINT '--- Test 3: Same room, overlapping time (expect ERROR 50021) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 2, @DoctorID = 11, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(MINUTE, 15, @SlotTime),  -- same room as Test 1
        @BookingMethod = 'in person',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 4 */
PRINT '--- Test 4: Appointment in the past (expect ERROR 50004) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = @PastTime, @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 5 */
PRINT '--- Test 5: Invalid booking method (expect ERROR 50002) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(HOUR, 3, @SlotTime), @BookingMethod = 'referral',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 6 */
PRINT '--- Test 6: Non-existent patient (expect ERROR 50010) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 99999, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(HOUR, 4, @SlotTime), @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 7 */
PRINT '--- Test 7: Service added without agreed price (expect ERROR 50015) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(HOUR, 5, @SlotTime), @BookingMethod = 'online',
        @ServiceID = 100,           -- service given but no @AgreedPrice
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 8 */
PRINT '--- Test 8: Service exists but not offered by the clinic (expect ERROR 50016) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(HOUR, 6, @SlotTime), @BookingMethod = 'online',
        @ServiceID = 200, @AgreedPrice = 100.00,   -- service 200 not in ClinicService for clinic 1
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 9 */
PRINT '--- Test 9: Valid booking with nurse + service (expect SUCCESS) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1, @DoctorID = 10, @ClinicID = 1, @RoomNo = '101',
        @AppointmentDateTime = DATEADD(HOUR, 7, @SlotTime), @BookingMethod = 'online',
        @NurseID = 20, @ServiceID = 100, @AgreedPrice = 120.00,
        @ServiceNotes = 'Standard consultation',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS VARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';
PRINT '=== All test cases executed ===';
