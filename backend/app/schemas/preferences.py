from pydantic import BaseModel, Field


class EmailPreferences(BaseModel):
    incident_digest: bool = True
    milestone_alerts: bool = True
    product_updates: bool = False


class SecurityPreferences(BaseModel):
    two_factor_enabled: bool = False
    biometric_lock: bool = False
    location_masking: bool = False


class AppearancePreferences(BaseModel):
    theme: str = Field(default="streetwatch", min_length=1, max_length=50)
    dark_mode: bool = False


class LanguagePreferences(BaseModel):
    language: str = Field(default="en", min_length=2, max_length=10)


class UserPreferencesRead(BaseModel):
    user_id: str
    email: EmailPreferences
    security: SecurityPreferences
    appearance: AppearancePreferences
    language: LanguagePreferences


class EmailPreferencesUpdate(BaseModel):
    incident_digest: bool
    milestone_alerts: bool
    product_updates: bool


class SecurityPreferencesUpdate(BaseModel):
    two_factor_enabled: bool
    biometric_lock: bool
    location_masking: bool


class AppearancePreferencesUpdate(BaseModel):
    theme: str = Field(min_length=1, max_length=50)
    dark_mode: bool


class LanguagePreferencesUpdate(BaseModel):
    language: str = Field(min_length=2, max_length=10)
