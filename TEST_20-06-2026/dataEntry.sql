Use SmartHealth;

DELETE FROM Prescription;
DELETE FROM Invoice;
DELETE FROM AppointmentNurse;
DELETE FROM AppointmentService;
DELETE FROM AppointmentRecord;
DELETE FROM Appointment;
DELETE FROM ClinicService;
DELETE FROM PatientProfile;
DELETE FROM PatientAllergy;
DELETE FROM ConsultationRoom;
DELETE FROM Doctor;
DELETE FROM Nurse;
DELETE FROM Receptionist;
DELETE FROM Staff;
DELETE FROM Patient;
DELETE FROM MedicalService;
DELETE FROM Clinic;


SET IDENTITY_INSERT Clinic ON;
INSERT INTO Clinic (clinicID, name, address, phoneNumber, operatingHours, status) VALUES
 (1, 'SmartHealth Newcastle', '12 Hunter St, Newcastle NSW 2300', '0249001000', 'Mon-Fri 08:00-18:00', 'Active'),
 (2, 'SmartHealth Sydney', '6 Elizabeth St, Sydney NSW 2000', '0290001000', 'Mon-Sat 08:00-20:00', 'Active'),
 (3, 'SmartHealth Melbourne', '5 Collins St, Melbourne VIC 3000', '0390001000', 'Mon-Fri 08:00-18:00', 'Active'),
 (4, 'SmartHealth Brisbane', '20 Queen St, Brisbane QLD 4000', '0730001000', 'Mon-Fri 08:00-17:00', 'Active'),
 (5, 'SmartHealth Perth', '7 Murray St, Perth WA 6000', '0860001000', 'Mon-Fri 08:00-18:00', 'Active'),
 (6, 'SmartHealth Adelaide', '3 Rundle Mall, Adelaide SA 5000', '0870001000', 'Mon-Fri 09:00-17:00', 'Active'),
 (7, 'SmartHealth Canberra', '15 London Cct, Canberra ACT 2600', '0260001000', 'Mon-Fri 09:00-17:00', 'Temporarily Closed'),
 (8, 'SmartHealth Gold Coast', '40 Cavill Ave, Surfers QLD 4217', '0750001000', 'Mon-Fri 08:00-18:00', 'Inactive');
SET IDENTITY_INSERT Clinic OFF;

SET IDENTITY_INSERT MedicalService ON;
INSERT INTO MedicalService (serviceID, name, description, standardDuration, basePrice, status) VALUES
 (100, 'General Consultation', 'Standard GP consultation', 15, 80.00, 'Active'),
 (200, 'Specialist Consultation', 'Consultation with a specialist', 30, 150.00, 'Active'),
 (300, 'Vaccination', 'Routine vaccination service', 10, 45.00, 'Active'),
 (400, 'Health Screening', 'General health screening', 45, 120.00, 'Active'),
 (500, 'Telehealth Consultation', 'Remote video consultation', 20, 60.00, 'Active'),
 (600, 'Minor Procedure', 'Minor in-clinic procedure', 60, 250.00, 'Active'),
 (700, 'Mental Health Consultation', 'Mental health support session', 50, 180.00, 'Active'),
 (800, 'Physiotherapy', 'Physiotherapy session', 40, 90.00, 'Inactive');
SET IDENTITY_INSERT MedicalService OFF;

SET IDENTITY_INSERT Patient ON;
INSERT INTO Patient (patientID, firstName, middleName, lastName, dateOfBirth, contactDetails, medicareOrInsuranceNo, emergencyContact) VALUES
 (1, 'John', 'Finney', 'Jawahar', '1998-03-12', '0413807010, john.jawahar@gmail.com', '2345678901', 'Dana Smith 0422222222'),
 (2, 'Yoon', 'Seong', 'Lee', '1997-07-25', '0433333333, Yoon.seong@gmail.com', '3456789012', 'Clorine Ives 0402677533'),
 (3, 'Shery', NULL, 'Azam',  '1999-09-25', '0482389977, shery.maza@gmail.com',  '4567890123', 'Danial Azam 0405546662'),
 (4, 'Yousuf', 'Muhammad', 'Aman', '2000-09-18', '0477251475, yousuf.aman@gmail.com',   '5678901234', 'Areeb Shoail 0484637491'),
 (5, 'Aribah', 'Khan', 'Azam', '1993-03-05', '0412785634, aribah.azam@gmail.com', '6789012345', 'Noor Aniya 0413738291'),
 (6, 'Alishbah', 'hermain', 'Iqbal', '1998-12-13', '0414856283, alishba13.@gmail.com', '7890123456', 'abira Harmain 0414827304'),
 (7, 'Noah', NULL, 'Wilson', '1990-12-05', '0416161616, noah.wilson@email.com', '8901234567', 'Ella Wilson 0413648254'),
 (8, 'Emma', 'Jane', 'Taylor', '1968-04-14', '0418181818, emma.taylor@email.com', '9012345678', 'Jack Taylor 0418492345');
