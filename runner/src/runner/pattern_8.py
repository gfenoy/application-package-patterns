# ## 8. one input, optional output

# The CWL includes:
# - one input parameter of type `Directory`
# - one output parameter of type `Directory?`

# This scenario takes as input an acquisition, applies an algorithm and may or may not generate and output

# Implementation: detects water bodies using the Normalized Difference Water Index (NDWI) and Otsu thresholding.

import os
import sys
import click
from loguru import logger
import rasterio
import pystac
import shutil
import rio_stac
from runner.functions import (
    aoi2box,
    crop,
    get_asset,
    normalized_difference,
    threshold,
    get_item,
)


@click.command(
    short_help="Water bodies detection",
    help="Detects water bodies using the Normalized Difference Water Index (NDWI) and Otsu thresholding.",
)
@click.option(
    "--input-item",
    "item_url",
    help="STAC Item URL or staged STAC catalog",
    required=True,
)
@click.option(
    "--aoi",
    "aoi",
    help="Area of interest expressed as a bounding box",
    required=True,
)
@click.option(
    "--epsg",
    "epsg",
    help="EPSG code",
    required=True,
)
@click.option(
    "--band",
    "bands",
    help="Common band name",
    required=True,
    multiple=True,
)
@click.option(
    "--produce-output",
    "produce_output",
    help="Flag to produce the output",
    is_flag=True,
)
def pattern_8(item_url, aoi, bands, epsg, produce_output):

    if not produce_output:
        logger.info("Will not produce anything")
        sys.exit(0)

    item = get_item(item_url)

    logger.info(f"Read {item.id} from {item.get_self_href()}")

    cropped_assets = {}

    for band in bands:
        asset = get_asset(item, band)
        logger.info(f"Read asset {band} from {asset.get_absolute_href()}")

        if not asset:
            msg = f"Common band name {band} not found in the assets"
            logger.error(msg)
            raise ValueError(msg)

        bbox = aoi2box(aoi)

        out_image, out_meta = crop(asset, bbox, epsg)

        cropped_assets[band] = out_image[0]

    nd = normalized_difference(cropped_assets[bands[0]], cropped_assets[bands[1]])

    water_bodies = threshold(nd)

    out_meta.update(
        {
            "dtype": "uint8",
            "driver": "COG",
            "tiled": True,
            "compress": "lzw",
            "blockxsize": 256,
            "blockysize": 256,
        }
    )

    water_body = "otsu.tif"

    with rasterio.open(water_body, "w", **out_meta) as dst_dataset:
        logger.info("Write otsu.tif")
        dst_dataset.write(water_bodies, indexes=1)

    logger.info("Creating a STAC Catalog")
    cat = pystac.Catalog(id="catalog", description="water-bodies")

    if os.path.isdir(item_url):
        catalog = pystac.read_file(os.path.join(item_url, "catalog.json"))
        item = next(catalog.get_items())
    else:
        item = pystac.read_file(item_url)

    os.makedirs(os.path.join("output", item.id), exist_ok=True)
    shutil.copy(water_body, os.path.join("output", item.id))

    out_item = rio_stac.stac.create_stac_item(
        source=water_body,
        input_datetime=item.datetime,
        id=item.id,
        asset_roles=["data", "visual"],
        asset_href=os.path.basename(water_body),
        asset_name="data",
        with_proj=True,
        with_raster=True,
    )

    os.remove(water_body)
    cat.add_items([out_item])

    cat.normalize_and_save(
        root_href="./output", catalog_type=pystac.CatalogType.SELF_CONTAINED
    )

    logger.info("Done!")
