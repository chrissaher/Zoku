import pytest

from zoku.dataset.kaggledataset import KaggleDataset


@pytest.mark.parametrize(
    "creator_name, dataset_name",
    [
        ("lantian773030", "pokemonclassification"),
        ("jiscecseaiml", "mental-health-dataset"),
    ],
)
def test_download_from_kaggle(tmp_path, creator_name, dataset_name):
    _ = KaggleDataset(
        creator_name=creator_name, dataset_name=dataset_name, cache_dir=tmp_path
    )
    expected_dataset_dir = tmp_path / creator_name / dataset_name
    assert expected_dataset_dir.exists(), True
    assert any(expected_dataset_dir.iterdir()), True


if __name__ == "__main__":
    dataset = KaggleDataset("lantian773030", "pokemonclassification")
    print("Done")
