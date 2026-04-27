from typing import Optional
from uuid import UUID

from awefull_pizza_shop.database.comment.repository import CommentRepository
from awefull_pizza_shop.database.models import Comment
from awefull_pizza_shop.database.service import DatabaseService


class CommentService(DatabaseService):
    repository: CommentRepository

    async def take_comment_by_id(self, comment_id: UUID, load_all: bool = False) -> Optional[Comment]:
        return await self.repository.take_by_id(comment_id, load_all=load_all)

    async def create_comment(self, *, creator_id: UUID, content: str) -> Comment:
        """
        create a comment in database and commit or rollback
        :param comment: the comment data
        :return: the created comment model
        """
        comment = await self.repository.create(
            creator_id=creator_id,
            content=content,
        )
        return comment

    async def get_comments(self) -> list[Comment]:
        """
        get all comments in the database
        :return: a list of all comments in database
        """
        return await self.repository.get_all_by(load_all=True)
