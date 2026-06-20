IF DB_ID('SmartHealth') IS NULL
    CREATE DATABASE SmartHealth;
GO
USE SmartHealth;
GO

DROP TABLE IF EXISTS Prescription;
DROP TABLE IF EXISTS Invoice;
DROP TABLE IF EXISTS AppointmentNurse;
DROP TABLE IF EXISTS AppointmentService;
DROP TABLE IF EXISTS AppointmentRecord;
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS ClinicService;
DROP TABLE IF EXISTS PatientProfile;
DROP TABLE IF EXISTS PatientAllergy;
DROP TABLE IF EXISTS ConsultationRoom;
DROP TABLE IF EXISTS Doctor;
DROP TABLE IF EXISTS Nurse;
DROP TABLE IF EXISTS Receptionist;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS MedicalService;
DROP TABLE IF EXISTS Clinic;
GO



-- Clinic: strong entity, no foreign keys. phoneNumber is an alternate key (UNIQUE).
-- Using nvarchar for all to maintain consistency and to cater for any accented names like Müller
CREATE TABLE Clinic (
    clinicID INT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(255) NOT NULL,
    phoneNumber NVARCHAR(20) NOT NULL,
    operatingHours  NVARCHAR(100) NOT NULL,
    status          NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_Clinic PRIMARY KEY (clinicID),
    CONSTRAINT UQ_Clinic_phone UNIQUE (phoneNumber),
    CONSTRAINT CK_Clinic_status CHECK (status IN ('Active','Inactive','Temporarily Closed'))
);

-- MedicalService: strong entity, no foreign keys.
CREATE TABLE MedicalService (
    serviceID INT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX) NULL,
    standardDuration INT NOT NULL,   -- minutes
    basePrice DECIMAL(10,2) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_MedicalService PRIMARY KEY (serviceID),
    CONSTRAINT CK_MedicalService_dur CHECK (standardDuration > 0),
    CONSTRAINT CK_MedicalService_price CHECK (basePrice >= 0),
    CONSTRAINT CK_MedicalService_status CHECK (status IN ('Active','Inactive'))
);

-- Patient: strong entity. name split into atomic parts (1NF), medicareOrInsuranceNo is an alternate key.
CREATE TABLE Patient (
    patientID INT IDENTITY(1,1) NOT NULL,
    firstName NVARCHAR(50) NOT NULL,
    middleName NVARCHAR(50) NULL,
    lastName NVARCHAR(50) NOT NULL,
    dateOfBirth DATE NOT NULL,
    contactDetails NVARCHAR(255) NOT NULL,
    medicareOrInsuranceNo NVARCHAR(30) NOT NULL,
    emergencyContact NVARCHAR(255) NULL,
    CONSTRAINT PK_Patient PRIMARY KEY (patientID),
    CONSTRAINT UQ_Patient_medno UNIQUE (medicareOrInsuranceNo)
);