SET IDENTITY_INSERT Patient OFF;

SET IDENTITY_INSERT Staff ON;
INSERT INTO Staff (staffID, fullName, contactNumber, email, qualification, employmentStatus, role, clinicID) VALUES
 (10, 'Dr. House Greogory', '0400000010', 'house.gregory@smarthealth.com', 'MBBS, FRACGP', 'Full-time', 'Doctor', 1),
 (11, 'Dr. Wilson James', '0400000011', 'wilson.james@smarthealth.com', 'MBBS, FRACP', 'Full-time', 'Doctor', 1),
 (12, 'Dr. Chase Robert', '0400000012', 'chase.robert@smarthealth.com', 'MBBS', 'Full-time', 'Doctor', 2),
 (13, 'Dr. Foreman Eric', '0400000013', 'foreman.eric@smarthealth.com', 'MBBS, FRACS', 'Part-time', 'Doctor', 3),
 (14, 'Dr. Cameron Allison', '0400000014', 'cameron.allison@smarthealth.com', 'MBBS', 'Full-time', 'Doctor', 4),
 (15, 'Dr. Cuddy Lisa', '0400000015', 'cuddy.lisa@smarthealth.com', 'MBBS', 'Full-time', 'Doctor', 5),
 (16, 'Dr. Taub Chris', '0400000016', 'taub.chris@smarthealth.com', 'MBBS, FRACGP', 'Casual', 'Doctor', 1),
 (20, 'Thirteen Olivia ', '0400000020', 'thirteen.olivia@smarthealth.com', 'Registered Nurse', 'Full-time', 'Nurse', 1),
 (21, 'Kutner Lawrence', '0400000021', 'kutner.lawrence@smarthealth.com', 'Enrolled Nurse', 'Part-time', 'Nurse', 2),
 (22, 'Masters Martha', '0400000022', 'masters.martha@smarthealth.com', 'Registered Nurse', 'Full-time', 'Nurse', 1),
 (23, 'Adams Jessica', '0400000023', 'adams.jessica@smarthealth.com', 'Registered Nurse', 'Full-time', 'Nurse', 3),
 (24, 'Park Chi', '0400000024', 'park.chi@smarthealth.com', 'Enrolled Nurse', 'Casual', 'Nurse', 4),
 (25, 'Stacy Warner', '0400000025', 'stacy.warner@smarthealth.com', 'Registered Nurse', 'Full-time', 'Nurse', 1),
 (26, 'Olivia King', '0400000026', 'olivia.king@smarthealth.com', 'Registered Nurse', 'Part-time', 'Nurse', 5),
 (30, 'Olivia Brown', '0400000030', 'olivia.brown@smarthealth.com', 'Cert III Health Admin', 'Full-time', 'Receptionist', 1),
 (31, 'James Cooper', '0400000031', 'james.cooper@smarthealth.com', 'Cert III Health Admin', 'Full-time', 'Receptionist', 2),
 (32, 'Priya Sharma', '0400000032', 'priya.sharma@smarthealth.com', 'Cert IV Health Admin', 'Full-time', 'Receptionist', 3),
 (33, 'Daniel White', '0400000033', 'daniel.white@smarthealth.com', 'Cert III Health Admin', 'Part-time', 'Receptionist', 1),
 (34, 'Chloe Evans', '0400000034', 'chloe.evans@smarthealth.com', 'Cert III Health Admin', 'Full-time', 'Receptionist', 4),
 (35, 'Ryan Scott', '0400000035', 'ryan.scott@smarthealth.com', 'Cert IV Health Admin', 'Casual', 'Receptionist', 5),
 (36, 'Hannah Lewis', '0400000036', 'hannah.lewis@smarthealth.com', 'Cert III Health Admin', 'Full-time', 'Receptionist', 1);
SET IDENTITY_INSERT Staff OFF;

INSERT INTO Doctor (staffID, specialization, providerNumber) VALUES
 (10, 'General Practice', 'PRV100010'),
 (11, 'Cardiology', 'PRV100011'),
 (12, 'Dermatology', 'PRV100012'),
 (13, 'Orthopaedics', 'PRV100013'),
 (14, 'General Practice', 'PRV100014'),
 (15, 'Paediatrics', 'PRV100015'),
 (16, 'General Practice', 'PRV100016');

