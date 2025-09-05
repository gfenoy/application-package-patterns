import pystac
import stac_asset
import asyncio
import os
import click
from stac_asset import http_client
import aiohttp
import aiohttp
from stac_asset import http_client

import aiohttp
from functools import wraps

_original_init = aiohttp.TCPConnector.__init__


@wraps(_original_init)
def _patched_init(self, *args, **kwargs):
    kwargs["force_close"] = True
    _original_init(self, *args, **kwargs)


aiohttp.TCPConnector.__init__ = _patched_init

config = stac_asset.Config(warn=True)


async def main(href: str, output_dir: str):
    item = pystac.read_file(href)

    target_dir = os.path.join(output_dir, item.id)
    os.makedirs(target_dir, exist_ok=True)

    cwd = os.getcwd()
    os.chdir(target_dir)

    item = await stac_asset.download_item(item=item, directory=".", config=config)

    os.chdir(cwd)

    cat = pystac.Catalog(
        id="catalog",
        description=f"Catalog with staged {item.id}",
        title=f"Catalog with staged {item.id}",
    )
    cat.add_item(item)

    cat.normalize_hrefs(target_dir)
    cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

    return cat


@click.command()
@click.argument("href")
@click.option(
    "--output-dir",
    default=".",
    show_default=True,
    help="Directory where the catalog will be saved",
)
def cli(href, output_dir):
    """Download STAC item and stage into a self-contained STAC catalog."""
    asyncio.run(main(href, output_dir))


if __name__ == "__main__":
    cli()
