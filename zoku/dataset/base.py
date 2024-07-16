class DefaultDataset:
    """
    Base class for datasets. All datasets must inherit from here.

    Attributes:
        name (str): Name of the dataset.
    """

    def __init__(self, name=None):
        """
        Initializes DefaultDataset with a name.

        Args:
            name (str): The name of the dataset.
        """
        self.name = "__default_dataset" if name is None else name

    def __str__(self):
        """
        Displays the name of the dataset when converted to str.
        """
        return self.name

    def get_lite(self):
        """
        Returns a lite dataset. Useful for unittest
        """
        raise NotImplementedError
