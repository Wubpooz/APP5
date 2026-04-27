import typing

from sqlalchemy.orm import Mapped, relationship

from awefull_pizza_shop.database.models.base import Base, TimestampMixin, USER_FK, PIZZA_FK

if typing.TYPE_CHECKING:
    from awefull_pizza_shop.database.models import User, Pizza


class Comment(TimestampMixin, Base):
    __tablename__ = "pizza_comment"

    creator_id: Mapped[USER_FK]
    pizza_id: Mapped[PIZZA_FK]

    content: Mapped[str]

    creator: Mapped["User"] = relationship(back_populates="comments")
    pizza: Mapped["Pizza"] = relationship(back_populates="comments")
