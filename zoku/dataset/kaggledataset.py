from pathlib import Path
from kaggle.api.kaggle_api_extended import KaggleApi

from zoku.dataset.base import DefaultDataset
from zoku.common.commons import DATASET_CACHE_DIR


class KaggleDataset(DefaultDataset):
    def __init__(self, creator_name, dataset_name, cache_dir=DATASET_CACHE_DIR):
        self.creator_name = creator_name
        self.dataset_name = dataset_name
        self.name = f"{self.creator_name}/{self.dataset_name}"
        super().__init__(self.name)

        kaggle_dataset = self.__get_kaggle_object()
        if not kaggle_dataset:
            raise ValueError("Dataset could not be found.")

        cache_dir = DATASET_CACHE_DIR if cache_dir is None else cache_dir
        cache_dir = Path(cache_dir) / self.creator_name / self.dataset_name

        # Todo: Find a better way to check if files were downloaded
        if not cache_dir.exists():
            cache_dir.mkdir(exist_ok=True, parents=True)
            self.__download(str(cache_dir))

    def __get_kaggle_object(self):
        api = KaggleApi()
        api.authenticate()
        datasets = api.dataset_list(search=self.name)
        for dataset in datasets:
            if dataset.__dict__["ref"] == self.name:
                return dataset
        return None

    def __download(self, download_dir):
        api = KaggleApi()
        api.authenticate()
        api.dataset_download_files(self.name, path=download_dir, unzip=True)
