import datetime
import random
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from models.models import Appointment, Patient
from services.notification_service import dispatch_notification

VALID_STATUS_TRANSITIONS = {
    "Pending": ["Confirmed", "Rejected", "Cancelled"],
    "Confirmed": ["Checked-In", "Rescheduled", "Cancelled"],
    "Checked-In": ["In-Progress", "Cancelled"],
    "In-Progress": ["Completed", "Cancelled"],
    "Rescheduled": ["Confirmed", "Cancelled"],
    "Completed": [],
    "Cancelled": [],
    "Rejected": [],
    "No-Show": [],
}

def generate_appointment_id(db: Session) -> str:
    """
    Format: APT-YYYYMMDD-XXXX (e.g. APT-20260923-0001)
    """
    today_str = datetime.date.today().strftime("%Y%m%d")
    count_today = db.query(Appointment).filter(
        Appointment.appointment_id.like(f"APT-{today_str}-%")
    ).count()
    seq = str(count_today + 1).zfill(4)
    return f"APT-{today_str}-{seq}"

def is_slot_available(
    db: Session,
    appointment_date: datetime.date,
    appointment_time: str,
    doctor_name: Optional[str] = None,
    service_name: Optional[str] = None,
    exclude_id: Optional[str] = None
) -> bool:
    """
    Prevent duplicate booking: Check if slot is already booked for the same date & time & doctor/service.
    """
    query = db.query(Appointment).filter(
        Appointment.appointment_date == appointment_date,
        Appointment.appointment_time == appointment_time,
        Appointment.status.in_(["Pending", "Confirmed", "Checked-In", "In-Progress"])
    )
    if doctor_name:
        query = query.filter(Appointment.doctor_name == doctor_name)
    if exclude_id:
        query = query.filter(Appointment.appointment_id != exclude_id)
        
    existing = query.first()
    return existing is None

async def create_new_appointment(
    db: Session,
    patient_name: str,
    service_name: str,
    appointment_date: str,
    appointment_time: str,
    mobile: Optional[str] = None,
    patient_id: Optional[str] = None,
    doctor_name: Optional[str] = None,
    note: Optional[str] = None,
    age: Optional[int] = None,
    gender: Optional[str] = None,
    initial_status: str = "Pending"
) -> Dict[str, Any]:
    """
    Production-level appointment creation:
    1. Parse and validate date
    2. Check slot availability
    3. Ensure patient profile exists or create it
    4. Insert appointment record
    5. Dispatch real-time WebSocket event + Firebase push notification
    """
    try:
        parsed_date = datetime.datetime.strptime(appointment_date[:10], "%Y-%m-%d").date()
    except Exception:
        parsed_date = datetime.date.today()

    # Slot availability check
    if not is_slot_available(db, parsed_date, appointment_time, doctor_name):
        return {
            "success": False,
            "message": f"Slot at {appointment_time} on {parsed_date} is already booked. Please choose another time.",
            "data": None
        }

    # Generate appointment ID
    apt_id = generate_appointment_id(db)

    # Ensure patient profile
    if not patient_id:
        existing_p = db.query(Patient).filter(Patient.mobile == (mobile or "")).first() if mobile else None
        if existing_p:
            patient_id = existing_p.patient_id
        else:
            patient_count = db.query(Patient).count()
            patient_id = f"AKR{str(patient_count + 135).zfill(3)}"
            new_patient = Patient(
                patient_id=patient_id,
                full_name=patient_name,
                mobile=mobile or "",
                age=age or 25,
                gender=gender or "Male",
                status="Active"
            )
            db.add(new_patient)
            db.commit()

    # Create Appointment
    new_apt = Appointment(
        appointment_id=apt_id,
        patient_id=patient_id,
        patient_name=patient_name,
        mobile=mobile,
        service_name=service_name,
        appointment_date=parsed_date,
        appointment_time=appointment_time,
        doctor_name=doctor_name or "Dr. Rajesh Sharma",
        note=note or "",
        status=initial_status,
        created_at=datetime.datetime.utcnow()
    )
    db.add(new_apt)
    db.commit()
    db.refresh(new_apt)

    # Dispatch Real-Time Notification & WebSocket Broadcast
    apt_data = {
        "id": new_apt.id,
        "appointment_id": apt_id,
        "patient_id": patient_id,
        "patient_name": patient_name,
        "mobile": mobile,
        "service_name": service_name,
        "appointment_date": str(parsed_date),
        "appointment_time": appointment_time,
        "doctor_name": doctor_name or "Dr. Rajesh Sharma",
        "note": note or "",
        "status": initial_status,
        "created_at": new_apt.created_at.strftime("%Y-%m-%d %H:%M:%S")
    }

    await dispatch_notification(
        db=db,
        title="New Appointment Booked 🔔",
        message=f"{patient_name} requested {service_name} on {parsed_date} at {appointment_time}",
        notification_type="Appointment",
        patient_id=patient_id,
        patient_name=patient_name,
        event_type="NEW_APPOINTMENT",
        extra_data={"appointment": apt_data}
    )

    return {
        "success": True,
        "message": "Appointment request submitted successfully.",
        "data": apt_data
    }
