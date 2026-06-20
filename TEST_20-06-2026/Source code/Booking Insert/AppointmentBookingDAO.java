package com.smarthealth.dao;

import com.smarthealth.entity.Appointment;
import com.smarthealth.entity.ConsultationRoom;
import com.smarthealth.entity.ConsultationRoomId;
import com.smarthealth.entity.Doctor;
import com.smarthealth.entity.Patient;
import com.smarthealth.util.HibernateUtil;

import org.hibernate.Session;
import org.hibernate.Transaction;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DAO for creating appointment bookings through Hibernate (Task 5, Operation #3).
 *
 * Uses a pure ORM insert (session.persist) rather than calling makeBooking.sql, so it
 * stays consistent with the form's other operations. FK existence and doctor/room overlap
 * are still checked here because double-booking is a time-overlap rule that FK/CHECK
 * constraints cannot enforce. The overlap logic is equivalent to makeBooking.sql under
 * the fixed 30-minute slot assumption.
 */
public class AppointmentBookingDAO {

    private static final int SLOT_MINUTES = 30;

    public Integer createBooking(Integer patientId,
                                 Integer doctorId,
                                 Integer clinicId,
                                 String roomNo,
                                 LocalDateTime appointmentDateTime,
                                 String bookingMethod) {

        if (patientId == null || doctorId == null || clinicId == null
                || roomNo == null || appointmentDateTime == null || bookingMethod == null) {
            throw new IllegalArgumentException("All fields are required.");
        }

        // Trim first so trailing/leading spaces don't fail the exact-match CHECK constraint
        // (e.g. "in person " would otherwise be rejected by the DB).
        roomNo = roomNo.trim();
        bookingMethod = bookingMethod.trim();

        if (roomNo.isEmpty() || bookingMethod.isEmpty()) {
            throw new IllegalArgumentException("All fields are required.");
        }

        // !isAfter also rejects a time exactly equal to now, matching makeBooking.sql's
        // <= SYSDATETIME() check.
        if (!appointmentDateTime.isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("Appointment date/time must be in the future.");
        }

        // Must match createTables.sql CK_Appointment_method exactly: 'online','phone','in person'.
        if (!bookingMethod.equals("online")
                && !bookingMethod.equals("phone")
                && !bookingMethod.equals("in person")) {
            throw new IllegalArgumentException("Booking method must be online, phone or in person.");
        }

        LocalDateTime newStart = appointmentDateTime;
        LocalDateTime newEnd = appointmentDateTime.plusMinutes(SLOT_MINUTES);
        // Overlap window: an existing appointment clashes when its start falls in
        // (newStart - slot, newEnd). Same result as makeBooking.sql, expressed without
        // any DB-specific date function so it runs through HQL unchanged.
        LocalDateTime earliest = newStart.minusMinutes(SLOT_MINUTES);

        Transaction tx = null;

        try (Session session = HibernateUtil.getSessionFactory().openSession()) {
            tx = session.beginTransaction();

            Patient patient = session.get(Patient.class, patientId);
            if (patient == null) {
                throw new IllegalArgumentException("Patient ID " + patientId + " does not exist.");
            }

            Doctor doctor = session.get(Doctor.class, doctorId);
            if (doctor == null) {
                throw new IllegalArgumentException("Doctor ID " + doctorId + " does not exist.");
            }

            // ConsultationRoom has a composite key (clinicID, roomNo).
            ConsultationRoom room = session.get(
                    ConsultationRoom.class, new ConsultationRoomId(clinicId, roomNo));
            if (room == null) {
                throw new IllegalArgumentException(
                        "Room " + roomNo + " does not exist for clinic " + clinicId + ".");
            }

            // Doctor not double-booked: counts only 'Confirmed' appointments, same rule as
            // makeBooking.sql.
            boolean doctorClash = !session.createQuery(
                    "SELECT a FROM Appointment a " +
                    "WHERE a.doctor.staffId = :docId " +
                    "AND a.status = 'Confirmed' " +
                    "AND a.appointmentDateTime > :earliest " +
                    "AND a.appointmentDateTime < :newEnd", Appointment.class)
                    .setParameter("docId", doctorId)
                    .setParameter("earliest", earliest)
                    .setParameter("newEnd", newEnd)
                    .setMaxResults(1)
                    .getResultList()
                    .isEmpty();
            if (doctorClash) {
                throw new IllegalArgumentException(
                        "Doctor already has an overlapping confirmed appointment.");
            }

            // Room not double-booked: same overlap rule, keyed by clinic + room.
            boolean roomClash = !session.createQuery(
                    "SELECT a FROM Appointment a " +
                    "WHERE a.consultationRoom.id.clinicId = :clinicId " +
                    "AND a.consultationRoom.id.roomNo = :roomNo " +
                    "AND a.status = 'Confirmed' " +
                    "AND a.appointmentDateTime > :earliest " +
                    "AND a.appointmentDateTime < :newEnd", Appointment.class)
                    .setParameter("clinicId", clinicId)
                    .setParameter("roomNo", roomNo)
                    .setParameter("earliest", earliest)
                    .setParameter("newEnd", newEnd)
                    .setMaxResults(1)
                    .getResultList()
                    .isEmpty();
            if (roomClash) {
                throw new IllegalArgumentException(
                        "Room is already booked for an overlapping confirmed appointment.");
            }

            Appointment appointment = new Appointment();
            appointment.setBookingDate(LocalDate.now());
            appointment.setAppointmentDateTime(appointmentDateTime);
            appointment.setStatus("Confirmed");          // allowed by CK_Appointment_status
            appointment.setBookingMethod(bookingMethod);
            appointment.setPatient(patient);
            appointment.setDoctor(doctor);
            appointment.setConsultationRoom(room);

            session.persist(appointment);                // appointmentID generated here (IDENTITY)
            tx.commit();

            return appointment.getAppointmentId();

        } catch (RuntimeException ex) {
            if (tx != null && tx.getStatus().canRollback()) {
                tx.rollback();
            }
            throw ex;   // re-throw so the form can show the message
        }
    }
}
