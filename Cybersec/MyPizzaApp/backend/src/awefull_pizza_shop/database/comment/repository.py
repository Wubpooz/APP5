from sqlgen import AsyncConstrainedRepository

from awefull_pizza_shop.database.models import Comment, Pizza


class CommentRepository(AsyncConstrainedRepository):
    cls = Comment
    bound_model = Pizza
