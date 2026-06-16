/*
===============================================================================
INFO6002 Assignment 1 - Task 4
File: makeBooking.sql
Purpose: Stored procedure draft for SmartHealth appointment booking

IMPORTANT:
This is a schema-ready draft. It assumes the table and column names below.
After Sheheryar shares the final createTables.sql, update table/column names if
needed before submission.

Assumed key tables / columns:
- Patient(patientID)
- Clinic(clinicID, status)
- Staff(staffID, employmentStatus, role)
- Doctor(staffID)
- Nurse(staffID)
- ConsultationRoom(clinicID, roomNo, status)
- MedicalService(serviceID, standardDurationMinutes, status)
- ClinicService(clinicID, serviceID, clinicSpecificPrice, startDate, endDate)
- Appointment(appointmentID IDENTITY, bookingDate, appointmentDateTime,
              status, bookingMethod, patientID, clinicID, doctorID, roomNo)
- AppointmentService(appointmentID, serviceID, agreedPrice, serviceNotes)
- AppointmentNurse(appointmentID, nurseID)

Business rules covered:
1. Patient, clinic, doctor, room, and service must exist.
2. Booking method must be online, phone, or in person.
3. Appointment date/time must be in the future.
4. The selected service must be offered by the selected clinic.
5. Doctor must not be double-booked for overlapping confirmed appointments.
6. Room must not be double-booked for overlapping confirmed appointments.
7. Optional nurse must not be double-booked for overlapping confirmed appointments.
8. Inserts Appointment, AppointmentService, and optionally AppointmentNurse
   in one transaction.

Limitations / team decision:
- This minimum version books one medical service per appointment.
  This still satisfies the "one or more" requirement for a basic booking because
  one service is a valid case. It can be extended later to multiple services with
  a table-valued parameter if required.
===============================================================================
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.makeBooking
    @PatientID INT,
    @ClinicID INT,
    @DoctorID INT,
    @RoomNo NVARCHAR(20),
    @ServiceID INT,
    @AppointmentDateTime DATETIME2(0),
    @BookingMethod NVARCHAR(20),
    @NurseID INT = NULL,
    @ServiceNotes NVARCHAR(500) = NULL,
    @NewAppointmentID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @NormalisedBookingMethod NVARCHAR(20),
        @DurationMinutes INT,
        @AppointmentEndDateTime DATETIME2(0),
        @AgreedPrice DECIMAL(10,2);

    BEGIN TRY
        -----------------------------------------------------------------------
        -- 1. Basic input validation
        -----------------------------------------------------------------------
        SET @NormalisedBookingMethod = LOWER(LTRIM(RTRIM(@BookingMethod)));

        IF @PatientID IS NULL
            THROW 51001, 'Patient ID is required.', 1;

        IF @ClinicID IS NULL
            THROW 51002, 'Clinic ID is required.', 1;

        IF @DoctorID IS NULL
            THROW 51003, 'Doctor ID is required.', 1;

        IF @RoomNo IS NULL OR LTRIM(RTRIM(@RoomNo)) = ''
            THROW 51004, 'Room number is required.', 1;

        IF @ServiceID IS NULL
            THROW 51005, 'Service ID is required.', 1;

        IF @AppointmentDateTime IS NULL
            THROW 51006, 'Appointment date and time are required.', 1;

        IF @AppointmentDateTime <= SYSDATETIME()
            THROW 51007, 'Appointment date and time must be in the future.', 1;

        IF @NormalisedBookingMethod NOT IN ('online', 'phone', 'in person')
            THROW 51008, 'Invalid booking method. Use online, phone, or in person.', 1;

        -----------------------------------------------------------------------
        -- 2. Existence and status checks
        --    Adjust status values if your final CHECK constraints use different
        --    wording, e.g. active/inactive, available/unavailable.
        -----------------------------------------------------------------------
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Patient
            WHERE patientID = @PatientID
        )
            THROW 51009, 'The selected patient does not exist.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Clinic
            WHERE clinicID = @ClinicID
              AND LOWER(status) = 'active'
        )
            THROW 51010, 'The selected clinic does not exist or is not active.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Doctor d
            INNER JOIN dbo.Staff s
                ON s.staffID = d.staffID
            WHERE d.staffID = @DoctorID
              AND LOWER(s.employmentStatus) = 'active'
        )
            THROW 51011, 'The selected doctor does not exist or is not active.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.ConsultationRoom
            WHERE clinicID = @ClinicID
              AND roomNo = @RoomNo
              AND LOWER(status) = 'available'
        )
            THROW 51012, 'The selected consultation room does not exist or is not available.', 1;

        IF @NurseID IS NOT NULL
           AND NOT EXISTS (
                SELECT 1
                FROM dbo.Nurse n
                INNER JOIN dbo.Staff s
                    ON s.staffID = n.staffID
                WHERE n.staffID = @NurseID
                  AND LOWER(s.employmentStatus) = 'active'
           )
            THROW 51013, 'The selected nurse does not exist or is not active.', 1;

        -----------------------------------------------------------------------
        -- 3. Check that the service is currently offered by the selected clinic.
        --    The clinic-specific price is used as the agreed price.
        -----------------------------------------------------------------------
        SELECT
            @AgreedPrice = cs.clinicSpecificPrice,
            @DurationMinutes = ms.standardDurationMinutes
        FROM dbo.ClinicService cs
        INNER JOIN dbo.MedicalService ms
            ON ms.serviceID = cs.serviceID
        WHERE cs.clinicID = @ClinicID
          AND cs.serviceID = @ServiceID
          AND LOWER(ms.status) = 'active'
          AND CAST(@AppointmentDateTime AS DATE) >= cs.startDate
          AND (cs.endDate IS NULL OR CAST(@AppointmentDateTime AS DATE) <= cs.endDate);

        IF @AgreedPrice IS NULL OR @DurationMinutes IS NULL
            THROW 51014, 'The selected service is not currently offered by the selected clinic.', 1;

        IF @DurationMinutes <= 0
            THROW 51015, 'The selected service has an invalid standard duration.', 1;

        SET @AppointmentEndDateTime = DATEADD(MINUTE, @DurationMinutes, @AppointmentDateTime);

        -----------------------------------------------------------------------
        -- 4. Double-booking checks for confirmed appointments
        --
        -- Overlap condition:
        -- existingStart < newEnd AND existingEnd > newStart
        -----------------------------------------------------------------------

        -- Doctor overlap
        IF EXISTS (
            SELECT 1
            FROM dbo.Appointment a
            OUTER APPLY (
                SELECT COALESCE(SUM(ms2.standardDurationMinutes), 30) AS durationMinutes
                FROM dbo.AppointmentService aps2
                INNER JOIN dbo.MedicalService ms2
                    ON ms2.serviceID = aps2.serviceID
                WHERE aps2.appointmentID = a.appointmentID
            ) dur
            WHERE LOWER(a.status) = 'confirmed'
              AND a.doctorID = @DoctorID
              AND a.appointmentDateTime < @AppointmentEndDateTime
              AND DATEADD(MINUTE, COALESCE(dur.durationMinutes, 30), a.appointmentDateTime) > @AppointmentDateTime
        )
            THROW 51016, 'The selected doctor is already booked for an overlapping confirmed appointment.', 1;

        -- Room overlap
        IF EXISTS (
            SELECT 1
            FROM dbo.Appointment a
            OUTER APPLY (
                SELECT COALESCE(SUM(ms2.standardDurationMinutes), 30) AS durationMinutes
                FROM dbo.AppointmentService aps2
                INNER JOIN dbo.MedicalService ms2
                    ON ms2.serviceID = aps2.serviceID
                WHERE aps2.appointmentID = a.appointmentID
            ) dur
            WHERE LOWER(a.status) = 'confirmed'
              AND a.clinicID = @ClinicID
              AND a.roomNo = @RoomNo
              AND a.appointmentDateTime < @AppointmentEndDateTime
              AND DATEADD(MINUTE, COALESCE(dur.durationMinutes, 30), a.appointmentDateTime) > @AppointmentDateTime
        )
            THROW 51017, 'The selected consultation room is already booked for an overlapping confirmed appointment.', 1;

        -- Optional nurse overlap
        IF @NurseID IS NOT NULL
           AND EXISTS (
                SELECT 1
                FROM dbo.Appointment a
                INNER JOIN dbo.AppointmentNurse an
                    ON an.appointmentID = a.appointmentID
                OUTER APPLY (
                    SELECT COALESCE(SUM(ms2.standardDurationMinutes), 30) AS durationMinutes
                    FROM dbo.AppointmentService aps2
                    INNER JOIN dbo.MedicalService ms2
                        ON ms2.serviceID = aps2.serviceID
                    WHERE aps2.appointmentID = a.appointmentID
                ) dur
                WHERE LOWER(a.status) = 'confirmed'
                  AND an.nurseID = @NurseID
                  AND a.appointmentDateTime < @AppointmentEndDateTime
                  AND DATEADD(MINUTE, COALESCE(dur.durationMinutes, 30), a.appointmentDateTime) > @AppointmentDateTime
           )
            THROW 51018, 'The selected nurse is already booked for an overlapping confirmed appointment.', 1;

        -----------------------------------------------------------------------
        -- 5. Insert the appointment and related rows in one transaction.
        -----------------------------------------------------------------------
        BEGIN TRANSACTION;

            INSERT INTO dbo.Appointment
            (
                bookingDate,
                appointmentDateTime,
                status,
                bookingMethod,
                patientID,
                clinicID,
                doctorID,
                roomNo
            )
            VALUES
            (
                SYSDATETIME(),
                @AppointmentDateTime,
                'confirmed',
                @NormalisedBookingMethod,
                @PatientID,
                @ClinicID,
                @DoctorID,
                @RoomNo
            );

            SET @NewAppointmentID = CONVERT(INT, SCOPE_IDENTITY());

            INSERT INTO dbo.AppointmentService
            (
                appointmentID,
                serviceID,
                agreedPrice,
                serviceNotes
            )
            VALUES
            (
                @NewAppointmentID,
                @ServiceID,
                @AgreedPrice,
                @ServiceNotes
            );

            IF @NurseID IS NOT NULL
            BEGIN
                INSERT INTO dbo.AppointmentNurse
                (
                    appointmentID,
                    nurseID
                )
                VALUES
                (
                    @NewAppointmentID,
                    @NurseID
                );
            END;

        COMMIT TRANSACTION;

        SELECT
            @NewAppointmentID AS newAppointmentID,
            'Appointment booking created successfully.' AS message;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
            @ErrorSeverity INT = ERROR_SEVERITY(),
            @ErrorState INT = ERROR_STATE();

        -- Re-throw a clear error message so that the test script and ORM form
        -- can display the problem to the user.
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
