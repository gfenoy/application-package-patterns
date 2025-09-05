import os
import click
import pystac
import rasterio
from skimage.filters import threshold_otsu
from rasterio.mask import mask
from pyproj import Transformer
from shapely import box
from loguru import logger
import rasterio
import pystac
import shutil
import rio_stac
import numpy as np

np.seterr(divide="ignore", invalid="ignore")


def get_item(item_url):

    if os.path.isdir(item_url):
        catalog = pystac.read_file(os.path.join(item_url, "catalog.json"))
        item = next(catalog.get_items())
    else:
        item = pystac.read_file(item_url)

    return item


def crop(asset: pystac.Asset, bbox, epsg):
    """_summary_

    Args:
        asset (_type_): _description_
        bbox (_type_): _description_
        epsg (_type_): _description_

    Returns:
        _type_: _description_
    """
    with rasterio.open(asset.get_absolute_href()) as src:
        transformer = Transformer.from_crs(epsg, src.crs, always_xy=True)

        minx, miny = transformer.transform(bbox[0], bbox[1])
        maxx, maxy = transformer.transform(bbox[2], bbox[3])

        transformed_bbox = box(minx, miny, maxx, maxy)

        logger.info(f"Crop {asset.get_absolute_href()}")

        out_image, out_transform = rasterio.mask.mask(
            src, [transformed_bbox], crop=True
        )
        out_meta = src.meta.copy()

        out_meta.update(
            {
                "height": out_image.shape[1],
                "width": out_image.shape[2],
                "transform": out_transform,
            }
        )

        return out_image.astype(np.float32), out_meta


def threshold(data):
    """Returns the Otsu threshold of a numpy array"""
    return data > threshold_otsu(data[np.isfinite(data)])


def normalized_difference(array1, array2):
    """Returns the normalized difference of two numpy arrays"""
    return (array1 - array2) / (array1 + array2)


def aoi2box(aoi):
    """Converts an area of interest expressed as a bounding box to a list of floats"""
    return [float(c) for c in aoi.split(",")]


def get_asset(item, common_name):
    """Returns the asset of a STAC Item defined with its common band name"""
    for _, asset in item.get_assets().items():
        if not "data" in asset.to_dict()["roles"]:
            continue

        eo_asset = pystac.extensions.eo.AssetEOExtension(asset)
        if not eo_asset.bands:
            continue
        for b in eo_asset.bands:
            if (
                "common_name" in b.properties.keys()
                and b.properties["common_name"] == common_name
            ):
                return asset
