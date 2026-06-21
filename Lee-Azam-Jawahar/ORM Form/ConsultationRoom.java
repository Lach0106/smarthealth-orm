package com.smarthealth.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "ConsultationRoom")
public class ConsultationRoom {

    @EmbeddedId
    private ConsultationRoomId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("clinicId")
    @JoinColumn(
            name = "clinicID",
            nullable = false,
            foreignKey = @ForeignKey(name = "FK_ConsultationRoom_Clinic")
    )
    private Clinic clinic;

    @Column(name = "roomType", nullable = false, length = 50)
    private String roomType;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    public ConsultationRoom() {
    }

    public ConsultationRoomId getId() {
        return id;
    }

    public void setId(ConsultationRoomId id) {
        this.id = id;
    }

    public Clinic getClinic() {
        return clinic;
    }

    public void setClinic(Clinic clinic) {
        this.clinic = clinic;
    }

    public String getRoomType() {
        return roomType;
    }

    public void setRoomType(String roomType) {
        this.roomType = roomType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}