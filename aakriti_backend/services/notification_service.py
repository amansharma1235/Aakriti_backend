import logging
import datetime
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session
from models.models import Notification, FcmToken
from websocket.manager import ws_manager
from services.firebase_service import send_push_notification

logger = logging.getLogger("notification_service")

async def dispatch_notification(
    db: Session,
    title: str,
    message: str,
    notification_type: str = "General",
    patient_id: Optional[str] = None,
    patient_name: Optional[str] = None,
    event_type: str = "NOTIFICATION",
    extra_data: Optional[Dict[str, Any]] = None,
) -> Notification:
    """
    1. Persist notification to MySQL
    2. Broadcast real-time WebSocket event to all connected admin dashboards
    3. Send Firebase push notification to registered admin device tokens
    Errors in WebSocket or Firebase are caught and logged, never aborting the DB record.
    """
    notif_id = f"NTF{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
    
    db_notif = Notification(
        notification_id=notif_id,
        patient_id=patient_id,
        patient_name=patient_name,
        title=title,
        message=message,
        notification_type=notification_type,
        status="Sent",
        is_read=False,
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)

    # 2. WebSocket Real-time Broadcast
    try:
        ws_payload = {
            "notification_id": notif_id,
            "title": title,
            "message": message,
            "type": notification_type,
            "patient_id": patient_id,
            "patient_name": patient_name,
            "created_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            **(extra_data or {}),
        }

        await ws_manager.broadcast(event_type=event_type, data=ws_payload)
        logger.info(f"[Notification] Dispatched WS event '{event_type}': {title}")
    except Exception as e:
        logger.error(f"[Notification] WS Broadcast failed (safe ignore): {e}")

    # 3. Firebase Push Notification
    try:
        # Fetch admin tokens and patient-specific tokens
        token_query = db.query(FcmToken)
        if patient_id:
            token_query = token_query.filter(
                (FcmToken.user_type == "admin") | (FcmToken.user_id == patient_id) | (FcmToken.user_type == "patient")
            )
        else:
            token_query = token_query.filter(FcmToken.user_type == "admin")
            
        tokens_records = token_query.all()
        token_list = list(set([t.token for t in tokens_records if t.token]))
        if token_list:
            fcm_data = {
                "event": event_type,
                "notification_id": notif_id,
                "notification_type": notification_type.lower(),
                "patient_id": patient_id or "",
            }
            if extra_data:
                for k, v in extra_data.items():
                    fcm_data[str(k)] = str(v)
            send_push_notification(
                tokens=token_list,
                title=title,
                body=message,
                data=fcm_data,
            )
    except Exception as e:
        logger.error(f"[Notification] Firebase push failed (safe ignore): {e}")

    return db_notif