-- Staff: supertype. role is the discriminator; email is an alternate key.
-- clinicID is mandatory (each staff member works at exactly one clinic) and NO ACTION
-- to avoid a multiple-cascade-path conflict on tables that descend from both Clinic and Staff. for e.g delete a clinic, cascades to its staff, cascades to the doctor rows, cascades to that doctors appointments.
CREATE TABLE Staff (
    staffID INT IDENTITY(1,1) NOT NULL,
    fullName NVARCHAR(100) NOT NULL,
    contactNumber NVARCHAR(20) NULL,
    email NVARCHAR(255) NOT NULL,
    qualification NVARCHAR(100) NULL,
    employmentStatus NVARCHAR(20) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    clinicID INT NOT NULL,
    CONSTRAINT PK_Staff PRIMARY KEY (staffID),
    CONSTRAINT UQ_Staff_email UNIQUE (email),
    CONSTRAINT CK_Staff_role CHECK (role IN ('Doctor','Nurse','Receptionist')),
    CONSTRAINT CK_Staff_emp CHECK (employmentStatus IN ('Full-time','Part-time','Casual','Contract')),
    CONSTRAINT FK_Staff_Clinic FOREIGN KEY (clinicID) REFERENCES Clinic(clinicID)
    	ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- Doctor: subtype of Staff. providerNumber is an alternate key.
CREATE TABLE Doctor (
    staffID INT NOT NULL,
    specialization NVARCHAR(100) NOT NULL,
    providerNumber NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_Doctor PRIMARY KEY (staffID),
    CONSTRAINT UQ_Doctor_provider UNIQUE (providerNumber),
    CONSTRAINT FK_Doctor_Staff FOREIGN KEY (staffID) REFERENCES Staff(staffID)
    	ON UPDATE NO ACTION ON DELETE CASCADE
);

-- Nurse: subtype of Staff.
CREATE TABLE Nurse (
    staffID INT NOT NULL,
    nursingGrade NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Nurse PRIMARY KEY (staffID),
    CONSTRAINT FK_Nurse_Staff FOREIGN KEY (staffID) REFERENCES Staff(staffID)
    	ON UPDATE NO ACTION ON DELETE CASCADE
);

-- Receptionist: subtype of Staff.
CREATE TABLE Receptionist (
    staffID INT NOT NULL,
    administrationLevel NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Receptionist PRIMARY KEY (staffID),
    CONSTRAINT FK_Receptionist_Staff FOREIGN KEY (staffID) REFERENCES Staff(staffID)
    	ON UPDATE NO ACTION ON DELETE CASCADE
);

-- ConsultationRoom: weak entity, identified within its clinic by roomNo (composite PK).
CREATE TABLE ConsultationRoom (
    clinicID INT NOT NULL,
    roomNo NVARCHAR(10) NOT NULL,
    roomType NVARCHAR(50) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_ConsultationRoom PRIMARY KEY (clinicID, roomNo),
    CONSTRAINT CK_ConsultationRoom_status CHECK (status IN ('Available','Occupied','Out of Service')),
    CONSTRAINT FK_ConsultationRoom_Clinic FOREIGN KEY (clinicID) REFERENCES Clinic(clinicID)
    	ON UPDATE NO ACTION ON DELETE CASCADE
);

-- PatientAllergy: holds the multi-valued knownAllergies attribute; all-key relation.
CREATE TABLE PatientAllergy (
    patientID INT NOT NULL,
    allergyName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_PatientAllergy PRIMARY KEY (patientID, allergyName),
    CONSTRAINT FK_PatientAllergy_Patient FOREIGN KEY (patientID) REFERENCES Patient(patientID)
        ON UPDATE NO ACTION ON DELETE CASCADE
);

-- PatientProfile: existence-dependent on Patient (1:1); patientID is both PK and FK.
-- preferred clinic/doctor are optional, so SET NULL on delete.
CREATE TABLE PatientProfile (
    patientID INT NOT NULL,
    medicalHistorySummary NVARCHAR(MAX) NULL,
    preferredClinicID INT NULL,
    preferredDoctorID INT NULL,
    registrationDate DATE NOT NULL,
    CONSTRAINT PK_PatientProfile PRIMARY KEY (patientID),
    CONSTRAINT FK_PatientProfile_Patient FOREIGN KEY (patientID) REFERENCES Patient(patientID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_PatientProfile_Clinic  FOREIGN KEY (preferredClinicID) REFERENCES Clinic(clinicID)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT FK_PatientProfile_Doctor  FOREIGN KEY (preferredDoctorID) REFERENCES Doctor(staffID)
        ON UPDATE NO ACTION ON DELETE SET NULL
);

-- ClinicService: resolves the M:N between Clinic and MedicalService. Composite PK.
CREATE TABLE ClinicService (
    clinicID INT NOT NULL,
    serviceID INT NOT NULL,
    clinicSpecificPrice DECIMAL(10,2) NOT NULL,
    currency NVARCHAR(3) NOT NULL CONSTRAINT DF_ClinicService_curr DEFAULT ('AUD'),
    startDate DATE NOT NULL,
    endDate DATE NULL,
    approvingReceptionistID INT NULL,
    CONSTRAINT PK_ClinicService PRIMARY KEY (clinicID, serviceID),
    CONSTRAINT CK_ClinicService_price CHECK (clinicSpecificPrice >= 0),
    CONSTRAINT CK_ClinicService_dates CHECK (endDate IS NULL OR endDate >= startDate),
    CONSTRAINT FK_ClinicService_Clinic FOREIGN KEY (clinicID) REFERENCES Clinic(clinicID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_ClinicService_Service FOREIGN KEY (serviceID) REFERENCES MedicalService(serviceID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_ClinicService_Recept  FOREIGN KEY (approvingReceptionistID) REFERENCES Receptionist(staffID)
        ON UPDATE NO ACTION ON DELETE SET NULL
);

-- Appointment: strong entity. clinicID+roomNo form a composite FK to ConsultationRoom.
-- All four references are mandatory (every appointment, incl. telehealth, has a room).
CREATE TABLE Appointment (
    appointmentID INT IDENTITY(1,1) NOT NULL,
    bookingDate DATE NOT NULL,
    appointmentDateTime DATETIME2 NOT NULL,
    status NVARCHAR(20) NOT NULL,
    bookingMethod NVARCHAR(20) NOT NULL,
    patientID INT NOT NULL,
    doctorID INT NOT NULL,
    clinicID INT NOT NULL,
    roomNo NVARCHAR(10) NOT NULL,
    CONSTRAINT PK_Appointment PRIMARY KEY (appointmentID),
    CONSTRAINT CK_Appointment_status CHECK (status IN ('Booked','Confirmed','Completed','Cancelled','No-show')),
    CONSTRAINT CK_Appointment_method CHECK (bookingMethod IN ('online','phone','in person')),
    CONSTRAINT FK_Appointment_Patient FOREIGN KEY (patientID) REFERENCES Patient(patientID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_Appointment_Doctor FOREIGN KEY (doctorID) REFERENCES Doctor(staffID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_Appointment_Room FOREIGN KEY (clinicID, roomNo) REFERENCES ConsultationRoom(clinicID, roomNo)
        ON UPDATE NO ACTION ON DELETE CASCADE
);

-- AppointmentRecord: existence-dependent on Appointment (1:1). staffID = creating staff member.
-- staffID is NO ACTION to avoid a Staff->Doctor->Appointment->Record vs Staff->Record cascade conflict.
CREATE TABLE AppointmentRecord (
    appointmentID INT NOT NULL,
    observations NVARCHAR(MAX) NULL,
    diagnosisNotes NVARCHAR(MAX) NULL,
    treatmentNotes NVARCHAR(MAX) NULL,
    followUpInstructions NVARCHAR(MAX) NULL,
    staffID INT NOT NULL,
    CONSTRAINT PK_AppointmentRecord PRIMARY KEY (appointmentID),
    CONSTRAINT FK_AppointmentRecord_Appt FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_AppointmentRecord_Staff FOREIGN KEY (staffID) REFERENCES Staff(staffID)
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- AppointmentService: resolves the M:N between Appointment and MedicalService. Composite PK.
CREATE TABLE AppointmentService (
    appointmentID INT NOT NULL,
    serviceID INT NOT NULL,
    agreedPrice DECIMAL(10,2) NOT NULL,
    serviceNotes NVARCHAR(MAX) NULL,
    CONSTRAINT PK_AppointmentService PRIMARY KEY (appointmentID, serviceID),
    CONSTRAINT CK_AppointmentService_price CHECK (agreedPrice >= 0),
    CONSTRAINT FK_AppointmentService_Appt FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_AppointmentService_Service FOREIGN KEY (serviceID) REFERENCES MedicalService(serviceID)
        ON UPDATE NO ACTION ON DELETE CASCADE
);

-- AppointmentNurse: resolves the optional M:N between Appointment and Nurse; all-key link table.
-- staffID is NO ACTION to avoid a Staff->Nurse->AN vs Staff->Doctor->Appointment->AN cascade conflict.
CREATE TABLE AppointmentNurse (
    appointmentID INT NOT NULL,
    staffID INT NOT NULL,
    CONSTRAINT PK_AppointmentNurse PRIMARY KEY (appointmentID, staffID),
    CONSTRAINT FK_AppointmentNurse_Appt FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_AppointmentNurse_Nurse FOREIGN KEY (staffID) REFERENCES Nurse(staffID)
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- Invoice: 1:1 with Appointment (appointmentID is the alternate key). finalAmountPayable removed
-- during normalisation as a stored attribute to satisfy BCNF, 
--then reintroduced as a computed column for convenience, which preserves BCNF because it cannot be set independently."
--Both staff FKs are NO ACTION to avoid cascade-path conflicts.

CREATE TABLE Invoice (
    invoiceID INT IDENTITY(1,1) NOT NULL,
    invoiceDate DATE NOT NULL,
    consultationCharges DECIMAL(10,2) NOT NULL CONSTRAINT DF_Invoice_cons DEFAULT (0),
    prescriptionCharges DECIMAL(10,2) NOT NULL CONSTRAINT DF_Invoice_pres DEFAULT (0),
    discountAmount DECIMAL(10,2) NOT NULL CONSTRAINT DF_Invoice_disc DEFAULT (0),
    penaltyCharge DECIMAL(10,2) NOT NULL CONSTRAINT DF_Invoice_pen DEFAULT (0),
    finalAmountPayable AS (consultationCharges + prescriptionCharges + penaltyCharge - discountAmount) PERSISTED,
    paymentMethod NVARCHAR(20) NULL,
    paymentStatus NVARCHAR(20) NOT NULL,
    appointmentID INT NOT NULL,
    finalisedByReceptionistID INT NOT NULL,
    discountApprovedByStaffID INT NULL,
    CONSTRAINT PK_Invoice PRIMARY KEY (invoiceID),
    CONSTRAINT UQ_Invoice_appt UNIQUE (appointmentID),
    CONSTRAINT CK_Invoice_amounts CHECK (consultationCharges >= 0 AND prescriptionCharges >= 0 AND discountAmount >= 0 AND penaltyCharge >= 0),
    CONSTRAINT CK_Invoice_discAppr CHECK (discountAmount = 0 OR discountApprovedByStaffID IS NOT NULL),
    CONSTRAINT CK_Invoice_payStatus CHECK (paymentStatus IN ('Unpaid','Paid','Partially Paid')),
    CONSTRAINT CK_Invoice_payMethod CHECK (paymentMethod IS NULL OR paymentMethod IN ('Cash','Card','Medicare','Insurance','Bank Transfer')),
    CONSTRAINT FK_Invoice_Appt FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT FK_Invoice_Recept FOREIGN KEY (finalisedByReceptionistID) REFERENCES Receptionist(staffID)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT FK_Invoice_Approver FOREIGN KEY (discountApprovedByStaffID) REFERENCES Staff(staffID)
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- Prescription: strong entity.
CREATE TABLE Prescription (
    prescriptionID INT IDENTITY(1,1) NOT NULL,
    prescriptionDate DATE NOT NULL,
    medicationName NVARCHAR(100) NOT NULL,
    dosage NVARCHAR(50) NOT NULL,
    frequency NVARCHAR(50) NOT NULL,
    duration NVARCHAR(50) NOT NULL,
    specialInstructions NVARCHAR(MAX) NULL,
    appointmentID INT NULL,
    patientID INT NOT NULL,
    doctorID INT NOT NULL,
    CONSTRAINT PK_Prescription PRIMARY KEY (prescriptionID),
    CONSTRAINT FK_Prescription_Appt FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID)
        ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT FK_Prescription_Patient FOREIGN KEY (patientID) REFERENCES Patient(patientID)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT FK_Prescription_Doctor  FOREIGN KEY (doctorID) REFERENCES Doctor(staffID)
        ON UPDATE NO ACTION ON DELETE NO ACTION
);
