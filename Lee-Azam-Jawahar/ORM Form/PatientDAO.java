package com.smarthealth.dao;

import com.smarthealth.entity.Patient;
import com.smarthealth.util.HibernateUtil;
import org.hibernate.Session;

public class PatientDAO {

    public boolean patientExists(Integer patientId)
    {
        if (patientId == null)
        {
            return false;
        }
        try (Session session =
                     HibernateUtil.getSessionFactory().openSession())
        {
            Patient patient = session.get(Patient.class, patientId);
            return patient != null;
        }
        catch (Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
}