package com.smarthealth.servlet;

import com.smarthealth.entity.Appointment;
import com.smarthealth.entity.Patient;
import com.smarthealth.service.AppointmentService;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

// Task 5, Operation #2: return a patient's latest appointment as JSON.
// Mirrors PatientValidationServlet (doGet + manually built JSON response).
// Front-end calls: latestAppointment?patientId=<id>
@WebServlet("/latestAppointment")
public class LatestAppointmentServlet extends HttpServlet {

    private final AppointmentService appointmentService = new AppointmentService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");

        Appointment appt = null;
        try {
            Integer patientId = Integer.parseInt(request.getParameter("patientId"));
            appt = appointmentService.getLatestAppointment(patientId);
        } catch (NumberFormatException e) {
            appt = null;   // non-numeric / missing id is treated as "nothing to show"
        }

        // No appointment (patient has none, or id was invalid)
        if (appt == null) {
            response.getWriter().write("{\"found\":false}");
            return;
        }

        Patient p = appt.getPatient();
        String fullName = p.getFirstName()
                + ((p.getMiddleName() != null && !p.getMiddleName().isBlank())
                        ? " " + p.getMiddleName() : "")
                + " " + p.getLastName();

        String json = "{\"found\":true,"
                + "\"appointmentId\":" + appt.getAppointmentId() + ","
                + "\"patientFullName\":\"" + escape(fullName) + "\","
                + "\"bookingDate\":\"" + appt.getBookingDate() + "\","
                + "\"appointmentDateTime\":\"" + appt.getAppointmentDateTime() + "\","
                + "\"status\":\"" + escape(appt.getStatus()) + "\","
                + "\"bookingMethod\":\"" + escape(appt.getBookingMethod()) + "\"}";

        response.getWriter().write(json);
    }

    // Minimal JSON escaping so a stray quote/backslash in a text value can't break the JSON.
    private String escape(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
