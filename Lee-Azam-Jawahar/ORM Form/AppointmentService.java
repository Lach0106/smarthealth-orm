package com.smarthealth.service;

import com.smarthealth.dao.AppointmentDAO;
import com.smarthealth.entity.Appointment;

// Service layer for Task 5, Operation #2 (display latest appointment).
// Mirrors PatientService: a thin wrapper that keeps the servlet free of DAO details.
public class AppointmentService {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();

    public Appointment getLatestAppointment(Integer patientId) {
        return appointmentDAO.getLatestAppointment(patientId);
    }
}
