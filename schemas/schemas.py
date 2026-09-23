from typing import Optional, Any, List
from pydantic import BaseModel, Field

class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Any] = None

class AppointmentCreateSchema(BaseModel):
    patient_name: str
    service_name: str
    appointment_date: str
    appointment_time: str
    mobile: Optional[str] = None
    patient_id: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = "Male"
    doctor_name: Optional[str] = None
    note: Optional[str] = None

class AppointmentStatusUpdateSchema(BaseModel):
    status: str
    note: Optional[str] = None

class AppointmentRescheduleSchema(BaseModel):
    new_date: str
    new_time: str
    note: Optional[str] = None

class FcmTokenRegisterSchema(BaseModel):
    token: str
    device_type: Optional[str] = "android"
    user_type: Optional[str] = "admin"
    user_id: Optional[str] = None
