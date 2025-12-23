import logging
import sys
import os

# Define log file path
LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "backend.log")

# Create formatters and handlers
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

file_handler = logging.FileHandler(LOG_FILE)
file_handler.setFormatter(formatter)
file_handler.setLevel(logging.INFO)

console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(formatter)
console_handler.setLevel(logging.INFO)

# Configure Root Logger
# This captures EVERYTHING (app, libraries, uvicorn error, etc.)
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)

# Clear existing handlers (e.g. from Uvicorn default config)
if root_logger.hasHandlers():
    root_logger.handlers.clear()

root_logger.addHandler(console_handler)
root_logger.addHandler(file_handler)

# Configure Uvicorn Access Logger explicitly to ensure access logs stored
# Uvicorn sometimes uses its own non-propagating logger for access logs
uvicorn_access = logging.getLogger("uvicorn.access")
if uvicorn_access.hasHandlers():
    uvicorn_access.handlers.clear()
uvicorn_access.addHandler(console_handler)
uvicorn_access.addHandler(file_handler)
uvicorn_access.propagate = False # Keep it separate or True if we want double logging (safest is explicit handlers + no propagate)

def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger instance.
    Since we configured the root logger, we just return the requested logger.
    It will propagate up to root and be logged.
    """
    return logging.getLogger(name)