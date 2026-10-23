import sys
import unittest
from fastapi.testclient import TestClient
from main import app
from core.security import create_access_token

class TestSecurityAndAuthorization(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        # Create test tokens
        cls.admin_token = create_access_token(
            data={"sub": "admin@aakriti.com", "role": "admin", "name": "Admin User"}
        )
        cls.patient_token = create_access_token(
            data={"sub": "patient1@test.com", "role": "patient", "patient_id": "P-TEST-1"}
        )

    def test_01_unauthenticated_admin_endpoint_returns_401(self):
        response = self.client.get("/dashboard/stats")
        self.assertEqual(response.status_code, 401)
        self.assertIn("Authentication credentials were not provided", response.json()["detail"])

    def test_02_invalid_token_returns_401(self):
        response = self.client.get(
            "/dashboard/stats",
            headers={"Authorization": "Bearer invalid.token.value"}
        )
        self.assertEqual(response.status_code, 401)

    def test_03_patient_accessing_admin_endpoint_returns_403(self):
        response = self.client.get(
            "/dashboard/stats",
            headers={"Authorization": f"Bearer {self.patient_token}"}
        )
        self.assertEqual(response.status_code, 403)
        self.assertIn("Administrator privileges required", response.json()["detail"])

    def test_04_admin_login_success(self):
        response = self.client.post(
            "/admin/login",
            json={"email": "admin@aakriti.com", "password": "809056"}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertIn("access_token", data["data"])
        self.assertEqual(data["data"]["role"], "admin")

    def test_05_admin_access_allowed(self):
        response = self.client.get(
            "/dashboard/stats",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        stats = data.get("data") if "data" in data and isinstance(data["data"], dict) else data
        self.assertIn("total_patients", stats)

    def test_06_verify_role_admin(self):
        response = self.client.get(
            "/api/auth/verify-role",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["is_admin"])
        self.assertEqual(data["role"], "admin")

    def test_07_verify_role_patient(self):
        response = self.client.get(
            "/api/auth/verify-role",
            headers={"Authorization": f"Bearer {self.patient_token}"}
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertFalse(data["is_admin"])
        self.assertEqual(data["role"], "patient")

    def test_08_patient_ownership_allowed_for_own_id(self):
        response = self.client.get(
            "/appointments/patient/P-TEST-1",
            headers={"Authorization": f"Bearer {self.patient_token}"}
        )
        self.assertEqual(response.status_code, 200)

    def test_09_patient_ownership_denied_for_other_id(self):
        response = self.client.get(
            "/appointments/patient/P-OTHER-99",
            headers={"Authorization": f"Bearer {self.patient_token}"}
        )
        self.assertEqual(response.status_code, 403)
        self.assertIn("You can only view your own appointments", response.json()["detail"])

    def test_10_admin_can_access_any_patient_records(self):
        response = self.client.get(
            "/appointments/patient/P-OTHER-99",
            headers={"Authorization": f"Bearer {self.admin_token}"}
        )
        self.assertEqual(response.status_code, 200)

if __name__ == "__main__":
    unittest.main()
