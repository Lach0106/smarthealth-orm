package com.smarthealth.servlet;

import com.smarthealth.service.AppointmentBookingService;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;

/**
 * Receives the "Book Appointment" form submission and inserts the appointment
 * through AppointmentBookingService -> AppointmentBookingDAO (Hibernate).
 *
 * doPost is used because this creates a record. The form sends six fields; the
 * numeric ones are parsed here so a bad value returns a clear JSON message
 * instead of a 500. The DAO throws IllegalArgumentException for business-rule
 * failures (patient/doctor/room not found, double-booking), which are passed
 * back to the form as the "error" field.
 */
@WebServlet("/bookAppointment")
public class BookAppointmentServlet extends HttpServlet {

    private final AppointmentBookingService bookingService = new AppointmentBookingService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String patientIdParam = request.getParameter("patientId");
        String doctorIdParam  = request.getParameter("doctorId");
        String clinicIdParam  = request.getParameter("clinicId");
        String roomNo         = request.getParameter("roomNo");
        String method         = request.getParameter("bookingMethod");
        String whenParam      = request.getParameter("appointmentDateTime");

       // Validate required fields before parsing so user input errors return a clear JSON message.
        if (isBlank(patientIdParam) || isBlank(doctorIdParam) || isBlank(clinicIdParam)
                || isBlank(roomNo) || isBlank(method) || isBlank(whenParam)) {
            out.write("{\"success\":false,\"error\":\"All fields are required.\"}");
            return;
        }

        try {
            Integer patientId = Integer.parseInt(patientIdParam.trim());
            Integer doctorId  = Integer.parseInt(doctorIdParam.trim());
            Integer clinicId  = Integer.parseInt(clinicIdParam.trim());

            // datetime-local sends "yyyy-MM-ddTHH:mm", which LocalDateTime.parse accepts directly.
            // trim() guards against stray surrounding whitespace (parseInt/parse reject it).
            LocalDateTime when = LocalDateTime.parse(whenParam.trim());

            Integer appointmentId = bookingService.createBooking(
                    patientId, doctorId, clinicId, roomNo, when, method);

            out.write("{\"success\":true,\"appointmentId\":" + appointmentId + "}");

        } catch (NumberFormatException e) {
            
            out.write("{\"success\":false,\"error\":\"Patient, doctor and clinic IDs must be numbers.\"}");
        } catch (DateTimeParseException e) {
            out.write("{\"success\":false,\"error\":\"Invalid appointment date and time.\"}");
        } catch (IllegalArgumentException e) {
            // Business-rule message thrown by the DAO (e.g. double-booking, patient not found).
            out.write("{\"success\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        } catch (Exception e) {
            // Unexpected failure (e.g. DB connection). Logged for debugging, generic message to the user.
            e.printStackTrace();
            out.write("{\"success\":false,\"error\":\"Booking failed due to a server error.\"}");
        }
    }

    // True when a request parameter is missing or only whitespace.
    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    // Minimal escaping so a message containing a quote or backslash can't break the JSON.
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
