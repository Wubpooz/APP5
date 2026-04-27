from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, computed_field

from awefull_pizza_shop.webserver.schemas.user import User


class CommentBase(BaseModel):
    content: str


class CommentCreation(CommentBase):
    pass


class Comment(CommentBase):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    creator: Annotated[User, Field(exclude=True)]

    @computed_field(alias="creatorName")
    @property
    def creator_name(self) -> str:
        return self.creator.name
