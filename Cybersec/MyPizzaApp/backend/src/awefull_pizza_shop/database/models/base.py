from datetime import datetime
from typing import Any
from uuid import uuid4, UUID

from pydantic import IPvAnyAddress
from sqlalchemy import func, ForeignKey, JSON, DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy_utils import ScalarListType, IPAddressType
from typing_extensions import Annotated

UUID_PK = Annotated[UUID, mapped_column(primary_key=True)]

USER_FK = Annotated[UUID, mapped_column(ForeignKey("user.id"))]
PIZZA_FK = Annotated[UUID, mapped_column(ForeignKey("pizza.id"))]


class Base(DeclarativeBase):
    type_annotation_map = {
        dict[str, Any]: JSON,
        dict[str, str]: JSON,
        datetime: DateTime(timezone=True),
        IPvAnyAddress: IPAddressType,
        list[IPvAnyAddress]: ScalarListType(IPAddressType)
    }
    id: Mapped[UUID_PK] = mapped_column(default=uuid4)


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(default=func.now())
