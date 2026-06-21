package com.smarthealth.dao;

import com.smarthealth.entity.Appointment;
import com.smarthealth.util.HibernateUtil;
import org.hibernate.Session;

// DAO for reading appointment data through Hibernate (Task 5, Operation #2).
// Returns the single most recent appointment for a given patient, or null if
// the patient has no appointments on record.
public class AppointmentDAO {

    public Appointment getLatestAppointment(Integer patientId) {
        if (patientId == null) {
            return null;
        }
        try (Session session = HibernateUtil.getSessionFactory().openSession()) {
            // JOIN FETCH a.patient loads the patient inside this session. The
            // @ManyToOne on Appointment is LAZY, so without the fetch the servlet
            // would hit a LazyInitializationException when it reads the patient's
            // name after the session has closed.
            return session.createQuery(
                    "FROM Appointment a JOIN FETCH a.patient " +
                    "WHERE a.patient.patientId = :pid " +
                    "ORDER BY a.appointmentDateTime DESC, a.appointmentId DESC", Appointment.class)
                    .setParameter("pid", patientId)
                    .setMaxResults(1)     // only the latest row
                    .uniqueResult();      // null when the patient has no appointments
        } catch (Exception e) {
            // Rethrow so a real DB/Hibernate error isn't hidden as "no appointment found".
            throw new RuntimeException("Failed to load latest appointment.", e);
        }
    }
}
