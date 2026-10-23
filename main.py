import sys
import os

backend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "aakriti_backend")
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

try:
    os.chdir(backend_dir)
except Exception as e:
    pass

from main import app  # noqa: F401
