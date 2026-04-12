from enum import Enum


class DamageType(str, Enum):
    pothole = "pothole"
    crack = "crack"
    broken_sign = "broken_sign"
    flooding = "flooding"
    debris = "debris"
    other = "other"


class Severity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class ReportStatus(str, Enum):
    pending = "pending"
    verified = "verified"
    rejected = "rejected"
    under_review = "under_review"
    resolved = "resolved"
