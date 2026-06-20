package com.smarthealth.service;

import com.smarthealth.dao.AppointmentBookingDAO;

import java.time.LocalDateTime;

/**
 * Thin service layer over AppointmentBookingDAO, kept to match the structure of
 * PatientService so the servlet talks to a service rather than the DAO directly.
 */
public class AppointmentBookingService {

    private final AppointmentBookingDAO bookingDAO = new AppointmentBookingDAO();

    public Integer createBooking(Integer patientId,
                                 Integer doctorId,
                                 Integer clinicId,
                                 String roomNo,
                                 LocalDateTime appointmentDateTime,
                                 String bookingMethod) {
        return bookingDAO.createBooking(
                patientId, doctorId, clinicId, roomNo, appointmentDateTime, bookingMethod);
    }
}
