# # one input/one output

# The CWL includes: 
# - one input parameter of type `Directory`
# - one output parameter of type `Directory`

# This scenario typically takes one input, applies an algorithm and produces a result

# Implementation: process the NDVI taking as input a Landsat-9 acquisition


import os
import click
import pystac
import rasterio
from loguru import logger
import shutil
import rio_stac
from vegetation_indexes.functions import (aoi2box, crop, get_asset,
    normalized_difference, threshold, get_item)

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
    "--dem",
    "dem",
    help="Digital Elevation Model (DEM) geotiff",
    required=True,
    multiple=False,
)
def pattern_11(item_url, aoi, bands, epsg, dem):

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

    
    if os.path.isdir(item_url):
        catalog = pystac.read_file(os.path.join(item_url, "catalog.json"))
        item = next(catalog.get_items())
    else:
        item = pystac.read_file(item_url)

    os.makedirs(item.id, exist_ok=True)
    shutil.copy(water_body, item.id)

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

    # DEM
    logger.info(f"Cropping DEM {dem} {type(dem)}")
    input_dem_asset = pystac.Asset(
        href=dem,
        title="Digital Elevation Model",
    )

    out_image, out_meta = crop(input_dem_asset, bbox, epsg)

    with rasterio.open("dem.tif", "w", **out_meta) as dst_dataset:
        logger.info("Write dem.tif")
        dst_dataset.write(out_image[0], indexes=1)

    dem_asset = pystac.Asset(
        href=os.path.basename("dem.tif"),
        title="Digital Elevation Model",
        media_type=pystac.MediaType.GEOTIFF,
        roles=["data", "visual"],
    )

    out_item.add_asset(
        "dem",
        dem_asset,
    )
    shutil.copy("dem.tif", item.id)
    os.remove("dem.tif")
    os.remove(water_body)

    logger.info("Creating a STAC Catalog")
    cat = pystac.Catalog(id="catalog", description="water-bodies")

    cat.add_items([out_item])

    cat.normalize_and_save(
        root_href="./", catalog_type=pystac.CatalogType.SELF_CONTAINED
    )

    logger.info("Done!")