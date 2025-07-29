# crop CLI
import os
import click
from runner.functions import crop, get_item, get_asset, aoi2box
import pystac
import rasterio
from loguru import logger
import shutil
import rio_stac

@click.command(
    short_help="Crop",
    help="Crops a STAC Item asset defined with its common band name",
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
    "band",
    help="Common band name",
    required=True,
)
@click.option(
    "--collection",
    "collection_url",
    help="STAC collection",
    required=False,
)
def crop_cli(item_url, aoi, band, epsg, collection_url):

    collection: pystac.Collection = pystac.read_file(collection_url) if collection_url else None

    item = get_item(item_url)

    logger.info(f"Read {item.id} from {item.get_self_href()}")

    asset = get_asset(item, band)
    logger.info(f"Read asset {band} from {asset.get_absolute_href()}")

    if not asset:
        msg = f"Common band name {band} not found in the assets"
        logger.error(msg)
        raise ValueError(msg)

    bbox = aoi2box(aoi)

    out_image, out_meta = crop(asset, bbox, epsg)

    cropped = f"{band}_cropped.tif"

    with rasterio.open(cropped, "w", **out_meta) as dst_dataset:
        logger.info(f"Write {cropped}")
        dst_dataset.write(out_image[0], indexes=1)

    logger.info("Creating a STAC Catalog")
    cat = pystac.Catalog(id="catalog", description=f"Cropped {item.id} {band}")

    output_item_id = f"cropped-{band}-{item.id}".lower()

    os.makedirs(output_item_id, exist_ok=True)
    shutil.copy(cropped, output_item_id)

    out_item: pystac.Item = rio_stac.stac.create_stac_item(
        source=cropped,
        input_datetime=item.datetime,
        id=output_item_id,
        asset_roles=["data", "visual"],
        asset_href=os.path.basename(cropped),
        asset_name="data",
        with_proj=True,
        with_raster=True,
    )

    out_item.properties["renders"] = {
        "reflectance": {
            "title": "Reflectance",
            "assets": ["data"],
            "nodata": "0",
            "resampling": "nearest",
			"rescale": [[0,3000]],
			"colormap_name": "blues_r"
        }
    }

    if collection:
        logger.info(f"Adding collection {collection.id} to the output item")
        out_item.collection_id = collection.id


    os.remove(cropped)
    cat.add_items([out_item])

    cat.normalize_and_save(
        root_href="./", catalog_type=pystac.CatalogType.SELF_CONTAINED
    )

    logger.info("Done!")