INSERT INTO Nurse (staffID, nursingGrade) VALUES
 (20, 'RN Grade 2'),
 (21, 'EN Grade 1'),
 (22, 'RN Grade 3'),
 (23, 'RN Grade 2'),
 (24, 'EN Grade 1'),
 (25, 'RN Grade 2'),
 (26, 'RN Grade 1');

INSERT INTO Receptionist (staffID, administrationLevel) VALUES
 (30, 'Senior'),
 (31, 'Standard'),
 (32, 'Senior'),
 (33, 'Standard'),
 (34, 'Standard'),
 (35, 'Junior'),
 (36, 'Standard');

INSERT INTO ConsultationRoom (clinicID, roomNo, roomType, status) VALUES
 (1, '101', 'Consultation', 'Available'),
 (1, '102', 'Procedure',    'Available'),
 (1, '103', 'Consultation', 'Available'),
 (2, '101', 'Consultation', 'Available'),
 (2, '102', 'Procedure',    'Occupied'),
 (3, '101', 'Consultation', 'Available'),
 (4, '101', 'Consultation', 'Available'),
 (5, '101', 'Consultation', 'Out of Service');

INSERT INTO PatientAllergy (patientID, allergyName) VALUES
 (1, 'Penicillin'),
 (1, 'Peanuts'),
 (2, 'Latex'),
 (4, 'Aspirin'),
 (4, 'Shellfish'),
 (5, 'Pollen'),
 (6, 'Dust mites'),
 (7, 'Ibuprofen');

INSERT INTO PatientProfile (patientID, medicalHistorySummary, preferredClinicID, preferredDoctorID, registrationDate) VALUES
 (1, 'Hypertension, managed with medication', 1, 10, '2024-01-15'),
 (2, 'No significant history', 1, 11, '2024-03-22'),
 (3, 'Asthma', NULL, NULL, '2025-06-10'),
 (4, 'Type 2 diabetes', 2, 12, '2024-05-30'),
 (5, 'High cholesterol', 1, 10, '2023-11-08'),
 (6, 'No significant history', 3, 13, '2025-02-14'),
 (7, 'Seasonal allergies', 1, 16, '2024-09-01'),
 (8, 'Osteoarthritis', 4, 14, '2023-07-19');

INSERT INTO ClinicService (clinicID, serviceID, clinicSpecificPrice, currency, startDate, endDate, approvingReceptionistID) VALUES
 (1, 100, 85.00, 'AUD', '2024-01-01', NULL, 30),
 (1, 300, 50.00, 'AUD', '2024-01-01', NULL, 30),
 (1, 400, 125.00, 'AUD', '2024-01-01', NULL, 33),
 (1, 500, 60.00, 'AUD', '2024-01-01', NULL, 30),
 (2, 100, 90.00, 'AUD', '2024-01-01', NULL, 31),
 (2, 200, 160.00, 'AUD', '2024-01-01', NULL, 31),
 (3, 100, 88.00, 'AUD', '2024-01-01', NULL, 32),
 (4, 200, 165.00, 'AUD', '2024-01-01', NULL, 34);

SET IDENTITY_INSERT Appointment ON;
INSERT INTO Appointment (appointmentID, bookingDate, appointmentDateTime, status, bookingMethod, patientID, doctorID, clinicID, roomNo) VALUES
 (1, '2026-05-01', '2026-05-10T09:00:00', 'Completed', 'in person', 1, 10, 1, '101'),
 (2, '2026-05-02', '2026-05-11T10:30:00', 'Completed', 'online', 2, 11, 1, '102'),
 (3, '2026-05-03', '2026-05-12T11:00:00', 'Completed', 'phone', 1, 10, 1, '103'),
 (4, '2026-05-04', '2026-05-13T09:30:00', 'Completed', 'online', 3, 11, 1, '101'),
 (5, '2026-05-05', '2026-05-14T14:00:00', 'Completed', 'in person', 4, 12, 2, '101'),
 (6, '2026-05-06', '2026-05-15T10:00:00', 'Completed', 'online', 5, 10, 1, '102'),
 (7, '2026-05-07', '2026-05-16T13:00:00', 'Completed', 'online', 6, 13, 3, '101'),
 (8, '2026-05-05', '2026-05-06T15:00:00', 'Cancelled', 'phone', 7, 10, 1, '101'),
 (9, '2026-05-08', '2026-05-09T11:30:00', 'No-show', 'online', 8, 11, 1, '102'),
 (10,'2026-07-01', '2026-07-15T09:00:00', 'Confirmed', 'online', 2, 14, 4, '101');
SET IDENTITY_INSERT Appointment OFF;

