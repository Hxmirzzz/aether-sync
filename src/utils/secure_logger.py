import logging
import re

class SecureFormatter(logging.Formatter):
    """
        Formateador de logs que aplica expresiones regulares para enmascarar
        datos sensibles y evitar fugas de información en texto plano.
    """
    SENSITIVE_PATTERNS = [
        (re.compile(r"'tax_identification':\s*'[^']+'"), "'tax_identification': '***MASKED***'"),
        (re.compile(r"'client_code':\s*'[^']+'"), "'client_code': '***MASKED***'")
    ]

    def format(self, record):
        original_message = super().format(record)

        for pattern, replacement in self.SENSITIVE_PATTERNS:
            original_message = pattern.sub(replacement, original_message)

        return original_message

def get_logger(name: str = "AetherSync") -> logging.Logger:
    logger = logging.getLogger(name)

    if not logger.hasHandlers():
        logger.setLevel(logging.INFO)

        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)

        formatter = SecureFormatter('%(asctime)s - [%(levelname)s] - %(name)s - %(message)s')
        console_handler.setFormatter(formatter)

        logger.addHandler(console_handler)

    return logger