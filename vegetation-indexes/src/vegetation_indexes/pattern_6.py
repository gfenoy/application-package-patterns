# ## 6. one input, no output

# The CWL includes: 
# - one input parameter of type `Directory`
# - there are no output parameters of type `Directory`

# This corner-case scenario takes as input an acquisition, applies an algorithm and generates an output that is not a STAC Catalog

# Implementation: derive the NDVI mean taking as input a Landsat-9 acquisition


import sys
import click
from loguru import logger
import numpy as np
from vegetation_indexes.functions import (aoi2box, crop, get_asset,
    normalized_difference, get_item)

@click.command(
    short_help="Vegetation index mean",
    help="Calculates the mean of the Normalized Difference Vegetation Index (NDVI) from Landsat-9 data.",
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
def pattern_6(item_url, aoi, epsg):

    item = get_item(item_url)

    logger.info(f"Read {item.id} from {item.get_self_href()}")

    cropped_assets = {}

    for band in ["red", "nir08"]:
        asset = get_asset(item, band)
        logger.info(f"Read asset {band} from {asset.get_absolute_href()}")

        if not asset:
            msg = f"Common band name {band} not found in the assets"
            logger.error(msg)
            raise ValueError(msg)

        bbox = aoi2box(aoi)

        out_image, out_meta = crop(asset, bbox, epsg)

        cropped_assets[band] = out_image[0]

    # calculate the mean of the NDVI excluding NaN values
    logger.info("Calculating NDVI mean...")
    mean = np.nanmean(normalized_difference(cropped_assets["nir08"], cropped_assets["red"]))
  
    sys.stdout.write(str(mean))

    logger.info("Done!")