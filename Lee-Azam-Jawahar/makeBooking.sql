/*===============================================================================
  makeBooking.sql  -  SmartHealth Appointment Booking (Task 4)
  Author: Yoon (Member 1)        Target: Microsoft SQL Server (T-SQL)
  -----------------------------------------------------------------------------
  ASSUMPTIONS (to reconcile with Sheheryar's createTables.sql before submission)
    1. Names follow our confirmed DBDL: Appointment(appointmentID, ...),
       Doctor(staffID), ConsultationRoom(clinicID, roomNo). If createTables.sql
       uses another convention, align all names in one pass.
    2. appointmentID is an IDENTITY column, so the new ID is read back with
       SCOPE_IDENTITY(). If IDs are entered manually, take @AppointmentID as a
       parameter instead and drop the SCOPE_IDENTITY line.
    3. Booking method values: 'online', 'phone', 'in person' - the CHECK
       constraint and the form dropdown must use these exact strings.
    4. Double-booking is only checked against existing 'Confirmed' appointments
       (per the scenario). New bookings default to 'Confirmed'.
    5. Appointment has no end time, so each one is treated as a fixed slot of
       @DurationMinutes (default 30); two appointments overlap when
       newStart < existingEnd AND existingStart < newEnd.
    6. A nurse and a service are optional at booking (scenario: an appointment
       "may" involve nurses / include services).
===============================================================================*/

IF OBJECT_ID('dbo.makeBooking', 'P') IS NOT NULL
    DROP PROCEDURE dbo.makeBooking;
GO

CREATE PROCEDURE dbo.makeBooking
    @PatientID            INT,
    @DoctorID             INT,
    @ClinicID             INT,
    @RoomNo               VARCHAR(10),
    @AppointmentDateTime  DATETIME2,
    @BookingMethod        VARCHAR(20),
    @DurationMinutes      INT           = 30,
    @NurseID              INT           = NULL,
    @ServiceID            INT           = NULL,
    @AgreedPrice          DECIMAL(10,2) = NULL,   -- required only if @ServiceID is set
    @ServiceNotes         VARCHAR(500)  = NULL,
    @NewAppointmentID     INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NewStart DATETIME2 = @AppointmentDateTime;
    DECLARE @NewEnd   DATETIME2 = DATEADD(MINUTE, @DurationMinutes, @AppointmentDateTime);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Input validation (PK/FK/CHECK constraints are the backstop for the rest)
        IF @PatientID IS NULL OR @DoctorID IS NULL OR @ClinicID IS NULL
           OR @RoomNo IS NULL OR @AppointmentDateTime IS NULL OR @BookingMethod IS NULL
            THROW 50001, 'A required parameter is missing.', 1;

        IF @BookingMethod NOT IN ('online', 'phone', 'in person')
            THROW 50002, 'Invalid booking method. Use online, phone or in person.', 1;

        IF @DurationMinutes IS NULL OR @DurationMinutes <= 0
            THROW 50003, 'Duration must be a positive number of minutes.', 1;

        IF @AppointmentDateTime <= SYSDATETIME()
            THROW 50004, 'Appointment date/time must be in the future.', 1;

        -- Existence checks (clearer messages than a raw FK violation)
        IF NOT EXISTS (SELECT 1 FROM Patient WHERE patientID = @PatientID)
            THROW 50010, 'Patient does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM Doctor WHERE staffID = @DoctorID)
            THROW 50011, 'Doctor does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM ConsultationRoom
                       WHERE clinicID = @ClinicID AND roomNo = @RoomNo)
            THROW 50012, 'Room does not exist for this clinic.', 1;

        IF @NurseID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM Nurse WHERE staffID = @NurseID)
            THROW 50013, 'Nurse does not exist.', 1;

        IF @ServiceID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM MedicalService WHERE serviceID = @ServiceID)
            THROW 50014, 'Service does not exist.', 1;

        -- Service must actually be offered by this clinic (via ClinicService)
        IF @ServiceID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ClinicService
                           WHERE clinicID = @ClinicID AND serviceID = @ServiceID)
            THROW 50016, 'This service is not offered by the selected clinic.', 1;

        IF @ServiceID IS NOT NULL AND @AgreedPrice IS NULL
            THROW 50015, 'Agreed price is required when a service is added.', 1;

        -- Double-booking checks: not enforceable by constraints; 'Confirmed' only
        -- Doctor not double-booked
        IF EXISTS (
            SELECT 1 FROM Appointment a
            WHERE a.doctorID = @DoctorID
              AND a.status   = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50020, 'Doctor already has an overlapping confirmed appointment.', 1;

        -- Room not double-booked
        IF EXISTS (
            SELECT 1 FROM Appointment a
            WHERE a.clinicID = @ClinicID
              AND a.roomNo   = @RoomNo
              AND a.status   = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50021, 'Room is already booked for an overlapping confirmed appointment.', 1;

        -- Nurse not double-booked (only if one is assigned)
        IF @NurseID IS NOT NULL AND EXISTS (
            SELECT 1
            FROM AppointmentNurse an
            JOIN Appointment a ON a.appointmentID = an.appointmentID
            WHERE an.staffID = @NurseID
              AND a.status   = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50022, 'Nurse is already assigned to an overlapping confirmed appointment.', 1;

        INSERT INTO Appointment
            (bookingDate, appointmentDateTime, status, bookingMethod,
             patientID, doctorID, clinicID, roomNo)
        VALUES
            (CAST(SYSDATETIME() AS DATE), @AppointmentDateTime, 'Confirmed', @BookingMethod,
             @PatientID, @DoctorID, @ClinicID, @RoomNo);

        SET @NewAppointmentID = CAST(SCOPE_IDENTITY() AS INT);

        -- Optional nurse / service
        IF @NurseID IS NOT NULL
            INSERT INTO AppointmentNurse (appointmentID, staffID)
            VALUES (@NewAppointmentID, @NurseID);

        IF @ServiceID IS NOT NULL
            INSERT INTO AppointmentService (appointmentID, serviceID, agreedPrice, serviceNotes)
            VALUES (@NewAppointmentID, @ServiceID, @AgreedPrice, @ServiceNotes);

        COMMIT TRANSACTION;

        PRINT 'Booking created. Appointment ID = ' + CAST(@NewAppointmentID AS VARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;   -- re-raise the original error for the caller
    END CATCH
END;
GO
