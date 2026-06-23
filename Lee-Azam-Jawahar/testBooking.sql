USE SmartHealth;
GO

/*===============================================================================
  Expected outcomes:
    Test 1  Valid booking ......................... SUCCESS
    Test 2  Doctor double-booked .................. ERROR 50020
    Test 3  Room double-booked .................... ERROR 50021
    Test 4  Appointment in the past ............... ERROR 50004
    Test 5  Invalid booking method ................ ERROR 50002
    Test 6  Non-existent patient .................. ERROR 50010
    Test 7  Service without agreed price .......... ERROR 50015
    Test 8  Service not offered by clinic ......... ERROR 50016
    Test 9  Valid booking with nurse + service .... SUCCESS
===============================================================================*/

SET NOCOUNT ON;

DECLARE @id INT;
DECLARE @SlotTime DATETIME2 = DATEADD(HOUR, 10,
                              DATEADD(DAY, 7, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2)));
DECLARE @PastTime DATETIME2 = DATEADD(DAY, -1, SYSDATETIME());

-- SQL Server can reject DATEADD expressions directly inside EXEC parameter assignments,
-- so all test times are calculated before EXEC calls.
DECLARE @Test2Time DATETIME2 = DATEADD(MINUTE, 15, @SlotTime);
DECLARE @Test3Time DATETIME2 = DATEADD(MINUTE, 15, @SlotTime);
DECLARE @Test5Time DATETIME2 = DATEADD(HOUR, 3, @SlotTime);
DECLARE @Test6Time DATETIME2 = DATEADD(HOUR, 4, @SlotTime);
DECLARE @Test7Time DATETIME2 = DATEADD(HOUR, 5, @SlotTime);
DECLARE @Test8Time DATETIME2 = DATEADD(HOUR, 6, @SlotTime);
DECLARE @Test9Time DATETIME2 = DATEADD(HOUR, 7, @SlotTime);

-- Make the test repeatable if it is run more than once.
DECLARE @CleanupIds TABLE (appointmentID INT PRIMARY KEY);

INSERT INTO @CleanupIds (appointmentID)
SELECT appointmentID
FROM dbo.Appointment
WHERE appointmentDateTime IN (@SlotTime, @Test9Time)
   OR (appointmentDateTime > @SlotTime AND appointmentDateTime < DATEADD(HOUR, 8, @SlotTime));

DELETE FROM dbo.AppointmentService WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);
DELETE FROM dbo.AppointmentNurse   WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);
DELETE FROM dbo.AppointmentRecord  WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);
DELETE FROM dbo.Invoice            WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);
UPDATE dbo.Prescription SET appointmentID = NULL WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);
DELETE FROM dbo.Appointment        WHERE appointmentID IN (SELECT appointmentID FROM @CleanupIds);

/*------------------------------------------------------------------ Test 1 */
PRINT '--- Test 1: Valid booking (expect SUCCESS) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @SlotTime,
        @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 2 */
PRINT '--- Test 2: Same doctor, overlapping time (expect ERROR 50020) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 2,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '102',
        @AppointmentDateTime = @Test2Time,
        @BookingMethod = 'phone',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 3 */
PRINT '--- Test 3: Same room, overlapping time (expect ERROR 50021) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 2,
        @DoctorID = 11,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test3Time,
        @BookingMethod = 'in person',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 4 */
PRINT '--- Test 4: Appointment in the past (expect ERROR 50004) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @PastTime,
        @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 5 */
PRINT '--- Test 5: Invalid booking method (expect ERROR 50002) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test5Time,
        @BookingMethod = 'referral',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 6 */
PRINT '--- Test 6: Non-existent patient (expect ERROR 50010) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 99999,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test6Time,
        @BookingMethod = 'online',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 7 */
PRINT '--- Test 7: Service added without agreed price (expect ERROR 50015) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test7Time,
        @BookingMethod = 'online',
        @ServiceID = 100,
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 8 */
PRINT '--- Test 8: Service exists but not offered by the clinic (expect ERROR 50016) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test8Time,
        @BookingMethod = 'online',
        @ServiceID = 200,
        @AgreedPrice = 100.00,
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20)) + '  (UNEXPECTED)';
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

/*------------------------------------------------------------------ Test 9 */
PRINT '--- Test 9: Valid booking with nurse + service (expect SUCCESS) ---';
BEGIN TRY
    EXEC dbo.makeBooking
        @PatientID = 1,
        @DoctorID = 10,
        @ClinicID = 1,
        @RoomNo = '101',
        @AppointmentDateTime = @Test9Time,
        @BookingMethod = 'online',
        @NurseID = 20,
        @ServiceID = 100,
        @AgreedPrice = 120.00,
        @ServiceNotes = 'Standard consultation',
        @NewAppointmentID = @id OUTPUT;
    PRINT 'Result: SUCCESS, AppointmentID = ' + CAST(@id AS NVARCHAR(20));
END TRY
BEGIN CATCH
    PRINT 'Result: ERROR ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ' - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

PRINT '=== All test cases executed ===';
GO
