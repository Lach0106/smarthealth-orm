package com.smarthealth.entity;

import jakarta.persistence.*;

import java.time.LocalDate;

@Entity
@Table(name = "Patient")
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "patientID")
    private Integer patientId;

    @Column(name = "firstName", nullable = false, length = 50)
    private String firstName;

    @Column(name = "middleName", length = 50)
    private String middleName;

    @Column(name = "lastName", nullable = false, length = 50)
    private String lastName;

    @Column(name = "dateOfBirth", nullable = false)
    private LocalDate dateOfBirth;

    @Column(name = "contactDetails", nullable = false, length = 255)
    private String contactDetails;

    @Column(
            name = "medicareOrInsuranceNo",
            nullable = false,
            unique = true,
            length = 30
    )
    private String medicareOrInsuranceNo;

    @Column(name = "emergencyContact", length = 255)
    private String emergencyContact;

    public Patient() {
    }

    public Integer getPatientId() {
        return patientId;
    }

    public void setPatientId(Integer patientId) {
        this.patientId = patientId;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getMiddleName() {
        return middleName;
    }

    public void setMiddleName(String middleName) {
        this.middleName = middleName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public LocalDate getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(LocalDate dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public String getContactDetails() {
        return contactDetails;
    }

    public void setContactDetails(String contactDetails) {
        this.contactDetails = contactDetails;
    }

    public String getMedicareOrInsuranceNo() {
        return medicareOrInsuranceNo;
    }

    public void setMedicareOrInsuranceNo(String medicareOrInsuranceNo) {
        this.medicareOrInsuranceNo = medicareOrInsuranceNo;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public void setEmergencyContact(String emergencyContact) {
        this.emergencyContact = emergencyContact;
    }
}