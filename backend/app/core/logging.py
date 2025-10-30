"""
Structured logging configuration using loguru.

Provides consistent, structured logging throughout the application
with contextual information, proper levels, and JSON formatting.
"""
from loguru import logger
import sys
import os


def setup_logging(level: str = "INFO", json_logs: bool = False):
    """
    Configure application-wide logging.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        json_logs: If True, output logs as JSON (useful for production)
    """
    # Remove default handler
    logger.remove()

    # Determine format based on environment
    if json_logs:
        # JSON format for production (easier to parse by log aggregators)
        logger.add(
            sys.stdout,
            format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {name}:{function}:{line} | {message}",
            level=level,
            serialize=True,  # Output as JSON
            enqueue=True,  # Thread-safe
        )
    else:
        # Human-readable format for development
        logger.add(
            sys.stdout,
            format="<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | <level>{message}</level>",
            level=level,
            colorize=True,
            enqueue=True,
        )

    # Optionally add file logging with rotation
    log_dir = os.getenv("LOG_DIR", "./logs")
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)

    # Rotate logs daily, keep for 7 days
    logger.add(
        f"{log_dir}/app.log",
        rotation="00:00",  # Rotate at midnight
        retention="7 days",  # Keep for 7 days
        level=level,
        format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {name}:{function}:{line} | {message}",
        enqueue=True,
    )

    logger.info(f"Logging initialized at {level} level")


def get_logger(name: str = __name__):
    """
    Get a logger instance with context.

    Args:
        name: Logger name (typically __name__)

    Returns:
        Configured logger instance
    """
    return logger.bind(name=name)
