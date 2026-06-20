package com.smarthealth.entity;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "Appointment")
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "appointmentID")
    private Integer appointmentId;

    @Column(name = "bookingDate", nullable = false)
    private LocalDate bookingDate;

    @Column(name = "appointmentDateTime", nullable = false)
    private LocalDateTime appointmentDateTime;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "bookingMethod", nullable = false, length = 20)
    private String bookingMethod;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "patientID",
            nullable = false,
            foreignKey = @ForeignKey(name = "FK_Appointment_Patient")
    )
    private Patient patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "doctorID",
            nullable = false,
            foreignKey = @ForeignKey(name = "FK_Appointment_Doctor")
    )
    private Doctor doctor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumns({
            @JoinColumn(
                    name = "clinicID",
                    referencedColumnName = "clinicID",
                    nullable = false
            ),
            @JoinColumn(
                    name = "roomNo",
                    referencedColumnName = "roomNo",
                    nullable = false
            )
    })
    private ConsultationRoom consultationRoom;

    public Appointment() {
    }

    public Integer getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Integer appointmentId) {
        this.appointmentId = appointmentId;
    }

    public LocalDate getBookingDate() {
        return bookingDate;
    }

    public void setBookingDate(LocalDate bookingDate) {
        this.bookingDate = bookingDate;
    }

    public LocalDateTime getAppointmentDateTime() {
        return appointmentDateTime;
    }

    public void setAppointmentDateTime(LocalDateTime appointmentDateTime) {
        this.appointmentDateTime = appointmentDateTime;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getBookingMethod() {
        return bookingMethod;
    }

    public void setBookingMethod(String bookingMethod) {
        this.bookingMethod = bookingMethod;
    }

    public Patient getPatient() {
        return patient;
    }

    public void setPatient(Patient patient) {
        this.patient = patient;
    }

    public Doctor getDoctor() {
        return doctor;
    }

    public void setDoctor(Doctor doctor) {
        this.doctor = doctor;
    }

    public ConsultationRoom getConsultationRoom() {
        return consultationRoom;
    }

    public void setConsultationRoom(ConsultationRoom consultationRoom) {
        this.consultationRoom = consultationRoom;
    }
}