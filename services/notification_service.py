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
    notif_id = f"NTF{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
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
            "created_at": datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
            **(extra_data or {}),
        }
        await ws_manager.broadcast(event_type=event_type, data=ws_payload)
        logger.info(f"[Notification] Dispatched WS event '{event_type}': {title}")
    except Exception as e:
        logger.error(f"[Notification] WS Broadcast failed (safe ignore): {e}")

    # 3. Firebase Push Notification
    try:
        tokens_records = db.query(FcmToken).filter(FcmToken.user_type == "admin").all()
        token_list = [t.token for t in tokens_records if t.token]
        if token_list:
            send_push_notification(
                tokens=token_list,
                title=title,
                body=message,
                data={"event": event_type, "notification_id": notif_id},
            )
    except Exception as e:
        logger.error(f"[Notification] Firebase push failed (safe ignore): {e}")

    return db_notif
