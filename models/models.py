import datetime
from sqlalchemy import Column, Integer, String, Text, Date, DateTime, Numeric, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from core.database import Base

class AdminUser(Base):
    __tablename__ = "admin_users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    full_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), default="Admin")
    status = Column(String(20), default="Active")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(20), unique=True, nullable=False, index=True)
    full_name = Column(String(100), nullable=False, index=True)
    mobile = Column(String(15), nullable=False, index=True)
    age = Column(Integer, default=0)
    gender = Column(String(10), default="Male")
    blood_group = Column(String(10), default="A+")
    email = Column(String(100), nullable=True)
    address = Column(Text, nullable=True)
    status = Column(String(20), default="Active")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    appointments = relationship("Appointment", back_populates="patient", foreign_keys="Appointment.patient_id", primaryjoin="Patient.patient_id==Appointment.patient_id")

class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    doctor_id = Column(String(20), unique=True, nullable=False, index=True)
    doctor_name = Column(String(100), nullable=False)
    specialization = Column(String(100), nullable=False)
    mobile = Column(String(15), nullable=False)
    experience = Column(String(50), nullable=True)
    status = Column(String(20), default="Active")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    service_id = Column(String(20), unique=True, nullable=False, index=True)
    service_name = Column(String(100), nullable=False, index=True)
    category = Column(String(50), default="Ultrasound")
    price = Column(Numeric(10, 2), default=0.0)
    duration = Column(String(50), default="30 min")
    description = Column(Text, nullable=True)
    status = Column(String(20), default="Active")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    appointment_id = Column(String(30), unique=True, nullable=False, index=True)
    patient_id = Column(String(20), nullable=False, index=True)
    patient_name = Column(String(100), nullable=False)
    mobile = Column(String(15), nullable=True)
    service_name = Column(String(100), nullable=False)
    appointment_date = Column(Date, nullable=False, index=True)
    appointment_time = Column(String(20), nullable=True)
    doctor_name = Column(String(100), nullable=True)
    note = Column(Text, nullable=True)
    status = Column(String(30), default="Pending", index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    patient = relationship("Patient", back_populates="appointments", foreign_keys=[patient_id], primaryjoin="Appointment.patient_id==Patient.patient_id")

class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    report_id = Column(String(20), unique=True, nullable=False, index=True)
    patient_id = Column(String(20), nullable=False, index=True)
    patient_name = Column(String(100), nullable=False)
    report_title = Column(String(150), nullable=False)
    report_type = Column(String(50), default="Ultrasound")
    report_date = Column(Date, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_path = Column(String(255), nullable=True)
    status = Column(String(20), default="Ready")
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    payment_id = Column(String(20), unique=True, nullable=False, index=True)
    patient_id = Column(String(20), nullable=False, index=True)
    patient_name = Column(String(100), nullable=False)
    amount = Column(Numeric(10, 2), default=0.0)
    payment_method = Column(String(50), default="Cash")
    payment_date = Column(Date, nullable=False)
    status = Column(String(20), default="Paid")
    transaction_id = Column(String(100), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    notification_id = Column(String(30), unique=True, nullable=False, index=True)
    patient_id = Column(String(20), nullable=True, index=True)
    patient_name = Column(String(100), nullable=True)
    title = Column(String(150), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(50), default="General")
    status = Column(String(20), default="Pending")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class FcmToken(Base):
    __tablename__ = "fcm_tokens"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    token = Column(String(255), unique=True, nullable=False, index=True)
    device_type = Column(String(50), default="android")
    user_type = Column(String(50), default="admin") # admin or patient
    user_id = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
