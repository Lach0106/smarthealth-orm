USE SmartHealth;
GO

DROP PROCEDURE IF EXISTS dbo.makeBooking;
GO

CREATE PROCEDURE dbo.makeBooking
    @PatientID            INT,
    @DoctorID             INT,
    @ClinicID             INT,
    @RoomNo               NVARCHAR(10),
    @AppointmentDateTime  DATETIME2,
    @BookingMethod        NVARCHAR(20),
    @DurationMinutes      INT            = 30,
    @NurseID              INT            = NULL,
    @ServiceID            INT            = NULL,
    @AgreedPrice          DECIMAL(10,2)  = NULL,
    @ServiceNotes         NVARCHAR(500)  = NULL,
    @NewAppointmentID     INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CleanRoomNo NVARCHAR(10) = NULLIF(LTRIM(RTRIM(@RoomNo)), '');
    DECLARE @CleanBookingMethod NVARCHAR(20) = NULLIF(LTRIM(RTRIM(@BookingMethod)), '');

    -- Basic input validation before opening a transaction.
    IF @PatientID IS NULL OR @DoctorID IS NULL OR @ClinicID IS NULL
       OR @CleanRoomNo IS NULL OR @AppointmentDateTime IS NULL OR @CleanBookingMethod IS NULL
        THROW 50001, 'A required parameter is missing.', 1;

    IF @CleanBookingMethod NOT IN ('online', 'phone', 'in person')
        THROW 50002, 'Invalid booking method. Use online, phone or in person.', 1;

    IF @DurationMinutes IS NULL OR @DurationMinutes <= 0
        THROW 50003, 'Duration must be a positive number of minutes.', 1;

    IF @AppointmentDateTime <= SYSDATETIME()
        THROW 50004, 'Appointment date/time must be in the future.', 1;

    IF @ServiceID IS NOT NULL AND @AgreedPrice IS NULL
        THROW 50015, 'Agreed price is required when a service is added.', 1;

    DECLARE @NewStart DATETIME2 = @AppointmentDateTime;
    DECLARE @NewEnd   DATETIME2 = DATEADD(MINUTE, @DurationMinutes, @AppointmentDateTime);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Existence checks with dbo-qualified table names.
        IF NOT EXISTS (SELECT 1 FROM dbo.Patient WHERE patientID = @PatientID)
            THROW 50010, 'Patient does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Doctor WHERE staffID = @DoctorID)
            THROW 50011, 'Doctor does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.ConsultationRoom
                       WHERE clinicID = @ClinicID AND roomNo = @CleanRoomNo)
            THROW 50012, 'Room does not exist for this clinic.', 1;

        IF @NurseID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Nurse WHERE staffID = @NurseID)
            THROW 50013, 'Nurse does not exist.', 1;

        IF @ServiceID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.MedicalService WHERE serviceID = @ServiceID)
            THROW 50014, 'Service does not exist.', 1;

        -- A service must be offered by the selected clinic.
        IF @ServiceID IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.ClinicService
                           WHERE clinicID = @ClinicID AND serviceID = @ServiceID)
            THROW 50016, 'This service is not offered by the selected clinic.', 1;

        -- Double-booking checks: confirmed appointments only.
        IF EXISTS (
            SELECT 1
            FROM dbo.Appointment AS a
            WHERE a.doctorID = @DoctorID
              AND a.status = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50020, 'Doctor already has an overlapping confirmed appointment.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.Appointment AS a
            WHERE a.clinicID = @ClinicID
              AND a.roomNo = @CleanRoomNo
              AND a.status = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50021, 'Room is already booked for an overlapping confirmed appointment.', 1;

        IF @NurseID IS NOT NULL AND EXISTS (
            SELECT 1
            FROM dbo.AppointmentNurse AS an
            JOIN dbo.Appointment AS a ON a.appointmentID = an.appointmentID
            WHERE an.staffID = @NurseID
              AND a.status = 'Confirmed'
              AND @NewStart < DATEADD(MINUTE, @DurationMinutes, a.appointmentDateTime)
              AND a.appointmentDateTime < @NewEnd
        )
            THROW 50022, 'Nurse is already assigned to an overlapping confirmed appointment.', 1;

        INSERT INTO dbo.Appointment
            (bookingDate, appointmentDateTime, status, bookingMethod,
             patientID, doctorID, clinicID, roomNo)
        VALUES
            (CAST(SYSDATETIME() AS DATE), @AppointmentDateTime, 'Confirmed', @CleanBookingMethod,
             @PatientID, @DoctorID, @ClinicID, @CleanRoomNo);

        SET @NewAppointmentID = CAST(SCOPE_IDENTITY() AS INT);

        IF @NurseID IS NOT NULL
            INSERT INTO dbo.AppointmentNurse (appointmentID, staffID)
            VALUES (@NewAppointmentID, @NurseID);

        IF @ServiceID IS NOT NULL
            INSERT INTO dbo.AppointmentService (appointmentID, serviceID, agreedPrice, serviceNotes)
            VALUES (@NewAppointmentID, @ServiceID, @AgreedPrice, @ServiceNotes);

        COMMIT TRANSACTION;

        PRINT 'Booking created. Appointment ID = ' + CAST(@NewAppointmentID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO
