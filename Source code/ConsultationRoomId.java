package com.smarthealth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ConsultationRoomId implements Serializable {

    @Column(name = "clinicID")
    private Integer clinicId;

    @Column(name = "roomNo", length = 10)
    private String roomNo;

    public ConsultationRoomId() {
    }

    public ConsultationRoomId(Integer clinicId, String roomNo) {
        this.clinicId = clinicId;
        this.roomNo = roomNo;
    }

    public Integer getClinicId() {
        return clinicId;
    }

    public void setClinicId(Integer clinicId) {
        this.clinicId = clinicId;
    }

    public String getRoomNo() {
        return roomNo;
    }

    public void setRoomNo(String roomNo) {
        this.roomNo = roomNo;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ConsultationRoomId)) return false;
        ConsultationRoomId that = (ConsultationRoomId) o;
        return Objects.equals(clinicId, that.clinicId)
                && Objects.equals(roomNo, that.roomNo);
    }

    @Override
    public int hashCode() {
        return Objects.hash(clinicId, roomNo);
    }
}