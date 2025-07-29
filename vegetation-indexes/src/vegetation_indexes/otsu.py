import os
import click
import pystac
import rasterio
from loguru import logger
import shutil
import rio_stac
from vegetation_indexes.functions import threshold, get_item


@click.command(
    short_help="Water bodies detection",
    help="Detects water bodies using the Normalized Difference Water Index (NDWI) and Otsu thresholding.",
)
@click.option(
    "--input-ndi",
    "item_ndi",
    help="Normalized Difference Index (NDI) STAC catalog",
)
@click.option("--item", 
              "ls9_item", 
              help="Landsat STAC Item", 
              required=True)
@click.option(
    "--collection",
    "collection_url",
    help="STAC collection",
    required=False,
)
def otsu_cli(item_ndi, ls9_item, collection_url):
    """
    Detects water bodies using the Otsu thresholding method on the NDI.
    """

    collection: pystac.Collection = pystac.read_file(collection_url) if collection_url else None

    # read STAC Catalog
    item_ndi: pystac.Item = get_item(item_ndi)
    ls9_item: pystac.Item = get_item(ls9_item)

    # get assets
    asset_ndi: pystac.Asset = item_ndi.assets.get("data")

    if not asset_ndi:
        msg = "NDI asset not found in the item"
        logger.error(msg)
        raise ValueError(msg)

    # read data
    with rasterio.open(asset_ndi.get_absolute_href()) as src:
        data = src.read(1)
        out_meta = src.meta.copy()

    # apply Otsu thresholding
    otsu_data = threshold(data)

    otsu = "otsu.tif"

    out_meta.update(
        {
            "dtype": "uint8",
            "driver": "GTiff",
            "compress": "lzw",
            "tiled": True,
        }
    )

    with rasterio.open(otsu, "w", **out_meta) as dst_dataset:
        dst_dataset.write(otsu_data.astype(rasterio.uint8), 1)

    logger.info(f"Otsu output written to {otsu}")

    logger.info("Creating a STAC Catalog")
    cat = pystac.Catalog(id="catalog", description=f"Detected water bodies from {ls9_item.id}")

    output_item_id = f"water-body-{ls9_item.id}".lower()

    os.makedirs(output_item_id, exist_ok=True)
    shutil.copy(otsu, output_item_id)

    # Create a STAC Item for the output
    out_item = rio_stac.stac.create_stac_item(
        source=otsu,
        input_datetime=ls9_item.datetime,
        id=output_item_id,
        asset_roles=["data", "visual"],
        asset_href=os.path.basename(otsu),
        asset_name="data",
    )

    out_item.properties["renders"] = {
        "overview": {
            "title": "Detected Water Bodies",
            "assets": ["data"],
            "nodata": 0,
            "colormap": {
                "1": "0000FF",       
            },
            "resampling": "nearest"
        }
    }

    if collection:
        logger.info(f"Adding collection {collection.id} to the output item")
        out_item.collection_id = collection.id

    os.remove(otsu)
    cat.add_items([out_item])
    
    cat.normalize_and_save(
        root_href="./", catalog_type=pystac.CatalogType.SELF_CONTAINED
    )

    logger.info("Otsu thresholding completed and saved to STAC catalog.")