INSERT INTO AppointmentRecord (appointmentID, observations, diagnosisNotes, treatmentNotes, followUpInstructions, staffID) VALUES
 (1, 'Patient reports mild headaches', 'Tension headache', 'Advised rest and hydration', 'Review in 2 weeks if persists', 10),
 (2, 'Routine cardiac check', 'Stable', 'Continue current medication', 'Annual review', 11),
 (3, 'Follow-up on blood pressure', 'Hypertension stable', 'Adjusted dosage', 'Review in 1 month', 10),
 (4, 'Sore throat and fever', 'Viral infection', 'Rest and fluids advised', 'Return if worsens', 11),
 (5, 'Skin rash assessment', 'Contact dermatitis', 'Prescribed topical cream', 'Review in 2 weeks', 12),
 (6, 'Telehealth cholesterol review', 'High cholesterol', 'Statin continued', 'Blood in 3 months', 10),
 (7, 'Knee pain assessment', 'Mild osteoarthritis','Physio referral discussed', 'Review in 6 weeks', 13);

INSERT INTO AppointmentService (appointmentID, serviceID, agreedPrice, serviceNotes) VALUES
 (1, 100, 85.00, 'Standard consultation'),
 (2, 100, 85.00, 'General review'),
 (3, 100, 85.00, 'Consultation'),
 (3, 400, 125.00, 'Added health screening'),
 (4, 300, 45.00, 'Vaccination administered'),
 (5, 200, 160.00, 'Specialist dermatology'),
 (6, 500, 60.00, 'Telehealth consultation'),
 (7, 100, 88.00, 'GP consultation');

INSERT INTO AppointmentNurse (appointmentID, staffID) VALUES
 (1, 20),
 (2, 22),
 (3, 20),
 (3, 25),
 (4, 25),
 (5, 21),
 (6, 22),
 (7, 23);

SET IDENTITY_INSERT Invoice ON;
INSERT INTO Invoice (invoiceID, invoiceDate, consultationCharges, prescriptionCharges, discountAmount, penaltyCharge, paymentMethod, paymentStatus, appointmentID, finalisedByReceptionistID, discountApprovedByStaffID) VALUES
 (1, '2026-05-10', 85.00, 10.00, 0.00, 0.00, 'Card', 'Paid', 1, 30, NULL),
 (2, '2026-05-11', 85.00, 0.00, 0.00, 0.00, 'Medicare', 'Paid', 2, 30, NULL),
 (3, '2026-05-12', 210.00, 0.00, 20.00, 0.00, 'Card', 'Partially Paid', 3, 33, 30),
 (4, '2026-05-13', 45.00, 0.00, 0.00, 0.00, 'Cash', 'Paid', 4, 30, NULL),
 (5, '2026-05-14', 160.00, 0.00, 0.00, 0.00, 'Insurance', 'Paid', 5, 31, NULL),
 (6, '2026-05-15', 60.00, 5.00, 10.00, 0.00, 'Card', 'Paid', 6, 30, 11),
 (7, '2026-05-16', 88.00, 0.00, 0.00, 0.00, 'Bank Transfer', 'Unpaid', 7, 32, NULL),
 (8, '2026-05-06', 0.00, 0.00, 0.00, 25.00, NULL, 'Unpaid', 8, 30, NULL),
 (9, '2026-05-09', 0.00, 0.00, 0.00, 50.00, NULL, 'Unpaid', 9, 30, NULL);
SET IDENTITY_INSERT Invoice OFF;

SET IDENTITY_INSERT Prescription ON;
INSERT INTO Prescription (prescriptionID, prescriptionDate, medicationName, dosage, frequency, duration, specialInstructions, appointmentID, patientID, doctorID) VALUES
 (1, '2026-05-10', 'Paracetamol', '500mg', 'Twice daily', '5 days', 'Take after food', 1, 1, 10),
 (2, '2026-05-11', 'Atorvastatin', '20mg', 'Once daily', '30 days', NULL, 2, 2, 11),
 (3, '2026-05-12', 'Amlodipine', '5mg', 'Once daily', '30 days', 'Monitor blood pressure',3, 1, 10),
 (4, '2026-05-12', 'Ibuprofen', '200mg', 'As needed', '7 days', 'Max 3 per day', 3, 1, 10),
 (5, '2026-05-14', 'nezkill','1%', 'Twice daily', '14 days', 'Apply to affected area',5, 4, 12),
 (6, '2026-05-15', 'kestine', '10mg', 'Once daily', '30 days', NULL, 6, 5, 10),
 (7, '2026-05-16', 'priorin', '250mg', 'Twice daily', '10 days', 'Take with food', 7, 6, 13),
 (8, '2026-06-01', 'nurofen', '200mg', 'As needed', '30 days', 'Inhaler, repeat script', NULL, 2, 11);


