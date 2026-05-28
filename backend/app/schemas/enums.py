from enum import Enum


class DamageType(str, Enum):
    pothole = "pothole"
    longitudinal_crack = "longitudinal_crack"
    transverse_crack = "transverse_crack"
    alligator_crack = "alligator_crack"
    other = "other"

    @classmethod
    def _missing_(cls, value: object):
        if not isinstance(value, str):
            return None

        normalized = value.strip().lower().replace("-", "_").replace(" ", "_")
        aliases = {
            "other": cls.other,
            "otherdamage": cls.other,
            "other_damage": cls.other,
            "other_damages": cls.other,
        }
        return aliases.get(normalized)


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
