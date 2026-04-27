from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from awefull_pizza_shop.database.models.user import UserRole


class UserBase(BaseModel):
    name: str
    email: EmailStr


class UserCreation(UserBase):
    password: str


class UserUpdate(UserBase):
    role: UserRole = Field(default=UserRole.USER)


class User(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    role: UserRole
    disabled: bool
