# ## one input/two outputs

# The CWL includes: 
# - one input parameter of type `Directory`
# - two output parameters of type `Directory`

# This scenario takes as input an acquisition, applies two algorithms and generates two outputs.

# Implementation: process the NDVI and NDWI taking as input a Landsat-9 acquisition. The output include two STAC Catalogs, each with a single STAC Item

import os
import click
import pystac
import rasterio
from loguru import logger
import shutil
import rio_stac
from runner.functions import (aoi2box, crop, get_asset,
    normalized_difference, get_item)

@click.command(
    short_help="NDVI and NDWI vegetation indexes",
    help="Calculates NDVI and NDWI vegetation indexes from Landsat-9 data.",
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
def pattern_4(item_url, aoi, epsg):

    item = get_item(item_url)

    logger.info(f"Read {item.id} from {item.get_self_href()}")

    cropped_assets = {}

    for band in ["red", "green", "nir08"]:
        asset = get_asset(item, band)
        logger.info(f"Read asset {band} from {asset.get_absolute_href()}")

        if not asset:
            msg = f"Common band name {band} not found in the assets"
            logger.error(msg)
            raise ValueError(msg)

        bbox = aoi2box(aoi)

        out_image, out_meta = crop(asset, bbox, epsg)

        cropped_assets[band] = out_image[0]

    ndvi = normalized_difference(cropped_assets["nir08"], cropped_assets["red"])
    ndwi = normalized_difference(cropped_assets["green"], cropped_assets["nir08"])

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

    for name, output in [("ndvi", ndvi), ("ndwi", ndwi)]:

        with rasterio.open(f"{name}.tif", "w", **out_meta) as dst_dataset:
            logger.info(f"Write output {name}.tif")
            dst_dataset.write(output, indexes=1)


        cat = pystac.Catalog(id="catalog", description=f"{name} vegetation index")

        os.makedirs(name, exist_ok=True)
       
        

        out_item = rio_stac.stac.create_stac_item(
            source=f"{name}.tif",
            input_datetime=item.datetime,
            id=name,
            asset_roles=["data", "visual"],
            asset_href=os.path.basename(f"{name}.tif"),
            asset_name="data",
            with_proj=True,
            with_raster=True,
        )
        
        cat.add_items([out_item])

        cat.normalize_and_save(
            root_href=f"./{name}", catalog_type=pystac.CatalogType.SELF_CONTAINED
        )
        shutil.copy(f"{name}.tif", os.path.join(name, name, f"{name}.tif"))
        os.remove(f"{name}.tif")

    logger.info("Done!")