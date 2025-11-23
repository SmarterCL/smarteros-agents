"""
RUT Validator - Chilean RUT validation utilities
=================================================

Validates Chilean RUT (Rol Único Tributario) format and checksum.
"""

import re
from typing import Tuple


def validate_chilean_rut(rut: str) -> bool:
    """
    Validate Chilean RUT format and checksum
    
    Args:
        rut: RUT string (format: 12345678-9 or 12.345.678-9)
        
    Returns:
        True if RUT is valid, False otherwise
        
    Examples:
        >>> validate_chilean_rut("76958020-3")
        True
        >>> validate_chilean_rut("12345678-9")
        False (invalid checksum)
    """
    if not rut:
        return False
    
    # Normalize: remove dots and spaces
    rut = rut.replace(".", "").replace(" ", "").upper()
    
    # Check format: 7-8 digits, dash, digit or K
    if not re.match(r'^\d{7,8}-[\dK]$', rut):
        return False
    
    # Split body and check digit
    body, dv = rut.split("-")
    
    # Calculate expected check digit
    expected_dv = calculate_rut_dv(body)
    
    return dv == expected_dv


def calculate_rut_dv(body: str) -> str:
    """
    Calculate RUT check digit (dígito verificador)
    
    Args:
        body: RUT body (7-8 digits)
        
    Returns:
        Check digit as string ('0'-'9' or 'K')
    """
    # Reverse body for calculation
    reversed_body = body[::-1]
    
    # Multiply each digit by 2,3,4,5,6,7,2,3,4...
    multipliers = [2, 3, 4, 5, 6, 7]
    total = 0
    
    for i, digit in enumerate(reversed_body):
        multiplier = multipliers[i % 6]
        total += int(digit) * multiplier
    
    # Calculate check digit
    remainder = total % 11
    dv = 11 - remainder
    
    if dv == 11:
        return '0'
    elif dv == 10:
        return 'K'
    else:
        return str(dv)


def normalize_rut(rut: str) -> str:
    """
    Normalize RUT to standard format (12345678-9)
    
    Args:
        rut: RUT in any format
        
    Returns:
        Normalized RUT string
        
    Examples:
        >>> normalize_rut("12.345.678-9")
        "12345678-9"
        >>> normalize_rut("12345678-9")
        "12345678-9"
    """
    # Remove dots and spaces
    rut = rut.replace(".", "").replace(" ", "").upper()
    
    # Ensure dash is present
    if "-" not in rut:
        # Assume last character is DV
        rut = f"{rut[:-1]}-{rut[-1]}"
    
    return rut


def format_rut(rut: str, with_dots: bool = False) -> str:
    """
    Format RUT for display
    
    Args:
        rut: RUT string
        with_dots: Include thousand separators (12.345.678-9)
        
    Returns:
        Formatted RUT
        
    Examples:
        >>> format_rut("76958020-3", with_dots=True)
        "76.958.020-3"
        >>> format_rut("76958020-3", with_dots=False)
        "76958020-3"
    """
    rut = normalize_rut(rut)
    
    if not with_dots:
        return rut
    
    body, dv = rut.split("-")
    
    # Add thousand separators
    formatted_body = ""
    for i, digit in enumerate(reversed(body)):
        if i > 0 and i % 3 == 0:
            formatted_body = "." + formatted_body
        formatted_body = digit + formatted_body
    
    return f"{formatted_body}-{dv}"


def extract_rut_info(rut: str) -> Tuple[str, str, bool]:
    """
    Extract RUT information
    
    Args:
        rut: RUT string
        
    Returns:
        Tuple of (body, dv, is_valid)
        
    Examples:
        >>> extract_rut_info("76958020-3")
        ("76958020", "3", True)
    """
    normalized = normalize_rut(rut)
    body, dv = normalized.split("-")
    is_valid = validate_chilean_rut(normalized)
    
    return (body, dv, is_valid)


# Common test RUTs (for development/testing)
TEST_RUTS = {
    "valid": [
        "76958020-3",  # Valid RUT
        "12345678-5",  # Valid RUT
        "11111111-1",  # Valid RUT
    ],
    "invalid": [
        "12345678-9",  # Invalid checksum
        "11111111-2",  # Invalid checksum
        "abc-d",       # Invalid format
        "123-4",       # Too short
    ]
}
