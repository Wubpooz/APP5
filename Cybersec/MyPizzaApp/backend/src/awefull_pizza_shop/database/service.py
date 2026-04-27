from sqlgen import AsyncRepository


class DatabaseService[T]:
    """
    Base class for DatabaseServices
    """

    def __init__(self, repository: AsyncRepository[T]):
        """
        :param repository: the repository used for querying the persistent layer of the database
        """
        self.repository = repository
