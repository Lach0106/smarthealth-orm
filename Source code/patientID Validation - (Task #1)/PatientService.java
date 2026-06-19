package com.smarthealth.service;

import com.smarthealth.dao.PatientDAO;

public class PatientService {
    private final PatientDAO patientDAO = new PatientDAO();
    public boolean patientExists(Integer patientId) {
        return patientDAO.patientExists(patientId);
    }
}