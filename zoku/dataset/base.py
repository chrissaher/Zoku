class DefaultDataset:
    def __init__(self, name=None):
        self.name = "__default_dataset" if name is None else name

    def __str__(self):
        return self.name

    def get_lite(self):
        "Returns a small dataset. Useful for unittest"
        raise NotImplementedError
