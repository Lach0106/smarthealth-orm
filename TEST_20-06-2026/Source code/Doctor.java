package com.smarthealth.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "Doctor")
@PrimaryKeyJoinColumn(name = "staffID")
public class Doctor extends Staff {

    @Column(name = "specialization", nullable = false, length = 100)
    private String specialization;

    @Column(
            name = "providerNumber",
            nullable = false,
            unique = true,
            length = 30
    )
    private String providerNumber;

    public Doctor() {
    }

    public String getSpecialization() {
        return specialization;
    }

    public void setSpecialization(String specialization) {
        this.specialization = specialization;
    }

    public String getProviderNumber() {
        return providerNumber;
    }

    public void setProviderNumber(String providerNumber) {
        this.providerNumber = providerNumber;
    }
}