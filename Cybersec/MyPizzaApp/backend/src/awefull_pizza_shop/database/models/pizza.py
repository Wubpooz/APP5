import enum
import typing

from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import Mapped, relationship

from awefull_pizza_shop.database.models.base import Base, TimestampMixin

if typing.TYPE_CHECKING:
    from awefull_pizza_shop.database.models import Comment


class PizzaCategory(enum.Enum):
    MEAT = "meat"
    FISH = "FISH"
    VEGAN = "vegan"


class Pizza(TimestampMixin, Base):
    __tablename__ = "pizza"
    __table_args__ = (UniqueConstraint("name"),)

    name: Mapped[str]
    price: Mapped[float]
    image_url: Mapped[str]
    description: Mapped[str]
    category: Mapped[PizzaCategory]

    comments: Mapped[list["Comment"]] = relationship(back_populates="pizza", cascade="all, delete-orphan")
