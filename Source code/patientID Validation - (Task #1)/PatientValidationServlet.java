package com.smarthealth.servlet;

import com.smarthealth.service.PatientService;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/validatePatient")
public class PatientValidationServlet extends HttpServlet {
    private final PatientService patientService = new PatientService();
    @Override
    protected void doGet(HttpServletRequest request,HttpServletResponse response) throws IOException
    {
        String patientIdParam = request.getParameter("patientId");
        boolean exists = false;
        try
        {
            Integer patientId = Integer.parseInt(patientIdParam);
            exists = patientService.patientExists(patientId);
        }
        catch (NumberFormatException e)
        {
            exists = false;
        }
        response.setContentType("application/json");
        response.getWriter().write("{\"exists\":" + exists + "}");
    }
}