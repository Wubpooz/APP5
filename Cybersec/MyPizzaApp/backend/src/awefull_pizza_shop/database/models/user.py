import enum
import typing

from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from awefull_pizza_shop.database.models.base import Base, TimestampMixin

if typing.TYPE_CHECKING:
    from awefull_pizza_shop.database.models import Comment


class UserRole(enum.Enum):
    ADMIN = "Admin"
    USER = "User"


class User(TimestampMixin, Base):
    __tablename__ = "user"
    __table_args__ = (UniqueConstraint("name"),)

    name: Mapped[str]
    hashed_password: Mapped[bytes]
    email: Mapped[str]
    role: Mapped[UserRole] = mapped_column(default=UserRole.USER)
    disabled: Mapped[bool] = mapped_column(default=False)

    comments: Mapped[list["Comment"]] = relationship(back_populates="creator", cascade="all, delete-orphan")
