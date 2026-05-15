from typing import Annotated
from uuid import UUID

import aiohttp

from awefull_pizza_shop.database.comment.service import CommentService
from awefull_pizza_shop.webserver import schemas
from awefull_pizza_shop.webserver.config import settings
from awefull_pizza_shop.webserver.dependencies.database_service import get_comment_service
from awefull_pizza_shop.webserver.dependencies.user import validate_user_admin, get_current_active_user
from awefull_pizza_shop.webserver.tags import Tags
from fastapi import APIRouter, Depends, Response
from starlette import status

from awefull_pizza_shop.database.models import User

router = APIRouter(
    prefix="/pizza/{pizza_id}/comment",
    tags=[Tags.COMMENT.value],
    dependencies=[Depends(get_current_active_user)]
)


@router.get("/")
async def get_comments(service: Annotated[CommentService, Depends(get_comment_service)]) -> list[schemas.Comment]:
    """
    Get all the comments
    """
    return await service.get_comments()


@router.get("/{comment_id}")
async def get_comment_by_id(comment_id: UUID,
                            service: Annotated[CommentService, Depends(get_comment_service)]
                            ) -> schemas.Comment:
    """
    Get a comment by its id
    """
    return await service.take_comment_by_id(comment_id, load_all=True)


@router.post("/create")
async def create_comment(service: Annotated[CommentService, Depends(get_comment_service)],
                         comment_data: schemas.CommentCreation,
                         creator: Annotated[User, Depends(get_current_active_user)],
                         pizza_id:UUID
                         ):
    """
    Get a comment by its id
    """
    await service.create_comment(creator_id=creator.id, content=comment_data.content)
    print(f"Comment created for pizza {pizza_id} by user {creator.username}, triggering XSS poller")
    async with aiohttp.ClientSession() as session:
        async with session.get(f"{settings.XSS_POLLER_URL}/{pizza_id}") as response:
            print(f"XSS poller response status: {response.status}")
            xss_poller = await response.text()
    return Response(body=xss_poller, status_code=status.HTTP_201_CREATED)
